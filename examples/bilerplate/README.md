# Alasgar Boiler Plate

A small multi-platform starter project for building [Alasgar](../../README.md) applications with Nim.

This example renders a rotating colored cube and includes build paths for native desktop, WebAssembly/Emscripten, and Android.

## Requirements

- Nim `>= 2.2.0`
- Nimble
- A compatible local `alasgar` checkout next to this example, or an installed `alasgar` package
- `sokol` available through Nimble
- Docker for the default web and Android builds
- Emscripten for local web builds without Docker

## Project Layout

```text
.
├── src/main.nim                 # Example Alasgar app
├── bilerplate.nimble            # Nimble package and build tasks
├── platforms/web/               # Emscripten shell and Dockerfile
├── platforms/android/           # Android Gradle project and Dockerfile
└── scripts/                     # Android build helpers
```

## Build and Run

From this directory:

```sh
nimble run
```

This builds a native debug binary and runs it.

Other available tasks:

```sh
nimble debug            # Build native debug binary
nimble release          # Build native release binary
nimble web              # Build web output with Docker
nimble webRelease       # Build web release output with Docker
nimble webLocal         # Build web output with local Emscripten
nimble webLocalRelease  # Build web release output with local Emscripten
nimble android          # Build Android debug APK with Docker
nimble clean            # Remove generated build outputs
```

## Outputs

- Native binary: `build/native/main`
- Web app: `build/web/index.html`
- Android APKs: `build/android/`

## Android Notes

The Android build uses Docker and expects a compatible local `sokol` package. If auto-detection fails, pass it explicitly:

```sh
SOKOL_DIR=/path/to/sokol nimble android
```

The build script compiles static libraries for `arm64-v8a`, `armeabi-v7a`, and `x86_64`, then runs Gradle to produce a debug APK.

## Web Notes

The Docker web build mounts the project, the local Alasgar checkout, and Nimble packages into an Emscripten container.

For local web builds, ensure `emcc` is available on `PATH`, then run:

```sh
nimble webLocal
```

## License

MIT. See [LICENSE](LICENSE).
