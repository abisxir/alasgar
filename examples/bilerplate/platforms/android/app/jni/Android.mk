LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := main_static
LOCAL_SRC_FILES := main/$(TARGET_ARCH_ABI)/libmain_static.a
include $(PREBUILT_STATIC_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE := main
LOCAL_C_INCLUDES := $(NIM_INCLUDE_DIR) $(LOCAL_PATH)/../../vendor/sokol/sokol/c
LOCAL_SRC_FILES := android_entry.c
LOCAL_WHOLE_STATIC_LIBRARIES := main_static
LOCAL_LDLIBS := -lGLESv3 -lEGL -llog -landroid -lc
LOCAL_CFLAGS := -DGL_GLEXT_PROTOTYPES
include $(BUILD_SHARED_LIBRARY)
