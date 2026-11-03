#include "sokol_app.h"
#include <android/log.h>

#define LOG_TAG "boiler-plate"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)

extern void NimMain(void);
extern sapp_desc alasgar_app_desc(void);

int cmdCount = 0;
char** cmdLine = 0;

static void (*nim_init_cb)(void) = 0;
static void (*nim_frame_cb)(void) = 0;
static void (*nim_cleanup_cb)(void) = 0;
static void (*nim_event_cb)(const sapp_event*) = 0;
static int frame_count = 0;

static void log_init_cb(void) {
    LOGI("init_cb: enter");
    if (nim_init_cb) {
        nim_init_cb();
    }
    LOGI("init_cb: leave");
}

static void log_frame_cb(void) {
    if (frame_count < 5) {
        LOGI("frame_cb: frame=%d size=%dx%d", frame_count, sapp_width(), sapp_height());
    }
    frame_count++;
    if (nim_frame_cb) {
        nim_frame_cb();
    }
}

static void log_cleanup_cb(void) {
    LOGI("cleanup_cb: enter");
    if (nim_cleanup_cb) {
        nim_cleanup_cb();
    }
    LOGI("cleanup_cb: leave");
}

static void log_event_cb(const sapp_event* event) {
    if (event) {
        LOGI(
            "event_cb: type=%d window=%dx%d framebuffer=%dx%d",
            event->type,
            event->window_width,
            event->window_height,
            event->framebuffer_width,
            event->framebuffer_height
        );
    }
    if (nim_event_cb) {
        nim_event_cb(event);
    }
}

sapp_desc sokol_main(int argc, char* argv[]) {
    LOGI("sokol_main: argc=%d", argc);
    cmdCount = argc;
    cmdLine = argv;
    LOGI("NimMain: enter");
    NimMain();
    LOGI("NimMain: leave");
    sapp_desc desc = alasgar_app_desc();
    nim_init_cb = desc.init_cb;
    nim_frame_cb = desc.frame_cb;
    nim_cleanup_cb = desc.cleanup_cb;
    nim_event_cb = desc.event_cb;
    desc.init_cb = log_init_cb;
    desc.frame_cb = log_frame_cb;
    desc.cleanup_cb = log_cleanup_cb;
    desc.event_cb = log_event_cb;
    LOGI(
        "sokol_main: desc width=%d height=%d sample_count=%d swap_interval=%d gl=%d.%d callbacks=%p/%p/%p/%p title=%s",
        desc.width,
        desc.height,
        desc.sample_count,
        desc.swap_interval,
        desc.gl_major_version,
        desc.gl_minor_version,
        nim_init_cb,
        nim_frame_cb,
        nim_cleanup_cb,
        nim_event_cb,
        desc.window_title ? desc.window_title : ""
    );
    return desc;
}
