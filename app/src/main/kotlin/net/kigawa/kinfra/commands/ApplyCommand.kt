package net.kigawa.kinfra.commands

import net.kigawa.kinfra.action.EnvironmentValidator
import net.kigawa.kinfra.action.TerraformService

class ApplyCommand(
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

        // Check if first additional arg is a plan file
        val planFile = if (additionalArgs.isNotEmpty() &&
            (additionalArgs[0].endsWith(".tfplan") || additionalArgs[0] == "tfplan")) {
            additionalArgs[0]
        } else {
            null
        }

        val argsWithoutPlan = if (planFile != null) additionalArgs.drop(1).toTypedArray() else additionalArgs

        val result = terraformService.apply(environment, planFile, argsWithoutPlan)
        return result.exitCode
    }

    override fun getDescription(): String {
        return "Apply the changes required to reach the desired state"
    }
}