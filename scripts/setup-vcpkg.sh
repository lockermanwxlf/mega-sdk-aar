#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDK_MANIFEST="${ROOT_DIR}/megasdk/vcpkg.json"
VCPKG_ROOT="${VCPKG_ROOT:-${ROOT_DIR}/.cache/vcpkg}"

if [[ -n "${VCPKG_DEFAULT_BINARY_CACHE:-}" ]]; then
    mkdir -p "${VCPKG_DEFAULT_BINARY_CACHE}"
fi

if [[ ! -f "${SDK_MANIFEST}" ]]; then
    echo "MEGA SDK submodule is missing. Run: git submodule update --init --recursive" >&2
    exit 1
fi

baseline="$(sed -n 's/.*"builtin-baseline"[[:space:]]*:[[:space:]]*"\([0-9a-f]*\)".*/\1/p' "${SDK_MANIFEST}")"
if [[ ! "${baseline}" =~ ^[0-9a-f]{40}$ ]]; then
    echo "Could not read the vcpkg baseline from ${SDK_MANIFEST}" >&2
    exit 1
fi

if [[ ! -d "${VCPKG_ROOT}/.git" ]]; then
    mkdir -p "$(dirname "${VCPKG_ROOT}")"
    git clone https://github.com/microsoft/vcpkg.git "${VCPKG_ROOT}"
fi

if ! git -C "${VCPKG_ROOT}" cat-file -e "${baseline}^{commit}" 2>/dev/null; then
    git -C "${VCPKG_ROOT}" fetch --depth 1 origin "${baseline}"
fi
git -C "${VCPKG_ROOT}" checkout --detach "${baseline}"
"${VCPKG_ROOT}/bootstrap-vcpkg.sh" -disableMetrics

echo "vcpkg ${baseline} is ready at ${VCPKG_ROOT}"
