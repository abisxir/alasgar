#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ALASGAR_DIR="$(cd "${PROJECT_DIR}/../alasgar" && pwd)"
IMAGE_NAME="${ANDROID_DOCKER_IMAGE:-boiler-plate-android-native}"
SOKOL_DIR="${SOKOL_DIR:-}"

if [[ -z "${SOKOL_DIR}" ]]; then
  while IFS= read -r candidate; do
    if [[ -f "${candidate}/sokol/app.nim" ]] && grep -q "glMajorVersion" "${candidate}/sokol/app.nim"; then
      SOKOL_DIR="${candidate}"
      break
    fi
  done < <(nimble path sokol 2>/dev/null || true)
fi

if [[ -z "${SOKOL_DIR}" || ! -d "${SOKOL_DIR}" ]]; then
  echo "Could not find compatible local sokol package. Set SOKOL_DIR=/path/to/sokol." >&2
  exit 1
fi

docker build -f "${PROJECT_DIR}/platforms/android/Dockerfile" -t "${IMAGE_NAME}" "${PROJECT_DIR}"
docker run --rm \
  -v "${PROJECT_DIR}:/app" \
  -v "${ALASGAR_DIR}:/alasgar:ro" \
  -v "${SOKOL_DIR}:/sokol:ro" \
  -e SOKOL_DIR=/sokol \
  -w /app \
  "${IMAGE_NAME}" \
  scripts/android_native_build.sh
