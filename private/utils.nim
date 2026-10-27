import strutils, logging

import aljebra

export aljebra

when defined(js):
  proc native_log(a: cstring) {.importc: "console.log".}
elif defined(emscripten):
  #proc emscripten_log(flags: cint) {.importc, varargs.}
  #template native_log(a: cstring) =
  #  emscripten_log(0, cstring("%s"), cstring(a))
  template native_log(a: string) = echo a
elif defined(macosx) or defined(ios):
  {.passL:"-framework Foundation".}
  {.emit: """

  #include <CoreFoundation/CoreFoundation.h>
  extern void NSLog(CFStringRef format, ...);

  """.}

  proc native_log(a: cstring) =
    {.emit: "NSLog(CFSTR(\"%s\"), `a`);".}
elif defined(android):
  proc log_write(prio: cint, tag, text: cstring) {.importc: "__android_log_write".}
  template native_log(a: cstring) =
    # ANDROID_LOG_INFO = 4
    log_write(4, "NIM_APP", a)
else:
  template native_log(a: string) = echo a

var currentOffset {.threadvar.}: string

## Writes a message to the engine log.
##
## Use `logi` for simple runtime diagnostics that should appear in the native
## platform log:
##
## - JavaScript: `console.log`
## - Android: `__android_log_write` with tag `NIM_APP`
## - macOS and iOS: `NSLog`
## - Other targets: standard output
##
## Arguments are converted with `$` and concatenated without separators, matching
## Nim's `echo`-style varargs behavior.
##
## Example:
##
## ```nim
## logi "Loaded scene: ", sceneName
## logi "Player position: ", player.transform.pos
## ```
##
## If called inside `enterLog`, the message is prefixed with the current
## indentation level.
proc logi*(a: varargs[string, `$`]) {.gcsafe.} =
  native_log(currentOffset & a.join())

proc increaseOffset() =
  currentOffset &= "  "

template decreaseOffset() =
  currentOffset.setLen(currentOffset.len - 2)

## Indents log output for the current scope.
##
## Use `enterLog` at the start of a block, procedure, or nested operation to make
## related log messages easier to read. The indentation is restored automatically
## when the calling scope exits, including early returns.
##
## Example:
##
## ```nim
## proc loadLevel(path: string) =
##   logi "Loading level: ", path
##   enterLog()
##
##   logi "Loading textures"
##   logi "Loading entities"
## ```
##
## Example output:
##
## ```
## Loading level: assets/levels/demo.json
##   Loading textures
##   Loading entities
## ```
template enterLog*() =
  increaseOffset()
  defer: decreaseOffset()

type SystemLogger = ref object of Logger

proc log*(logger: SystemLogger, level: Level, args: varargs[string, `$`]) =
  native_log(currentOffset & args.join())

proc registerLogger() =
  var lg: SystemLogger
  lg.new()
  addHandler(lg)

# General funcs
## Stops the application with an error message.
##
## Use `halt` when the engine cannot continue safely, for example after a
## missing required asset, invalid configuration, or unrecoverable platform
## failure. The message is written with `logi` before terminating the process.
##
## Example:
##
## ```nim
## if not fileExists(configPath):
##   halt "Missing config file: " & configPath
## ```
proc halt*(message: string) =
  logi message
  quit message

registerLogger()
