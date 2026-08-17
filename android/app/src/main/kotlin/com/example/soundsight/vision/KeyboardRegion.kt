package com.example.soundsight.vision

// Stores one position inside the camera image.
// The x value moves left to right, while y moves top to bottom.
class ImagePoint(
    val x: Double,
    val y: Double
) {
    // Converts this custom Kotlin point into simple values that Flutter's
    // platform channel can understand.
    fun createFlutterData(): Map<String, Double> {
        val pointData = HashMap<String, Double>()

        pointData["x"] = x
        pointData["y"] = y

        return pointData
    }
}

// Stores the four detected corners of the keyboard in one camera image.
// Four corners are required because a keyboard viewed from an angle may appear
// as a trapezoid instead of a straight rectangle.
class KeyboardRegion(
    val topLeft: ImagePoint,
    val topRight: ImagePoint,
    val bottomRight: ImagePoint,
    val bottomLeft: ImagePoint,
    val imageWidth: Int,
    val imageHeight: Int,
    val timestamp: Long,
    val confidence: Double
) {
    // Converts the detected keyboard region into simple nested maps and numbers
    // that can be transferred from Kotlin to Dart.
    fun createFlutterData(): Map<String, Any> {
        val keyboardRegionData = HashMap<String, Any>()

        keyboardRegionData["topLeft"] =
            topLeft.createFlutterData()

        keyboardRegionData["topRight"] =
            topRight.createFlutterData()

        keyboardRegionData["bottomRight"] =
            bottomRight.createFlutterData()

        keyboardRegionData["bottomLeft"] =
            bottomLeft.createFlutterData()

        keyboardRegionData["imageWidth"] = imageWidth
        keyboardRegionData["imageHeight"] = imageHeight
        keyboardRegionData["timestamp"] = timestamp
        keyboardRegionData["confidence"] = confidence

        return keyboardRegionData
    }
}