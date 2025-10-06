package net.kigawa.kinfra.commands

class InitCommand : EnvironmentCommand() {
    override fun execute(args: Array<String>): Int {
        if (args.isEmpty()) return 1

        val environment = args[0]
        val isAutoSelected = args.contains("--auto-selected")
        val additionalArgs = args.drop(1).filter { it != "--auto-selected" }.toTypedArray()

        if (!validateEnvironment(environment, isAutoSelected)) return 1

        val envDir = setupEnvironment(environment)

        val allArgs = arrayOf("terraform", "init") + additionalArgs

        return executeTerraformCommand(*allArgs, workingDir = envDir)
    }

    override fun getDescription(): String {
        return "Initialize Terraform working directory"
    }
}