# Package

version     = "0.4.4"
author      = "Abi Mohammadi"
description = "Game Engine"
license     = "MIT"

# Directory configuration
installDirs = @["alasgar", "assets"]
installFiles = @["alasgar.nim"]

requires "nim >= 2.2.0"

# Dependencies
requires "checksums == 0.2.1"
requires "chroma == 0.2.7"
requires "stb_image == 2.5"
requires "jnim == 0.5.2" # For android target
requires "https://github.com/yglukhov/android"
