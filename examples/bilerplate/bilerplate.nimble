version       = "0.1.0"
author        = "Abi Mohammadi"
description   = "a multi-platform boiler plate for alasgar apps"
license       = "MIT"
srcDir        = "src"
bin           = @["main"]
binDir        = "build/native"

requires "nim >= 2.2.0"
import std/os
import std/strformat
import std/strutils

const
  appName = "boiler-plate"
  entry = "src/main.nim"
  nativeOut = "build/native/main"
  nativeCache = "build/nimcache/native"
  webOut = "build/web/index.html"
  webCache = "build/nimcache/web"
  webShellFile = "platforms/web/index.html"
  webDockerfile = "platforms/web/Dockerfile"
  androidOut = "build/android"
  dockerImage = "alasgar-emscripten"

proc localAlasgarPath(): string =
  for path in [
    getCurrentDir().parentDir().parentDir(),
    getCurrentDir().parentDir() / "alasgar",
    getCurrentDir().parentDir().parentDir() / "alasgar",
  ]:
    if fileExists(path / "alasgar.nim") and dirExists(path / "private"):
      return path
  ""

proc localAlasgarSwitch(): string =
  let path = localAlasgarPath()
  if path.len > 0:
    &"--path:\"{path}\" "
  else:
    ""

proc isUsablePackagePath(packageName, path: string): bool =
  result = path.len > 0 and dirExists(path / packageName)
  if result and packageName == "sokol":
    let appModule = path / packageName / "app.nim"
    result = fileExists(appModule) and readFile(appModule).contains("glMajorVersion")

proc packagePathSwitch(packageName: string): string =
  let nimblePathOutput = staticExec(&"nimble path {packageName} 2>/dev/null || true")
  for rawPath in nimblePathOutput.splitLines():
    let path = rawPath.strip()
    if isUsablePackagePath(packageName, path):
      return &"--path:\"{path}\" "

  let pkgs2Dir = getHomeDir() / ".nimble" / "pkgs2"
  if dirExists(pkgs2Dir):
    for kind, path in walkDir(pkgs2Dir):
      if kind == pcDir and path.splitPath().tail.startsWith(packageName & "-") and isUsablePackagePath(packageName, path):
        return &"--path:\"{path}\" "

  ""

proc ensureBuildDirs() =
  exec "mkdir -p build/native build/web build/android build/nimcache/native build/nimcache/web"

proc buildNative(release: bool) =
  ensureBuildDirs()
  let mode = if release: "-d:release " else: ""
  exec &"nim c {mode}{localAlasgarSwitch()}{packagePathSwitch(\"sokol\")}--nimcache:{nativeCache} --out:{nativeOut} {entry}"

proc webCompileCommand(release: bool; extraSwitches = ""; includeLocalAlasgar = true): string =
  let mode = if release: "-d:release " else: ""
  let alasgarSwitch = if includeLocalAlasgar: localAlasgarSwitch() else: ""
  result = &"nim c {mode}-d:emscripten --threads:off --mm:arc --os:linux --cpu:i386 --cc:clang " &
    "--clang.exe:emcc --clang.linkerexe:emcc " &
    &"--nimcache:{webCache} " &
    &"--out:{webOut} " &
    alasgarSwitch &
    extraSwitches &
    "--passC:\"-O3 -sUSE_WEBGL2=1 -sFULL_ES3=1\" " &
    "--passL:\"-O3 -sUSE_WEBGL2=1 -sFULL_ES3=1 -sUSE_PTHREADS=0 -sALLOW_MEMORY_GROWTH=1 --preload-file res --shell-file " & webShellFile & "\" " &
    entry

proc buildWeb(release: bool) =
  ensureBuildDirs()
  exec webCompileCommand(release)

proc buildWebDocker(release: bool) =
  ensureBuildDirs()
  let projectDir = getCurrentDir()
  let nimbleDir = getHomeDir() / ".nimble" / "pkgs2"
  let alasgarPath = localAlasgarPath()
  let sokolDir = packagePathSwitch("sokol").split("\"")[1].splitPath().tail
  let packagePaths = &"--path:/alasgar --path:/host-nimble-pkgs2/{sokolDir} "
  let command = webCompileCommand(release, packagePaths, false)
  exec &"docker build -f {webDockerfile} -t {dockerImage} ."
  exec &"docker run --rm -v \"{projectDir}:/app\" -v \"{alasgarPath}:/alasgar:ro\" -v \"{nimbleDir}:/host-nimble-pkgs2:ro\" -w /app {dockerImage} " &
    &"sh -lc '{command} && chown -R $(stat -c %u:%g /app) /app/build'"

proc buildAndroid() =
  ensureBuildDirs()
  exec "./scripts/build_android_docker.sh"
  exec &"rm -rf {androidOut}/*"
  exec &"find platforms/android/app/build/outputs/apk -name '*.apk' -exec cp {{}} {androidOut}/ \\;"

task debug, "Build native debug binary":
  buildNative(false)

task release, "Build native release binary":
  buildNative(true)

task run, "Build and run native debug binary":
  buildNative(false)
  exec nativeOut

task web, "Build Emscripten/WebAssembly debug output with Docker":
  buildWebDocker(false)

task webRelease, "Build Emscripten/WebAssembly release output with Docker":
  buildWebDocker(true)

task webLocal, "Build Emscripten/WebAssembly debug output without Docker":
  buildWeb(false)

task webLocalRelease, "Build Emscripten/WebAssembly release output without Docker":
  buildWeb(true)

task android, "Build native Android debug APK with Docker":
  buildAndroid()

task clean, "Remove generated build outputs":
  exec "docker run --rm -v \"$PWD:/work\" -w /work alpine sh -c 'chown -R $(stat -c %u:%g /work) build nimcache platforms/android/.gradle platforms/android/app/build platforms/android/app/src/main/assets platforms/android/app/jni/main platforms/android/nimcache platforms/android/vendor src/main 2>/dev/null || true' 2>/dev/null || true"
  exec "rm -rf build nimcache platforms/android/.gradle platforms/android/app/build platforms/android/app/src/main/assets platforms/android/app/jni/main platforms/android/nimcache platforms/android/vendor src/main"
