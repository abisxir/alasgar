import ../core
import ../input
import ../system

type
    ScriptProc = proc(component: ScriptComponent) {.closure.}
    ScriptComponent* = ref object of Component
        update*: ScriptProc
        inactive*: bool
    InputProc = proc(component: InputComponent, input: Input) {.closure.}
    InputComponent* = ref object of Component
        update*: InputProc
        inactive*: bool
    ScriptSystem* = ref object of System
    InputSystem* = ref object of System

# Script component implementation
func `$`*(s: ScriptComponent): string = "ScriptComponent"
proc newScriptComponent*(update: ScriptProc): ScriptComponent = ScriptComponent(update: update)
proc program*(e: Entity, update: ScriptProc) = add(e, newScriptComponent(update))

# Input component implementation
func `$`*(s: InputComponent): string = "InputComponent"
proc newInputComponent*(update: InputProc): InputComponent = InputComponent(update: update)
proc program*(e: Entity, update: InputProc) = add(e, newInputComponent(update))

# Script system implementation
proc newScriptSystem*(): ScriptSystem =
    new(result)
    result.name = "Script"

proc updateScript(script: ScriptComponent, i: Input, d: float32) =
    if script.update != nil and not script.inactive:
        script.update(script)

method process*(sys: ScriptSystem, scene: Scene, input: Input, delta: float32, frames: int, age: float32) =
    {.warning[LockLevel]:off.}
    forEachComponent(scene, input, delta, updateScript)

# Input system implementation
proc newInputSystem*(): InputSystem =
    new(result)
    result.name = "Input"

proc updateInput(component: InputComponent, i: Input, d: float32) =
    if component.update != nil and not component.inactive:
        component.update(component, i)

method process*(sys: InputSystem, scene: Scene, input: Input, delta: float32, frames: int, age: float32) =
    {.warning[LockLevel]:off.}
    forEachComponent(scene, input, delta, updateInput)

