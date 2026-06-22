import logger, aljebra/[vec4, vec3, vec2, quat, common, swizzling]

export logger, vec4, vec3, vec2, quat, common, swizzling

# General funcs
proc halt*(message: string) =
  logi message
  quit message
