package net.kigawa.kinfra.commands

import net.kigawa.kinfra.model.Command
import net.kigawa.kinfra.model.R2BackendConfig
import net.kigawa.kinfra.infrastructure.bitwarden.BitwardenSecretManagerRepository
import net.kigawa.kinfra.infrastructure.config.EnvFileLoader
import java.io.File

/**
 * Bitwarden Secret Manager SDK を使用したR2バックエンドセットアップコマンド
 */
class SetupR2CommandWithSDK(
    private val secretManagerRepository: BitwardenSecretManagerRepository
) : Command {

    companion object {
        const val RESET = "\u001B[0m"
        const val RED = "\u001B[31m"
        const val GREEN = "\u001B[32m"
        const val YELLOW = "\u001B[33m"
        const val BLUE = "\u001B[34m"
    }

    override fun execute(args: Array<String>): Int {
        println("${BLUE}=== Cloudflare R2 Backend Setup (Secret Manager SDK) ===${RESET}")
        println()

        // プロジェクトIDを引数、環境変数、.envファイルから取得
        val projectId = if (args.isNotEmpty()) {
            args[0]
        } else {
            EnvFileLoader.get("BW_PROJECT") ?: System.getenv("BW_PROJECT_ID")
        }

        if (projectId != null) {
            println("${BLUE}Using project ID: ${projectId}${RESET}")
        }

        println("${BLUE}Fetching secrets from Bitwarden Secret Manager...${RESET}")

        val secrets = try {
            secretManagerRepository.listSecrets()
        } catch (e: Exception) {
            println("${RED}Error:${RESET} Failed to fetch secrets: ${e.message}")
            return 1
        }

        if (secrets.isEmpty()) {
            println("${YELLOW}No secrets found in Secret Manager${RESET}")
            return 1
        }

        println("${GREEN}✓${RESET} Found ${secrets.size} secrets")
        println()

        // R2認証情報を検索
        val accessKeySecret = secrets.find { it.key == "r2-access" }
        val secretKeySecret = secrets.find { it.key == "r2-secret" }
        val accountSecret = secrets.find { it.key == "r2-account" }
        val bucketSecret = secrets.find { it.key == "r2-bucket" }

        // 利用可能なシークレットキーを表示
        if (accessKeySecret == null || secretKeySecret == null || accountSecret == null) {
            println("${RED}Error:${RESET} Required secrets not found.")
            println()
            println("${YELLOW}Required secret keys and formats:${RESET}")
            println("  - r2-access: R2 Access Key ID (32-char hex)")
            println("  - r2-secret: R2 Secret Access Key (64-char hex)")
            println("  - r2-account: R2 Account ID (32-char hex)")
            println("  - r2-bucket: Bucket name (optional, defaults to 'kigawa-infra-state', NOT a URL)")
            println()
            println("${BLUE}Available secrets:${RESET}")
            secrets.forEach { println("  - ${it.key}") }
            return 1
        }

        val accessKey = accessKeySecret.value
        val secretKey = secretKeySecret.value
        val accountId = accountSecret.value
        val bucketName = bucketSecret?.value ?: "kigawa-infra-state"

        println("${GREEN}✓${RESET} Credentials retrieved successfully")
        println()

        // 環境選択
        println("${BLUE}Select environment:${RESET}")
        println("  1) prod (recommended)")
        println("  2) global (root backend.tfvars)")
        print("Choice [1]: ")
        val envChoice = readLine()?.takeIf { it.isNotBlank() } ?: "1"

        val (backendFile, stateKey) = when (envChoice) {
            "1" -> Pair("environments/prod/backend.tfvars", "prod/terraform.tfstate")
            "2" -> Pair("backend.tfvars", "terraform.tfstate")
            else -> {
                println("${RED}Invalid choice${RESET}")
                return 1
            }
        }

        // バックエンド設定を作成
        val config = R2BackendConfig(
            bucket = bucketName,
            key = stateKey,
            endpoint = "https://$accountId.r2.cloudflarestorage.com",
            accessKey = accessKey,
            secretKey = secretKey
        )

        // ファイルに保存
        println("${BLUE}Creating backend configuration file...${RESET}")
        val backendConfigFile = File(backendFile)
        backendConfigFile.parentFile?.mkdirs()
        backendConfigFile.writeText(config.toTfvarsContent())

        // ファイル権限を設定 (owner read/write only)
        backendConfigFile.setReadable(true, true)
        backendConfigFile.setWritable(true, true)

        println("${GREEN}✓${RESET} Backend configuration saved to: $backendFile")
        println()

        // 次のステップを表示
        println("${BLUE}=== Next Steps ===${RESET}")
        println()
        println("1. Initialize Terraform with R2 backend:")
        println("   ${GREEN}./gradlew run --args=\"init prod\"${RESET}")
        println()
        println("2. If migrating from local state, Terraform will ask:")
        println("   ${YELLOW}\"Do you want to copy existing state to the new backend?\"${RESET}")
        println("   Answer: ${GREEN}yes${RESET}")
        println()
        println("3. Verify the setup:")
        println("   ${GREEN}./gradlew run --args=\"plan prod\"${RESET}")
        println()

        println("${GREEN}Setup complete!${RESET}")

        return 0
    }

    override fun requiresEnvironment(): Boolean = false

    override fun getDescription(): String {
        return "Setup Cloudflare R2 backend using Bitwarden Secret Manager SDK"
    }
}
