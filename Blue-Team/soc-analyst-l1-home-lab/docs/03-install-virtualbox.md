# 3. Installing VirtualBox

VirtualBox is a powerful, open-source virtualization platform that lets you create and manage multiple virtual machines on a single host.

## Step-by-Step Installation

1. **Download:** go to https://www.virtualbox.org/ and download the latest version for your OS.
2. **Run the installer:** double-click the downloaded file and click "Next".
3. **Choose components:** on the Custom Setup screen, leave all default components checked, click "Next".
4. **Ready to install:** click "Install" to begin. Accept the warning about a temporary network interface interruption.
5. **Progress:** wait for installation to complete.
6. **Done:** click "Finish" — Oracle VM VirtualBox opens automatically.

## After Installation — VirtualBox Manager

Once VirtualBox Manager opens, your VMs will be listed in the left panel (empty for now). Use "New" at the top to create a VM, or "Import" to bring in a pre-built one.

## Network Configuration (Important)

This lab uses two kinds of networks:

| Network Type | Purpose |
|---|---|
| NAT Network | VMs get internet access (for Windows/Kali updates) |
| Internal Network | Isolated VM-to-VM communication (e.g., Windows ↔ Splunk) |

### How to Create an Internal Network

1. Open VirtualBox Manager
2. File → Host Network Manager
3. Click "Create"
4. Enable DHCP if needed
5. "Apply" and close

In each VM's settings, under the Network tab, set the adapter to "Internal Network" and use the same network name (e.g. `intnet`) across all VMs.

## Important Notes

- Enable virtualization (VT-x/AMD-V) in BIOS — critical for performance
- Give each VM enough RAM and CPU
- Use the Internal Network to keep log routing secure

## Common Pitfalls

- VT-x/AMD-V disabled in BIOS (Fix: enable it in BIOS settings)
- Installation fails (Fix: temporarily disable antivirus)
- Network not working (Fix: check adapter settings)
- Not enough disk space (Fix: free up storage)
