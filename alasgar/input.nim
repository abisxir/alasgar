import ports/sdl2
import utils

type
    MouseButton* = enum
        mouseButtonNone,
        mouseButtonLeft,
        mouseButtonRight,
        mouseButtonMiddle,
        mouseButtonX1,
        mouseButtonX2,
        mouseButtonUnknown

    MouseState* = enum
        mouseStateNone,
        mouseStateDown,
        mouseStateUp

    TouchState* = enum
        touchStateNone,
        touchStateFingerDown,
        touchStateFingerUp,
        touchStateUnknown

    WheelState* = enum
        mouseWheelStateNone,
        mouseWheelStateScroll,
        mouseWheelStateUnknown

    TouchData* = object
        id: int
        position: Vec2
        timestamp: uint32
        pressure: float

    Touch* = object
        state: TouchState
        data: seq[TouchData]

    Wheel* = object
        x, y: int
        state: WheelState

    Mouse* = object
        position: Vec2
        state: MouseState
        button: MouseButton
        clicks: uint8
        wheel: Wheel

    Keyboard* = object
        keyDown: bool
        keyUp: bool
        keyName: string
        repeat: bool

    Input* = object
        event*: Event
        keyboard*: Keyboard
        mouse*: Mouse
        touch*: Touch

proc updateMousePosition*(outInput: ptr Input) =
    var x, y: cint
    discard getMouseState(x, y)
    outInput.mouse.position.x = x.float32
    outInput.mouse.position.y = y.float32

proc parseEvent*(pEvent: ptr Event, windowSize: Vec2, outInput: ptr Input) =
    outInput.event = pEvent[]

    # Updates mouse state
    updateMousePosition(outInput)

    #outInput.touchState = touchStateUnknown
    #outInput.mouseState = mouseStateNone
    #outInput.mouseButton = mouseButtonNone
    #outInput.mouseWheelState = mouseWheelStateNone
    #outInput.mouseClicks = 0
    case pEvent[].kind:
        of KeyDown, KeyUp:
            let 
                event = cast[KeyboardEventPtr](pEvent)
                name = getKeyName(event.keysym.sym)
            outInput.keyboard.keyDown = event.kind == KeyDown
            outInput.keyboard.keyUp = event.kind == KeyUp
            outInput.keyboard.repeat = event.repeat.bool
            outInput.keyboard.keyName = $name
        of MouseMotion:
            let mouseMotionEvent = cast[MouseButtonEventPtr](pEvent)
            if mouseMotionEvent.which != SDL_TOUCH_MOUSEID:
                outInput.mouse.clicks = mouseMotionEvent.clicks.uint8
                if mouseMotionEvent.state.KeyState == KeyPressed:
                    outInput.mouse.state = mouseStateDown
                elif mouseMotionEvent.state.KeyState == KeyReleased:
                    outInput.mouse.state = mouseStateUp
                outInput.mouse.button = case mouseMotionEvent.button:
                    of sdl2.BUTTON_LEFT: mouseButtonLeft
                    of sdl2.BUTTON_MIDDLE: mouseButtonMiddle
                    of sdl2.BUTTON_RIGHT: mouseButtonRight
                    of sdl2.BUTTON_X1: mouseButtonX1
                    of sdl2.BUTTON_X2: mouseButtonX2
                    else: mouseButtonUnknown
                outInput.mouse.state = if outInput.mouse.button == mouseButtonUnknown: mouseStateUp else: mouseStateDown
                outInput.mouse.position.x = mouseMotionEvent.x.float32
                outInput.mouse.position.y = mouseMotionEvent.y.float32
        of MouseButtonDown, MouseButtonUp:
            #when not defined(ios) and not defined(android):
            #    if pEvent[].kind == MouseButtonDown:
            #        discard sdl2.captureMouse(True32)
            #    else:
            #        discard sdl2.captureMouse(False32)
            
            # Casts to SDL mouse event object, to extract information
            let mouseEvent = cast[MouseButtonEventPtr](pEvent)
            
            if mouseEvent.which != SDL_TOUCH_MOUSEID:
                outInput.mouse.clicks = mouseEvent.clicks.uint8
                if mouseEvent.state.KeyState == KeyPressed:
                    outInput.mouse.state = mouseStateDown
                elif mouseEvent.state.KeyState == KeyReleased:
                    outInput.mouse.state = mouseStateUp

                outInput.mouse.button = case mouseEvent.button:
                    of sdl2.BUTTON_LEFT: mouseButtonLeft
                    of sdl2.BUTTON_MIDDLE: mouseButtonMiddle
                    of sdl2.BUTTON_RIGHT: mouseButtonRight
                    of sdl2.BUTTON_X1: mouseButtonX1
                    of sdl2.BUTTON_X2: mouseButtonX2
                    else: mouseButtonUnknown
                outInput.mouse.position.x = mouseEvent.x.float32
                outInput.mouse.position.y = mouseEvent.y.float32
        of FingerMotion, FingerDown, FingerUp:
            outInput.touch.state = case pEvent[].kind
                of FingerDown: touchStateFingerDown
                of FingerUp: touchStateFingerUp
                else: touchStateUnknown

            let touchEvent = cast[TouchFingerEventPtr](pEvent)
            let touchPosition = vec2(touchEvent.x * windowSize.x, touchEvent.y * windowSize.y)
            add(
                outInput.touch.data, 
                TouchData(
                    position: touchPosition, 
                    id: int(touchEvent.fingerID), 
                    timestamp: touchEvent.timestamp,
                    pressure: touchEvent.pressure
                )
            )

            if outInput.touch.state == touchStateFingerDown:
                outInput.mouse.button = mouseButtonLeft
                outInput.mouse.state = mouseStateDown
            elif outInput.touch.state == touchStateFingerUp:
                outInput.mouse.button = mouseButtonLeft
                outInput.mouse.state = mouseStateUp
        of MouseWheel:
            # Casts to SDL mouse wheel event object, to extract information
            let mouseWheelEvent = cast[MouseWheelEventPtr](pEvent)
            if mouseWheelEvent.x != 0 or mouseWheelEvent.y != 0:
                outInput.mouse.wheel.state = mouseWheelStateScroll
                outInput.mouse.wheel.x = mouseWheelEvent.x
                outInput.mouse.wheel.y = mouseWheelEvent.y
            else:
                outInput.mouse.wheel.state = mouseWheelStateUnknown
        else:
            discard

