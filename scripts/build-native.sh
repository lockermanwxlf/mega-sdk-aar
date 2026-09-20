#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDK_DIR="${ROOT_DIR}/megasdk"
OUTPUT_DIR="${MEGA_OUTPUT_DIR:-${ROOT_DIR}/mega-sdk/build/generated/mega-sdk}"
NATIVE_BUILD_ROOT="${MEGA_NATIVE_BUILD_DIR:-${ROOT_DIR}/build/native}"
ANDROID_API_LEVEL="${ANDROID_API_LEVEL:-28}"
BUILD_TYPE="${MEGA_BUILD_TYPE:-Release}"
BUILD_ABIS="${BUILD_ABIS:-armeabi-v7a arm64-v8a x86 x86_64}"

case "${OUTPUT_DIR}" in
    "${ROOT_DIR}/mega-sdk/build/"*) ;;
    *)
        echo "MEGA_OUTPUT_DIR must be inside ${ROOT_DIR}/mega-sdk/build" >&2
        exit 1
        ;;
esac

if [[ ! -f "${SDK_DIR}/CMakeLists.txt" ]]; then
    echo "MEGA SDK submodule is missing. Run: git submodule update --init --recursive" >&2
    exit 1
fi

ANDROID_NDK_HOME="${ANDROID_NDK_HOME:-${NDK_ROOT:-}}"
if [[ -z "${ANDROID_NDK_HOME}" || ! -f "${ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake" ]]; then
    echo "Set ANDROID_NDK_HOME or NDK_ROOT to Android NDK r27b (27.1.12297006) or newer." >&2
    exit 1
fi
export ANDROID_NDK_HOME

if [[ -z "${VCPKG_ROOT:-}" || ! -f "${VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" ]]; then
    echo "Set VCPKG_ROOT to a bootstrapped vcpkg checkout." >&2
    echo "You can create the pinned checkout with: ./scripts/setup-vcpkg.sh" >&2
    exit 1
fi

for tool in cmake javac swig; do
    if ! command -v "${tool}" >/dev/null 2>&1; then
        echo "Required tool not found: ${tool}" >&2
        exit 1
    fi
done

case "$(uname -s)" in
    Darwin) host_tag="darwin-x86_64" ;;
    Linux) host_tag="linux-x86_64" ;;
    *) echo "Unsupported build host: $(uname -s)" >&2; exit 1 ;;
esac

strip_tool="${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/${host_tag}/bin/llvm-strip"
if [[ ! -x "${strip_tool}" ]]; then
    echo "NDK strip tool not found: ${strip_tool}" >&2
    exit 1
fi

jobs="${MEGA_BUILD_JOBS:-}"
if [[ -z "${jobs}" ]]; then
    if command -v nproc >/dev/null 2>&1; then
        jobs="$(nproc)"
    else
        jobs="$(sysctl -n hw.logicalcpu)"
    fi
fi

rm -rf "${OUTPUT_DIR}"
mkdir -p \
    "${OUTPUT_DIR}/java/nz/mega/sdk" \
    "${OUTPUT_DIR}/jniLibs" \
    "${OUTPUT_DIR}/resources/META-INF"
cp "${SDK_DIR}/LICENSE" "${OUTPUT_DIR}/resources/META-INF/LICENSE-mega-sdk"

first_abi=true
for abi in ${BUILD_ABIS}; do
    build_dir="${NATIVE_BUILD_ROOT}/${abi}"
    native_output="${OUTPUT_DIR}/jniLibs/${abi}"
    mkdir -p "${native_output}"

    echo "Configuring MEGA SDK for ${abi}"
    cmake -S "${SDK_DIR}" --preset mega-android \
        -B "${build_dir}" \
        -DVCPKG_ROOT="${VCPKG_ROOT}" \
        -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" \
        -DANDROID_PLATFORM="${ANDROID_API_LEVEL}" \
        -DANDROID_ABI="${abi}" \
        -DENABLE_SDKLIB_EXAMPLES=OFF \
        -DENABLE_SDKLIB_TESTS=OFF

    echo "Building MEGA SDK for ${abi}"
    cmake --build "${build_dir}" --target SDKJavaBindings --parallel "${jobs}"

    cp "${build_dir}/bindings/java/libmega.so" "${native_output}/libmega.so"
    "${strip_tool}" "${native_output}/libmega.so"

    if [[ "${first_abi}" == true ]]; then
        cp "${build_dir}"/bindings/java/nz/mega/sdk/*.java "${OUTPUT_DIR}/java/nz/mega/sdk/"
        first_abi=false
    fi
done

echo "MEGA SDK outputs are ready in ${OUTPUT_DIR}"
