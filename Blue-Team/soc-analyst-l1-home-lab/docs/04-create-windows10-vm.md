# 4. Creating the Windows 10 VM (Victim / Endpoint)

In this step, we'll create the Windows 10 virtual machine that acts as the victim/endpoint in our lab.

## Step-by-Step VM Creation

1. **New VM:** open VirtualBox, click "New".
2. **Name and OS type:** Name: `Windows10`, Type: Microsoft Windows, Version: Windows 10 (64-bit). "Next".
3. **Memory size:** allocate at least 4096 MB (4 GB) of RAM. "Next".
4. **Hard disk:** choose "Create a virtual hard disk now". "Create".
5. **Disk type:** VDI (VirtualBox Disk Image). "Next".
6. **Storage:** choose "Dynamically allocated".
7. **Location and size:** keep the default location, size: at least 50 GB. "Create".
8. **VM created:** Windows10 now appears in the list.

## VM Settings Summary

| Setting | Value |
|---|---|
| Name | Windows10 |
| Type | Microsoft Windows |
| Version | Windows 10 (64-bit) |
| Memory (RAM) | 4096 MB (dynamic) |
| Hard Disk | 50 GB or more |
| Network | Internal Network |
| OS ISO | Windows 10 ISO |

## Network Configuration

Open the VM's settings → Network tab → Adapter 1 → set "Attached to: Internal Network", using the same network name across all VMs (so it can talk to Splunk).

## Windows Installation

Start the VM, attach the Windows 10 ISO to the virtual optical drive, and follow the installation wizard. Creating a local user account (e.g. `testuser`) during setup will come in handy for the attack simulations later.

## Important Notes

- Use the Internal Network for all lab VMs
- Adding a NAT adapter as Adapter 2 on Windows 10 gives it internet access for Windows Update
- Take a snapshot after important steps
- This VM represents a corporate endpoint (think of it as a realistic employee machine)

## Common Issues

- VM won't start → enable virtualization in BIOS
- No internet → check the NAT adapter settings
- Can't see other VMs → confirm all VMs are on the same Internal Network
