import ../core
import ../input
import ../system

type
    ScriptComponent* = ref object of Component
        update*: proc(component: ScriptComponent, input: Input, delta: float32) {.closure.}
        inactive*: bool

    ScriptSystem* = ref object of System


# Component implementation
func newScriptComponent*(update: proc(component: ScriptComponent, input: Input, delta: float32) {.closure.}): ScriptComponent =
    new(result)
    result.update = update


# System implementation
proc newScriptSystem*(): ScriptSystem =
    new(result)
    result.name = "Script System"


proc updateScript(script: ScriptComponent, i: Input, d: float32) =
    if script.update != nil and not script.inactive:
        script.update(script, i, d)


method process*(sys: ScriptSystem, scene: Scene, input: Input, delta: float32) =
    forEachComponent(scene, input, delta, updateScript)

