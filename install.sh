#! /usr/bin/env bash

# Verificar permisos de root
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecuta este script con sudo o como root."
  exit 1
fi

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

390(){
echo "==> Instalando dependencias (Nvidia 390)..."
KVER=$(uname -r | cut -d'.' -f1-2)
echo "==> Kernel activo detectado: $(uname -r). Instalando cabeceras linux${KVER}-headers..."
xbps-install -Sy mesa-dri mesa-dri-32bit dkms gcc make patch curl tar \
 nvidia390-opencl nvidia390-libs nvidia390-gtklibs nvidia390 \
 nvidia390-opencl-32bit nvidia390-libs-32bit nvidia390-gtklibs-32bit \
 nvtop SDL2-32bit SDL2 libGL-32bit "linux${KVER}-headers"

echo "==> Iniciando parcheo para 390xx..."
bash "$BASE_DIR/nvidia-390-patch.sh"

echo "==> Aplicando configuración del sistema..."
bash "$BASE_DIR/nvidia-config.sh"
}

470(){
echo "==> Instalando dependencias (Nvidia 470)..."
KVER=$(uname -r | cut -d'.' -f1-2)
echo "==> Kernel activo detectado: $(uname -r). Instalando cabeceras linux${KVER}-headers..."
xbps-install -Sy mesa-dri mesa-dri-32bit dkms gcc make patch curl tar \
 nvidia470-opencl nvidia470-libs nvidia470-gtklibs nvidia470 \
 nvidia470-libs-32bit SDL2-32bit SDL2 libGL-32bit "linux${KVER}-headers"

echo "==> Iniciando parcheo para 470xx..."
bash "$BASE_DIR/nvidia-470-patch.sh"

echo "==> Aplicando configuración del sistema..."
bash "$BASE_DIR/nvidia-config.sh"
}

580(){
echo "==> Instalando dependencias (Nvidia 580 Proprietary)..."
KVER=$(uname -r | cut -d'.' -f1-2)
echo "==> Kernel activo detectado: $(uname -r). Instalando cabeceras linux${KVER}-headers..."
xbps-install -Sy mesa-dri mesa-dri-32bit nvidia580 nvidia580-dkms nvidia580-firmware nvidia580-gtklibs \
 nvidia580-libs nvidia580-opencl nvidia580-libs-32bit nvidia-vaapi-driver \
 SDL2-32bit SDL2 libGL-32bit "linux${KVER}-headers"

echo "==> Aplicando configuración del sistema..."
bash "$BASE_DIR/nvidia-config.sh"
}

latest(){
echo "==> Instalando dependencias (Nvidia Latest Proprietary)..."
KVER=$(uname -r | cut -d'.' -f1-2)
echo "==> Kernel activo detectado: $(uname -r). Instalando cabeceras linux${KVER}-headers..."
xbps-install -Sy mesa-dri mesa-dri-32bit nvidia nvidia-dkms \
 nvidia-firmware nvidia-gtklibs nvidia-gtklibs-32bit nvidia-libs nvidia-libs-32bit \
 nvidia-opencl nvidia-vaapi-driver nvidia-docker nvidia-container-toolkit \
 SDL2-32bit SDL2 libGL-32bit "linux${KVER}-headers"

echo "==> Aplicando configuración del sistema..."
bash "$BASE_DIR/nvidia-config.sh"
}

open(){
echo "==> Instalando dependencias (Nvidia Open)..."
KVER=$(uname -r | cut -d'.' -f1-2)
echo "==> Kernel activo detectado: $(uname -r). Instalando cabeceras linux${KVER}-headers..."
xbps-install -Sy mesa-dri mesa-dri-32bit mesa-nouveau-dri mesa-vulkan-nouveau mesa-nouveau-dri-32bit mesa-vulkan-nouveau-32bit xf86-video-nouveau \
SDL2-32bit SDL2 libGL-32bit "linux${KVER}-headers"

echo "==> Aplicando configuración del sistema..."
bash "$BASE_DIR/nvidia-config.sh"
}

case "$1" in
  390)390 ;;
  470)470 ;;
  580)580 ;;
  latest)latest ;;
  open)open ;;
  *) echo "Uso: $0 {390|470|580|latest|open}"; exit 1 ;;
esac
