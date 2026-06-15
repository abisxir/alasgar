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
requires "chroma == 1.0.0"
requires "vmath == 3.0.0"
