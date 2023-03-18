import sets
import tables
import algorithm

const moveCost = 1

func calcHeuristic(pos, goal: (int, int)): int = abs(pos[0] - goal[0]) + abs(pos[1] - goal[1])
func calcTotalCost(gCost, hCost: int): int = gCost + hCost
func isValidSquare(grid: openArray[int], rows, columns: int, pos: (int, int)): bool = 
    let cell = pos[0] * columns + pos[1]
    result = pos[0] >= 0 and pos[0] < rows and pos[1] >= 0 and pos[1] < columns and cell < len(grid) and grid[cell] == 0

proc findNeighbors(grid: openArray[int], rows, columns: int, pos: (int, int)): seq[(int, int)] =
    var (x, y) = pos
    var neighbors = [(x+1, y), (x, y+1), (x-1, y), (x, y-1)]
    for n in neighbors:
        if isValidSquare(grid, rows, columns, n):
            add(result, n)

proc findMinCost(s: HashSet[(int, int)]): (int, int) =
    var 
        minCost = int.high

    for e in items(s):
        let totalCost = calcTotalCost(e[0], e[1])
        if totalCost < minCost:
            result = e
            minCost = totalCost
        

proc findPath*(grid: openArray[int], rows, columns: int, start, goal: (int, int)): seq[(int, int)] =
    var 
        openSet = initHashSet[(int, int)]()
        closedSet = initHashSet[(int, int)]()
        costs = newTable[(int, int), (int, int)]()
        parents = newTable[(int, int), (int, int)]()

    openSet.incl(start)
    costs[start] = (0, calcHeuristic(start, goal))
    parents[start] = (-1, -1)

    # keep looping until the open set is empty or the end square is found
    while openSet.len > 0:
        # find the square in the open set with the lowest total cost
        var current = findMinCost(openSet)
        # check if the current square is the end square
        if current == goal:
            while current[0] >= 0:
                add(result, current)
                current = parents[current]
            reverse(result)
            break
        else:
            openSet.excl(current)
            closedSet.incl(current)

            for neighbor in findNeighbors(grid, rows, columns, current):
                # if the neighbor is already in the closed set, skip it
                if not (neighbor in closedSet):
                    # calculate the g-cost and h-cost of the neighbor
                    let 
                        gCost = costs[current][0] + moveCost
                        hCost = calcHeuristic(neighbor, goal)
                        cost = calcTotalCost(gCost, hCost)

                    # if the neighbor is not in the open set, or if the current path to the neighbor is cheaper than any previous path:
                    if not(neighbor in openSet) or (cost < costs[neighbor][0]):
                            # update the g-cost, h-cost, and parent of the neighbor
                            costs[neighbor] = (gCost, hCost)
                            parents[neighbor] = current

                            # add the neighbor to the open set
                            openSet.incl(neighbor)

when isMainModule:
    const grid = [
        0, 0, 1, 0, 0, 0, 1,
        0, 0, 0, 0, 0, 1, 0,
        0, 0, 1, 0, 1, 0, 0,
        1, 0, 0, 0, 1, 0, 0,
    ]
    let r = findPath(grid, 4, 7, (0, 0), (3, 6))
    echo(r)
