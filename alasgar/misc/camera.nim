import ../core
import ../engine
import ../input
import ../components/camera
import ../components/script

const MAX_STEP = 5

type
    CameraControllerComponent* = ref object of Component
        distance*: float32
        theta: float32
        phi: float32
        target*: Vec3
        lastMousePos: Vec2
        delta: Vec2
        speed*: float32
        rotating: bool
        panning: bool

proc handleRotating(controller: CameraControllerComponent, input: Input, delta: float32) =
    var 
        theta = controller.theta - controller.delta.x * delta
        phi = controller.phi + controller.delta.y * delta

    if phi > PI / 2:
        phi = PI / 2
    elif phi < -PI / 2:
        phi = -PI / 2

    controller.theta = theta
    controller.phi = phi      

proc handlePanning(controller: CameraControllerComponent, input: Input, delta: float32) =
    let offset = vec3(
        controller.delta.x * delta, 
        controller.delta.y * delta, 
        0
    )
    controller.target = lerp(
        controller.target, 
        controller.target + offset, 
        controller.speed * delta * 2
    )

#proc handlePanning(controller: CameraControllerComponent) =
#    let 
#        camera = controller.entity[CameraComponent]
#        amount = controller.lastMousePos - input.mouse.position
#        right = normalize(cross(camera.direction, camera.up))
#        up = normalize(cross(right, camera.direction))
#        target = controller.target + right * amount.x * 0.01 + up * amount.y * 0.01
#    controller.target = target

proc handleCameraControler(script: ScriptComponent) =
    let 
        input = runtime.input
        delta = runtime.delta
        camera = script[CameraComponent]
        controller = script[CameraControllerComponent]
        mouseDelta = input.mouse.position - controller.lastMousePos

    controller.delta = vec2(clamp(mouseDelta.x, -MAX_STEP, MAX_STEP), clamp(mouseDelta.y, -MAX_STEP, MAX_STEP))
    controller.lastMousePos = input.mouse.position

    if getMouseButtonDown(input, mouseButtonLeft):
        controller.rotating = true
    elif getMouseButtonUp(input, mouseButtonLeft):
        controller.rotating = false
    elif getMouseButtonDown(input, mouseButtonRight):
        controller.panning = true
    elif getMouseButtonUp(input, mouseButtonRight):
        controller.panning = false
    elif input.mouse.scrolling:
        controller.distance -= input.mouse.wheel.y * delta * controller.speed * 2
    
    if controller.rotating:
        handleRotating(controller, input, delta)
    elif controller.panning:
        handlePanning(controller, input, delta)

    let 
        radius = controller.distance
        newPosition = controller.target + vec3(
            radius * sin(controller.theta) * cos(controller.phi), 
            radius * sin(controller.phi), 
            radius * cos(controller.theta) * cos(controller.phi)
        )
    camera.transform.position = lerp(
        camera.transform.position, 
        newPosition, 
        controller.speed * delta
    )
    camera.direction = controller.target - camera.transform.position


proc addCameraController*(e: Entity, theta=PI/4.0, phi=PI/4.0) =
    let controller = new(CameraControllerComponent)
    controller.distance = 10
    controller.speed = 10
    controller.theta = theta
    controller.phi = phi
    addComponent(e, controller)
    addComponent(e, newScriptComponent(handleCameraControler))
