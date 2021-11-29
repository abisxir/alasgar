# Package

version     = "0.2"
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
requires "jnim" # For android target
requires "https://github.com/yglukhov/android"
requires "https://github.com/yglukhov/darwin"
