# MEGA SDK AAR

This repository builds the official [MEGA C++ SDK](https://github.com/meganz/sdk) submodule and packages its Java API and native Android libraries into a single AAR. Tagged builds are published as assets on this repository's GitHub Releases page.

The AAR contains `libmega.so` for `armeabi-v7a`, `arm64-v8a`, `x86`, and `x86_64`. It supports Android 9 (API 28) and newer.

## Prerequisites

- JDK 21
- Android SDK 36
- Android NDK r27b (`27.1.12297006`) or newer
- CMake 3.20 or newer
- SWIG, Git, and standard C/C++ build tools

On macOS, the required host tools can be installed with:

```bash
brew install cmake swig autoconf automake autoconf-archive libtool nasm pkgconf
```

Set `ANDROID_NDK_HOME` (or `NDK_ROOT`) to the NDK directory. The build script creates a vcpkg checkout pinned to the baseline declared by the selected MEGA SDK revision.

## Build

```bash
git clone --recurse-submodules <repository-url>
cd mega-sdk-aar
export ANDROID_NDK_HOME="$ANDROID_HOME/ndk/27.1.12297006"
./scripts/build-aar.sh
```

The output is `mega-sdk/build/outputs/aar/mega-sdk-release.aar`.

To use an existing vcpkg checkout, set `VCPKG_ROOT` before running the build. To build fewer architectures during development, set a space-separated `BUILD_ABIS`, for example:

```bash
BUILD_ABIS="arm64-v8a x86_64" ./scripts/build-aar.sh
```

## Consume the AAR

Download the AAR from a GitHub Release, place it in your app's `libs` directory, and add:

```kotlin
dependencies {
    implementation(files("libs/mega-sdk-<version>.aar"))
    implementation("androidx.exifinterface:exifinterface:1.4.1")
}
```

The Java API is in the `nz.mega.sdk` package. MEGA requires applications to use a valid application key and comply with its terms of service.

## Release

Push a tag beginning with `v` (for example, `v10.8.0-1`). GitHub Actions builds the four-ABI AAR and creates or updates the matching GitHub Release with:

- `mega-sdk-<version>.aar`
- `mega-sdk-<version>.aar.sha256`

The workflow can also be run manually for an existing tag. A release version describes this wrapper build; the exact upstream SDK revision is always pinned by the `megasdk` submodule.

## Updating MEGA SDK

```bash
git -C megasdk fetch --tags origin
git -C megasdk checkout <sdk-tag-or-commit>
git add megasdk
```

Commit the updated submodule pointer, verify `./scripts/build-aar.sh`, and create a new wrapper release tag.

The MEGA SDK itself is distributed under its own license; see [`megasdk/LICENSE`](megasdk/LICENSE).
