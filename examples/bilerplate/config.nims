# begin Nimble config (version 2)
when withDir(thisDir(), system.fileExists("nimble.paths")):
  include "nimble.paths"
# end Nimble config

import std/os
import std/strutils

let nativeOutDir = thisDir() / "build" / "native"
discard staticExec("mkdir -p " & quoteShell(nativeOutDir))

let localAlasgar = thisDir().parentDir / "alasgar"
if dirExists(localAlasgar):
  switch("path", localAlasgar)

let sokolPath = staticExec("nimble path sokol 2>/dev/null | tail -n1").strip()
if sokolPath.len > 0:
  switch("path", sokolPath)
