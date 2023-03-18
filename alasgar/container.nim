import tables
import utils

type
    CachedContainer[T] = ref object
        cache: Table[string, T]
        container: seq[T]

        destroy: proc(t: T)

proc newCachedContainer*[T](destroy: proc(t: T)): CachedContainer[T] =
    new(result)
    result.destroy = destroy

proc remove[T](c: CachedContainer, t: T, removeFromCache: bool) = 
    if not isNil(t):
        if removeFromCache:
            var found = ""
            for key, value in pairs(c.cache):
                if value == t:
                    found = key
            if not isEmptyOrWhitespace(found):
                del(c.cache, found)   
            c.container = filterIt(c.container, it != t)     
        c.destroy(t)

proc remove*[T](c: CachedContainer[T], t: T) = remove[T](c, t, true)

proc clear*[T](c: CachedContainer[T]) = 
    for item in c.container:
        remove(c, item, false)
    clear(c.cache)
    clear(c.container)

proc has*[T](c: CachedContainer[T], key: string): bool = hasKey(c.cache, key)
proc get*[T](c: CachedContainer[T], key: string): T = c.cache[key]
proc add*[T](c: CachedContainer[T], key: string, value: T) = c.cache[key] = value
proc add*[T](c: CachedContainer[T], value: T) = add(c.container, value)
proc len*[T](c: CachedContainer[T]): int = 
    result = len(c.container)
