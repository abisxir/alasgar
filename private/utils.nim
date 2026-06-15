import logger

export logger

# General funcs
proc halt*(message: string) =
  logi message
  quit message
