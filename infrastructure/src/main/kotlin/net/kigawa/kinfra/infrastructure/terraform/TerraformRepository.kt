package net.kigawa.kinfra.infrastructure.terraform

import net.kigawa.kinfra.domain.Environment
import net.kigawa.kinfra.domain.TerraformConfig
import net.kigawa.kinfra.infrastructure.file.FileRepository
import java.io.File

/**
 * Terraform設定の取得を担当するリポジトリ
 */
interface TerraformRepository {
    fun getTerraformConfig(environment: Environment): TerraformConfig
}

class TerraformRepositoryImpl(
    private val fileRepository: FileRepository
) : TerraformRepository {

    override fun getTerraformConfig(environment: Environment): TerraformConfig {
        val environmentsDir = File("environments")
        val envDir = File(environmentsDir, environment.name)

        // 環境ディレクトリを作成
        fileRepository.createDirectory(environmentsDir)
        fileRepository.createDirectory(envDir)

        // tfvarsファイルの存在確認
        val tfvarsFile = File(envDir, "terraform.tfvars")
        val varFile = if (fileRepository.exists(tfvarsFile)) tfvarsFile else null

        // SSH設定ファイルのパス
        val sshConfigPath = fileRepository.getAbsolutePath(File("ssh_config"))

        return TerraformConfig(
            environment = environment,
            workingDirectory = envDir,
            varFile = varFile,
            sshConfigPath = sshConfigPath
        )
    }
}