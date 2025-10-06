package net.kigawa.kinfra.infrastructure.process

import net.kigawa.kinfra.domain.CommandResult
import java.io.File
import java.io.IOException

/**
 * 外部プロセスの実行を担当
 */
interface ProcessExecutor {
    fun execute(
        args: Array<String>,
        workingDir: File? = null,
        environment: Map<String, String> = emptyMap()
    ): CommandResult

    fun checkInstalled(command: String): Boolean
}

class ProcessExecutorImpl : ProcessExecutor {
    override fun execute(
        args: Array<String>,
        workingDir: File?,
        environment: Map<String, String>
    ): CommandResult {
        return try {
            val processBuilder = ProcessBuilder(*args)

            if (workingDir != null) {
                processBuilder.directory(workingDir)
            }

            environment.forEach { (key, value) ->
                processBuilder.environment()[key] = value
            }

            processBuilder.inheritIO()

            val process = processBuilder.start()
            val exitCode = process.waitFor()

            CommandResult(exitCode)
        } catch (e: IOException) {
            CommandResult.failure(message = "Error executing command: ${e.message}")
        }
    }

    override fun checkInstalled(command: String): Boolean {
        return try {
            val process = ProcessBuilder(command, "version")
                .redirectOutput(ProcessBuilder.Redirect.DISCARD)
                .redirectError(ProcessBuilder.Redirect.DISCARD)
                .start()
            process.waitFor() == 0
        } catch (_: Exception) {
            false
        }
    }
}