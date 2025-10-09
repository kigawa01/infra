package net.kigawa.kinfra

import net.kigawa.kinfra.infrastructure.logging.Logger
import net.kigawa.kinfra.model.Command
import net.kigawa.kinfra.model.CommandType
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import org.koin.core.qualifier.named
import kotlin.system.exitProcess

class TerraformRunner : KoinComponent {
    private val logger: Logger by inject()
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
        logger.info("Starting Terraform Runner with args: ${args.joinToString(" ")}")

        if (args.isEmpty()) {
            logger.warn("No command provided")
            commands[CommandType.HELP.commandName]?.execute(emptyArray())
            exitProcess(1)
        }

        var commandName = args[0]
        logger.debug("Original command: $commandName")

        // deploy と setup-r2 コマンドは常に SDK 版を使用
        when (commandName) {
            CommandType.DEPLOY.commandName -> {
                commandName = CommandType.DEPLOY_SDK.commandName
                logger.info("Command redirected to SDK version: $commandName")
            }
            CommandType.SETUP_R2.commandName -> {
                commandName = CommandType.SETUP_R2_SDK.commandName
                logger.info("Command redirected to SDK version: $commandName")
            }
        }

        val command = commands[commandName]

        if (command == null) {
            // SDK版コマンドが見つからない場合、BWS_ACCESS_TOKENの設定を促す
            if (commandName == CommandType.DEPLOY_SDK.commandName || commandName == CommandType.SETUP_R2_SDK.commandName) {
                logger.error("BWS_ACCESS_TOKEN is not set for SDK command: $commandName")
                println("${RED}Error:${RESET} BWS_ACCESS_TOKEN is not set.")
                println()
                println("${BLUE}Secret Manager is required for this command.${RESET}")
                println("${BLUE}Please set the BWS_ACCESS_TOKEN environment variable:${RESET}")
                println("  export BWS_ACCESS_TOKEN=\"your-token\"")
                println()
                println("${BLUE}To generate a token:${RESET}")
                println("  1. Log in to Bitwarden Web Vault")
                println("  2. Go to Secret Manager section")
                println("  3. Generate an access token from project settings")
                exitProcess(1)
            }

            logger.error("Unknown command: $commandName")
            println("${RED}Error:${RESET} Unknown command: $commandName")
            commands[CommandType.HELP.commandName]?.execute(emptyArray())
            exitProcess(1)
        }

        // Skip Terraform check for help, login, config and setup-r2 commands
        val skipTerraformCheck = commandName == CommandType.HELP.commandName
            || commandName == CommandType.LOGIN.commandName
            || commandName == CommandType.CONFIG.commandName
            || commandName == CommandType.SETUP_R2.commandName
            || commandName == CommandType.SETUP_R2_SDK.commandName
        if (!skipTerraformCheck && !isTerraformInstalled()) {
            logger.error("Terraform is not installed")
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
                logger.info("Auto-selecting 'prod' environment")
                arrayOf("prod", "--auto-selected")
            } else {
                args.drop(1).toTypedArray()
            }
        } else {
            args.drop(1).toTypedArray()
        }

        logger.info("Executing command: $commandName with args: ${commandArgs.joinToString(" ")}")
        val exitCode = command.execute(commandArgs)
        logger.info("Command $commandName finished with exit code: $exitCode")

        if (exitCode != 0) {
            logger.error("Command $commandName failed with exit code: $exitCode")
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
