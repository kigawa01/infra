package net.kigawa.kinfra.infrastructure.logging

import java.io.File
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

/**
 * ファイルにログを出力するロガー実装
 */
class FileLogger(
    private val logDirectory: String = "logs",
    private val logLevel: LogLevel = LogLevel.INFO
) : Logger {

    private val dateFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")
    private val timestampFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.SSS")

    init {
        // ログディレクトリの作成
        File(logDirectory).mkdirs()
    }

    /**
     * 現在の日付に基づいてログファイルを取得
     */
    private fun getLogFile(): File {
        val today = LocalDateTime.now().format(dateFormatter)
        return File(logDirectory, "kinfra-$today.log")
    }

    /**
     * ログメッセージを書き込む
     */
    private fun log(level: LogLevel, message: String, throwable: Throwable? = null) {
        if (level.ordinal < logLevel.ordinal) {
            return
        }

        val timestamp = LocalDateTime.now().format(timestampFormatter)
        val logMessage = buildString {
            append("[$timestamp] [${level.name}] $message")
            if (throwable != null) {
                append("\n")
                append(throwable.stackTraceToString())
            }
            append("\n")
        }

        try {
            getLogFile().appendText(logMessage)
        } catch (e: Exception) {
            System.err.println("Failed to write log: ${e.message}")
        }
    }

    override fun debug(message: String) {
        log(LogLevel.DEBUG, message)
    }

    override fun info(message: String) {
        log(LogLevel.INFO, message)
    }

    override fun warn(message: String) {
        log(LogLevel.WARN, message)
    }

    override fun error(message: String) {
        log(LogLevel.ERROR, message)
    }

    override fun error(message: String, throwable: Throwable) {
        log(LogLevel.ERROR, message, throwable)
    }
}