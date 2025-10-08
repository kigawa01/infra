package net.kigawa.kinfra.model

import java.io.File

/**
 * Terraformの設定を表すドメインモデル
 */
data class TerraformConfig(
    val environment: Environment,
    val workingDirectory: File,
    val varFile: File?,
    val sshConfigPath: String
) {
    fun hasVarFile(): Boolean = varFile?.exists() == true
}