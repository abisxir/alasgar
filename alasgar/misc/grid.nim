import ../core
import ../shaders/types
import ../shaders/compile
import ../shaders/base
import ../geometry/plane

proc vs(POSITION: Vec3, UV: Vec2, CAMERA: Uniform[Camera], GRID_SCALE: Uniform[int], DATA: var Vec2, gl_Position: var Vec4) =
    var 
        gridSize = GRID_SCALE.float * CAMERA.FAR - CAMERA.NEAR
        position: Vec3 = gridSize * POSITION
    DATA = position.xz
    gl_Position = CAMERA.PROJECTION_MATRIX * CAMERA.VIEW_MATRIX * vec4(position, 1.0)

proc check(point: Vec2, v, thinkness: float): bool =
    let 
        a = v + thinkness
        b = v - thinkness
    if point.x > b and point.x < a:
        result = true
    elif point.y > b and point.y < a:
        result = true
    else:
        result = false

proc onGrid(UV: Vec2, ticknes: float): bool = 
    let 
        x = abs(fract(UV.x))
        y = abs(fract(UV.y))
    if x < ticknes or y < ticknes:
        result = true
    else:
        result = false

proc fs(CAMERA: Uniform[Camera], TICKNESS: Uniform[float], GRID_COLOR: Uniform[Vec3], DATA: Vec2, COLOR: var Vec4) = 
    COLOR.a = 0.0
    COLOR.rgb = GRID_COLOR
    if check(DATA, 0.0, TICKNESS + TICKNESS / 3.0):
        COLOR.a = 1.0
    elif onGrid(DATA, TICKNESS):
        COLOR.a = 1.0
    
    if COLOR.a > 0.0:
        let 
            maxDistance = (CAMERA.FAR - CAMERA.NEAR) / 2.0
            distance = min(length(CAMERA.POSITION.xz - DATA), maxDistance)
        COLOR.a = 1.0 - distance / maxDistance
    else:
        discard

proc newGrid*(scene: Scene, gridSize: int=1, tickness: float=0.02, color=rgb(0.5, 0.5, 0.5)): Entity =
    let 
        shader = newSpatialShader(vs, fs)
    
    set(shader, "GRID_SCALE", gridSize)
    set(shader, "TICKNESS",  tickness)
    set(shader, "GRID_COLOR",  color.vec3)

    result = newEntity(scene, "Grid")
    addComponent(result, newPlaneMesh(1, 1))
    addComponent(result, newShaderComponent(shader))