func hasKeyboardEvent*(i: Input): bool = i.event.kind == KeyUp or i.event.kind == KeyDown
func isKeyDown*(i: Input, name: string): bool = i.keyboard.keyDown and toLower(name) == toLower(i.keyboard.keyName)
func isKeyUp*(i: Input, name: string): bool = i.keyboard.keyUp and toLower(name) == toLower(i.keyboard.keyName)
func isKeyDown*(i: Input): bool = i.keyboard.keyDown
func isKeyUp*(i: Input): bool = i.keyboard.keyUp
func getKey*(i: Input): string = i.keyboard.keyName
func hasMouseEvent*(i: Input): bool = i.event.kind == FingerMotion or i.event.kind == FingerUp or i.event.kind == FingerDown
func getMousePosition*(i: Input): Vec2 = i.mouse.position
func getMousePosition*(): Vec2 = 
    var x, y: cint
    discard getMouseState(x, y)
    result.x = x.float32
    result.y = y.float32
func getMouseButtonDown*(i: Input, btn: MouseButton): bool = i.mouse.state == mouseStateDown and i.mouse.button == btn
func getMouseButtonUp*(i: Input, btn: MouseButton): bool = i.mouse.state == mouseStateUp and i.mouse.button == btn
func getMouseClicks*(i: Input): uint8 = i.mouse.clicks
func hasTouchEvent*(i: Input): bool = i.event.kind == MouseButtonDown or i.event.kind == MouseButtonUp or i.event.kind == MouseMotion or i.event.kind == MouseWheel
func getTouchCount*(i: Input): int = len(i.touch.data)
func getTouchPosition*(i: Input, pos: var Vec2): bool =
    result = len(i.touch.data) > 0
    if result:
        pos = i.touch.data[0].position

func getTouch*(i: Input, index: int): TouchData = i.touch.data[index]

func getMouseWheel*(i: Input, scroll: var Vec2): bool =
    result = i.mouse.wheel.state == mouseWheelStateScroll
    if result:
        scroll.x = float32(i.mouse.wheel.x)
        scroll.y = float32(i.mouse.wheel.y)

func getGlobalMousePosition*(): Vec2 =
    var x, y: cint
    discard getMouseState(x, y)
    result = vec2(x.float32, y.float32)

func `mouse`*(i: Input): Mouse = i.mouse
func `position`*(m: Mouse): Vec2 = m.position
func `wheel`*(m: Mouse): Vec2 = vec2(m.wheel.x.float32, m.wheel.y.float32)
func `scrolling`*(m: Mouse): bool = m.wheel.state == mouseWheelStateScroll
func `keyboard`*(i: Input): Keyboard = i.keyboard
func `touch`*(i: Input): Touch = i.touch
func `$`*(mouse: Mouse): string = &"Mouse\n\tposition: [{mouse.position}]\n\tstate: [{mouse.state}]\n\tbutton: [{mouse.button}]\n\tclicks: [{mouse.clicks}]\n\twheel state: [{mouse.wheel.state}]\n\twheel data: [{mouse.wheel.x}, {mouse.wheel.y}]"
func `$`*(keyboard: Keyboard): string = &"Keyboard\n\tkey down: [{keyboard.keyDown}]\n\tkey up: [{keyboard.keyUp}]\n\tkey name: [{keyboard.keyName}]\n\trepeated: [{keyboard.repeat}]"
func `$`*(touch: Touch): string = &"Touch\n\tstate: [{touch.state}]\n\tdata: [{touch.data}]"
func `$`*(i: Input): string =
    result = &"{i.keyboard}\n{i.mouse}\n{i.touch}"


