package net.kigawa.kinfra

import net.kigawa.kinfra.model.Command
import net.kigawa.kinfra.model.CommandType
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import org.koin.core.qualifier.named
import kotlin.system.exitProcess

class TerraformRunner : KoinComponent {
    companion object {
        const val RESET = "\u001B[0m"
        const val RED = "\u001B[31m"
        const val BLUE = "\u001B[34m"
    }

    private val commands: Map<String, Command> by lazy {
        buildMap {
            CommandType.entries.forEach { commandType ->
                runCatching {
                    val command: Command by inject(named(commandType.commandName))
                    put(commandType.commandName, command)
                }
            }
        }
    }

    fun run(args: Array<String>) {
        if (args.isEmpty()) {
            commands[CommandType.HELP.commandName]?.execute(emptyArray())
            exitProcess(1)
        }

        var commandName = args[0]

        // BWS_ACCESS_TOKEN が設定されている場合、SDK版コマンドを使用
        val bwsAccessToken = System.getenv("BWS_ACCESS_TOKEN")
        val hasBwsToken = bwsAccessToken != null && bwsAccessToken.isNotBlank()

        if (hasBwsToken) {
            when (commandName) {
                CommandType.DEPLOY.commandName -> {
                    println("${BLUE}Using SDK-based deploy (BWS_ACCESS_TOKEN detected)${RESET}")
                    commandName = CommandType.DEPLOY_SDK.commandName
                }
                CommandType.SETUP_R2.commandName -> {
                    println("${BLUE}Using SDK-based setup (BWS_ACCESS_TOKEN detected)${RESET}")
                    commandName = CommandType.SETUP_R2_SDK.commandName
                }
            }
        }

        val command = commands[commandName]

        if (command == null) {
            println("${RED}Error:${RESET} Unknown command: $commandName")
            commands[CommandType.HELP.commandName]?.execute(emptyArray())
            exitProcess(1)
        }

        // Skip Terraform check for help, login and setup-r2 commands
        val skipTerraformCheck = commandName == CommandType.HELP.commandName
            || commandName == CommandType.LOGIN.commandName
            || commandName == CommandType.SETUP_R2.commandName
            || commandName == CommandType.SETUP_R2_SDK.commandName
        if (!skipTerraformCheck && !isTerraformInstalled()) {
            println("${RED}Error:${RESET} Terraform is not installed or not found in PATH.")
            println("${BLUE}Please install Terraform:${RESET}")
            println("  Ubuntu/Debian: sudo apt-get install terraform")
            println("  macOS: brew install terraform")
            println("  Or download from: https://www.terraform.io/downloads.html")
            exitProcess(1)
        }

        val commandArgs = if (command.requiresEnvironment()) {
            if (args.size < 2) {
                // Automatically use 'prod' environment if not specified
                arrayOf("prod", "--auto-selected")
            } else {
                args.drop(1).toTypedArray()
            }
        } else {
            args.drop(1).toTypedArray()
        }

        val exitCode = command.execute(commandArgs)
        if (exitCode != 0) {
            exitProcess(exitCode)
        }
    }

    private fun isTerraformInstalled(): Boolean {
        return try {
            val process = ProcessBuilder("terraform", "version")
                .redirectOutput(ProcessBuilder.Redirect.DISCARD)
                .redirectError(ProcessBuilder.Redirect.DISCARD)
                .start()
            process.waitFor() == 0
        } catch (_: Exception) {
            false
        }
    }
}
