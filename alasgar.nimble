# Package

version     = "1.0.0"
author      = "Abi Mohammadi"
description = "Game Engine"
license     = "MIT"

# Directory configuration
installDirs = @["alasgar", "assets"]
installFiles = @["alasgar.nim"]

requires "nim >= 2.2.0"

# Dependencies
requires "sokol == 0.6.0"
