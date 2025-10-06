package net.kigawa.kinfra.commands

import net.kigawa.kinfra.action.EnvironmentValidator
import net.kigawa.kinfra.action.TerraformService

class DeployCommand(
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

        println("${BLUE}Starting full deployment pipeline for environment: ${environment.name}${RESET}")
        println()

        // Step 1: Initialize
        println("${BLUE}Step 1/3: Initializing Terraform${RESET}")
        val initResult = terraformService.init(environment)
        if (initResult.isFailure) return initResult.exitCode

        println()

        // Step 2: Plan
        println("${BLUE}Step 2/3: Creating execution plan${RESET}")
        val planResult = terraformService.plan(environment, additionalArgs)
        if (planResult.isFailure) return planResult.exitCode

        println()

        // Step 3: Apply
        println("${BLUE}Step 3/3: Applying changes${RESET}")
        val applyResult = terraformService.apply(environment, additionalArgs = additionalArgs)

        if (applyResult.isSuccess) {
            println()
            println("${GREEN}✅ Deployment completed successfully!${RESET}")
        }

        return applyResult.exitCode
    }

    override fun getDescription(): String {
        return "Full deployment pipeline (init → plan → apply)"
    }
}