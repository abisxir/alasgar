# begin Nimble config (version 2)
when withDir(thisDir(), system.fileExists("nimble.paths")):
  include "nimble.paths"
# end Nimble config

# The renderer talks to raw OpenGL while Sokol only provides windowing and input,
# so always request the OpenGL backend (instead of Metal/D3D11) from Sokol.
switch("define", "gl")
