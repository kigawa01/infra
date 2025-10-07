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

    fun executeWithOutput(
        args: Array<String>,
        workingDir: File? = null,
        environment: Map<String, String> = emptyMap()
    ): ExecutionResult

    fun checkInstalled(command: String): Boolean
}

data class ExecutionResult(
    val exitCode: Int,
    val output: String,
    val error: String = ""
)

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

    override fun executeWithOutput(
        args: Array<String>,
        workingDir: File?,
        environment: Map<String, String>
    ): ExecutionResult {
        return try {
            val processBuilder = ProcessBuilder(*args)

            if (workingDir != null) {
                processBuilder.directory(workingDir)
            }

            environment.forEach { (key, value) ->
                processBuilder.environment()[key] = value
            }

            val process = processBuilder.start()
            val output = process.inputStream.bufferedReader().readText()
            val error = process.errorStream.bufferedReader().readText()
            val exitCode = process.waitFor()

            ExecutionResult(exitCode, output, error)
        } catch (e: IOException) {
            ExecutionResult(1, "", "Error executing command: ${e.message}")
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