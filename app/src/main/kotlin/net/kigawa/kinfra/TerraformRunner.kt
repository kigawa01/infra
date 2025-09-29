package net.kigawa.kinfra

import java.io.File
import kotlin.system.exitProcess

class TerraformRunner {
    companion object {
        const val RESET = "\u001B[0m"
        const val RED = "\u001B[31m"
        const val GREEN = "\u001B[32m"
        const val YELLOW = "\u001B[33m"
        const val BLUE = "\u001B[34m"
    }

    private val supportedCommands = setOf(
        "init", "plan", "apply", "destroy", "validate", "fmt", "help"
    )

    fun run(args: Array<String>) {
        if (args.isEmpty()) {
            showUsage()
            exitProcess(1)
        }

        val command = args[0]

        if (command == "help") {
            showUsage()
            return
        }

        if (!isTerraformInstalled()) {
            println("${RED}Error:${RESET} Terraform is not installed or not found in PATH.")
            println("${BLUE}Please install Terraform:${RESET}")
            println("  Ubuntu/Debian: sudo apt-get install terraform")
            println("  macOS: brew install terraform")
            println("  Or download from: https://www.terraform.io/downloads.html")
            exitProcess(1)
        }

        when (command) {
            "fmt" -> {
                executeTerraformCommand("terraform", "fmt", "-recursive")
                return
            }
            "validate" -> {
                executeTerraformCommand("terraform", "validate")
                return
            }
            in supportedCommands -> {
                if (args.size < 2) {
                    println("${RED}Error:${RESET} Environment not specified for command '$command'.")
                    showUsage()
                    exitProcess(1)
                }
                executeCommandWithEnvironment(command, args[1], args.drop(2).toTypedArray())
            }
            else -> {
                println("${RED}Error:${RESET} Unknown command: $command")
                showUsage()
                exitProcess(1)
            }
        }
    }

    private fun executeCommandWithEnvironment(command: String, environment: String, additionalArgs: Array<String>) {
        val environmentsDir = File("environments")
        if (!environmentsDir.exists()) {
            environmentsDir.mkdirs()
            println("${YELLOW}Warning:${RESET} Created 'environments' directory.")
        }

        val envDir = File(environmentsDir, environment)

        if (command == "init" && !envDir.exists()) {
            envDir.mkdirs()
            println("${GREEN}Created environment directory:${RESET} environments/$environment")
        } else if (command != "init" && !envDir.exists()) {
            println("${RED}Error:${RESET} Environment '$environment' not found. Available environments:")
            environmentsDir.listFiles()?.forEach { println("  ${it.name}") }
                ?: println("  No environments found.")
            exitProcess(1)
        }

        val tfvarsFile = File(envDir, "terraform.tfvars")
        val varFileArgs = if (tfvarsFile.exists()) {
            arrayOf("-var-file=${tfvarsFile.absolutePath}")
        } else {
            println("${YELLOW}Warning:${RESET} No terraform.tfvars file found for environment '$environment'")
            emptyArray()
        }

        // Set SSH config environment variable
        val processBuilder = ProcessBuilder()
        processBuilder.environment()["SSH_CONFIG"] = "./ssh_config"

        when (command) {
            "init" -> {
                val allArgs = arrayOf("terraform", "init") + additionalArgs
                executeTerraformCommand(*allArgs, processBuilder = processBuilder)
            }
            "plan" -> {
                val allArgs = arrayOf("terraform", "plan") + varFileArgs + additionalArgs
                executeTerraformCommand(*allArgs, processBuilder = processBuilder)
            }
            "apply" -> {
                // Check if first additional arg is a plan file
                val isPlanFile = additionalArgs.isNotEmpty() &&
                    (additionalArgs[0].endsWith(".tfplan") || additionalArgs[0] == "tfplan")

                val allArgs = if (isPlanFile) {
                    arrayOf("terraform", "apply") + additionalArgs
                } else {
                    arrayOf("terraform", "apply") + varFileArgs + additionalArgs
                }
                executeTerraformCommand(*allArgs, processBuilder = processBuilder)
            }
            "destroy" -> {
                val allArgs = arrayOf("terraform", "destroy") + varFileArgs + additionalArgs
                executeTerraformCommand(*allArgs, processBuilder = processBuilder)
            }
        }
    }

    private fun executeTerraformCommand(vararg args: String, processBuilder: ProcessBuilder = ProcessBuilder()) {
        println("${GREEN}Running:${RESET} ${args.joinToString(" ")}")

        processBuilder.command(*args)
        processBuilder.inheritIO()

        try {
            val process = processBuilder.start()
            val exitCode = process.waitFor()
            if (exitCode != 0) {
                exitProcess(exitCode)
            }
        } catch (e: Exception) {
            println("${RED}Error executing command:${RESET} ${e.message}")
            exitProcess(1)
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

    private fun showUsage() {
        println("${BLUE}Usage:${RESET} java -jar app.jar [command] [environment] [options]")
        println()
        println("${BLUE}Commands:${RESET}")
        println("  init       - Initialize Terraform working directory")
        println("  plan       - Create an execution plan")
        println("  apply      - Apply the changes required to reach the desired state")
        println("  destroy    - Destroy the Terraform-managed infrastructure")
        println("  validate   - Validate the configuration files")
        println("  fmt        - Reformat configuration files to canonical format")
        println("  help       - Show this help message")
        println()
        println("${BLUE}Environments:${RESET}")
        println("  dev        - Development environment")
        println("  staging    - Staging environment")
        println("  prod       - Production environment")
        println()
        println("${BLUE}Options:${RESET}")
        println("  -auto-approve  - Skip interactive approval (for apply/destroy)")
        println("  -var-file      - Specify a variable file")
        println()
        println("${BLUE}Examples:${RESET}")
        println("  java -jar app.jar init dev")
        println("  java -jar app.jar plan prod")
        println("  java -jar app.jar apply staging")
        println("  java -jar app.jar destroy dev -auto-approve")
        println("  java -jar app.jar fmt")
        println("  java -jar app.jar validate")
    }
}