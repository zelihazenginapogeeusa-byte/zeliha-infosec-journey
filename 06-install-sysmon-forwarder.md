# 6. Installing Sysmon and the Splunk Universal Forwarder

In this step we'll install Sysmon on Windows 10 for advanced logging, and the Splunk Universal Forwarder to ship those logs to Splunk.

## 1. Installing Sysmon

1. Download Sysmon from Sysinternals.
2. Open an elevated (Administrator) Command Prompt/PowerShell.
3. Install with the default config, accepting the EULA:
   ```
   sysmon64.exe -accepteula -i
   ```
   or with a custom config (like `configs/sysmonconfig-sample.xml` in this repo):
   ```
   sysmon64.exe -accepteula -i sysmonconfig-sample.xml
   ```

### Verify the Sysmon Service
- Open Services (services.msc)
- Find "Sysmon64", confirm its status is "Running"

## 2. Installing the Splunk Universal Forwarder

1. Download the Splunk Universal Forwarder.
2. Run the installer as Administrator.
3. Accept the license agreement.
4. Continue with the default install settings and click "Install".
5. Click "Finish" to complete the install.

## 3. Configure inputs.conf

File location: `%SPLUNK_HOME%\etc\system\local\inputs.conf`

Add the Windows Event Logs (Security/System/Application) and the Sysmon operational log:

```ini
[WinEventLog://Security]
disabled = 0
index = windows

[WinEventLog://System]
disabled = 0
index = windows

[WinEventLog://Application]
disabled = 0
index = windows

[WinEventLog://Microsoft-Windows-Sysmon/Operational]
disabled = 0
index = sysmon
```

(Full example: `configs/inputs.conf`)

## 4. Configure outputs.conf

File location: `%SPLUNK_HOME%\etc\system\local\outputs.conf`

Add the Splunk server IP and port 9997:

```ini
[tcpout]
defaultGroup = splunk_server

[tcpout:splunk_server]
server = <SPLUNK_SERVER_IP>:9997
sslVerifyServerCert = false
compressed = true
```

(Full example: `configs/outputs.conf`)

## 5. Restart the Forwarder

```
splunk restart
```
This applies the new configuration.

## 6. Verify the Data in Splunk

Go to the Splunk Web UI, and in Search & Reporting run:
```spl
index=windows OR index=sysmon
```
If you see events coming in, the forwarder is working correctly.

## Important Notes

- Sysmon gives you deep visibility into process, network, and file activity
- The Universal Forwarder is a lightweight agent — it's only responsible for shipping logs
- Restart the forwarder after any config change
- This lab uses two indexes: "windows" and "sysmon"

## Common Pitfalls

- UF isn't sending data → check `outputs.conf` (Splunk IP and port)
- No logs → check the `inputs.conf` path and input settings
- Connection refused → confirm port 9997 is open on the Splunk server
- No Sysmon logs → confirm the Sysmon service installed and is named "sysmon"

## What You Learn in This Step

How to ship logs collected from an endpoint to a SIEM so they're visible for monitoring and analysis.
