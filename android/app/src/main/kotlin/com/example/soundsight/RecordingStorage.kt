package com.example.soundsight

import java.io.File
import kotlin.math.*

/** Only this feature's private cache is eligible for automatic deletion. */
class RecordingStorage(private val directory: File) {
    companion object {
        fun validId(id: String) = id.matches(Regex("[a-zA-Z0-9_-]{1,100}"))
        fun videoSize(sourceWidth: Int, sourceHeight: Int): Pair<Int, Int> {
            require(sourceWidth > 0 && sourceHeight > 0)
            val scale = min(1.0, min(1280.0 / sourceWidth, 720.0 / sourceHeight))
            return max(2, (sourceWidth * scale).toInt() / 2 * 2) to
                max(2, (sourceHeight * scale).toInt() / 2 * 2)
        }
    }

    fun attemptDirectory(id: String): File {
        require(validId(id))
        val root = directory.canonicalFile
        return File(root, id).canonicalFile.also { require(it.parentFile == root) }
    }

    fun discard(id: String) { attemptDirectory(id).deleteRecursively() }

    fun cleanup(activeId: String?) {
        directory.listFiles()?.forEach {
            if (it.name != activeId && validId(it.name)) runCatching { discard(it.name) }
        }
    }
}
