import ../utils

proc isPointInsideBox*(point, aabbMin, aabbMax: Vec3): bool =
    result = (point.x >= aabbMin.x and point.x <= aabbMax.x) and
             (point.y >= aabbMin.y and point.y <= aabbMax.y) and
             (point.z >= aabbMin.z and point.z <= aabbMax.z)

proc isPointInsideSphere*(point: Vec3, center: Vec3, radius: float32): bool =
    result = length(point - center) < radius


proc isBoxIntersectsBox*(aMin, aMax, bMin, bMax: Vec3): bool =
    result = (aMin.x <= bMax.x and aMax.x >= bMin.x) and
             (aMin.y <= bMax.y and aMax.y >= bMin.y) and
             (aMin.z <= bMax.z and aMax.z >= bMin.z) 

proc isSphereIntersectsSphere*(ca: Vec3, ra: float32, cb: Vec3, rb: float32): bool =
    result = length(cb - ca) < ra + rb

proc isSphereIntersectsBox*(center: Vec3, radius: float32, vmin, vmax: Vec3): bool =
    var x = max(vmin.x, min(center.x, vmax.x))
    var y = max(vmin.y, min(center.y, vmax.y))
    var z = max(vmin.z, min(center.z, vmax.z))

    return length(vec3(x, y, z) - center) < radius

proc isTriangleIntersectsBox*(p1, p2, p3: Vec3, vmin, vmax: Vec3): bool =
    if min(max(p1.x, p2.x), p3.x) > vmax.x: return false
    if max(max(p1.x, p2.x), p3.x) < vmin.x: return false

    if min(max(p1.y, p2.y), p3.y) > vmax.y: return false
    if max(max(p1.y, p2.y), p3.y) < vmin.y: return false

    if min(max(p1.z, p2.z), p3.z) > vmax.z: return false
    if max(max(p1.z, p2.z), p3.z) < vmin.z: return false

    if min(min(p1.z, p2.z), p3.z) > vmax.z: return false
    if max(max(p1.z, p2.z), p3.z) < vmin.z: return false

    if min(min(p1.y, p2.y), p3.y) > vmax.y: return false
    if max(max(p1.y, p2.y), p3.y) < vmin.y: return false
    
    return true

proc isRayIntersectsBox*(rayOrigin, rayNormalizedDirection: Vec3, rayLength: float32, vmin, vmax: Vec3, outIntersectionPoint: ptr Vec3): bool = 
    let t1 = (vmin.x - rayOrigin.x) / rayNormalizedDirection.x
    let t2 = (vmax.x - rayOrigin.x) / rayNormalizedDirection.x
    let t3 = (vmin.y - rayOrigin.y) / rayNormalizedDirection.y
    let t4 = (vmax.y - rayOrigin.y) / rayNormalizedDirection.y
    let t5 = (vmin.z - rayOrigin.z) / rayNormalizedDirection.z
    let t6 = (vmax.z - rayOrigin.z) / rayNormalizedDirection.z
    let t7 = max(max(min(t1, t2), min(t3, t4)), min(t5, t6))
    let t8 = min(min(max(t1, t2), max(t3, t4)), max(t5, t6))
    result = not(t8 < 0 or t7 > t8) and t7 > 0 and t7 <= rayLength
    if result:
        outIntersectionPoint[] = rayOrigin + (rayNormalizedDirection * t7)

proc isRayIntersectsBox*(rayOrigin, 
                         rayNormalizedDirection, 
                         rayInvertedNormalizedDirection: Vec3, 
                         rayLength: float32, 
                         vMin, 
                         vMax: Vec3, 
                         outIntersectionPoint: ptr Vec3): bool =
    let tx1 = (vMin.x - rayOrigin.x) * rayInvertedNormalizedDirection.x
    let tx2 = (vMax.x - rayOrigin.x) * rayInvertedNormalizedDirection.x

    var tmin = min(tx1, tx2)
    var tmax = max(tx1, tx2)

    let ty1 = (vMin.y - rayOrigin.y) * rayInvertedNormalizedDirection.y
    let ty2 = (vMax.y - rayOrigin.y) * rayInvertedNormalizedDirection.y

    tmin = max(tmin, min(ty1, ty2))
    tmax = min(tmax, max(ty1, ty2))

    let tz1 = (vMin.z - rayOrigin.z) * rayInvertedNormalizedDirection.z
    let tz2 = (vMax.z - rayOrigin.z) * rayInvertedNormalizedDirection.z

    tmin = max(tmin, min(tz1, tz2))
    tmax = min(tmax, max(tz1, tz2))

    result = tmax >= max(0.0, tmin) and tmin < rayLength
    if result:
        outIntersectionPoint[] = rayOrigin + rayNormalizedDirection * tmin



proc isRayIntersectsSphere*(rayOrigin, 
                            rayNormalizedDirection: Vec3, 
                            rayLength: float32,
                            sphereCenter: Vec3, 
                            sphereRadius: float32, 
                            outIntersectionPoint1, 
                            outIntersectionPoint2: ptr Vec3): bool =
    result = false
    var t = dot(sphereCenter - rayOrigin, rayNormalizedDirection)
    var p = rayOrigin + rayNormalizedDirection * t
    var y = length(sphereCenter - p)
    if y < sphereRadius:
        var x = sqrt(sphereRadius * sphereRadius - y * y)
        var t1 = t - x
        var t2 = t + x
        if t1 > t2:
            swap(t1, t2)
        if rayLength > t1:
            outIntersectionPoint1[] = rayOrigin + (rayNormalizedDirection * t1)
            outIntersectionPoint2[] = rayOrigin + (rayNormalizedDirection * t2)
            result = true


proc isRayIntersectsTriangle*(rayOrigin, rayDirection, vertex0, vertex1, vertex2: Vec3, outIntersectionPoint: ptr Vec3): bool =
    var edge1, edge2, h, s, q: Vec3
    var a, f, u, v: float
    edge1 = vertex1 - vertex0
    edge2 = vertex2 - vertex0
    h = cross(rayDirection, edge2)
    a = dot(edge1, h);
    if a > -EPSILON and a < EPSILON:
        # This ray is parallel to this triangle.
        return false
    f = 1.0/a
    s = rayOrigin - vertex0
    u = f * dot(s, h)
    if u < 0.0 or u > 1.0:
        return false
    q = cross(s, edge1)
    v = f * dot(rayDirection, q)
    if v < 0.0 or u + v > 1.0:
        return false
    
    # At this stage we can compute t to find out where the intersection point is on the line.
    let t = f * dot(edge2, q)
    if t > EPSILON:
        outIntersectionPoint[] = rayOrigin + (rayDirection * t)
        return true
    else: 
        # This means that there is a line intersection but not a ray intersection.
        return false

