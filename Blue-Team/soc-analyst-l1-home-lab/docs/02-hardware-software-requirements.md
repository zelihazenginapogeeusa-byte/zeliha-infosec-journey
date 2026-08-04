# 2. Hardware and Software Requirements

## Hardware Requirements

| Component | Minimum | Recommended |
|---|---|---|
| CPU | 2 cores | 4 cores or more |
| RAM | 8 GB | 16 GB or more |
| Storage | 100 GB free | 200 GB+ SSD |
| Virtualization | Enabled in BIOS (VT-x/AMD-V) | Enabled |
| Internet | Required | Required |

Since three VMs (Windows 10, Kali Linux, Ubuntu Server) run simultaneously, 16 GB of RAM is recommended so your host machine stays comfortable to use. 8 GB is possible too, but you'll need to be careful how you split RAM across the VMs.

## Software Requirements

| Tool | Purpose |
|---|---|
| Oracle VM VirtualBox | Virtualization platform |
| Windows 10 ISO | Victim / endpoint machine |
| Kali Linux ISO | Attacker machine |
| Ubuntu Server ISO | For the Splunk install |
| Splunk Enterprise | SIEM / log analysis |
| Sysmon | Windows logging |
| Splunk Universal Forwarder | Log-shipping agent |
| Python 3 (optional) | Tooling/scripting |
| Google Chrome / any browser | Access to the Splunk Web UI |

## Download Links

- VirtualBox: https://www.virtualbox.org/
- Windows 10 ISO: official Microsoft site (Media Creation Tool)
- Kali Linux ISO: https://www.kali.org/get-kali/
- Ubuntu Server ISO: https://ubuntu.com/download/server
- Splunk Enterprise: https://www.splunk.com/en_us/download/splunk-enterprise.html
- Sysmon: https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon
- Splunk Universal Forwarder: https://www.splunk.com/en_us/download/universal-forwarder.html

> Keeping downloads in separate folders (VirtualBox Installer / ISO Files / Sysmon Tools / Splunk & Forwarder) avoids confusion during setup.

## Tips

- Allocate RAM per VM individually — don't give the host's entire RAM to the VMs
- Use an SSD for disk performance
- Keep all VMs on the same Internal Network
- Take a VM snapshot after each major step (so you can roll back on failure)
- Keep your system and tools updated

## Common Pitfalls

- Virtualization disabled in BIOS (Error: VT-x/AMD-V not available)
- VMs don't have enough RAM allocated (VMs run slowly)
- Network misconfigured (VMs can't see each other)
- UF routing misconfigured (logs never reach Splunk — check `outputs.conf` and `inputs.conf`)
