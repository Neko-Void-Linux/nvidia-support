# NVIDIA Support for Void Linux

This repository provides scripts and patches to install and configure NVIDIA drivers on Void Linux, with support for legacy (390, 470) and modern (580, latest, open) versions.

## Prerequisites

- Void Linux with Linux kernel
- Internet connection to download drivers
- Root permissions (`sudo` or `doas`)

## Quick Installation

1. **Download the repository**

```bash
curl -fsSL -o /tmp/nvidia-support.tar.gz https://github.com/Neko-Void-Linux/nvidia-support/archive/refs/heads/main.tar.gz
tar -xzf /tmp/nvidia-support.tar.gz -C /tmp/
cd /tmp/nvidia-support-main
```

2. **Run the installer**

```bash
sudo ./install.sh <version>
# or
doas ./install.sh <version>
```

Replace `<version>` with one of the available options below.

## Available Versions

| Version | Command | Description |
| :--- | :--- | :--- |
| **390** | `sudo ./install.sh 390` | Legacy driver for older GPUs (Tesla, Fermi) |
| **470** | `sudo ./install.sh 470` | Legacy driver for Kepler, Maxwell, Pascal GPUs |
| **580** | `sudo ./install.sh 580` | Proprietary driver for modern GPUs |
| **latest** | `sudo ./install.sh latest` | Latest stable NVIDIA driver |
| **open** | `sudo ./install.sh open` | Open-source kernel module version |

## What does this script do?

- **Installs dependencies:** Mesa, DKMS, GCC, kernel headers, etc.
- **Patches the driver:** Applies compatibility patches for recent kernels.
- **Compiles with DKMS:** The driver is automatically compiled for your kernel.
- **Configures the system:**
  - Blacklists nouveau
  - Configures `nvidia-drm.modeset=1`
  - Power management for Optimus laptops
  - Xorg/Wayland configuration
  - NVIDIA environment variables

## Repository Structure

```text
nvidia-support/
├── install.sh              # Main installation script
├── nvidia-390-patch.sh     # Patcher for version 390
├── nvidia-470-patch.sh     # Patcher for version 470
├── nvidia-config.sh        # System configuration
├── patches-390xx/          # Patches for driver 390
├── patches-470xx/          # Patches for driver 470
├── grub/                   # GRUB configuration
└── LICENSE                 # BSD 2-Clause License
```

## Troubleshooting

### Error: "Kernel headers not found"
Install the headers manually:

```bash
sudo xbps-install linux$(uname -r | cut -d'.' -f1-2)-headers
```

### DKMS compilation error
Check the logs to identify the module name and version:

```bash
sudo dkms status
# Then check build logs for errors
```

### System doesn't boot after installation
In the GRUB menu, select the previous kernel. Then uninstall the driver.

### Wayland issues
Make sure you have these environment variables set:

```bash
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __NV_PRIME_RENDER_OFFLOAD=1
export WLR_NO_HARDWARE_CURSORS=1  # If you experience flickering
```

## Important Notes

- **For Optimus laptops:** The script automatically configures on-demand rendering. Use `nvidia-run` to run applications with the dedicated GPU:
  ```bash
  nvidia-run steam
  ```
- **Supported kernels:** Patches cover from kernel 6.2 to 7.0. If you use a newer kernel, additional patches may be needed.
- **GRUB:** The script automatically modifies `GRUB_DEFAULT` to use the current kernel.
- **Dracut:** The initramfs is regenerated automatically.

## Uninstallation

To completely uninstall a driver, use `xbps-remove` to remove the packages. For example, for the 470 driver:

```bash
sudo xbps-remove nvidia(Version) nvidia(Version)-libs nvidia(Version)-opencl
# Remove configuration files if necessary:
sudo rm -rf /etc/modprobe.d/nvidia.conf /etc/modules-load.d/nvidia.conf
sudo rm -rf /etc/X11/xorg.conf.d/10-nvidia-drm-outputclass.conf
```

## Contributing

If you find a bug or have a patch for a newer kernel, feel free to open an issue or pull request!

## License

BSD 2-Clause License - see the LICENSE file for details.

## Credits

- Original patches by Joan Bruguera
- Void Linux adaptation by Neko-Void-Linux and ANOMALI0x00
