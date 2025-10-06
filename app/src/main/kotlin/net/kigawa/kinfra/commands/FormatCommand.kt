package net.kigawa.kinfra.commands

import net.kigawa.kinfra.action.TerraformService
import net.kigawa.kinfra.domain.Command

class FormatCommand(
    private val terraformService: TerraformService
) : Command {
    override fun execute(args: Array<String>): Int {
        val result = terraformService.format(recursive = true)
        return result.exitCode
    }

    override fun getDescription(): String {
        return "Reformat configuration files to canonical format"
    }

    override fun requiresEnvironment(): Boolean {
        return false
    }
}
