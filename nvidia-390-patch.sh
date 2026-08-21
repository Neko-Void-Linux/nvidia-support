#!/bin/bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  exit 1
fi

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DRIVER_VER="390.157"
PACKAGE_NAME="nvidia390"
SRC_DIR="/usr/src/${PACKAGE_NAME}-${DRIVER_VER}"
TEMP_DIR=$(mktemp -d)

trap 'rm -rf "$TEMP_DIR"' EXIT

if [ -n "${1:-}" ]; then
    TARGET_KERNEL="$1"
else
    TARGET_KERNEL=$(uname -r)
fi

if [ ! -d "/lib/modules/$TARGET_KERNEL/build" ]; then
    exit 1
fi

PATCH_DIR="$BASE_DIR/patches-390xx"

if [ ! -d "$PATCH_DIR" ]; then
    exit 1
fi

RUN_FILE="$TEMP_DIR/NVIDIA-Linux-x86_64-${DRIVER_VER}.run"

if [ ! -f "/tmp/NVIDIA-Linux-x86_64-${DRIVER_VER}.run" ]; then
    curl -fL -o "/tmp/NVIDIA-Linux-x86_64-${DRIVER_VER}.run" "https://us.download.nvidia.com/XFree86/Linux-x86_64/${DRIVER_VER}/NVIDIA-Linux-x86_64-${DRIVER_VER}.run"
fi
cp "/tmp/NVIDIA-Linux-x86_64-${DRIVER_VER}.run" "$RUN_FILE"

rm -rf "$SRC_DIR"
mkdir -p "$SRC_DIR"

cd "$TEMP_DIR"
sh "$RUN_FILE" --extract-only
cp -r "$TEMP_DIR/NVIDIA-Linux-x86_64-${DRIVER_VER}/kernel/"* "$SRC_DIR/"

cd "$SRC_DIR"
for p in "$PATCH_DIR"/*.patch; do
    [ -e "$p" ] || continue
    patch -p2 --batch -N -s < "$p" 2>/dev/null || true
done

GCC_INC=$(gcc -print-file-name=include)
cat << EOF > "$SRC_DIR/dkms.conf"
PACKAGE_NAME="$PACKAGE_NAME"
PACKAGE_VERSION="$DRIVER_VER"
BUILT_MODULE_NAME[0]="nvidia"
DEST_MODULE_LOCATION[0]="/kernel/drivers/video"
BUILT_MODULE_NAME[1]="nvidia-uvm"
DEST_MODULE_LOCATION[1]="/kernel/drivers/video"
BUILT_MODULE_NAME[2]="nvidia-modeset"
DEST_MODULE_LOCATION[2]="/kernel/drivers/video"
BUILT_MODULE_NAME[3]="nvidia-drm"
DEST_MODULE_LOCATION[3]="/kernel/drivers/video"
AUTOINSTALL="yes"
MAKE[0]="'make' -j\$(nproc) NV_EXCLUDE_BUILD_MODULES='' KERNEL_UNAME=\${kernelver} NV_EXTRA_CFLAGS='-I$GCC_INC' modules"
EOF

dkms remove -m "$PACKAGE_NAME" -v "$DRIVER_VER" -k "$TARGET_KERNEL" 2>/dev/null || true
dkms install -m "$PACKAGE_NAME" -v "$DRIVER_VER" -k "$TARGET_KERNEL" --force 2>/dev/null || exit 1