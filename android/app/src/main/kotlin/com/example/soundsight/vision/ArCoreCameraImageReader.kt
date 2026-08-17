package com.example.soundsight.vision

import android.media.Image
import com.google.ar.core.Frame
import com.google.ar.core.exceptions.DeadlineExceededException
import com.google.ar.core.exceptions.NotYetAvailableException
import com.google.ar.core.exceptions.ResourceExhaustedException

// Acquires the CPU-readable image belonging to the current ARCore frame.
// The grayscale pixels are copied before the original Android image is closed.
class ArCoreCameraImageReader {

    fun readCameraImage(frame: Frame): CameraImageData? {
        var cameraImage: Image? = null

        try {
            cameraImage = frame.acquireCameraImage()

            return copyGrayscalePixels(cameraImage)
        } catch (exception: NotYetAvailableException) {
            return null
        } catch (exception: DeadlineExceededException) {
            return null
        } catch (exception: ResourceExhaustedException) {
            return null
        } finally {
            cameraImage?.close()
        }
    }

    // Copies the brightness plane from Android's YUV camera image into a
    // continuous array that remains usable after the original image is closed.
    private fun copyGrayscalePixels(
        cameraImage: Image
    ): CameraImageData? {
        val imageWidth = cameraImage.width
        val imageHeight = cameraImage.height

        if (imageWidth <= 0 || imageHeight <= 0) {
            return null
        }

        val imagePlanes = cameraImage.planes

        if (imagePlanes.isEmpty()) {
            return null
        }

        val brightnessPlane = imagePlanes[0]
        val brightnessBuffer = brightnessPlane.buffer
        val rowStride = brightnessPlane.rowStride
        val pixelStride = brightnessPlane.pixelStride

        val copiedPixels =
            ByteArray(imageWidth * imageHeight)

        var copiedPixelIndex = 0
        val bufferStart = brightnessBuffer.position()
        val bufferLimit = brightnessBuffer.limit()

        for (row in 0 until imageHeight) {
            val rowStart = bufferStart + (row * rowStride)

            for (column in 0 until imageWidth) {
                val bufferIndex =
                    rowStart + (column * pixelStride)

                if (bufferIndex >= bufferLimit) {
                    return null
                }

                copiedPixels[copiedPixelIndex] =
                    brightnessBuffer.get(bufferIndex)

                copiedPixelIndex++
            }
        }

        return CameraImageData(
            width = imageWidth,
            height = imageHeight,
            timestamp = cameraImage.timestamp,
            grayscalePixels = copiedPixels
        )
    }
}