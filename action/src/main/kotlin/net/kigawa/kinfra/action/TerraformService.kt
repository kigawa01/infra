package net.kigawa.kinfra.action

import net.kigawa.kinfra.model.CommandResult
import net.kigawa.kinfra.model.Environment
import net.kigawa.kinfra.model.TerraformConfig

/**
 * Terraformコマンドの実行を管理するサービス
 */
interface TerraformService {
    fun init(environment: Environment, additionalArgs: Array<String> = emptyArray(), quiet: Boolean = true): CommandResult
    fun plan(environment: Environment, additionalArgs: Array<String> = emptyArray(), quiet: Boolean = true): CommandResult
    fun apply(environment: Environment, planFile: String? = null, additionalArgs: Array<String> = emptyArray(), quiet: Boolean = true): CommandResult
    fun destroy(environment: Environment, additionalArgs: Array<String> = emptyArray(), quiet: Boolean = true): CommandResult
    fun format(recursive: Boolean = true, quiet: Boolean = true): CommandResult
    fun validate(quiet: Boolean = true): CommandResult
    fun getTerraformConfig(environment: Environment): TerraformConfig
}

/**
 * 環境名のバリデーションを担当
 */
interface EnvironmentValidator {
    fun validate(environmentName: String): Environment?
    fun isValid(environmentName: String): Boolean
}