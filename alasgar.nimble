# Package

version     = "0.1"
author      = "Abi Mohammadi"
description = "Game Engine"
license     = "MIT"

# Directory configuration
installDirs = @["alasgar", "assets"]
installFiles = @["alasgar.nim"]


# Dependencies

requires "nake"
requires "sdl2"
requires "chroma"
requires "stbimage"
requires "closure_compiler >= 0.3.1"
requires "plists"
requires "jnim" # For android target
requires "variant >= 0.2 & < 0.3"
requires "kiwi"
requires "jsbind"
requires "rect_packer"
requires "https://github.com/yglukhov/android"
requires "https://github.com/yglukhov/darwin"
requires "os_files"
requires "https://github.com/tormund/nester"
requires "nimwebp"
requires "https://github.com/nimgl/imgui.git"
