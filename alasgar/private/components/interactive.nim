import ../core
import ../system
import ../physics/collision
import ../physics/ray
import ../physics/collision
import collision as collision_component
import camera


type
    InteractionHandleProc* = proc(component: InteractiveComponent, collision: Collision)
    OutHandleProc* = proc(component: InteractiveComponent)

    InteractiveComponent* = ref object of Component
        hover*: bool
        pressed*: bool
        pressStartTime*: float
        pressEndTime*: float
        input: Input
        onHover: InteractionHandleProc
        onOut: OutHandleProc
        onMotion: InteractionHandleProc
        onPress: InteractionHandleProc
        onRelease: InteractionHandleProc

    InteractiveSystem* = ref object of System


proc newInteractiveComponent*(onHover: InteractionHandleProc=nil, 
                              onOut: OutHandleProc=nil, 
                              onMotion: InteractionHandleProc=nil,
                              onPress: InteractionHandleProc=nil,
                              onRelease: InteractionHandleProc=nil): InteractiveComponent =
    new(result)
    result.onHover = onHover
    result.onMotion = onMotion
    result.onOut = onOut
    result.onPress = onPress
    result.onRelease = onRelease

proc handleMouseIn*(ic: InteractiveComponent, collision: Collision) =
    if not ic.hover:
        ic.hover = true
        if ic.onHover != nil:
            ic.onHover(ic, collision)
    if ic.onMotion != nil:
        ic.onMotion(ic, collision)


proc handleMouseOut*(ic: InteractiveComponent) =
    if ic.hover:
        ic.hover = false
        if ic.onOut != nil:
            ic.onOut(ic)
        ic.pressed = false


proc handleMousePress*(ic: InteractiveComponent, collision: Collision) =
    ic.pressed = true
    if ic.onPress != nil:
        ic.onPress(ic, collision)


proc handleMouseRelease*(ic: InteractiveComponent, collision: Collision) =
    ic.pressed = false
    if ic.onRelease != nil:
        ic.onRelease(ic, collision)

# System implementation
func newInteractiveSystem*(): InteractiveSystem =
    new(result)
    result.name = "Interactive System"


method process*(sys: InteractiveSystem, scene: Scene, input: Input, delta: float32, frames: float32, age: float32) =
    let activeCamera = scene.activeCamera
    let worldCoords = screenToWorldCoord(
        getMousePosition(input),
        sys.graphic.windowSize, 
        activeCamera
    )
    var ray: Ray
    if activeCamera.kind == orthographicCamera:
        let near = vec3(worldCoords.x, worldCoords.y, activeCamera.near)
        let far = vec3(worldCoords.x, worldCoords.y, activeCamera.far)
        ray = newRay(near, far - near)
    else:
        let rayDirection = normalize(worldCoords.xyz) * activeCamera.far
        ray = newRay(activeCamera.transform.globalPosition, rayDirection)
    for ic in iterateComponents[InteractiveComponent](scene):
        ic.input = input
        # Checks that entity is visible
        if ic.entity.visible:
            var cc = getComponent[CollisionComponent](ic)
            if cc != nil:
                var collision = intersects(cc, ray)
                if collision != nil:
                    handleMouseIn(ic, collision)
                    if getMouseButtonDown(input, mouseButtonLeft):
                        handleMousePress(ic, collision)
                    if getMouseButtonUp(input, mouseButtonLeft):
                        handleMouseRelease(ic, collision)
                else:
                    handleMouseOut(ic)


func `input`*(c: InteractiveComponent): Input = c.input
