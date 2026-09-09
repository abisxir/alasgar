# PRNG
# A dead simple shiftxor32 implementation
import math

type
  Rng* = object
    state: uint32

proc initRng*(seed: uint32): Rng =
  # xorshift32 must not have an all-zero state.
  Rng(state: if seed == 0: 0x6D2B79F5'u32 else: seed)

proc randi(rng: var Rng): uint32 =
  var x = rng.state
  x = x xor (x shl 13)
  x = x xor (x shr 17)
  x = x xor (x shl 5)
  rng.state = x
  x

proc randf*(rng: var Rng): float32 = float32(randi(rng)) / float32(0xFFFFFFFF'u32)
proc range*[T:SomeInteger](rng: var Rng, lo, hi: T): T = lo + (randi(rng).T mod (hi - lo + 1))
proc range*[T:SomeFloat](rng: var Rng, lo, hi: T): T = lo + (hi - lo) * randf(rng)
proc select*[T](rng: var Rng, ar: openArray[T]): T = ar[range(rng, ar.low, ar.high)]
