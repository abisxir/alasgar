import vmath

type
    Settings = object
        maxBatchSize*: int
        maxLights*: int
        screenSize*: Vec2
        verbose*: bool
        fps*: int
        depthMapSize*: int

var settings* = Settings(
    maxBatchSize: 1,
    maxLights: 8,
    screenSize: vec2(0, 0),
    verbose: false,
    fps: 60,
    depthMapSize: 1024,
)