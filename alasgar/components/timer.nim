import ../core
import ../input
import ../system

type
    TimerProc = proc(component: TimerComponent) {.closure.}
    TimerComponent* = ref object of Component
        timeout*: float32
        handler: TimerProc
        inactive: bool
        count: int
        lastTicks: float32
    TimerSystem* = ref object of System


# Component implementation
proc newTimerComponent*(timeout: float32, handler: TimerProc, autoStart=true): TimerComponent = 
    TimerComponent(
        timeout: timeout, 
        handler: handler, 
        inactive: not autoStart,
        lastTicks: 0.0,
        count: 0
    )
proc timer*(e: Entity, timeout: float32, handler: TimerProc, autoStart=true) =  e.add(newTimerComponent(timeout, handler, autoStart))
proc start*(timer: TimerComponent) = timer.inactive = false
proc stop*(timer: TimerComponent) = timer.inactive = true
proc `callCount`*(timer: TimerComponent): int = timer.count

# System implementation
proc newTimerSystem*(): TimerSystem =
    new(result)
    result.name = "Timer System"

method process*(sys: TimerSystem, scene: Scene, input: Input, delta: float32, frames: int, age: float32) =
    {.warning[LockLevel]:off.}
    for timer in iterateComponents[TimerComponent](scene):
        if timer.handler != nil and not timer.inactive:
            if timer.lastTicks == 0.0:
                timer.lastTicks = age
            elif age - timer.lastTicks >= timer.timeout:
                timer.handler(timer)
                timer.lastTicks = age
                timer.count += 1

