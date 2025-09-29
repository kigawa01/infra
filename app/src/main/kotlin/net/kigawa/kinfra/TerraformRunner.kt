package net.kigawa.kinfra

import net.kigawa.kinfra.domain.Command
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

    private val fmtCommand: Command by inject(named("fmt"))
    private val validateCommand: Command by inject(named("validate"))
    private val initCommand: Command by inject(named("init"))
    private val planCommand: Command by inject(named("plan"))
    private val applyCommand: Command by inject(named("apply"))
    private val destroyCommand: Command by inject(named("destroy"))
    private val deployCommand: Command by inject(named("deploy"))
    private val helpCommand: Command by inject(named("help"))

    private val commands: Map<String, Command> by lazy {
        mapOf(
            "fmt" to fmtCommand,
            "validate" to validateCommand,
            "init" to initCommand,
            "plan" to planCommand,
            "apply" to applyCommand,
            "destroy" to destroyCommand,
            "deploy" to deployCommand,
            "help" to helpCommand
        )
    }

    fun run(args: Array<String>) {
        if (args.isEmpty()) {
            commands["help"]?.execute(emptyArray())
            exitProcess(1)
        }

        val commandName = args[0]
        val command = commands[commandName]

        if (command == null) {
            println("${RED}Error:${RESET} Unknown command: $commandName")
            commands["help"]?.execute(emptyArray())
            exitProcess(1)
        }

        if (!isTerraformInstalled()) {
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
        } catch (e: Exception) {
            false
        }
    }
}
