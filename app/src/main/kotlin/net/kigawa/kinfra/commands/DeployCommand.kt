package net.kigawa.kinfra.commands

class DeployCommand : EnvironmentCommand() {
    override fun execute(args: Array<String>): Int {
        if (args.isEmpty()) return 1

        val environment = args[0]
        val isAutoSelected = args.contains("--auto-selected")
        val additionalArgs = args.drop(1).filter { it != "--auto-selected" }.toTypedArray()

        if (!validateEnvironment(environment, isAutoSelected)) return 1

        val envDir = setupEnvironment(environment)
        val varFileArgs = getVarFileArgs(envDir)

        println("${BLUE}Starting full deployment pipeline for environment: $environment${RESET}")
        println()

        // Step 1: Initialize
        println("${BLUE}Step 1/3: Initializing Terraform${RESET}")
        val initResult = executeTerraformCommand("terraform", "init")
        if (initResult != 0) return initResult

        println()

        // Step 2: Plan
        println("${BLUE}Step 2/3: Creating execution plan${RESET}")
        val planArgs = arrayOf("terraform", "plan") + varFileArgs + additionalArgs
        val planResult = executeTerraformCommand(*planArgs)
        if (planResult != 0) return planResult

        println()

        // Step 3: Apply
        println("${BLUE}Step 3/3: Applying changes${RESET}")
        val applyArgs = arrayOf("terraform", "apply") + varFileArgs + additionalArgs
        val applyResult = executeTerraformCommand(*applyArgs)

        if (applyResult == 0) {
            println()
            println("${GREEN}✅ Deployment completed successfully!${RESET}")
        }

        return applyResult
    }

    override fun getDescription(): String {
        return "Full deployment pipeline (init → plan → apply)"
    }
}