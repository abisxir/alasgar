import tables

import ../ports/sdl2_mixer as mixer

import ../core
import ../system
import camera


type
    SoundEffectComponent* = ref object of Component
        path: string
        volume: float32
        handle: ChunkPtr
        channel: cint
        repeat: bool

    MusicComponent* = ref object of Component
        path: string
        volume: float32
        handle: MusicPtr

    SoundSystem* = ref object of System


var musicCache = initTable[string, MusicPtr]()
var chunkCache = initTable[string, ChunkPtr]()

# Forwarding
proc play*(c: SoundEffectComponent, count: int=0): bool

func volumeOf(v: float32): cint = cint(v * MIX_MAX_VOLUME.float32)

proc newSoundEffectComponent*(path: string, volume: float32=1.0, repeat: bool=false, autoplay: bool=false): SoundEffectComponent =
    new(result)
    result.path = path
    result.repeat = repeat
    result.channel = -1
    result.volume = volume

    if hasKey(chunkCache, path):
        result.handle = chunkCache[path]
    else:
        result.handle = loadWAV(path)
        if isNil(result.handle):
            raise newAlasgarError(&"Cannot load audio file [{path}], audio file for effects must be wav file.")
        else:
            chunkCache[path] = result.handle

    if autoplay:
        discard play(result)


proc ready(c: SoundEffectComponent): bool = c.channel != -1


proc play(c: SoundEffectComponent, count: int=0): bool =
    echo "Playing music:", c.channel
    var repeat = 0
    if count > 0:
        repeat = count - 1
    elif c.repeat:
        repeat = -1

    echo "Music is ready to play..."
    c.channel = playChannel(-1, c.handle, repeat.cint)
    result = c.channel != -1 
    if result:
        discard volume(c.channel, volumeOf(c.volume))


proc stop*(c: SoundEffectComponent) =
    if ready(c):
        discard haltChannel(c.channel)


proc isPlaying*(c: SoundEffectComponent): bool =
    result = ready(c) and playing(c.channel) != 0


proc adjustBy(c: SoundEffectComponent, pos: Vec3) =
    let 
        cpos = c.transform.globalPosition
        distance = max(1, min(255, distanceSq(cpos, pos)))
        angle = abs(radToDeg(angle(cpos, pos)))
    discard setPosition(c.channel, angle.int16, distance.uint8)


# System implementation
proc newSoundSystem*(): SoundSystem = 
    new(result)
    result.name = "Sound"


method init*(sys: SoundSystem) = 
    var 
        audio_rate: cint
        audio_format: uint16
        audio_buffers: cint = 4096
        audio_channels: cint = 2

    if openAudio(audio_rate, audio_format, audio_channels, audio_buffers) != 0:
        raise newAlasgarError("Could not open audio!")

method process*(sys: SoundSystem, scene: Scene, input: Input, delta: float32, frames: int, age: float32) = 
    let 
        activeCamera = scene.activeCamera 
        pos = activeCamera.transform.globalPosition
    for c in iterate[SoundEffectComponent](scene):
        if isPlaying(c):
            adjustBy(c, pos)

method cleanup*(sys: SoundSystem) = 
    {.warning[LockLevel]:off.}
    for music in values(musicCache):
        freeMusic(music)
    clear(musicCache)

    for chunk in values(chunkCache):
        freeChunk(chunk)
    clear(chunkCache)

    mixer.closeAudio()


