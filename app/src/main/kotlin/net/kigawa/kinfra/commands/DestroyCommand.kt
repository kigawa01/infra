package net.kigawa.kinfra.commands

class DestroyCommand : EnvironmentCommand() {
    override fun execute(args: Array<String>): Int {
        if (args.isEmpty()) return 1

        val environment = args[0]
        val isAutoSelected = args.contains("--auto-selected")
        val additionalArgs = args.drop(1).filter { it != "--auto-selected" }.toTypedArray()

        if (!validateEnvironment(environment, isAutoSelected)) return 1

        val envDir = setupEnvironment(environment)
        val varFileArgs = getVarFileArgs(envDir)

        val allArgs = arrayOf("terraform", "destroy") + varFileArgs + additionalArgs

        return executeTerraformCommand(*allArgs)
    }

    override fun getDescription(): String {
        return "Destroy the Terraform-managed infrastructure"
    }
}