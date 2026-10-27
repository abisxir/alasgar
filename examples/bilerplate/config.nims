# begin Nimble config (version 2)
when withDir(thisDir(), system.fileExists("nimble.paths")):
  include "nimble.paths"
# end Nimble config

import std/os
import std/strutils

let nativeOutDir = thisDir() / "build" / "native"
discard staticExec("mkdir -p " & quoteShell(nativeOutDir))

for localAlasgar in [
  thisDir().parentDir().parentDir(),
  thisDir().parentDir() / "alasgar",
  thisDir().parentDir().parentDir() / "alasgar",
]:
  if fileExists(localAlasgar / "alasgar.nim") and dirExists(localAlasgar / "private"):
    switch("path", localAlasgar)
    break

let sokolPathOutput = staticExec("nimble path sokol 2>/dev/null || true")
for rawPath in sokolPathOutput.splitLines():
  let sokolPath = rawPath.strip()
  let appModule = sokolPath / "sokol" / "app.nim"
  if sokolPath.len > 0 and dirExists(sokolPath / "sokol") and fileExists(appModule) and readFile(appModule).contains("glMajorVersion"):
    switch("path", sokolPath)
    break
