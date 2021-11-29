import streams
import strutils
import logger
import strformat

export streams

when defined(android):
    import sdl2
    import jnim
    import android/ndk/aasset_manager
    import android/app/activity
    import android/content/res/asset_manager
    import android/content/context

proc openAssetStream*(url: string): Stream =
    var filename: string
    when defined(android):
        filename = url.replace("res://", "")
        logi &"Loading [{filename}] for android ..."
        theEnv = cast[JNIEnvPtr](androidGetJNIEnv())
        let am = currentActivity().getApplication().getAssets().getNative()
        result = am.streamForReading(filename)
        if result == nil:
            logi &"Could not open [{filename}]."
        else:
            logi &"File [{filename}] opened."
    else:
        filename = url.replace("res://", "res/")
        logi &"Loading [{filename}] for linux ..."
        result = newFileStream(filename, fmRead)