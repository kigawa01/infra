package net.kigawa.kinfra.infrastructure.file

import java.io.File

/**
 * ファイル操作を担当するリポジトリ
 */
interface FileRepository {
    fun createDirectory(path: File): Boolean
    fun exists(path: File): Boolean
    fun getAbsolutePath(path: File): String
}

class FileRepositoryImpl : FileRepository {
    override fun createDirectory(path: File): Boolean {
        if (!path.exists()) {
            return path.mkdirs()
        }
        return true
    }

    override fun exists(path: File): Boolean {
        return path.exists()
    }

    override fun getAbsolutePath(path: File): String {
        return path.absolutePath
    }
}