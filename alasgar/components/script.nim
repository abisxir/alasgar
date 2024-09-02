import ../core
import ../input
import ../system

type
    ScriptProc = proc(component: ScriptComponent) {.closure.}
    ScriptComponent* = ref object of Component
        update*: ScriptProc
        inactive*: bool

    ScriptSystem* = ref object of System


# Component implementation
proc newScriptComponent*(update: ScriptProc): ScriptComponent = ScriptComponent(update: update)
proc program*(e: Entity, update: ScriptProc) = add(e, newScriptComponent(update))

# System implementation
proc newScriptSystem*(): ScriptSystem =
    new(result)
    result.name = "Script System"


proc updateScript(script: ScriptComponent, i: Input, d: float32) =
    if script.update != nil and not script.inactive:
        script.update(script)


method process*(sys: ScriptSystem, scene: Scene, input: Input, delta: float32, frames: int, age: float32) =
    {.warning[LockLevel]:off.}
    forEachComponent(scene, input, delta, updateScript)

