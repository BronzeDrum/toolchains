# Reset the values so they don't accumulate
set(ANDROID_COMPILER_FLAGS )
set(ANDROID_LINKER_FLAGS )

# ARM-specific flags
if(${ANDROID_ARCHITECTURE} STREQUAL "arm")

    # Why do we need this?
    set(ANDROID_COMPILER_FLAGS "${ANDROID_COMPILER_FLAGS} -fPIC")

    # Have consistent FP ABI, use Neon by default
    set(ANDROID_COMPILER_FLAGS "${ANDROID_COMPILER_FLAGS} -mfloat-abi=softfp -mfpu=neon")

    # Fix hardware error in some Cortex A8 implementations
    # (is this still needed or already enabled by default?)
    set(ANDROID_LINKER_FLAGS "${ANDROID_LINKER_FLAGS} -Wl,--fix-cortex-a8")

    if(${ANDROID_ABI} STREQUAL "armeabi-v7a")
        set(ANDROID_COMPILER_FLAGS "${ANDROID_COMPILER_FLAGS} -march=armv7-a")
        set(ANDROID_LINKER_FLAGS "${ANDROID_LINKER_FLAGS} -march=armv7-a")
    else()
        message(FATAL_ERROR "Unsupported Android ARM ABI ${ANDROID_ABI}")
    endif()

# x86-specific flags
elseif(${ANDROID_ARCHITECTURE} STREQUAL "x86")
    # (None)

# Otherwise unsupported
else()
    message(FATAL_ERROR "Unsupported Android ABI ${ANDROID_ABI}")
endif()

# Fix distributed build on GCC 4.6+
# https://android-review.googlesource.com/#/c/47564/
set(ANDROID_LINKER_FLAGS "${ANDROID_LINKER_FLAGS} -no-canonical-prefixes")

# Specify sysroot so the compiler and linker can find stuff
set(ANDROID_COMPILER_FLAGS "${ANDROID_COMPILER_FLAGS} --sysroot=${ANDROID_SYSROOT} -target ${ANDROID_TARGET} -gcc-toolchain ${ANDROID_NDK_ROOT}/toolchains/${ANDROID_GCC_TOOLCHAIN}/prebuilt/linux-x86_64")
set(ANDROID_LINKER_FLAGS "${ANDROID_LINKER_FLAGS} --sysroot=${ANDROID_SYSROOT} -target ${ANDROID_TARGET}")

# Disallow undefined symbols, memory corruption mitigation, etc.
# This is needed to ensure that everything is really linked in, because it
# won't print any info on runtime
set(ANDROID_COMPILER_FLAGS "${ANDROID_COMPILER_FLAGS} -Wa,--noexecstack")
set(CMAKE_SHARED_LINKER_FLAGS "${ANDROID_LINKER_FLAGS} -Wl,--no-undefined -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now")
set(CMAKE_MODULE_LINKER_FLAGS "${ANDROID_LINKER_FLAGS}")

# Set the flags and make sure they don't get overriden
set(CMAKE_C_FLAGS "${ANDROID_COMPILER_FLAGS}" CACHE STRING "C compiler flags")
set(CMAKE_CXX_FLAGS "${ANDROID_COMPILER_FLAGS}" CACHE STRING "CXX compiler flags")
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS}" CACHE STRING "Shared library linker flags")
set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS}" CACHE STRING "Module linker flags")

# Use static LLVM libc++ to have proper C++11 support with std::stoi() etc
set(CMAKE_CXX_CREATE_SHARED_LIBRARY "<CMAKE_CXX_COMPILER> <CMAKE_SHARED_LIBRARY_CXX_FLAGS> <LANGUAGE_COMPILE_FLAGS> <LINK_FLAGS> -L${ANDROID_NDK_ROOT}/sources/cxx-stl/llvm-libc++/libs/${ANDROID_ABI} <CMAKE_SHARED_LIBRARY_CREATE_CXX_FLAGS> <SONAME_FLAG><TARGET_SONAME> -o <TARGET> <OBJECTS> <LINK_LIBRARIES> -lc++_static")
include_directories(SYSTEM
    "${ANDROID_NDK_ROOT}/sources/cxx-stl/llvm-libc++/libcxx/include"
    "${ANDROID_NDK_ROOT}/sources/android/support/include"
    "${ANDROID_NDK_ROOT}/sources/cxx-stl/llvm-libc++abi/libcxxabi/include")
