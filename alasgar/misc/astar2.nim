import heapq, math

type
  Node = object
    x: int
    y: int
    f: float
    g: float
    h: float
    parent: Node

# define a comparison operator for nodes
proc `<`(a, b: Node): bool =
  a.f < b.f

# define a comparison operator for nodes
proc `>`(a, b: Node): bool =
  a.f > b.f

# define a function to calculate the heuristic cost
# between two points
proc heuristic(x1, y1, x2, y2: int): float =
  math.sqrt(abs(x1 - x2) ** 2 + abs(y1 - y2) ** 2)

# define a function to get the neighbors of a given node
proc neighbors(grid: seq[seq[int]], node: Node): seq[Node] =
  # define a list of offsets for the eight directions
  # a node can move in
  var offsets = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]
  # create a list to store the neighbors
  var neighbors = newSeq[Node]()

  # loop through the offsets
  for offset in offsets:
    # calculate the new x and y coordinates
    x = node.x + offset[0]
    y = node.y + offset[1]

    # skip the neighbor if it is out of bounds
    if x < 0 or x >= len(grid) or y < 0 or y >= len(grid[0]):
      continue

    # skip the neighbor if it is not traversable
    if grid[x][y] == 1:
      continue

    # create a new node for the neighbor and add it to the list
    var neighbor = Node(x: x, y: y, f: 0, g: 0, h: 0, parent: node)
    neighbors.add(neighbor)

  # return the list of neighbors
  return neighbors

# define the A* search function
proc astar(grid: seq[seq[int]], start, goal: tuple[int, int]): Node =
  # create a priority queue for storing the nodes to visit
  var pq = newHeap[Node]()

  # create a set for storing the visited nodes
  var visited = set[tuple[int, int]]()

  # create the starting node and add it to the queue
  var startNode = Node(x: start[0], y: start[1], f: 0, g: 0, h: heuristic(start[0], start[1], goal[0], goal[1]), parent: nil)
  heapq.heappush(pq, startNode)

  # loop until the queue is empty
  while pq.len > 0:
    # get the node with the lowest f value
    var currentNode = heapq.heappop(pq)

    # check if we have reached the goal
    if currentNode.x == goal[0] and currentNode.y == goal[1]:
      return currentNode

    # mark the node as visited
    visited.add((currentNode.x, currentNode.y))

    # get the neighbors of the current node
    for neighbor in neighbors(grid, currentNode):
      # skip the neighbor if it has already been visited
      if (neighbor.x, neighbor.y) in visited:
        continue

      # calculate the cost to reach the neighbor
      cost = math.sqrt(abs(currentNode.x - neighbor.x) ** 2 + abs(currentNode.y - neighbor.y) ** 2)

      # update the neighbor's g, h, and f values
      neighbor.g = currentNode.g + cost
      neighbor.h = heuristic(neighbor.x, neighbor.y, goal[0], goal[1])
      neighbor.f = neighbor.g + neighbor.h

      # add the neighbor to the queue
      heapq.heappush(pq, neighbor)

# define a function to get the path from the start to the goal
proc getPath(node: Node): seq[tuple[int, int]] =
  # create a list to store the path
  var path = newSeq[tuple[int, int]]()

  # loop through the nodes, starting from the goal and going
  # backwards until we reach the start
  while node.parent != nil:
    path.add((node.x, node.y))
    node = node.parent

  # add the starting node to the path
  path.add((node.x, node.y))

  # reverse the path so that it goes from start to goal
  path.reverse()

  # return the path
  return path


when isMainModule:
  # define a test grid
  var grid = [
    [0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0],
    [0, 0, 0, 1, 0, 0],
    [0, 0, 0, 1, 0, 0],
    [0, 0, 0, 1, 0, 0],
    [0, 0, 0, 0, 0, 0]
  ]
  # find the path from the start to the goal
  var start = (0, 0)
  var goal = (5, 5)
  var path = getPath(astar(grid, start, goal))

  # print the path
  echo path
