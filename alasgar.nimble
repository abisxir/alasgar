# Package

version     = "0.4"
author      = "Abi Mohammadi"
description = "Game Engine"
license     = "MIT"

# Directory configuration
installDirs = @["alasgar", "assets"]
installFiles = @["alasgar.nim"]


# Dependencies
requires "chroma"
requires "vmath"
requires "stb_image"
#requires "pixie"
requires "nake"
requires "jnim" # For android target
requires "plists"
requires "closure_compiler"
requires "https://github.com/tormund/nester"
requires "https://github.com/yglukhov/android"
requires "https://github.com/yglukhov/darwin"
