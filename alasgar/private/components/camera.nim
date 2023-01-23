import times
import math

import ../utils
import ../shader
import ../core
import ../system
import ../physics/plane

type
    CameraType* = enum
        orthographicCamera, perspectiveCamera

    CameraComponent* = ref object of Component
        kind: CameraType
        direction*: Vec3
        up*: Vec3

        # Perspective
        fov*: float32
        aspect*: float32

        # Orthographic
        left*, right*, bottom*, top*: float32
        
        near*: float32
        far*: float32
        timestamp*: float

        effects: seq[(string, Shader, bool)]

    CameraSystem* = ref object of System


# Component implementation
func `$`*(c: CameraComponent): string =
    result = &"direction={c.direction}, fov={c.fov}, aspect={c.aspect}, near={c.near} far={c.far}"

func `kind`*(c: CameraComponent): CameraType = c.kind

proc newPerspectiveCamera*(fov, aspect, near, far: float32, direction: Vec3,
        up: Vec3 = VEC3_UP): CameraComponent =
    new(result)
    result.fov = fov
    result.aspect = aspect
    result.near = near
    result.far = far
    result.direction = direction
    result.up = up
    result.kind = perspectiveCamera


proc newOrthographicCamera*(left, right, bottom, top, near, far: float32, direction: Vec3,
        up: Vec3 = VEC3_UP): CameraComponent =
    new(result)
    result.left = left
    result.right = right
    result.bottom = bottom
    result.top = top
    result.near = near
    result.far = far
    result.direction = direction
    result.up = up

proc `projection`*(camera: CameraComponent): Mat4 = 
    if camera.kind == perspectiveCamera:
        perspective(camera.fov, camera.aspect, camera.near, camera.far)
    else:
        ortho(camera.left, camera.right, camera.bottom, camera.top, camera.near, camera.far)

proc `view`*(camera: CameraComponent): Mat4 = lookAt(
    camera.transform.globalPosition, 
    camera.transform.globalPosition + camera.direction, 
    camera.up)

proc activate*(camera: CameraComponent) = camera.timestamp = cpuTime()

proc screenToWorldCoord*(pos: Vec2, windowSize: Vec2, camera: CameraComponent): Vec4 =
    # First brings to device coordinate
    var x = (2 * pos.x) / windowSize.x - 1
    var y = (2 * pos.y) / windowSize.y - 1
    var pointerCoords = vec4(x, -y, -1, 1.0)
    var projection = camera.projection
    var view = camera.view

    # Puts in eye coordinate
    var eyeCoords = vec4((inverse(projection) * pointerCoords).xyz, 0)

    # Puts in world coordinate
    result = inverse(view) * eyeCoords

func extractFrustumPlanes*(camera: CameraComponent, planes: var array[6, Plane]) =
    let mvp = camera.projection * camera.transform.world
    planes[0].x = mvp[12] + mvp[0]
    planes[0].y = mvp[13] + mvp[1]
    planes[0].z = mvp[14] + mvp[2]
    planes[0].w = mvp[15] + mvp[3]
    # Right clipping plane
    planes[1].x = mvp[12] - mvp[0]
    planes[1].y = mvp[13] - mvp[1]
    planes[1].z = mvp[14] - mvp[2]
    planes[1].w = mvp[15] - mvp[3]
    # Top clipping plane
    planes[2].x = mvp[12] - mvp[4]
    planes[2].y = mvp[13] - mvp[5]
    planes[2].z = mvp[14] - mvp[6]
    planes[2].w = mvp[15] - mvp[7]
    # Bottom clipping plane
    planes[3].x = mvp[12] + mvp[4]
    planes[3].y = mvp[13] + mvp[5]
    planes[3].z = mvp[14] + mvp[6]
    planes[3].w = mvp[15] + mvp[7]
    # Near clipping plane
    planes[4].x = mvp[12] + mvp[8]
    planes[4].y = mvp[13] + mvp[9]
    planes[4].z = mvp[14] + mvp[10]
    planes[4].w = mvp[15] + mvp[11]
    # Far clipping plane
    planes[5].x = mvp[12] - mvp[8]
    planes[5].y = mvp[13] - mvp[9]
    planes[5].z = mvp[14] - mvp[10]
    planes[5].w = mvp[15] - mvp[11]


