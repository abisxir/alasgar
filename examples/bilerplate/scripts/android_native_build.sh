#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/app"
ANDROID_DIR="${APP_DIR}/platforms/android"
MAIN_FILE="${APP_DIR}/src/main.nim"
ALASGAR_DIR="${ALASGAR_DIR:-/alasgar}"
SOKOL_DIR="${SOKOL_DIR:-/sokol}"
NIM_INCLUDE_DIR="$(dirname "$(command -v nim)")/../lib"
export NIM_INCLUDE_DIR

if [[ ! -d "${ALASGAR_DIR}" ]]; then
  echo "Missing Alasgar source at ${ALASGAR_DIR}" >&2
  exit 1
fi

if [[ ! -d "${SOKOL_DIR}" ]]; then
  echo "Missing compatible Sokol source at ${SOKOL_DIR}" >&2
  exit 1
fi

if [[ -z "${ANDROID_NDK_HOME:-}" || ! -d "${ANDROID_NDK_HOME}" ]]; then
  echo "ANDROID_NDK_HOME is not set or invalid" >&2
  exit 1
fi

rm -rf "${ANDROID_DIR}/app/src/main/assets"
mkdir -p "${ANDROID_DIR}/app/src/main/assets" "${ANDROID_DIR}/app/jni/main"
cp -R "${APP_DIR}/res/." "${ANDROID_DIR}/app/src/main/assets/"

VENDOR_DIR="${ANDROID_DIR}/vendor"
rm -rf "${VENDOR_DIR}/sokol"
mkdir -p "${VENDOR_DIR}"
cp -R "${SOKOL_DIR}" "${VENDOR_DIR}/sokol"
python3 - <<'PY'
from pathlib import Path

vendor = Path("/app/platforms/android/vendor")

sokol_root = vendor / "sokol/sokol"
app_nim = sokol_root / "app.nim"
text = app_nim.read_text()
text = text.replace(
"""elif defined linux:
  {.passc:"-DSOKOL_GLCORE".}
  {.passl:"-lX11 -lXi -lXcursor -lGL -lm -ldl -lpthread".}
else:
  error("unsupported platform")
""",
"""elif defined android:
  {.passc:"-DSOKOL_GLES3".}
  {.passl:"-lGLESv3 -lEGL -llog -landroid".}
elif defined linux:
  {.passc:"-DSOKOL_GLCORE".}
  {.passl:"-lX11 -lXi -lXcursor -lGL -lm -ldl -lpthread".}
else:
  error("unsupported platform")
""")
app_nim.write_text(text)

sokol_app_c = sokol_root / "c" / "sokol_app.c"
text = sokol_app_c.read_text()
text = text.replace("#define SOKOL_NO_ENTRY\n", "#ifndef __ANDROID__\n#define SOKOL_NO_ENTRY\n#endif\n")
sokol_app_c.write_text(text)
PY

TOOLCHAIN_BIN="${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin"

build_abi() {
  local abi="$1"
  local cpu="$2"
  local target="$3"
  local api="$4"
  local out_dir="${ANDROID_DIR}/app/jni/main/${abi}"
  local cache_dir="${ANDROID_DIR}/nimcache/${abi}"

  mkdir -p "${out_dir}" "${cache_dir}"
  nim c \
    -d:android \
    -d:androidNDK \
    --os:android \
    --cpu:"${cpu}" \
    --cc:clang \
    --clang.exe:"${TOOLCHAIN_BIN}/clang" \
    --clang.linkerexe:"${TOOLCHAIN_BIN}/llvm-ar" \
    --clang.linkTmpl:"rcs \$exefile \$objfiles" \
    --passC:"-target ${target}${api} -fPIC -DGL_GLEXT_PROTOTYPES" \
    --noMain \
    --threads:on \
    --warning[LockLevel]:off \
    --hint[Pattern]:off \
    --nimcache:"${cache_dir}" \
    --putEnv:NIMX_RES_PATH="${ANDROID_DIR}/app/src/main/assets" \
    --path:"${ALASGAR_DIR}" \
    --path:"${VENDOR_DIR}/sokol" \
    --out:"${out_dir}/libmain_static.a" \
    "${MAIN_FILE}"
}

build_abi "arm64-v8a" "arm64" "aarch64-linux-android" "21"
build_abi "armeabi-v7a" "arm" "armv7a-linux-androideabi" "21"
build_abi "x86_64" "amd64" "x86_64-linux-android" "21"

cd "${ANDROID_DIR}"
gradle assembleDebug
