package net.kigawa.kinfra.commands

class ApplyCommand : EnvironmentCommand() {
    override fun execute(args: Array<String>): Int {
        if (args.isEmpty()) return 1

        val environment = args[0]
        val isAutoSelected = args.contains("--auto-selected")
        val additionalArgs = args.drop(1).filter { it != "--auto-selected" }.toTypedArray()

        if (!validateEnvironment(environment, isAutoSelected)) return 1

        val envDir = setupEnvironment(environment)

        // Check if first additional arg is a plan file
        val isPlanFile = additionalArgs.isNotEmpty() &&
            (additionalArgs[0].endsWith(".tfplan") || additionalArgs[0] == "tfplan")

        val allArgs = if (isPlanFile) {
            arrayOf("terraform", "apply") + additionalArgs
        } else {
            val varFileArgs = getVarFileArgs(envDir)
            arrayOf("terraform", "apply") + varFileArgs + additionalArgs
        }

        return executeTerraformCommand(*allArgs)
    }

    override fun getDescription(): String {
        return "Apply the changes required to reach the desired state"
    }
}