import ../core
import ../input
import ../system

type
    ScriptProc = proc(component: ScriptComponent, input: Input, delta: float32) {.closure.}
    ScriptComponent* = ref object of Component
        update*: ScriptProc
        inactive*: bool

    ScriptSystem* = ref object of System


# Component implementation
proc newScriptComponent*(update: ScriptProc): ScriptComponent = ScriptComponent(update: update)
proc addScript*(e: Entity, update: ScriptProc) = addComponent(e, newScriptComponent(update))

# System implementation
proc newScriptSystem*(): ScriptSystem =
    new(result)
    result.name = "Script System"


proc updateScript(script: ScriptComponent, i: Input, d: float32) =
    if script.update != nil and not script.inactive:
        script.update(script, i, d)


method process*(sys: ScriptSystem, scene: Scene, input: Input, delta: float32, frames: float32, age: float32) =
    forEachComponent(scene, input, delta, updateScript)

