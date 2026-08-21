#! /bin/bash
set -e
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Copiar grub local
rm -rf /etc/default/grub
cp "$BASE_DIR/grub" /etc/default/grub

mkdir -p /etc/dracut.conf.d
cat << 'EOFDRACUT' > /etc/dracut.conf.d/nvidia.conf
#Incluir los módulos esenciales de NVIDIA en el initramfs
add_drivers+=" nvidia nvidia_modeset nvidia_uvm nvidia_drm "
EOFDRACUT
chmod 644 /etc/dracut.conf.d/nvidia.conf

# 1. Forzar carga de todos los módulos de nvidia al inicio
mkdir -p /etc/modules-load.d
cat << 'EOFMODULES' > /etc/modules-load.d/nvidia.conf
nvidia
nvidia_modeset
nvidia_uvm
nvidia_drm
EOFMODULES

# 2. Configurar modprobe.d: Gestión de energía, modeset y blacklist nouveau
mkdir -p /etc/modprobe.d
cat << 'EOFMODPROBE' > /etc/modprobe.d/nvidia.conf
# Gestión de energía dinámica (Optimus)
options nvidia "NVreg_DynamicPowerManagement=0x02"
# Forzar modeset en nvidia-drm
options nvidia-drm modeset=1
# Bloquear completamente el driver nouveau
blacklist nouveau
EOFMODPROBE

# Reglas udev para Optimus
mkdir -p /etc/udev/rules.d
cat << 'EOFUDEV' > /etc/udev/rules.d/80-nvidia-pm.rules
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c0330", ATTR{power/control}="auto", ATTR{remove}="1"
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c8000", ATTR{power/control}="auto", ATTR{remove}="1"
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{power/control}="auto", ATTR{remove}="1"
ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="auto"
ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="auto"
ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="on"
ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="on"
EOFUDEV

# FORZAR USO DE NVIDIA EN TODO EL ENTORNO GRÁFICO (Xorg)
mkdir -p /etc/X11/xorg.conf.d
cat << 'EOFXORG' > /etc/X11/xorg.conf.d/10-nvidia-drm-outputclass.conf
Section "Module"
    Load "glx"
EndSection

Section "OutputClass"
    Identifier "nvidia"
    MatchDriver "nvidia-drm"
    Driver "nvidia"
    Option "PrimaryGPU" "yes"
EndSection
EOFXORG

# Atajo nvidia-run para forzar NVIDIA en juegos específicos (opcional)
cat << 'EOFNVRUN' > /usr/local/bin/nvidia-run
#!/bin/bash
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia "$@"
EOFNVRUN
chmod +x /usr/local/bin/nvidia-run

# Variables de entorno para Wayland y NVIDIA
cat << 'EOFWAYLAND' > /etc/profile.d/nvidia-wayland.sh
# Forzar EGL y GLX en NVIDIA para Wayland y X11 globalmente
export __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/10_nvidia.json
# Las siguientes líneas son solo para laptops con Optimus. En PC de escritorio deben estar comentadas.
# export __NV_PRIME_RENDER_OFFLOAD=1
# export __GLX_VENDOR_LIBRARY_NAME=nvidia
# Descomentar la siguiente línea si usas un compositor wlroots (Sway/Hyprland) y tienes parpadeo
# export WLR_NO_HARDWARE_CURSORS=1
EOFWAYLAND
chmod +x /etc/profile.d/nvidia-wayland.sh

kernel_set(){
# ==========================================
GRUB_FILE="/etc/default/grub"
GRUB_CFG="/boot/grub/grub.cfg"
# ==========================================

# 1. Usar el kernel que está activo en este momento
KERNEL_VERSION=$(uname -r)
echo "Kernel activo detectado: $KERNEL_VERSION"

# 2. Extraer el nombre exacto en el GRUB
KERNEL_ENTRY=$(grep "menuentry" "$GRUB_CFG" | grep "$KERNEL_VERSION" | sed -n "s/.*menuentry ['\"]\([^'\"]*\)['\"].*/\1/p" | head -n 1)

# 3. Comprobar si se encontró
if [ -z "$KERNEL_ENTRY" ]; then
    echo "ERROR: No se encontró ninguna entrada con el kernel $KERNEL_VERSION en $GRUB_CFG"
    exit 1
fi

echo "Entrada encontrada: $KERNEL_ENTRY"

# 4. Modificar /etc/default/grub
sed -i "s|^GRUB_DEFAULT=.*|GRUB_DEFAULT=\"$KERNEL_ENTRY\"|" "$GRUB_FILE"

echo "Se ha actualizado $GRUB_FILE con la nueva entrada."
}

kernel_set

# Regenerar initramfs y GRUB manualmente
dracut --force --kver "$(uname -r)"
grub-mkconfig -o /boot/grub/grub.cfg