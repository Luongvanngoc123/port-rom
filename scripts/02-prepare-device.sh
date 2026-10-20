#!/usr/bin/env bash
# Turn the LineageOS gtowifi device tree into a PE (aosp_*) one. Safe to run twice.
# Usage: scripts/02-prepare-device.sh [workdir]      (default: $HOME/pe13)
set -euo pipefail

WORK="${1:-$HOME/pe13}"
DEV="$WORK/device/samsung/gtowifi"
[ -d "$DEV" ] || { echo "$DEV not found, run 01-sync.sh first"; exit 1; }

# 0. vendor_gms is removed in gto.xml (its gitlab host is gone) but vendor/aosp inherits it
#    unconditionally. Make that optional. `repo sync --force-sync` reverts this, so rerun the script after it.
COMMON="$WORK/vendor/aosp/config/common.mk"
[ -f "$COMMON" ] || { echo "$COMMON not found, run 01-sync.sh first"; exit 1; }
sed -i 's#\$(call inherit-product, vendor/gms/products/gms.mk)#$(call inherit-product-if-exists, vendor/gms/products/gms.mk)#' "$COMMON"
grep -q 'inherit-product-if-exists, vendor/gms/products/gms.mk' "$COMMON" \
  || { echo "GMS patch did not apply to $COMMON, vendor/aosp changed upstream?"; exit 1; }

cd "$DEV"

# 1. Product makefile: lineage_gtowifi -> aosp_gtowifi. PRODUCT_DEVICE stays gtowifi because
#    Android.mk guards everything with `ifeq ($(TARGET_DEVICE),gtowifi)`.
if [ -f lineage_gtowifi.mk ]; then
  mv lineage_gtowifi.mk aosp_gtowifi.mk
fi
sed -i \
  -e 's#vendor/lineage/config/common_full_tablet_wifionly.mk#vendor/aosp/config/common_full_tablet_wifionly.mk#' \
  -e 's#^PRODUCT_NAME := .*#PRODUCT_NAME := aosp_gtowifi#' \
  aosp_gtowifi.mk

# 2. PE options. Must be set before the inherit-product line that pulls in vendor/aosp.
if ! grep -q 'TARGET_BOOT_ANIMATION_RES' aosp_gtowifi.mk; then
  sed -i '/^# Inherit some common Lineage stuff/i \
# Pixel Experience options\
TARGET_BOOT_ANIMATION_RES := 1080\
TARGET_FACE_UNLOCK_SUPPORTED := false\
TARGET_INCLUDE_LIVE_WALLPAPERS := false\
' aosp_gtowifi.mk
  sed -i 's/^# Inherit some common Lineage stuff/# Inherit some common PE stuff/' aosp_gtowifi.mk
fi

# 3. AndroidProducts.mk
cat > AndroidProducts.mk <<'EOF'
PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/aosp_gtowifi.mk

COMMON_LUNCH_CHOICES := \
    aosp_gtowifi-user \
    aosp_gtowifi-userdebug \
    aosp_gtowifi-eng
EOF

# 4. LineageOS-only metadata. PE does not read lineage.dependencies and overlay-lineage targets lineage-sdk.
rm -rf lineage.dependencies overlay-lineage

# 5. OTA assert: TWRP on the LTE model reports "gto", so accept both.
sed -i 's/^TARGET_OTA_ASSERT_DEVICE := .*/TARGET_OTA_ASSERT_DEVICE := gtowifi,gto/' BoardConfig.mk

echo "Device tree prepared. Next: scripts/03-build.sh $WORK"
git -C "$DEV" status --short || true
