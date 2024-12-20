import ../utils
import ../system

type
    SomeValue = float32 | Vec2 | Vec3 | Quat
    SamplerFunc[T: SomeValue] = proc (track: AnimationTrack[T], frame: int, t: float32): T 
    #ApplyPropertyFunc[T: SomeValue] = proc (e: Entity, value: T)
    InterpolationMode* = enum
        imLinear = 1
        imStep = 2
        imCubic = 3
    TargetPath* = enum
        tpRotation = 1
        tpScale = 2
        tpTranslation = 3
    AnimationState* = enum
        asStop = 1
        asPlay = 2
        asPause = 3
    AnimationFrame*[T: SomeValue] = object
        value*: T
        dataIn*: T
        dataOut*: T
        time*: float32
    AnimationTrack*[T: SomeValue] = object
        frames*: seq[AnimationFrame[T]]
        interpolation: InterpolationMode
        sampler: SamplerFunc[T]
    AnimationProperty*[T: SomeValue] = object
        path: string
        track: AnimationTrack[T]
    AnimationChannel* = object
        #clip: AnimationClipComponent
        entity*{.cursor.}: Entity
        rotation*: AnimationTrack[Quat]
        scale*: AnimationTrack[Vec3]
        translation*: AnimationTrack[Vec3]
    AnimationClipComponent* = ref object of Component
        name: string
        animator: AnimatorComponent
        channels: seq[AnimationChannel]
        startTime: float32
        endTime: float32
        duration: float32
    AnimatorComponent* = ref object of Component
        clips: seq[AnimationClipComponent]
        active: string
        state: AnimationState
        loop*: bool
        speed*: float32
        time: float32
    AnimationSystem* = ref object of System

proc adjustHermiteResult(f: float32): float32 = f
proc adjustHermiteResult(f: Vec3): Vec3 = f
proc adjustHermiteResult(f: Quat): Quat = normalize(f)

proc neighborhood(a, b: float32): float = b
proc neighborhood(a, b: Vec3): Vec3 = b
proc neighborhood(a, b: Quat): Quat = 
    if dot(a, b) < 0:
        result = b * -1

proc hermite[T](t: float32, p1, s1, p2, s2: T): T = 
    let 
        tt = t * t
        ttt = tt * t
        ttt2 = ttt * 2.0f
        tt3 = tt * 3.0f
        h1 = ttt2 - tt3 + 1.0f
        h2 = tt3 - ttt2 # -2.0f * ttt + 3.0f * tt
        h3 = ttt - 2.0f * tt + t
        h4 = ttt - tt
        f = p1 * h1 + neighborhood(p1, p2) * h2 + s1 * h3 + s2 * h4
    result = adjustHermiteResult(f)
proc interpolate(a, b, t: float32): float32 = a + (b - a) * t
proc interpolate(a, b: Vec3, t: float32): Vec3 = mix(a, b, t)
proc interpolate(a, b: Quat, t: float32): Quat =  
    result = mix(a, b, t)
    if dot(a, b) < 0: # Neighborhood
        result = mix(a, b * -1, t)
    result = normalize(result) #NLerp, not slerp

proc newAnimationClipComponent*(animator: AnimatorComponent, name: string): AnimationClipComponent =
    result = AnimationClipComponent.new
    result.animator = animator
    add(result.animator.clips, result)
    result.name = name
    result.startTime = float32.high
    result.endTime = float32.low
    result.duration = 0

method `$`*(c: AnimatorComponent): string = &"AnimatorComponent"
method `$`*(c: AnimationClipComponent): string = &"AnimationClipComponent[{c.name}]"
proc `name`*(c: AnimationClipComponent): string = c.name
proc `duration`*(c: AnimationClipComponent): float32 = c.duration

func newAnimatorComponent*(): AnimatorComponent = 
    new(result)
    result.state = asStop
    result.speed = 1.0

func play*(c: AnimatorComponent, name: string) =
    for clip in c.clips:
        if clip.name == name:
            c.time = clip.startTime
            c.state = asPlay
            c.active = name

func stop*(c: AnimatorComponent) = 
    c.active = ""
    c.state = asStop

func pause*(c: AnimatorComponent) = c.state = asPause
func playing(c: AnimatorComponent, clipName: string): bool = c.active == clipName
func `active`*(c: AnimatorComponent): string = c.active

iterator clips*(c: AnimatorComponent): string =
    for clip in c.clips:
        yield clip.name

template `startTime`*[T: SomeValue](track: AnimationTrack[T]): float32 = track.frames[0].time 
template `endTime`*[T: SomeValue](track: AnimationTrack[T]): float32 = track.frames[^1].time 
template `duration`*[T: SomeValue](track: AnimationTrack[T]): float32 = track.endTime - track.startTime
template `size`*[T: SomeValue](track: AnimationTrack[T]): int = len(track.frames)
proc resize*[T: SomeValue](track: var AnimationTrack[T], size: int) = setLen(track.frames, size)
proc findFrameIndex[T: SomeValue](track: AnimationTrack[T], t: float32): int =
    for i in countdown(track.size - 1, 0):
        if t >= track.frames[i].time:
            result = i
            break

