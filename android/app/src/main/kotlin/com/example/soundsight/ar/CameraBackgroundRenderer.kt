package com.example.soundsight.ar

import android.opengl.GLES11Ext
import android.opengl.GLES20
import android.util.Log
import com.google.ar.core.Coordinates2d
import com.google.ar.core.Frame
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer

// Draws the ARCore camera texture across the OpenGL surface.
// The rectangle, shaders, and texture drawing commands are kept here.
class CameraBackgroundRenderer {
    private val logTag: String =
        "CameraBackgroundRenderer"

    private val vertexShaderCode: String =
        """
        attribute vec4 vertexPosition;
        attribute vec2 textureCoordinate;

        varying vec2 cameraTextureCoordinate;

        void main() {
            gl_Position = vertexPosition;
            cameraTextureCoordinate = textureCoordinate;
        }
        """

    private val fragmentShaderCode: String =
        """
        #extension GL_OES_EGL_image_external : require

        precision mediump float;

        uniform samplerExternalOES cameraTexture;
        varying vec2 cameraTextureCoordinate;

        void main() {
            gl_FragColor = texture2D(
                cameraTexture,
                cameraTextureCoordinate
            );
        }
        """

    private val screenCoordinates: FloatArray =
        floatArrayOf(
            -1.0f, -1.0f,
            1.0f, -1.0f,
            -1.0f, 1.0f,
            1.0f, 1.0f
        )

    private val cameraTextureCoordinates: FloatArray =
        FloatArray(8)

    private val screenCoordinateBuffer: FloatBuffer
    private val cameraTextureCoordinateBuffer: FloatBuffer

    private var shaderProgram: Int = 0
    private var vertexPositionLocation: Int = -1
    private var textureCoordinateLocation: Int = -1
    private var cameraTextureLocation: Int = -1

    init {
        val screenCoordinateByteCount =
            screenCoordinates.size * 4

        val screenCoordinateByteBuffer =
            ByteBuffer.allocateDirect(screenCoordinateByteCount)

        screenCoordinateByteBuffer.order(
            ByteOrder.nativeOrder()
        )

        screenCoordinateBuffer =
            screenCoordinateByteBuffer.asFloatBuffer()

        screenCoordinateBuffer.put(
            screenCoordinates
        )

        screenCoordinateBuffer.position(0)

        val textureCoordinateByteCount =
            cameraTextureCoordinates.size * 4

        val textureCoordinateByteBuffer =
            ByteBuffer.allocateDirect(textureCoordinateByteCount)

        textureCoordinateByteBuffer.order(
            ByteOrder.nativeOrder()
        )

        cameraTextureCoordinateBuffer =
            textureCoordinateByteBuffer.asFloatBuffer()

        cameraTextureCoordinateBuffer.put(
            cameraTextureCoordinates
        )

        cameraTextureCoordinateBuffer.position(0)
    }

    // Compiles and links the shaders used to draw the camera texture.
    // Returns false when the GPU cannot prepare the drawing program.
    fun createOnGlThread(): Boolean {
        val vertexShaderId =
            compileShader(
                GLES20.GL_VERTEX_SHADER,
                vertexShaderCode
            )

        if (vertexShaderId == 0) {
            return false
        }

        val fragmentShaderId =
            compileShader(
                GLES20.GL_FRAGMENT_SHADER,
                fragmentShaderCode
            )

        if (fragmentShaderId == 0) {
            GLES20.glDeleteShader(vertexShaderId)
            return false
        }

        val newShaderProgram =
            GLES20.glCreateProgram()

        if (newShaderProgram == 0) {
            GLES20.glDeleteShader(vertexShaderId)
            GLES20.glDeleteShader(fragmentShaderId)

            Log.e(
                logTag,
                "OpenGL could not create the shader program."
            )

            return false
        }

        GLES20.glAttachShader(
            newShaderProgram,
            vertexShaderId
        )

        GLES20.glAttachShader(
            newShaderProgram,
            fragmentShaderId
        )

        GLES20.glLinkProgram(newShaderProgram)

        val linkStatus = IntArray(1)

        GLES20.glGetProgramiv(
            newShaderProgram,
            GLES20.GL_LINK_STATUS,
            linkStatus,
            0
        )

        GLES20.glDeleteShader(vertexShaderId)
        GLES20.glDeleteShader(fragmentShaderId)

        if (linkStatus[0] == 0) {
            val errorMessage =
                GLES20.glGetProgramInfoLog(newShaderProgram)

            Log.e(
                logTag,
                "Shader program linking failed: $errorMessage"
            )

            GLES20.glDeleteProgram(newShaderProgram)

            return false
        }

        shaderProgram = newShaderProgram

        vertexPositionLocation =
            GLES20.glGetAttribLocation(
                shaderProgram,
                "vertexPosition"
            )

        textureCoordinateLocation =
            GLES20.glGetAttribLocation(
                shaderProgram,
                "textureCoordinate"
            )

        cameraTextureLocation =
            GLES20.glGetUniformLocation(
                shaderProgram,
                "cameraTexture"
            )

        if (
            vertexPositionLocation < 0 ||
            textureCoordinateLocation < 0 ||
            cameraTextureLocation < 0
        ) {
            Log.e(
                logTag,
                "OpenGL could not find the shader variables."
            )

            GLES20.glDeleteProgram(shaderProgram)
            shaderProgram = 0

            return false
        }

        return true
    }

