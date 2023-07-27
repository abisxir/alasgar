import tables
import strutils
import ../utils

type
    ResourceLoadFunc* = proc(url: string): Resource
    ResourceDestroyFunc* = proc(r: Resource)
    ResourceManager = object
        load: ResourceLoadFunc
        destroy: ResourceDestroyFunc

    Resource* {.inheritable.} = ref object 
        url: string
        kind: string

func `url`*(r: Resource): string = r.url
func `kind`*(r: Resource): string = r.kind

var managers = initTable[string, ResourceManager]()
var caches = initTable[string, Resource]()

proc registerResourceManager*(kind: string, load: ResourceLoadFunc, destroy: ResourceDestroyFunc) =
    managers[kind] = ResourceManager(load: load, destroy: destroy)

proc extractKind(url: string): string =
    if startsWith(url, "data:image/") and find(url, "base64") > 0:
        let short = replace(url[0..24], "data:image/", "")
        result = split(short, ";")[0]
    else:
        let words = url.split(".")
        result = words[^1]
    
proc load*(url: string): Resource =
    if not caches.hasKey(url):
        let kind = extractKind(url)
        let loader = managers[kind].load
        let resource = loader(url)
        resource.url = url
        resource.kind = kind
        caches[url] = resource
    result = caches[url]

func shorten(text: string): string = 
    if len(text) > 64: 
        text[0..64] 
    else: 
        text

proc destroy(r: Resource, deleteFromCache: bool) =
    echo &"Destroying resource[{shorten(r.url)}]..."
    let destroy = managers[r.kind].destroy
    if deleteFromCache:
        del(caches, r.url)
    destroy(r)

proc destroy*(r: Resource) = destroy(r, true)
proc cleanupResources*() =
    if len(caches) > 0:
        echo &"Cleaning up [{len(caches)}] resources..."
        for r in values(caches):
            destroy(r, false)
        clear(caches)

