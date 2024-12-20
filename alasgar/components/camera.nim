import times
import math

import ../utils
import ../shaders/base
import ../core
import ../system
import ../physics/plane
import ../physics/ray
import ../render/gpu

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
method `$`*(c: CameraComponent): string = &"CameraComponent[direction={c.direction}, fov={c.fov}, aspect={c.aspect}, near={c.near} far={c.far}]"

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


proc newOrthoCamera*(left, right, bottom, top, near, far: float32, direction: Vec3,
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

proc `view`*(camera: CameraComponent): Mat4 = 
    lookAt(
        camera.transform.globalPosition, 
        camera.transform.globalPosition + camera.direction, 
        camera.up
    )
    #fromAngles(
    #    toAngles(
    #        camera.transform.globalPosition, 
    #        camera.transform.globalPosition + camera.direction
    #    )
    #)

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

proc getRayToScreenPosition*(camera: CameraComponent, position: Vec2): Ray =
    let
        worldCoords = screenToWorldCoord(
            position,
            graphics.windowSize, 
            camera
        )
    if camera.kind == orthographicCamera:
        let 
            near = vec3(worldCoords.x, worldCoords.y, camera.near)
            far = vec3(worldCoords.x, worldCoords.y, camera.far)
        result = newRay(near, far - near)
    else:
        let rayDirection = normalize(worldCoords.xyz) * camera.far
        result = newRay(camera.transform.globalPosition, rayDirection)    

func extractFrustumPlanes*(camera: CameraComponent, planes: var array[6, Plane]) =
    let mvp = camera.projection * camera.transform.world
    planes[0].x = mvp.m30 + mvp.m00
    planes[0].y = mvp.m31 + mvp.m01
    planes[0].z = mvp.m32 + mvp.m02
    planes[0].w = mvp.m33 + mvp.m03
    # Right clipping plane
    planes[1].x = mvp.m30 - mvp.m00
    planes[1].y = mvp.m31 - mvp.m01
    planes[1].z = mvp.m32 - mvp.m02
    planes[1].w = mvp.m33 - mvp.m03
    # Top clipping plane
    planes[2].x = mvp.m30 - mvp.m10
    planes[2].y = mvp.m31 - mvp.m11
    planes[2].z = mvp.m32 - mvp.m12
    planes[2].w = mvp.m33 - mvp.m13
    # Bottom clipping plane
    planes[3].x = mvp.m30 + mvp.m10
    planes[3].y = mvp.m31 + mvp.m11
    planes[3].z = mvp.m32 + mvp.m12
    planes[3].w = mvp.m33 + mvp.m13
    # Near clipping plane
    planes[4].x = mvp.m30 + mvp.m20
    planes[4].y = mvp.m31 + mvp.m21
    planes[4].z = mvp.m32 + mvp.m22
    planes[4].w = mvp.m33 + mvp.m23
    # Far clipping plane
    planes[5].x = mvp.m30 - mvp.m20
    planes[5].y = mvp.m31 - mvp.m21
    planes[5].z = mvp.m32 - mvp.m22
    planes[5].w = mvp.m33 - mvp.m23


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

template addEffect*(camera: CameraComponent, name: string, fs: untyped) = 
    addEffect(camera, name, newCanvasShader(fs))
template addEffect*(camera: CameraComponent, name: string, vx, fx: untyped) = 
    addEffect(camera, name, newCanvasShader(vx, fs))
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
    result.name = "Camera"

proc `activeCamera`*(scene: Scene): CameraComponent =
    result = nil
    for c in iterate[CameraComponent](scene):
        if result == nil or c.timestamp > result.timestamp:
            result = c

proc updateShader(shader: Shader, 
                  active: CameraComponent, 
                  screenSize: Vec2, 
                  age, delta: float32, 
                  frames: int, 
                  mouseXY: Vec2,
                  mouseZW: Vec2) =
                  #today: DateTime,
                  #timestamp: Time) =
    use(shader)

    shader["CAMERA.PROJECTION_MATRIX"] = active.projection
    shader["CAMERA.INV_PROJECTION_MATRIX"] = inverse(active.projection)
    shader["CAMERA.VIEW_MATRIX"] = active.view
    shader["CAMERA.INV_VIEW_MATRIX"] = inverse(active.view)
    shader["CAMERA.INVERSE_VIEW_PROJECTION_MATRIX"] = inverse(active.view * active.projection)
    shader["CAMERA.POSITION"] = active.transform.globalPosition
    shader["CAMERA.DIRECTION"] = active.direction
    shader["CAMERA.NEAR"] = active.near
    shader["CAMERA.FAR"] = active.far

    shader["FRAME.RESOLUTION"] = vec3(screenSize.x, screenSize.y, 0)
    shader["FRAME.TIME"] = age
    shader["FRAME.TIME_DELTA"] = delta
    shader["FRAME.COUNT"] = frames.float32
    shader["FRAME.MOUSE"] = vec4(mouseXY.x, mouseXY.y, mouseZW.x, mouseZW.y)
    #shader["FRAME.DATE"] = vec4(today.year.float32, today.month.float32, today.monthday.float32, toUnixFloat(timestamp))

 
method process*(sys: CameraSystem, scene: Scene, input: Input, delta: float32, frames: int, age: float32) =
    {.warning[LockLevel]:off.}
    let active = scene.activeCamera
    #let today = now()
    #let timestamp = getTime()
    let mouseXY = getMousePosition(input)
    let mouseZW = if getMouseButtonDown(input, mouseButtonLeft): mouseXY else: mouseXY * -1

    for shader in graphics.context.shaders:
        updateShader(
            shader, 
            active, 
            graphics.screenSize, 
            age, delta, 
            frames,
            mouseXY,
            mouseZW,
            #today,
            #timestamp
        )

    for (name, shader, enable) in active.effects:
        if enable:
            updateShader(
                shader, 
                active, 
                graphics.screenSize, 
                age, delta, 
                frames,
                mouseXY,
                mouseZW,
                #today,
                #timestamp
            )
            add(graphics.context.effects, shader)
