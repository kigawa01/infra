package net.kigawa.kinfra.commands

import net.kigawa.kinfra.action.TerraformService
import net.kigawa.kinfra.model.Command

class ValidateCommand(
    private val terraformService: TerraformService
) : Command {
    override fun execute(args: Array<String>): Int {
        val result = terraformService.validate()
        return result.exitCode
    }

    override fun getDescription(): String {
        return "Validate the configuration files"
    }

    override fun requiresEnvironment(): Boolean {
        return false
    }
}