    // Converts the screen corners into camera-texture positions.
    // ARCore performs the conversion so camera cropping stays correct.
    fun updateCameraTextureCoordinates(frame: Frame) {
        screenCoordinateBuffer.position(0)
        cameraTextureCoordinateBuffer.position(0)

        frame.transformCoordinates2d(
            Coordinates2d.OPENGL_NORMALIZED_DEVICE_COORDINATES,
            screenCoordinateBuffer,
            Coordinates2d.TEXTURE_NORMALIZED,
            cameraTextureCoordinateBuffer
        )

        cameraTextureCoordinateBuffer.position(0)
    }

    // Draws the latest ARCore camera texture over the full-screen rectangle.
    fun draw(cameraTextureId: Int) {
        if (shaderProgram == 0 || cameraTextureId < 0) {
            return
        }

        GLES20.glDisable(GLES20.GL_DEPTH_TEST)
        GLES20.glDepthMask(false)

        GLES20.glUseProgram(shaderProgram)

        screenCoordinateBuffer.position(0)

        GLES20.glEnableVertexAttribArray(
            vertexPositionLocation
        )

        GLES20.glVertexAttribPointer(
            vertexPositionLocation,
            2,
            GLES20.GL_FLOAT,
            false,
            0,
            screenCoordinateBuffer
        )

        cameraTextureCoordinateBuffer.position(0)

        GLES20.glEnableVertexAttribArray(
            textureCoordinateLocation
        )

        GLES20.glVertexAttribPointer(
            textureCoordinateLocation,
            2,
            GLES20.GL_FLOAT,
            false,
            0,
            cameraTextureCoordinateBuffer
        )

        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)

        GLES20.glBindTexture(
            GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
            cameraTextureId
        )

        GLES20.glUniform1i(
            cameraTextureLocation,
            0
        )

        GLES20.glDrawArrays(
            GLES20.GL_TRIANGLE_STRIP,
            0,
            4
        )

        GLES20.glBindTexture(
            GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
            0
        )

        GLES20.glDisableVertexAttribArray(
            vertexPositionLocation
        )

        GLES20.glDisableVertexAttribArray(
            textureCoordinateLocation
        )

        GLES20.glUseProgram(0)
        GLES20.glDepthMask(true)
    }

    // Converts shader text into instructions that the GPU can execute.
    // Returns 0 when OpenGL cannot create or compile the shader.
    private fun compileShader(
        shaderType: Int,
        shaderCode: String
    ): Int {
        val shaderId =
            GLES20.glCreateShader(shaderType)

        if (shaderId == 0) {
            Log.e(
                logTag,
                "OpenGL could not create the shader."
            )

            return 0
        }

        GLES20.glShaderSource(
            shaderId,
            shaderCode
        )

        GLES20.glCompileShader(shaderId)

        val compileStatus = IntArray(1)

        GLES20.glGetShaderiv(
            shaderId,
            GLES20.GL_COMPILE_STATUS,
            compileStatus,
            0
        )

        if (compileStatus[0] == 0) {
            val errorMessage =
                GLES20.glGetShaderInfoLog(shaderId)

            Log.e(
                logTag,
                "Shader compilation failed: $errorMessage"
            )

            GLES20.glDeleteShader(shaderId)

            return 0
        }

        return shaderId
    }
}