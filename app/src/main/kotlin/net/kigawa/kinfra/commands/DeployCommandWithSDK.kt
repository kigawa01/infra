package net.kigawa.kinfra.commands

import net.kigawa.kinfra.action.EnvironmentValidator
import net.kigawa.kinfra.action.TerraformService
import net.kigawa.kinfra.infrastructure.bitwarden.BitwardenSecretManagerRepository
import net.kigawa.kinfra.infrastructure.config.EnvFileLoader
import net.kigawa.kinfra.model.R2BackendConfig
import java.io.File

/**
 * Bitwarden Secret Manager SDK を使用したデプロイコマンド
 */
class DeployCommandWithSDK(
    private val terraformService: TerraformService,
    private val environmentValidator: EnvironmentValidator,
    private val secretManagerRepository: BitwardenSecretManagerRepository
) : EnvironmentCommand() {
    override fun execute(args: Array<String>): Int {
        if (args.isEmpty()) return 1

        val environmentName = args[0]
        val isAutoSelected = args.contains("--auto-selected")
        val additionalArgs = args.drop(1).filter { it != "--auto-selected" }.toTypedArray()

        val environment = environmentValidator.validate(environmentName)
        if (environment == null) {
            println("${RED}Error:${RESET} Only 'prod' environment is allowed.")
            println("${BLUE}Available environment:${RESET} prod")
            return 1
        }

        if (isAutoSelected) {
            println("${BLUE}Using environment:${RESET} ${environment.name} (automatically selected)")
        }

        println("${BLUE}Starting full deployment pipeline for environment: ${environment.name}${RESET}")
        println()

        // Step 0: Setup R2 backend if needed
        if (!setupR2BackendIfNeeded(environment.name)) {
            return 1
        }

        // Step 1: Initialize
        println("${BLUE}Step 1/3: Initializing Terraform${RESET}")
        val initResult = terraformService.init(environment)
        if (initResult.isFailure) return initResult.exitCode

        println()

        // Step 2: Plan
        println("${BLUE}Step 2/3: Creating execution plan${RESET}")
        val planResult = terraformService.plan(environment, additionalArgs)
        if (planResult.isFailure) return planResult.exitCode

        println()

        // Step 3: Apply
        println("${BLUE}Step 3/3: Applying changes${RESET}")
        val applyArgsWithAutoApprove = if (additionalArgs.contains("-auto-approve")) {
            additionalArgs
        } else {
            additionalArgs + "-auto-approve"
        }
        val applyResult = terraformService.apply(environment, additionalArgs = applyArgsWithAutoApprove)

        if (applyResult.isSuccess) {
            println()
            println("${GREEN}✅ Deployment completed successfully!${RESET}")
        }

        return applyResult.exitCode
    }

    override fun getDescription(): String {
        return "Full deployment pipeline using Secret Manager SDK (init → plan → apply)"
    }

    private fun setupR2BackendIfNeeded(environmentName: String): Boolean {
        val backendFile = File("environments/$environmentName/backend.tfvars")

        // Check if backend.tfvars already exists and is valid
        if (backendFile.exists()) {
            val content = backendFile.readText()
            if (!content.contains("<account-id>") && !content.contains("your-r2-")) {
                println("${GREEN}✓${RESET} Backend configuration already exists")
                return true
            }
        }

        println("${YELLOW}Backend configuration not found or contains placeholders${RESET}")
        println("${BLUE}Fetching credentials from Bitwarden Secret Manager...${RESET}")

        // プロジェクトIDを.envまたは環境変数から取得
        val projectId = EnvFileLoader.get("BW_PROJECT")
        if (projectId != null) {
            println("${BLUE}Using project ID from .env: ${projectId}${RESET}")
        }

        // シークレットを取得
        val secrets = try {
            secretManagerRepository.listSecrets()
        } catch (e: Exception) {
            println("${RED}Error:${RESET} Failed to fetch secrets: ${e.message}")
            println()
            println("${BLUE}Make sure BWS_ACCESS_TOKEN environment variable is set${RESET}")
            if (projectId != null) {
                println("${BLUE}Using BW_PROJECT from .env: ${projectId}${RESET}")
            }
            return false
        }

        // R2認証情報を検索
        val accessKeySecret = secrets.find { it.key == "r2-access" }
        val secretKeySecret = secrets.find { it.key == "r2-secret" }
        val accountSecret = secrets.find { it.key == "r2-account" }
        val bucketSecret = secrets.find { it.key == "r2-bucket" }

        if (accessKeySecret == null || secretKeySecret == null || accountSecret == null) {
            println("${RED}Error:${RESET} Required secrets not found in Secret Manager.")
            println()
            println("${YELLOW}Required secret keys and formats:${RESET}")
            println("  - r2-access: R2 Access Key ID (32-char hex, e.g. f187f7a87ac5ab2d425bfd783e11146f)")
            println("  - r2-secret: R2 Secret Access Key (64-char hex)")
            println("  - r2-account: R2 Account ID (32-char hex, e.g. e9f30fd43ef4cc3d46050e34dad5c811)")
            println("  - r2-bucket: Bucket name (optional, e.g. kigawa-infra-state, NOT a URL)")
            println()
            println("${BLUE}Available secrets:${RESET}")
            secrets.forEach { println("  - ${it.key}") }
            return false
        }

        val accessKey = accessKeySecret.value
        val secretKey = secretKeySecret.value
        val accountId = accountSecret.value
        val bucketName = bucketSecret?.value ?: "kigawa-infra-state"

        println("${GREEN}✓${RESET} Credentials retrieved from Secret Manager")
        println("${BLUE}Debug - Secret values:${RESET}")
        println("  r2-access (Access Key ID): ${accessKey.take(10)}...")
        println("  r2-secret (Secret Key): ${secretKey.take(10)}...")
        println("  r2-account (Account ID): ${accountId.take(10)}...")
        println("  r2-bucket (Bucket): $bucketName")

        // Create backend config
        val config = R2BackendConfig(
            bucket = bucketName,
            key = "$environmentName/terraform.tfstate",
            endpoint = "https://$accountId.r2.cloudflarestorage.com",
            accessKey = accessKey,
            secretKey = secretKey
        )

        // Save to file
        backendFile.parentFile?.mkdirs()
        backendFile.writeText(config.toTfvarsContent())
        backendFile.setReadable(true, true)
        backendFile.setWritable(true, true)

        println("${GREEN}✓${RESET} Backend configuration created successfully")
        println()

        return true
    }
}
