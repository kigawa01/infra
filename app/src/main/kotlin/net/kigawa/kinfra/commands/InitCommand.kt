package net.kigawa.kinfra.commands

import net.kigawa.kinfra.action.EnvironmentValidator
import net.kigawa.kinfra.action.TerraformService

class InitCommand(
    private val terraformService: TerraformService,
    private val environmentValidator: EnvironmentValidator
) : EnvironmentCommand() {
    override fun execute(args: Array<String>): Int {
        if (args.isEmpty()) return 1

        val environmentName = args[0]
        val isAutoSelected = args.contains("--auto-selected")
        val additionalArgs = args.drop(1).filter { it != "--auto-selected" }.toTypedArray()

        val environment = environmentValidator.validate(environmentName)
        if (environment == null) {
            println("${RED}Error:${RESET} Only 'prod' environment is allowed.")
            println("${BLUE}Available environment:${RESET} prod")
            return 1
        }

        if (isAutoSelected) {
            println("${BLUE}Using environment:${RESET} ${environment.name} (automatically selected)")
        }

        val config = terraformService.getTerraformConfig(environment)
        printInfo("Working directory: ${config.workingDirectory.absolutePath}")

        val result = terraformService.init(environment, additionalArgs)
        return result.exitCode
    }

    override fun getDescription(): String {
        return "Initialize Terraform working directory"
    }
}