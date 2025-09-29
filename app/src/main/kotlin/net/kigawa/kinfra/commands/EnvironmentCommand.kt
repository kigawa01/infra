package net.kigawa.kinfra.commands

import net.kigawa.kinfra.Command
import java.io.File
import java.io.IOException

abstract class EnvironmentCommand : Command {
    companion object {
        const val RESET = "\u001B[0m"
        const val RED = "\u001B[31m"
        const val GREEN = "\u001B[32m"
        const val YELLOW = "\u001B[33m"
        const val BLUE = "\u001B[34m"
    }

    override fun requiresEnvironment(): Boolean = true

    protected fun validateEnvironment(environment: String, isAutoSelected: Boolean = false): Boolean {
        if (environment != "prod") {
            println("${RED}Error:${RESET} Only 'prod' environment is allowed.")
            println("${BLUE}Available environment:${RESET} prod")
            return false
        }

        if (isAutoSelected) {
            println("${BLUE}Using environment:${RESET} $environment (automatically selected)")
        }

        return true
    }

    protected fun setupEnvironment(environment: String): File {
        val environmentsDir = File("environments")
        if (!environmentsDir.exists()) {
            environmentsDir.mkdirs()
            println("${YELLOW}Warning:${RESET} Created 'environments' directory.")
        }

        val envDir = File(environmentsDir, environment)
        if (!envDir.exists()) {
            envDir.mkdirs()
            println("${GREEN}Created environment directory:${RESET} environments/$environment")
        }

        return envDir
    }

    protected fun getVarFileArgs(envDir: File): Array<String> {
        val tfvarsFile = File(envDir, "terraform.tfvars")
        return if (tfvarsFile.exists()) {
            arrayOf("-var-file=${tfvarsFile.absolutePath}")
        } else {
            println("${YELLOW}Warning:${RESET} No terraform.tfvars file found for environment '${envDir.name}'")
            emptyArray()
        }
    }

    protected fun executeTerraformCommand(vararg args: String): Int {
        println("${GREEN}Running:${RESET} ${args.joinToString(" ")}")

        return try {
            val processBuilder = ProcessBuilder(*args)
            processBuilder.environment()["SSH_CONFIG"] = "./ssh_config"
            processBuilder.inheritIO()

            val process = processBuilder.start()
            process.waitFor()
        } catch (e: IOException) {
            println("${RED}Error executing command:${RESET} ${e.message}")
            1
        }
    }
}