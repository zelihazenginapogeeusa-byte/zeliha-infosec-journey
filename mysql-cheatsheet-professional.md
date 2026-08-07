# MySQL Cheat Sheet

**MySQL** is the database engine that shows up most often behind port 3306 during eJPT-style engagements — as a target to enumerate directly (`mysql -h <ip> -u root -p`), as the backend `sqlmap` is fingerprinting during a SQLi attack, or as loot once you already have a foothold and want to pull credentials/config out of a web app's database. This sheet covers the SQL and admin commands themselves; for *how to break in*, see `sqlmap-cheatsheet-professional.md` (injection) and `hydra-cheatsheet-professional.md` (credential brute-force) — this one picks up once you have a shell.

---

## Table of Contents

1. [Connecting](#1-connecting)
2. [Database Operations](#2-database-operations)
3. [Table Operations](#3-table-operations)
4. [CRUD — Insert, Select, Update, Delete](#4-crud--insert-select-update-delete)
5. [WHERE Conditions & Query Clauses](#5-where-conditions--query-clauses)
6. [JOINs](#6-joins)
7. [Aggregate Functions, GROUP BY & HAVING](#7-aggregate-functions-group-by--having)
8. [String & Utility Functions](#8-string--utility-functions)
9. [Indexes](#9-indexes)
10. [Views, Triggers & Stored Procedures](#10-views-triggers--stored-procedures)
11. [User & Privilege Management](#11-user--privilege-management)
12. [Backup & Restore](#12-backup--restore)
13. [Manual Enumeration & Exploitation Notes](#13-manual-enumeration--exploitation-notes)
14. [Quick Command Reference](#14-quick-command-reference)

---

## 1. Connecting

```bash
# Connect, prompt for password
mysql -u root -p

# Connect to a specific host/port (typical during an engagement)
mysql -h <target-ip> -P 3306 -u root -p

# Connect straight into a specific database
mysql -u root -p database_name

# Run a single query non-interactively (useful in scripts / one-liners)
mysql -u root -p -e "SELECT User, Host FROM mysql.user;"

# Exit the shell
exit;
```

| Flag | Meaning |
|---|---|
| `-u` | Username |
| `-p` | Prompt for password (append inline as `-pPASSWORD` with no space — leaks to shell history/process list, avoid outside labs) |
| `-h` | Target host |
| `-P` | Port (default 3306) |
| `-e` | Execute one statement and exit — good for automation |

---

## 2. Database Operations

```sql
SHOW DATABASES;
CREATE DATABASE db_name;
CREATE DATABASE IF NOT EXISTS db_name CHARACTER SET utf8mb4;
USE db_name;
DROP DATABASE db_name;
ALTER DATABASE db_name CHARACTER SET utf8mb4;
```

---

## 3. Table Operations

```sql
SHOW TABLES;
DESCRIBE table_name;               -- alias: SHOW FIELDS FROM table_name;
SHOW CREATE TABLE table_name;      -- full CREATE statement, incl. engine/charset

CREATE TABLE users (
  id INT AUTO_INCREMENT,
  first_name VARCHAR(50),
  last_name  VARCHAR(50),
  email      VARCHAR(100) UNIQUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
);

CREATE TEMPORARY TABLE tmp_table (...);

ALTER TABLE users ADD age VARCHAR(3);
ALTER TABLE users MODIFY COLUMN age INT(3);
ALTER TABLE users DROP COLUMN age;
ALTER TABLE users ADD INDEX (email);

DROP TABLE IF EXISTS users;
```

---

## 4. CRUD — Insert, Select, Update, Delete

```sql
-- Insert
INSERT INTO users (first_name, last_name, email)
VALUES ('Zeliha', 'Zengin', 'zeliha@example.com');

-- Select
SELECT * FROM users;
SELECT first_name, email FROM users;
SELECT DISTINCT location FROM users;

-- Update
UPDATE users SET email = 'new@example.com' WHERE id = 2;

-- Delete
DELETE FROM users WHERE id = 6;
TRUNCATE users;                    -- delete all rows, reset AUTO_INCREMENT (no WHERE)
```

---

## 5. WHERE Conditions & Query Clauses

```sql
SELECT * FROM users WHERE location = 'Colorado';
SELECT * FROM users WHERE location = 'Colorado' AND dept = 'engineering';
SELECT * FROM users WHERE location = 'Colorado' OR location = 'Utah';
SELECT * FROM users WHERE age BETWEEN 20 AND 25;
SELECT * FROM users WHERE dept LIKE 'eng%';
SELECT * FROM users WHERE dept NOT LIKE 'eng%';
SELECT * FROM users WHERE dept IN ('design', 'sales');
SELECT * FROM users WHERE dept NOT IN ('design', 'sales');
SELECT * FROM users WHERE middle_name IS NULL;
SELECT * FROM users WHERE middle_name IS NOT NULL;

SELECT * FROM users
ORDER BY last_name ASC
LIMIT 10;
```

| Operator | Meaning |
|---|---|
| `=` / `<>` | Equal / not equal |
| `LIKE 'val%'` | Pattern match — `%` = any chars, `_` = exactly one char |
| `RLIKE` | Pattern match using a regular expression |
| `IN (...)` / `NOT IN (...)` | Value is/isn't one of a list |
| `IS NULL` / `IS NOT NULL` | Null check (never use `= NULL`, it won't match) |
| `BETWEEN a AND b` | Inclusive range |

---

## 6. JOINs

```sql
-- INNER JOIN — only rows with a match on both sides
SELECT users.first_name, posts.title
FROM users
INNER JOIN posts ON users.id = posts.user_id;

-- LEFT JOIN — all rows from the left table, matched right-side data or NULL
SELECT posts.title, comments.body
FROM posts
LEFT JOIN comments ON posts.id = comments.post_id;

-- Joining three+ tables
SELECT users.first_name, posts.title, comments.body
FROM users
INNER JOIN posts    ON users.id = posts.user_id
INNER JOIN comments ON posts.id = comments.post_id;
```

> Foreign key definition, for reference when reading a schema: `FOREIGN KEY (user_id) REFERENCES users(id)`.

---

## 7. Aggregate Functions, GROUP BY & HAVING

```sql
SELECT COUNT(id) FROM users;
SELECT MAX(age), MIN(age) FROM users;
SELECT SUM(age) FROM users;
SELECT AVG(age) FROM users;

SELECT dept, COUNT(*) FROM users GROUP BY dept;
SELECT dept, COUNT(*) AS total FROM users GROUP BY dept HAVING total >= 2;
```

`WHERE` filters rows before grouping; `HAVING` filters groups after aggregation — that's the whole distinction, and it's a common interview gotcha (see `Interview-Prep/fundamentals-qa.md`).

---

## 8. String & Utility Functions

```sql
SELECT CONCAT(first_name, ' ', last_name) AS full_name FROM users;
SELECT UCASE(first_name), LCASE(last_name) FROM users;
SELECT LENGTH(email) FROM users;
SELECT NOW();                      -- current datetime
SELECT DATABASE();                 -- current database
SELECT VERSION();                  -- MySQL version — first thing to check when enumerating
SELECT CURRENT_USER();             -- who you're authenticated as
```

---

## 9. Indexes

```sql
CREATE INDEX idx_location ON users (location);
CREATE UNIQUE INDEX idx_email ON users (email);
ALTER TABLE users ADD INDEX idx_dept (dept);
DROP INDEX idx_location ON users;
```

---

## 10. Views, Triggers & Stored Procedures

```sql
-- Views
CREATE VIEW active_users AS SELECT * FROM users WHERE active = 1;
CREATE OR REPLACE VIEW active_users AS SELECT * FROM users WHERE active = 1;
DROP VIEW IF EXISTS active_users;

-- Triggers
CREATE TRIGGER before_user_insert
BEFORE INSERT ON users
FOR EACH ROW
SET NEW.created_at = NOW();

DROP TRIGGER IF EXISTS before_user_insert;

-- Stored procedures (note the DELIMITER change so semicolons inside the body don't end it early)
DELIMITER //
CREATE PROCEDURE GetUsersByDept(IN dept_name VARCHAR(50))
BEGIN
  SELECT * FROM users WHERE dept = dept_name;
END //
DELIMITER ;

CALL GetUsersByDept('engineering');
DROP PROCEDURE IF EXISTS GetUsersByDept;
```

---

## 11. User & Privilege Management

The section that matters most once you have a foothold — enumerating what a compromised account can actually do, or setting up persistence.

```sql
-- Who exists, and from where can they connect
SELECT User, Host FROM mysql.user;

-- What can the current/a given account do
SHOW GRANTS;
SHOW GRANTS FOR 'someuser'@'localhost';

CREATE USER 'someuser'@'localhost' IDENTIFIED BY 'S0mePassword!';

GRANT ALL PRIVILEGES ON *.* TO 'someuser'@'localhost';
GRANT SELECT, INSERT, UPDATE ON db_name.* TO 'someuser'@'localhost';
FLUSH PRIVILEGES;                  -- required after manually editing grant tables

REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'someuser'@'localhost';
SET PASSWORD FOR 'someuser'@'localhost' = PASSWORD('NewPass!');
DROP USER 'someuser'@'localhost';
```

> **Enumeration angle:** `FILE` privilege + known web root path is what `sqlmap --os-shell` needs to write a payload (see `sqlmap-cheatsheet-professional.md`); a user with `%` as host (`'root'@'%'`) accepts remote connections from anywhere — worth flagging in a report even without further exploitation.

---

## 12. Backup & Restore

```bash
# Dump a single database to a .sql file
mysqldump -u root -p db_name > db_name_backup.sql

# Dump everything
mysqldump -u root -p --all-databases > full_backup.sql

# Restore from a dump
mysql -u root -p db_name < db_name_backup.sql

# Sanity-check tables after a restore
mysqlcheck -u root -p --all-databases
```

---

## 13. Manual Enumeration & Exploitation Notes

This is the part that separates a DB-admin reference from a pentest one — what to run once you have raw access (a foothold, an exposed port, or a confirmed injection point) and want to enumerate or escalate manually, without `sqlmap`.

### `information_schema` — manual database/table/column enumeration

```sql
-- Version & current context — always start here
SELECT version(), current_user(), database(), @@hostname, @@datadir;

-- Every database on the server
SELECT schema_name FROM information_schema.schemata;

-- Every table, everywhere (or scoped to one database)
SELECT table_schema, table_name FROM information_schema.tables;
SELECT table_name FROM information_schema.tables WHERE table_schema = 'target_db';

-- Every column in a specific table — what you're usually actually after
SELECT column_name, data_type FROM information_schema.columns
WHERE table_schema = 'target_db' AND table_name = 'users';

-- Hunt for interesting column names across the whole server
SELECT table_schema, table_name, column_name FROM information_schema.columns
WHERE column_name LIKE '%pass%' OR column_name LIKE '%email%' OR column_name LIKE '%token%';
```

> This is the manual equivalent of what `sqlmap --dbs / --tables / --columns / --dump` automates (see `sqlmap-cheatsheet-professional.md`) — reach for these when sqlmap isn't an option (WAF in the way, a raw authenticated connection rather than an injection point, or a CTF that wants the manual path shown).

### Reading & writing files — `LOAD_FILE()` / `INTO OUTFILE`

```sql
-- Check whether file read/write is even possible, and where it's restricted to
SHOW VARIABLES LIKE 'secure_file_priv';

-- Read a file off the server's filesystem (needs the FILE privilege)
SELECT LOAD_FILE('/etc/passwd');

-- Write query output to a file on the server (needs FILE + a writable path)
-- <payload> = your own webshell/one-liner — kept as a placeholder here rather than
-- a literal copy-pasteable snippet, since AV/EDR tools commonly signature-match that string.
SELECT '<payload>' INTO OUTFILE '/var/www/html/shell.php';
```

| `secure_file_priv` value | Meaning |
|---|---|
| *(empty string)* | No restriction — read/write anywhere the OS user can |
| `NULL` | `LOAD_FILE` / `INTO OUTFILE` fully disabled |
| `/some/path/` | Restricted to that one directory |

### Privilege escalation via UDF (User Defined Functions)

If an account has `FILE` and `INSERT` on `mysql.func`, a compiled UDF (e.g. the well-known `lib_mysqludf_sys`) can be written to the plugin directory via `INTO OUTFILE` and loaded with `CREATE FUNCTION ... SONAME`, giving OS-level command execution as the MySQL service account.

```sql
-- Confirm the plugin directory a UDF .so must land in
SHOW VARIABLES LIKE 'plugin_dir';

-- After the .so is on disk (via INTO OUTFILE or another upload path):
CREATE FUNCTION sys_exec RETURNS INTEGER SONAME '<udf_library>.so';
SELECT sys_exec('<os_command>');
```

> Depends on MySQL version/config — UDF loading is disabled by default on modern installs — and needs a way to land the compiled `.so` on the box first. Treat as a reference for when the conditions line up, not a first move; for full walkthroughs see HackTricks' MySQL pentesting page or PayloadsAllTheThings' MySQL Injection reference.

---

## 14. Quick Command Reference

| Need | Command |
|---|---|
| Connect to a target's MySQL | `mysql -h <target-ip> -u root -p` |
| List databases | `SHOW DATABASES;` |
| List tables | `SHOW TABLES;` |
| Table structure | `DESCRIBE table_name;` |
| Basic select | `SELECT * FROM table_name;` |
| Filtered select | `SELECT * FROM table WHERE field = 'value';` |
| Join | `SELECT a.x, b.y FROM a INNER JOIN b ON a.id = b.a_id;` |
| Group + count | `SELECT field, COUNT(*) FROM table GROUP BY field;` |
| Insert | `INSERT INTO table (f1, f2) VALUES (v1, v2);` |
| Update | `UPDATE table SET f1 = v1 WHERE condition;` |
| Delete | `DELETE FROM table WHERE condition;` |
| Current user / version | `SELECT CURRENT_USER(), VERSION();` |
| List users | `SELECT User, Host FROM mysql.user;` |
| Check own privileges | `SHOW GRANTS;` |
| Dump a database | `mysqldump -u root -p db_name > backup.sql` |
| List all databases (manual) | `SELECT schema_name FROM information_schema.schemata;` |
| List tables in a DB (manual) | `SELECT table_name FROM information_schema.tables WHERE table_schema='db';` |
| List columns in a table (manual) | `SELECT column_name FROM information_schema.columns WHERE table_schema='db' AND table_name='t';` |
| Read a server-side file | `SELECT LOAD_FILE('/etc/passwd');` |
| Check file read/write restriction | `SHOW VARIABLES LIKE 'secure_file_priv';` |

---

*Compiled as a pentest-oriented SQL/admin reference for use alongside `sqlmap-cheatsheet-professional.md` (automated injection) and `port-enumeration-exploitation-playbook.md` (service discovery on port 3306). Sources consulted: [Devhints MySQL Cheat Sheet](https://devhints.io/mysql), [Brad Traversy's MySQL Cheat Sheet (GitHub Gist)](https://gist.github.com/bradtraversy/c831baaad44343cc945e76c2e30927b3), [MySQLTutorial.org Cheat Sheet](https://www.mysqltutorial.org/mysql-cheat-sheet/). All techniques should only be used within written authorization (scope/RoE).*
