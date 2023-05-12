when defined(emscripten):
    import jsbind/emscripten
import sdl2
import alasgar/ports/glad

  
var
  window: sdl2.WindowPtr
  renderer: sdl2.RendererPtr
  
proc mainloop() {.cdecl.} =
  renderer.setDrawColor(255, 128, 0, 255)
  renderer.clear()        
  renderer.present()
  
sdl2.init(INIT_VIDEO)
discard sdl2.createWindowAndRenderer(640, 480, 0, window, renderer)
  
const simulate_infinite_loop = 1
const fps = -1
when defined(emscripten):
    emscripten_set_main_loop(mainloop, fps, simulate_infinite_loop)
#else:
#    while true:
#        mainloop()
  
renderer.destroy
window.destroyWindow
sdl2.quit()