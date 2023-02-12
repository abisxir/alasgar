type
    Settings = object
        maxBatchSize*: int
        maxLights*: int

var settings* = Settings(
    maxBatchSize: 8192,
    maxLights: 8
)