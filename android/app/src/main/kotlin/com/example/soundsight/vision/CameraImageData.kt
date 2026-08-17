package com.example.soundsight.vision

// Stores one camera image copied from an ARCore frame.
// Only grayscale pixels are stored because keyboard detection mainly needs
// brightness differences, edges, and black-key shapes.
class CameraImageData(
    val width: Int,
    val height: Int,
    val timestamp: Long,
    val grayscalePixels: ByteArray
)