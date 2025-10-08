package net.kigawa.kinfra.infrastructure.terraform

import net.kigawa.kinfra.model.Environment
import net.kigawa.kinfra.model.TerraformConfig
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
        // プロジェクトルートを特定
        // Gradleから実行された場合、user.dirはappディレクトリを指すので親に移動
        val currentDir = File(System.getProperty("user.dir"))
        val projectRoot = if (currentDir.name == "app") {
            currentDir.parentFile
        } else {
            currentDir
        }

        val environmentsDir = File(projectRoot, "environments")
        val envDir = File(environmentsDir, environment.name)

        // 環境ディレクトリを作成
        fileRepository.createDirectory(environmentsDir)
        fileRepository.createDirectory(envDir)

        // tfvarsファイルの存在確認
        val tfvarsFile = File(envDir, "terraform.tfvars")
        val varFile = if (fileRepository.exists(tfvarsFile)) tfvarsFile else null

        // SSH設定ファイルのパス
        val sshConfigFile = File(projectRoot, "ssh_config")
        val sshConfigPath = fileRepository.getAbsolutePath(sshConfigFile)

        // Terraformファイルはterraformディレクトリに配置
        val terraformDir = File(projectRoot, "terraform")

        return TerraformConfig(
            environment = environment,
            workingDirectory = terraformDir,
            varFile = varFile,
            sshConfigPath = sshConfigPath
        )
    }
}