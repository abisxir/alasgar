
import ../core
import curve/catmull

type
    CurveMoveComponent* = ref object of Component
        curve*: CatMull
        playing*: bool
        loop*: bool
