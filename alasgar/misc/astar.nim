import std/heapqueue
import std/options
import std/tables
import std/times

type
    Node = object
        pos: (int, int)
        priority: int

func hash(n: (int, int)): int = (n[0] + 1) * (n[1] + 1)
func `==`(a, b: (int, int)): bool = a[0] == b[0] and a[1] == b[1]
func `+`(a, b: (int, int)): (int, int) = (a[0] + b[0], a[1] + b[1])
func inRange(n: (int, int), width, height: int): bool =
    n[0] >= 0 and n[0] < width and n[1] >= 0 and n[1] < height
func isNotBlocked(maze: openArray[int], width: int, n: (int, int)): bool = maze[n[0] + n[1] * width] == 0
func cost(a, b: (int, int)): int = 1
func heuristic(a, b: (int, int)): int = abs(a[0] - b[0]) + abs(a[1] - b[1])

func `<`(a, b: Node): bool = a.priority < b.priority

let directions = [(0, -1), (0, 1), (-1, 0), (1, 0)]
iterator neighbours(n: (int, int), maze: openArray[int], width, height: int): (int, int) =
    for dir in directions:
        let n = n + dir
        if inRange(n, width, height) and isNotBlocked(maze, width, n):
            yield n

proc findPath*(maze: openArray[int], width, height: int, start: (int, int), goal: (int, int), path: var seq[(int, int)]): bool =
    var 
        frontier: HeapQueue[Node]
        cameFrom: Table[(int, int), Option[(int, int)]]
        costSoFar: Table[(int, int), int]
        current: Node
        
    # Clears the path
    result = false
    setLen(path, 0)
    
    push(frontier, Node(pos: start, priority: 0))
    cameFrom[start] = none((int, int))
    costSoFar[start] = 0

    while not result and len(frontier) > 0:
        current = frontier.pop()
        result = current.pos == goal
        # Checks that whether we reached the goal
        if not result:
            for next in neighbours(current.pos, maze, width, height):
                let newCost = costSoFar[current.pos] + cost(current.pos, next)
                if next notin costSoFar or newCost < costSoFar[next]:
                    costSoFar[next] = newCost
                    let priority = newCost + heuristic(next, goal)
                    push(frontier, Node(pos: next, priority: priority))
                    cameFrom[next] = some(current.pos)
        
    if result:
        var head = current.pos
        insert(path, head, 0)
        while true:
            let p = cameFrom[head]
            if isSome(p):
                head = p.get
                insert(path, head, 0)
            else:
                break

when isMainModule:
    const grid = [
        0, 0, 0, 0, 
        0, 0, 1, 0, 
        0, 1, 1, 0, 
        1, 0, 0, 0, 
    ]
    var 
        start = epochTime()
    for i in 0..<1000000:        
        var path: seq[(int, int)]
        discard findPath(grid, 4, 4, (0, 0), (1, 3), path)
    echo "Elapsed time: ", epochTime() - start, "ms"
