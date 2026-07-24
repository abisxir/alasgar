import alasgar

proc depthVs(
  IN_POSITION: Layout[0, Vec3],
  MODEL: Uniform[Mat4],
) =
  gl_Position = GLSL_CAMERA.PROJECTION * GLSL_CAMERA.VIEW * MODEL * vec4(IN_POSITION, 1)

proc depthFs(OUT_COLOR: var Layout[0, Vec4]) =
  # Nim `discard` emits GLSL `discard;`, which would skip depth writes.
  OUT_COLOR = vec4(1, 1, 1, 1)

proc sceneVs(
  IN_POSITION: Layout[0, Vec3],
  IN_NORMAL: Layout[1, Vec4],
  IN_COLOR: Layout[3, Vec4],
  MODEL: Uniform[Mat4],
  LIGHT_VIEW_PROJECTION: Uniform[Mat4],
  VS_COLOR: var Vec4,
  VS_NORMAL: var Vec3,
  VS_LIGHT_POSITION: var Vec4,
) =
  let
    worldPosition = MODEL * vec4(IN_POSITION, 1)
    worldNormal = MODEL * vec4(IN_NORMAL.x, IN_NORMAL.y, IN_NORMAL.z, 0)
  gl_Position = GLSL_CAMERA.PROJECTION * GLSL_CAMERA.VIEW * worldPosition
  VS_COLOR = IN_COLOR
  VS_NORMAL = normalize(vec3(worldNormal.x, worldNormal.y, worldNormal.z))
  VS_LIGHT_POSITION = LIGHT_VIEW_PROJECTION * worldPosition

proc sceneFs(
  VS_COLOR: Vec4,
  VS_NORMAL: Vec3,
  VS_LIGHT_POSITION: Vec4,
  DEPTH_MAP: Uniform[Sampler2D],
  LIGHT_DIRECTION: Uniform[Vec3],
  OUT_COLOR: var Layout[0, Vec4],
) =
  var
    normal = normalize(VS_NORMAL)
    lightPosition = VS_LIGHT_POSITION / VS_LIGHT_POSITION.w
    shadowUv = vec2(lightPosition.x * 0.5 + 0.5, lightPosition.y * 0.5 + 0.5)
    currentDepth = lightPosition.z * 0.5 + 0.5
    closestDepth = texture(DEPTH_MAP, shadowUv).x
    bias = max(0.0015, 0.006 * (1.0 - dot(normal, LIGHT_DIRECTION)))
    shadow = 1.0

  if currentDepth - bias > closestDepth:
    shadow = 0.38

  let
    diffuse = clamp(dot(normal, LIGHT_DIRECTION), 0.0, 1.0)
    light = 0.28 + diffuse * 0.72 * shadow
  OUT_COLOR = vec4(VS_COLOR.x * light, VS_COLOR.y * light, VS_COLOR.z * light, 1)

const
  ShadowSize = 1024'u32
  LightDirection = vec3(0.52, 0.70, 0.49)

var
  cubeDepth: Pipeline
  planeDepth: Pipeline
  cubeScene: Pipeline
  planeScene: Pipeline
  cubeTransform = Transform(position: vec3(0.0, 0.5, 0.0), scale: vec3(0.5))
  planeTransform = Transform(position: vec3(0.0, -1.0, 0.0), scale: vec3(8.0, 1.0, 8.0))
  camera: Camera
  lightCamera: Camera
  depthMap: View
  depthSampler: Sampler

proc load() =
  let
    cameraTransform = lookAt(vec3(5.0, 4.0, 6.0), vec3(0.0, -0.15, 0.0), vec3(0.0, 1.0, 0.0))
    lightTransform = lookAt(vec3(5.2, 7.0, 4.9), vec3(0.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0))
    depthShader = graphics.shader(depthVs, depthFs)
    sceneShader = graphics.shader(sceneVs, sceneFs)
    cube = graphics.cube(color=vec4(1.0, 0.32, 0.22, 1.0))
    plane = graphics.plane(color=vec4(0.72, 0.74, 0.68, 1.0))

  camera = graphics.perspective(cameraTransform, 45.0, 0.1, 50.0)
  lightCamera = graphics.ortho(lightTransform, 9.0, 1.0, 25.0)

  graphics.color = vec4(0.06, 0.07, 0.08, 1.0)


  cubeDepth = graphics.compact(cube, depthShader)
  planeDepth = graphics.compact(plane, depthShader)
  cubeScene = graphics.compact(cube, sceneShader)
  planeScene = graphics.compact(plane, sceneShader)

  depthMap = graphics.depth(ShadowSize, ShadowSize)
  depthSampler = graphics.sampler(depthMap.texture, minFilter=tfNearest, magFilter=tfNearest)

proc renderDepth(pipeline: var Pipeline, model: Mat4) =
  pipeline.shader.set("MODEL", model)
  graphics.render(pipeline, lightCamera)

proc renderScene(pipeline: var Pipeline, model: Mat4) =
  pipeline.shader.set("MODEL", model)
  pipeline.shader.set("LIGHT_VIEW_PROJECTION", lightCamera.projection * inverse(lightCamera.transform.world))
  pipeline.shader.set("LIGHT_DIRECTION", LightDirection)
  pipeline.shader.set("DEPTH_MAP", depthSampler, 0)
  graphics.render(pipeline, camera)

proc draw() =
  cubeTransform.rotation = fromEuler(runtime.age * 0.7, 0.0, 0.18)

  depthMap.use()
  renderDepth(cubeDepth, cubeTransform.world)
  renderDepth(planeDepth, planeTransform.world)

  graphics.screen()
  renderScene(planeScene, planeTransform.world)
  renderScene(cubeScene, cubeTransform.world)

proc cleanup() =
  destroy(cubeDepth)
  destroy(planeDepth)
  destroy(cubeScene)
  destroy(planeScene)
  destroy(depthSampler)
  destroy(depthMap)

window(960, 540, "Shadow Map", load, draw, cleanup)
