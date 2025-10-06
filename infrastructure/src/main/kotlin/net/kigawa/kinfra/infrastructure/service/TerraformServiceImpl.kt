package net.kigawa.kinfra.infrastructure.service

import net.kigawa.kinfra.action.TerraformService
import net.kigawa.kinfra.domain.CommandResult
import net.kigawa.kinfra.domain.Environment
import net.kigawa.kinfra.domain.TerraformConfig
import net.kigawa.kinfra.infrastructure.process.ProcessExecutor
import net.kigawa.kinfra.infrastructure.terraform.TerraformRepository

/**
 * TerraformServiceの実装
 */
class TerraformServiceImpl(
    private val processExecutor: ProcessExecutor,
    private val terraformRepository: TerraformRepository
) : TerraformService {

    override fun init(environment: Environment, additionalArgs: Array<String>): CommandResult {
        val config = terraformRepository.getTerraformConfig(environment)
        val args = arrayOf("terraform", "init") + additionalArgs

        return processExecutor.execute(
            args = args,
            workingDir = config.workingDirectory,
            environment = mapOf("SSH_CONFIG" to config.sshConfigPath)
        )
    }

    override fun plan(environment: Environment, additionalArgs: Array<String>): CommandResult {
        val config = terraformRepository.getTerraformConfig(environment)
        val varFileArgs = if (config.hasVarFile()) {
            arrayOf("-var-file=${config.varFile!!.absolutePath}")
        } else {
            emptyArray()
        }

        val args = arrayOf("terraform", "plan") + varFileArgs + additionalArgs

        return processExecutor.execute(
            args = args,
            workingDir = config.workingDirectory,
            environment = mapOf("SSH_CONFIG" to config.sshConfigPath)
        )
    }

    override fun apply(environment: Environment, planFile: String?, additionalArgs: Array<String>): CommandResult {
        val config = terraformRepository.getTerraformConfig(environment)

        val baseArgs = arrayOf("terraform", "apply")
        val varFileArgs = if (planFile == null && config.hasVarFile()) {
            arrayOf("-var-file=${config.varFile!!.absolutePath}")
        } else {
            emptyArray()
        }
        val planArgs = if (planFile != null) arrayOf(planFile) else emptyArray()

        val args = baseArgs + varFileArgs + planArgs + additionalArgs

        return processExecutor.execute(
            args = args,
            workingDir = config.workingDirectory,
            environment = mapOf("SSH_CONFIG" to config.sshConfigPath)
        )
    }

    override fun destroy(environment: Environment, additionalArgs: Array<String>): CommandResult {
        val config = terraformRepository.getTerraformConfig(environment)
        val varFileArgs = if (config.hasVarFile()) {
            arrayOf("-var-file=${config.varFile!!.absolutePath}")
        } else {
            emptyArray()
        }

        val args = arrayOf("terraform", "destroy") + varFileArgs + additionalArgs

        return processExecutor.execute(
            args = args,
            workingDir = config.workingDirectory,
            environment = mapOf("SSH_CONFIG" to config.sshConfigPath)
        )
    }

    override fun format(recursive: Boolean): CommandResult {
        val args = if (recursive) {
            arrayOf("terraform", "fmt", "-recursive")
        } else {
            arrayOf("terraform", "fmt")
        }

        return processExecutor.execute(args = args)
    }

    override fun validate(): CommandResult {
        return processExecutor.execute(args = arrayOf("terraform", "validate"))
    }

    override fun getTerraformConfig(environment: Environment): TerraformConfig {
        return terraformRepository.getTerraformConfig(environment)
    }
}