proc sampleConstant[T: SomeValue](track: AnimationTrack[T], thisFrame: int, t: float32): T =
    result = track.frames[thisFrame].value

proc sampleLinear[T: SomeValue](track: AnimationTrack[T], thisFrame: int, t: float32): T =
    let 
        nextFrame = thisFrame + 1
        a = track.frames[thisFrame].time
        b = track.frames[nextFrame].time
        delta = b - a
    if delta > 0:
        let 
            time = (t - a) / delta
            p1 = track.frames[thisFrame].value
            p2 = track.frames[nextFrame].value
        result = interpolate(p1, p2, time)    

proc sampleCubic[T: SomeValue](track: AnimationTrack[T], thisFrame: int, t: float32): T =
    let 
        nextFrame = thisFrame + 1
        a = track.frames[thisFrame].time
        b = track.frames[nextFrame].time
        delta = b - a
    if delta > 0:
        let 
            time = (t - a) / delta
            p1 = track.frames[thisFrame].value
            s1 = delta * track.frames[thisFrame].dataOut
            p2 = track.frames[nextFrame].value
            s2 = delta * track.frames[nextFrame].dataIn
        result = hermite(time, p1, s1, p2, s2)

func `interpolation`*[T:SomeValue](track: AnimationTrack[T]): InterpolationMode = track.interpolation
func `interpolation=`*[T:SomeValue](track: var AnimationTrack[T], value: InterpolationMode) =
    track.interpolation = value
    if value == imLinear:
        track.sampler = sampleLinear
    elif value == imCubic:
        track.sampler = sampleCubic
    else:
        track.sampler = sampleConstant

proc newAnimationTrack*[T: SomeValue](interpolation: InterpolationMode): AnimationTrack[T] =
    result.interpolation = interpolation

proc sample*[T: SomeValue](track: AnimationTrack[T], t: float32, valid: var bool): T =
    if t >= track.startTime and t <= track.endTime:
        let 
            maxSize = if track.interpolation == imStep: track.size else: track.size - 1
            frame = findFrameIndex[T](track, t)
        if frame >= 0 and frame < maxSize:
            result = track.sampler(track, frame, t)
            valid = true

proc sample*(channel: AnimationChannel, t: float32) =
    var valid: bool
    if channel.rotation.size > 0:
        let rotation = sample(channel.rotation, t, valid)
        if valid:
            channel.entity.transform.rotation = rotation
    elif channel.scale.size > 0:
        let scale = sample(channel.scale, t, valid)
        if valid:
            channel.entity.transform.scale = scale
    elif channel.translation.size > 0:
        let translation = sample(channel.translation, t, valid)
        if valid:
            channel.entity.transform.position = translation

proc `startTime`*(channel: AnimationChannel): float32 =
    if channel.rotation.size > 0:
        result = channel.rotation.startTime
    elif channel.scale.size > 0:
        result = channel.scale.startTime
    elif channel.translation.size > 0:
        result = channel.translation.startTime

proc `endTime`*(channel: AnimationChannel): float32 =
    if channel.rotation.size > 0:
        result = channel.rotation.endTime
    elif channel.scale.size > 0:
        result = channel.scale.endTime
    elif channel.translation.size > 0:
        result = channel.translation.endTime

proc `priority`*(channel: AnimationChannel): int =
    if channel.rotation.size > 0:
        result = 1
    elif channel.scale.size > 0:
        result = 2
    elif channel.translation.size > 0:
        result = 0

proc recalculate(clip: AnimationClipComponent) =
    clip.startTime = float32.high
    clip.endTime = float32.low
    for channel in clip.channels:
        if channel.startTime < clip.startTime:
            clip.startTime = channel.startTime
        if channel.endTime > clip.endTime:
            clip.endTime = channel.endTime
    clip.duration = clip.endTime - clip.startTime
    #clip.time = clip.startTime

proc addChannel*(clip: AnimationClipComponent, channel: AnimationChannel) = 
    add(clip.channels, channel)
    recalculate(clip)

#proc setChannels*(clip: AnimationClipComponent, channels: seq[AnimationChannel]) = 
#    clip.channels = channels
#    recalculate(clip)

proc sample*(clip: AnimationClipComponent, delta: float32) =
    if clip.animator.loop and clip.animator.time > clip.endTime:
        clip.animator.time = clip.startTime
    
    if clip.animator.time >= clip.startTime and clip.animator.time <= clip.endTime:
        for channel in clip.channels:
            sample(channel, clip.animator.time)
        clip.animator.time += delta * clip.animator.speed


# System implementation
proc newAnimationSystem*(): AnimationSystem =
    new(result)
    result.name = "Animation"

method process*(sys: AnimationSystem, scene: Scene, input: Input, delta: float32, frames: int, age: float32) =
    {.warning[LockLevel]:off.}
    for c in iterate[AnimationClipComponent](scene):
        # Checks that entity is visible
        if c.entity.visible:
            if playing(c.animator, c.name):
                sample(c, delta)

