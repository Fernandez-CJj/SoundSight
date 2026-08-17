package com.example.soundsight.vision

// Stores the position, dimensions, and detected contour area of one dark
// shape that may be a black piano key in the straightened keyboard image.
class BlackKeyCandidate(
    val left: Int,
    val top: Int,
    val width: Int,
    val height: Int,
    val contourArea: Double
) {
    // Converts this possible black-key shape into simple numbers that can be
    // transferred through Flutter's platform channel.
    fun createFlutterData(): Map<String, Any> {
        val blackKeyData = HashMap<String, Any>()

        blackKeyData["left"] = left
        blackKeyData["top"] = top
        blackKeyData["width"] = width
        blackKeyData["height"] = height
        blackKeyData["contourArea"] = contourArea

        return blackKeyData
    }
}