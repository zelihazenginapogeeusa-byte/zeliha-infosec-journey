# 5. Installing Splunk SIEM (on Ubuntu Server)

In this step we'll install Splunk Enterprise on Ubuntu Server. Splunk acts as our SIEM in the lab, collecting, indexing, and analyzing logs from the endpoints.

## Step-by-Step Installation

### 1. Update Ubuntu Server
```bash
sudo apt update && sudo apt upgrade -y
```

### 2. Download Splunk Enterprise
Download the `.deb` package from Splunk's official site (the free tier is fine for lab/educational use) and transfer it to the Ubuntu VM.

### 3. Install the package
```bash
sudo dpkg -i splunk-<version>-linux-amd64.deb
```

### 4. Start the service
```bash
sudo /opt/splunk/bin/splunk start --accept-license
sudo /opt/splunk/bin/splunk enable boot-start
```

### 5. Access the Web UI
From a browser, go to `http://<ubuntu_ip>:8000` (default port 8000).

### 6. Set up the admin account
On first login, sign in with the default `admin` username — you'll be prompted to set a strong password.

## Verifying the Install

```bash
sudo systemctl status splunkd
```
or if you can reach the Splunk Dashboard at `http://<ubuntu_ip>:8000` in your browser, the install succeeded.

## Splunk's Role in This Lab

Splunk (the SIEM) collects and indexes Sysmon and Windows Event Log data coming from the Windows 10 endpoint, lets you search it, and raises alerts based on the rules you define.

## Important Notes

- Keep Splunk updated
- Definitely change the default admin password
- Splunk is fairly RAM-hungry — give the Ubuntu VM at least 4 GB
- Make sure port 8000 is reachable from your host machine (via NAT or port forwarding)

## Common Pitfalls

- Port 8000 won't open → check that the Splunk service is running (`sudo systemctl status splunkd`)
- Can't log in → make sure you changed the password correctly
- Permission errors → prefix Splunk commands with `sudo`
- Out of memory → give the Ubuntu VM more RAM

## What You Learn in This Step

You installed and configured the SIEM (Splunk) that will collect and help you analyze security logs from your endpoints.