proc calculateViewCenter*(camera: CameraComponent, vOut: var Vec3, rOut: var float32) =
    vOut = camera.transform.globalPosition + (normalize(camera.direction) * ((camera.far - camera.near) / 2 + camera.near))
    let far = camera.transform.globalPosition + (normalize(camera.direction) * camera.far)
    let angle = degToRad(camera.fov) / 2
    let opposite = camera.far * sin(angle) 
    let farLeft = far + (VEC3_LEFT * opposite)
    rOut = length(farLeft - vOut)

proc hasEffect*(camera: CameraComponent, name: string): bool =
    for it in camera.effects:
        if it[0] == name:
            return true
    return false

proc removeEffect*(camera: CameraComponent, name: string) = 
    for it in camera.effects:
        if it[0] == name:
            destroy(it[1])
    keepItIf(camera.effects, it[0] != name)

proc addEffect*(camera: CameraComponent, name: string, shader: Shader) =
    removeEffect(camera, name)
    add(camera.effects, (name, shader, true))

proc addEffect*(camera: CameraComponent, name: string, source: string) = addEffect(camera, name, newCanvasShader(source))
proc addEffect*(camera: CameraComponent, name: string, vsource, fsource: string) = addEffect(camera, name, newCanvasShader(vsource, fsource))
proc getEffect*(camera: CameraComponent, name: string): Shader =
    for (key, shader, enable) in camera.effects:
        if key == name and enable:
            return shader

proc disableEffect*(camera: CameraComponent, name: string) =
    for it in mitems(camera.effects):
        if it[0] == name:
            it[2] = false

proc enableEffect*(camera: CameraComponent, name: string) =
    for it in mitems(camera.effects):
        if it[0] == name:
            it[2] = true


# System implementation
proc newCameraSystem*(): CameraSystem =
    new(result)
    result.name = "Camera System"

proc `activeCamera`*(scene: Scene): CameraComponent =
    result = nil
    for c in iterateComponents[CameraComponent](scene):
        if result == nil or c.timestamp > result.timestamp:
            result = c
 
method process*(sys: CameraSystem, scene: Scene, input: Input, delta: float32, frames: float32, age: float32) =
    let 
        active = scene.activeCamera
        today = now()
        timestamp = getTime()
        mouseXY = getMousePosition(input)
        mouseZW = if getMouseButtonDown(input, mouseButtonLeft): mouseXY else: -1 * mouseXY

    for shader in sys.graphic.context.shaders:
        use(shader)
        shader["camera.projection"] = active.projection
        shader["camera.view"] = active.view
        shader["camera.position"] = active.transform.globalPosition
        shader["camera.near"] = active.near
        shader["camera.far"] = active.far

        shader["frame.resolution"] = vec3(sys.graphic.screenSize.x, sys.graphic.screenSize.y, 0)
        shader["frame.time"] = age
        shader["frame.time_delta"] = delta
        shader["frame.frame"] = frames
        shader["frame.mouse"] = vec4(mouseXY.x, mouseXY.y, mouseZW.x, mouseZW.y)
        shader["frame.date"] = vec4(today.year.float32, today.month.float32, today.monthday.float32, toUnixFloat(timestamp))

    for (name, shader, enable) in active.effects:
        if enable:
            use(shader)

            shader["camera.projection"] = active.projection
            shader["camera.view"] = active.view
            shader["camera.position"] = active.transform.globalPosition
            shader["camera.near"] = active.near
            shader["camera.far"] = active.far

            shader["frame.resolution"] = vec3(sys.graphic.screenSize.x, sys.graphic.screenSize.y, 0)
            shader["frame.time"] = age
            shader["frame.time_delta"] = delta
            shader["frame.frame"] = frames
            shader["frame.mouse"] = vec4(mouseXY.x, mouseXY.y, mouseZW.x, mouseZW.y)
            shader["frame.date"] = vec4(today.year.float32, today.month.float32, today.monthday.float32, toUnixFloat(timestamp))

            add(sys.graphic.context.effects, shader)
