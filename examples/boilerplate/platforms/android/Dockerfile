FROM debian:bookworm-slim

ARG ANDROID_CMDLINE_TOOLS=11076708
ARG ANDROID_PLATFORM=36
ARG ANDROID_BUILD_TOOLS=36.0.0
ARG ANDROID_NDK=29.0.14206865
ARG GRADLE_VERSION=8.10.2

ENV DEBIAN_FRONTEND=noninteractive
ENV ANDROID_HOME=/opt/android-sdk
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_NDK_HOME=/opt/android-sdk/ndk/${ANDROID_NDK}
ENV GRADLE_HOME=/opt/gradle-${GRADLE_VERSION}
ENV PATH=/root/.nimble/bin:${GRADLE_HOME}/bin:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    clang \
    curl \
    gcc \
    git \
    openjdk-17-jdk-headless \
    python3 \
    unzip \
    xz-utils \
  && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -o /tmp/gradle.zip \
  && unzip -q /tmp/gradle.zip -d /opt \
  && rm /tmp/gradle.zip

RUN curl -fsSL https://nim-lang.org/choosenim/init.sh -o /tmp/choosenim.sh \
  && sh /tmp/choosenim.sh -y \
  && nimble refresh \
  && nimble install -y sokol@0.6.0

RUN mkdir -p ${ANDROID_HOME}/cmdline-tools \
  && curl -fsSL https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS}_latest.zip -o /tmp/cmdline-tools.zip \
  && unzip -q /tmp/cmdline-tools.zip -d /tmp/android-cmdline-tools \
  && mv /tmp/android-cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest \
  && yes | sdkmanager --licenses >/dev/null \
  && sdkmanager \
    "platform-tools" \
    "platforms;android-${ANDROID_PLATFORM}" \
    "build-tools;${ANDROID_BUILD_TOOLS}" \
    "ndk;${ANDROID_NDK}"

WORKDIR /app
CMD ["scripts/android_native_build.sh"]
