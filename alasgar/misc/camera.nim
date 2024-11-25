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

proc handleRotating(controller: CameraControllerComponent) =
    var 
        theta = controller.theta - controller.delta.x * runtime.delta
        phi = controller.phi + controller.delta.y * runtime.delta

    if phi > PI / 2:
        phi = PI / 2
    elif phi < -PI / 2:
        phi = -PI / 2

    controller.theta = theta
    controller.phi = phi      

proc handlePanning(controller: CameraControllerComponent) =
    let offset = vec3(
        controller.delta.x * runtime.delta, 
        controller.delta.y * runtime.delta, 
        0
    )
    controller.target = mix(
        controller.target, 
        controller.target + offset, 
        controller.speed * runtime.delta * 2
    )

#proc handlePanning(controller: CameraControllerComponent) =
#    let 
#        camera = controller.entity[CameraComponent]
#        amount = controller.lastMousePos - input.mouse.position
#        right = normalize(cross(camera.direction, camera.up))
#        up = normalize(cross(right, camera.direction))
#        target = controller.target + right * amount.x * 0.01 + up * amount.y * 0.01
#    controller.target = target

proc handleInput(component: InputComponent, input: Input) =
    let 
        controller = component[CameraControllerComponent]
        mouseDelta = input.mouse.position - controller.lastMousePos
    if getMouseButtonDown(input, mouseButtonLeft):
        controller.rotating = true
    elif getMouseButtonUp(input, mouseButtonLeft):
        controller.rotating = false
    elif getMouseButtonDown(input, mouseButtonRight):
        controller.panning = true
    elif getMouseButtonUp(input, mouseButtonRight):
        controller.panning = false
    elif input.mouse.scrolling:
        controller.distance -= input.mouse.wheel.y * runtime.delta * controller.speed * 2

    controller.delta = vec2(clamp(mouseDelta.x, -MAX_STEP, MAX_STEP), clamp(mouseDelta.y, -MAX_STEP, MAX_STEP))
    controller.lastMousePos = input.mouse.position


proc updateCameraControler(script: ScriptComponent) =
    let 
        delta = runtime.delta
        camera = script[CameraComponent]
        controller = script[CameraControllerComponent]
   
    if controller.rotating:
        handleRotating(controller)
    elif controller.panning:
        handlePanning(controller)

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


proc addCameraController*(e: Entity, distance= 10.0, theta=PI/4.0, phi=PI/4.0) =
    let controller = new(CameraControllerComponent)
    controller.distance = distance
    controller.speed = 10
    controller.theta = theta
    controller.phi = phi
    add(e, controller)
    add(e, newInputComponent(handleInput))
    add(e, newScriptComponent(updateCameraControler))
