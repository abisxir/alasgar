import ../../utils

type
    CatMull* = object
        steps: int
        points: seq[Vec3]
        nodes: seq[(Vec3, float32)]

func newCatMull*(steps: int): CatMull =
    result.steps = steps
  
func interpolate(P0, P1, P2, P3: Vec3, u: float32): Vec3 =
    result = 0.5 * u * u * u * ((-1) * P0 + 3 * P1 - 3 * P2 + P3)
    result += u * u * (2 * P0 - 5 * P1 + 4 * P2 - P3) / 2
    result += u * ((-1) * P0 + P2) / 2
    result += P1

func addNode(c: var CatMull, n: Vec3) =
    var distance = 0'f32
    if len(c.nodes) > 0:
        let last = c.nodes[high(c.nodes)]
        let segmentDistance = length(n - last[0])
        distance = segmentDistance + last[1]
    add(c.nodes, (n, distance))

func node*(c: CatMull, i: int): Vec3 = c.nodes[i][0]
func length*(c: CatMull, i: int): float32 = c.nodes[i][1]
func size*(c: CatMull): int = len(c.nodes)
func `pointsCount`*(c: CatMull): int = len(c.points)
func `nodesCount`*(c: CatMull): int = len(c.nodes)
func `first`*(c: CatMull): Vec3 = c.nodes[low(c.nodes)][0]
func `last`*(c: CatMull): Vec3 = c.nodes[high(c.nodes)][0]

iterator `nodes`*(c: CatMull): Vec3 =
    for n in c.nodes:
        yield n[0]

iterator `pairs`*(c: CatMull): (int, Vec3) =
    var i = 0
    for n in c.nodes:
        yield (i, n[0])
        inc(i)

func push*(c: var CatMull, p: Vec3) = 
    c.points.add(p)
    if len(c.points) > 3:
        let pt = len(c.points) - 3
        for i in 0..c.steps:
            let u = float32(i) / float32(c.steps)
            let node = interpolate(c.points[pt - 1], c.points[pt], c.points[pt + 1], c.points[pt + 2], u)
            addNode(c, node)

func reset*(c: var CatMull) =
    var points = c.points
    clear(c.points)
    clear(c.nodes)
    for p in points:
        push(c, p)

func clear*(c: var CatMull) =
    clear(c.points)
    clear(c.nodes)

func replace*(c: var CatMull, i: int, p: Vec3) =
    c.points[i] = p
    reset(c)

func length*(c: CatMull): float32 = 
    if len(c.nodes) > 0:
        length(c, high(c.nodes))
    else:
        0'f32

func hasNode*(c: CatMull, i: int): bool = len(c.nodes) - 1 >= i
