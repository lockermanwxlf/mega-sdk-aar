#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export VCPKG_ROOT="${VCPKG_ROOT:-${ROOT_DIR}/.cache/vcpkg}"

"${ROOT_DIR}/scripts/setup-vcpkg.sh"
"${ROOT_DIR}/gradlew" --no-daemon :mega-sdk:assembleRelease "$@"

echo "AAR: ${ROOT_DIR}/mega-sdk/build/outputs/aar/mega-sdk-release.aar"
