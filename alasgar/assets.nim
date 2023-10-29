import streams
import strutils
import logger
import strformat
import os

#import error

export streams

when defined(android):
    import ports/sdl2
    import jnim
    import android/ndk/aasset_manager
    import android/app/activity
    import android/content/res/asset_manager
    import android/content/context


proc normalize(url: string): string =
    when defined(android):
        result = url.replace("res://", "")
    else:
        result = url.replace("res://", "res/").replace("/", &"{DirSep}")
    result = replace(result, "%20", " ")

proc openAssetStream*(url: string): Stream =
    let filename = normalize(url)
    when defined(android):
        logi &"Loading [{filename}] for android ..."
        theEnv = cast[JNIEnvPtr](androidGetJNIEnv())
        let am = currentActivity().getApplication().getAssets().getNative()
        result = am.streamForReading(filename)
        if result == nil:
            logi &"Could not open [{filename}]."
            raise newAlasgarError(&"Could not open [{filename}].")
        else:
            logi &"File [{filename}] opened."
        logi &"Loading [{filename}] for windows ..."        
    else:
        logi &"Loading [{filename}] ..."
        result = newFileStream(filename, fmRead)

proc readAsset*(url: string): string =
    let stream = openAssetStream(url)
    defer: close(stream)
    result = readAll(stream)

proc exists*(url: string): bool =
    when defined(android):
        let stream = openAssetStream(url)
        result = stream != nil
        if result:
            close(stream)
    else:
        let filename = normalize(url)
        result = fileExists(filename)

