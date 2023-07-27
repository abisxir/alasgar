import vmath

type
    Settings = object
        maxBatchSize*: int
        maxLights*: int
        screenSize*: Vec2
        keepRatio*: bool
        verbose*: bool
        maxFPS*: int
        depthMapSize*: int
        exitOnEsc*: bool

var settings* = Settings(
    maxBatchSize: 1,
    maxLights: 8,
    screenSize: vec2(0, 0),
    keepRatio: false,
    verbose: false,
    maxFPS: 60,
    depthMapSize: 1024,
    exitOnEsc: false,
)
