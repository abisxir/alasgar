import math

proc linear*(t, b, c, d: float32): float32 =
  return c * t / d + b

proc inQuad*(t, b, c, d: float32): float32 =
  let t_hat = t / d
  return c * t_hat * t_hat + b

proc outQuad*(t, b, c, d: float32): float32 =
  let t_hat = t / d
  return -c * t_hat * (t_hat - 2) + b

proc inOutQuad*(t, b, c, d: float32): float32 =
  let t_hat = t / (d / 2)
  if t_hat < 1:
    return c / 2 * t_hat * t_hat + b
  else:
    return -c / 2 * ((t_hat - 1) * (t_hat - 3) - 1) + b

proc inCubic* (t, b, c, d: float32): float32 =
  let t_hat = t / d
  return c * pow(t_hat, 3) + b

proc outCubic*(t, b, c, d: float32): float32 =
  let t_hat = t / d - 1
  return c * (pow(t_hat, 3) + 1) + b

proc inOutCubic*(t, b, c, d: float32): float32 =
  let t_hat = t / d * 2
  if t_hat < 1:
    return c / 2 * t_hat * t_hat * t_hat + b
  else:
    let t_hat = t_hat - 2
    return c / 2 * (t_hat * t_hat * t_hat + 2) + b

proc inQuart*(t, b, c, d: float32): float32 =
  return c * pow(t / d, 4) + b

proc outQuart*(t, b, c, d: float32): float32 =
  return -c * (pow(t / d - 1, 4) - 1) + b

proc inOutQuart*(t, b, c, d: float32): float32 =
  let t_hat = t / (d / 2)
  if t_hat < 1:
    return c/2 * pow(t_hat, 4) + b
  else:
    return -c/2 * (pow(t_hat-2, 4) - 2) + b

proc inQuint*(t, b, c, d: float32): float32 =
  return c * pow(t / d, 5) + b

proc outQuint*(t, b, c, d: float32): float32 =
  return c * (pow(t / d - 1, 5) + 1) + b

proc inOutQuint*(t, b, c, d: float32): float32 =
  let t_hat = t / (d / 2)
  if t_hat < 1:
    return c / 2 * pow(t_hat, 5) + b
  else:
    return c / 2 * (pow(t_hat - 2, 5) + 2) + b

proc inSine*(t, b, c, d: float32): float32 =
  return -c * cos(t / d * (PI / 2)) + c + b

proc outSine*(t, b, c, d: float32): float32 =
  return c * sin(t / d * (PI / 2)) + b

proc inOutSine*(t, b, c, d: float32): float32 =
  return -c / 2 * (cos(PI * t / d) - 1) + b

proc inExpo*(t, b, c, d: float32): float32 =
  if t == 0:
    return b
  else:
    return c * pow(2, 10 * (t / d - 1)) + b - c * 0.001

proc outExpo*(t, b, c, d: float32): float32 =
  if t == d:
    return b + c
  else:
    return c * 1.001 * (-pow(2, -10 * t / d) + 1) + b

proc inOutExpo*(t, b, c, d: float32): float32 =
  if t < d / 2:
    return inExpo((t * 2) - d, b + c / 2, c / 2, d)
  else:
    return outExpo(t * 2, b, c / 2, d)

proc inCirc*(t, b, c, d: float32): float32 =
  let t_hat = t / d
  return(-c * (sqrt(1 - pow(t_hat, 2)) - 1) + b)

proc outCirc*(t, b, c, d: float32): float32 =
  let t_hat = t / d - 1
  return(c * sqrt(1 - pow(t_hat, 2)) + b)

proc inOutCirc*(t, b, c, d: float32): float32 =
  let t_hat = t / d * 2
  if t_hat < 1:
    return -c / 2 * (sqrt(1 - t_hat * t_hat) - 1) + b
  else:
    let t_hat = t_hat - 2
    return c / 2 * (sqrt(1 - t_hat * t_hat) + 1) + b

proc cubicBezier*(t, P0, P1, P2, P3: float32): float32 =
    result = pow((1-t), 3) * P0 + 3 * t * (1 - t) * (1 - t) * P1 + 3 * t * t * (1 - t) * P2 + t * t * t * P3 
