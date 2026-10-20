#!/usr/bin/env bash
# Build the PE 13 zip for gtowifi.
# Usage: scripts/03-build.sh [workdir] [variant]      (default: $HOME/pe13, userdebug)
set -euo pipefail

WORK="${1:-$HOME/pe13}"
VARIANT="${2:-userdebug}"
cd "$WORK"

export USE_CCACHE=1
export CCACHE_EXEC="$(command -v ccache || true)"
export LC_ALL=C

# shellcheck disable=SC1091
source build/envsetup.sh
lunch "aosp_gtowifi-$VARIANT"
mka bacon -j"$(nproc)" 2>&1 | tee "$WORK/build-$VARIANT.log"

ls -lh "out/target/product/gtowifi/"*.zip 2>/dev/null || true
