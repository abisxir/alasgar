import unicode
import sdl2
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

    TouchData* = object
        id: int
        position: Vec2
        timestamp: uint32
        pressure: float

    MouseWheelState* = enum
        mouseWheelStateNone,
        mouseWheelStateScroll,
        mouseWheelStateUnknown

    MouseWheelData* = object
        x, y: int

    Input* = object
        keyDown: bool
        keyUp: bool
        keyName: string
        repeated: bool
        mousePosition: Vec2
        mouseState: MouseState
        mouseButton: MouseButton
        mouseClicks: uint8
        mouseWheelState: MouseWheelState
        mouseWheelData: MouseWheelData
        touchState: TouchState
        touches: seq[TouchData]

func `keyName`*(i: Input): string = i.keyName

proc updateMousePosition*(outInput: ptr Input) =
    var x, y: cint
    discard getMouseState(x, y)
    outInput.mousePosition.x = x.float32
    outInput.mousePosition.y = y.float32


proc parseEvent*(pEvent: ptr Event, windowSize: Vec2, outInput: ptr Input) =
    if pEvent[].kind == KeyDown or pEvent[].kind == KeyUp:
        outInput.keyDown = pEvent[].kind == KeyDown
        outInput.keyUp = pEvent[].kind == KeyUp
        var name = getKeyName(pEvent[].evKeyboard.keysym.sym)
        outInput.keyName = $name
        outInput.repeated = pEvent[].evKeyboard.repeat
    
    # Updates mouse state
    updateMousePosition(outInput)

    #outInput.touchState = touchStateUnknown
    #outInput.mouseState = mouseStateNone
    #outInput.mouseButton = mouseButtonNone
    #outInput.mouseWheelState = mouseWheelStateNone
    #outInput.mouseClicks = 0
    case pEvent[].kind:
        of MouseButtonDown, MouseButtonUp:
            when not defined(ios) and not defined(android):
                if pEvent[].kind == MouseButtonDown:
                    discard sdl2.captureMouse(True32)
                else:
                    discard sdl2.captureMouse(False32)
            
            # Casts to SDL mouse event object, to extract information
            let mouseEvent = cast[MouseButtonEventPtr](pEvent)
            
            if mouseEvent.which != SDL_TOUCH_MOUSEID:
                outInput.mouseClicks = mouseEvent.clicks.uint8
                if mouseEvent.state.KeyState == KeyPressed:
                    outInput.mouseState = mouseStateDown
                elif mouseEvent.state.KeyState == KeyReleased:
                    outInput.mouseState = mouseStateUp

                outInput.mouseButton = case mouseEvent.button:
                    of sdl2.BUTTON_LEFT: mouseButtonLeft
                    of sdl2.BUTTON_MIDDLE: mouseButtonMiddle
                    of sdl2.BUTTON_RIGHT: mouseButtonRight
                    of sdl2.BUTTON_X1: mouseButtonX1
                    of sdl2.BUTTON_X2: mouseButtonX2
                    else: mouseButtonUnknown

        of FingerMotion, FingerDown, FingerUp:
            outInput.touchState = case pEvent[].kind
                of FingerDown: touchStateFingerDown
                of FingerUp: touchStateFingerUp
                else: touchStateUnknown

            let touchEvent = cast[TouchFingerEventPtr](pEvent)
            let touchPosition = vec2(touchEvent.x * windowSize.x, touchEvent.y * windowSize.y)
            add(outInput.touches, TouchData(position: touchPosition, 
                                            id: int(touchEvent.fingerID), 
                                            timestamp: touchEvent.timestamp,
                                            pressure: touchEvent.pressure))

            if outInput.touchState == touchStateFingerDown:
                outInput.mouseButton = mouseButtonLeft
                outInput.mouseState = mouseStateDown
            elif outInput.touchState == touchStateFingerUp:
                outInput.mouseButton = mouseButtonLeft
                outInput.mouseState = mouseStateUp
        of MouseWheel:
            # Casts to SDL mouse wheel event object, to extract information
            let mouseWheelEvent = cast[MouseWheelEventPtr](pEvent)
            if mouseWheelEvent.x != 0 or mouseWheelEvent.y != 0:
                outInput.mouseWheelState = mouseWheelStateScroll
                outInput.mouseWheelData.x = mouseWheelEvent.x
                outInput.mouseWheelData.y = mouseWheelEvent.y
            else:
                outInput.mouseWheelState = mouseWheelStateUnknown
        else:
            discard

func isKeyDown*(i: Input, name: string=""): bool = i.keyDown and (toLower(name) == toLower(i.keyName) or len(name) == 0)
func isKeyUp*(i: Input, name: string=""): bool = i.keyUp and (toLower(name) == toLower(i.keyName) or len(name) == 0)
func getKey*(i: Input): string = i.keyName
func getMousePosition*(i: Input): Vec2 = i.mousePosition
func getMouseButtonDown*(i: Input, btn: MouseButton): bool = i.mouseState == mouseStateDown and i.mouseButton == btn
func getMouseButtonUp*(i: Input, btn: MouseButton): bool = i.mouseState == mouseStateUp and i.mouseButton == btn
func getMouseClicks*(i: Input): uint8 = i.mouseClicks
func getTouchCount*(i: Input): int = len(i.touches)

func getTouchPosition*(i: Input, pos: var Vec2): bool =
    result = len(i.touches) > 0
    if result:
        pos = i.touches[0].position

func getTouch*(i: Input, index: int): TouchData = i.touches[index]

func getMouseWheel*(i: Input, scroll: var Vec2): bool =
    result = i.mouseWheelState == mouseWheelStateScroll
    if result:
        scroll.x = float32(i.mouseWheelData.x)
        scroll.y = float32(i.mouseWheelData.y)

func getGlobalMousePosition*(): Vec2 =
    var x, y: cint
    discard getMouseState(x, y)
    result = vec2(x.float32, y.float32)

func `$`*(i: Input): string =
    result = &" keyDown: {i.keyDown}\n keyUp: {i.keyUp}\n keyName: {i.keyName}\n repeated: {i.repeated}\n mousePosition: {i.mousePosition}\n mouseState: {i.mouseState}\n mouseButton: {i.mouseButton}\n mouseClicks: {i.mouseClicks}\n mouseWheelState: {i.mouseWheelState}\n mouseWheelData: {i.mouseWheelData}\n touchState: {i.touchState} \n touches: {i.touches}"


