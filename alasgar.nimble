# Package

version     = "0.4.1"
author      = "Abi Mohammadi"
description = "Game Engine"
license     = "MIT"

# Directory configuration
installDirs = @["alasgar", "assets"]
installFiles = @["alasgar.nim"]


# Dependencies
requires "checksums"
requires "chroma"
requires "stb_image"
requires "jnim" # For android target
requires "https://github.com/yglukhov/android"
