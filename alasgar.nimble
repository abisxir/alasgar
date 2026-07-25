# Package

version     = "1.0.0"
author      = "Abi Mohammadi"
description = "Game Engine"
license     = "MIT"

# Directory configuration
installDirs = @["alasgar", "private", "assets"]
installFiles = @["alasgar.nim"]

requires "nim >= 2.2.0"

# Dependencies
requires "sokol == 0.6.0"

# monogram font used as default bitmap font: https://itch.io/t/214662/monogram-a-free-monospace-pixel-font
