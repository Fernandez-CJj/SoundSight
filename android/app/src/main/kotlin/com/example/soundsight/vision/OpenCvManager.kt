package com.example.soundsight.vision

import org.opencv.android.OpenCVLoader

// Keeps track of whether the OpenCV native library is ready.
// Camera-image processing must not begin until this value becomes true.
class OpenCvManager {
    private var openCvLoaded = false

    // Attempts to load the native OpenCV library before image processing begins.
    // The stored result prevents OpenCV tools from being used if loading fails.
    fun loadOpenCv(): Boolean {
        if (openCvLoaded) {
            return true
        }

        openCvLoaded = OpenCVLoader.initLocal()

        return openCvLoaded
    }

    // Allows other native classes to check whether OpenCV can safely be used.
    fun isOpenCvLoaded(): Boolean {
        return openCvLoaded
    }
}