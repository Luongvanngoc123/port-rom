#!/usr/bin/env bash
# Sync Pixel Experience 13 plus the gtowifi/gto local manifest.
# Usage: scripts/01-sync.sh [workdir]      (default: $HOME/pe13)
# Needs: repo, git, git-lfs, ~250 GB free disk, 16 GB+ RAM for the later build.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="${1:-$HOME/pe13}"

command -v repo >/dev/null || { echo "repo not found: https://source.android.com/docs/setup/download#installing-repo"; exit 1; }
command -v git-lfs >/dev/null || { echo "git-lfs not found (PE vendor_gms uses LFS)"; exit 1; }

mkdir -p "$WORK"
cd "$WORK"
git lfs install

if [ ! -d .repo ]; then
  repo init -u https://github.com/PixelExperience/manifest -b thirteen-plus --depth=1 --git-lfs
fi

mkdir -p .repo/local_manifests
cp "$HERE/local_manifests/gto.xml" .repo/local_manifests/gto.xml

repo sync -c -j"$(nproc)" --force-sync --no-clone-bundle --no-tags

# LineageOS's manifest creates these two guard files with <linkfile>, PE's does not have an
# msm8953 entry at all. Without them the msm8953 HAL is never pulled into the soong build.
GUARD=hardware/qcom-caf/msm8953
ln -sfn ../common/os_pickup.mk      "$GUARD/Android.mk"
ln -sfn ../common/os_pickup_qssi.bp "$GUARD/Android.bp"

echo "Synced into $WORK. Next: scripts/02-prepare-device.sh $WORK"
