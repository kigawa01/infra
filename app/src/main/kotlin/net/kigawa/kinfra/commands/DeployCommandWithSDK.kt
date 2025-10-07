package net.kigawa.kinfra.commands

import net.kigawa.kinfra.action.EnvironmentValidator
import net.kigawa.kinfra.action.TerraformService
import net.kigawa.kinfra.infrastructure.bitwarden.BitwardenSecretManagerRepository
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
        val applyResult = terraformService.apply(environment, additionalArgs = additionalArgs)

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

        // シークレットを取得
        val secrets = try {
            secretManagerRepository.listSecrets()
        } catch (e: Exception) {
            println("${RED}Error:${RESET} Failed to fetch secrets: ${e.message}")
            println()
            println("${BLUE}Make sure BWS_ACCESS_TOKEN environment variable is set${RESET}")
            return false
        }

        // R2認証情報を検索
        val accessKeySecret = secrets.find { it.key == "r2_access_key" || it.key == "access_key" }
        val secretKeySecret = secrets.find { it.key == "r2_secret_key" || it.key == "secret_key" }
        val accountIdSecret = secrets.find { it.key == "r2_account_id" || it.key == "account_id" }
        val bucketNameSecret = secrets.find { it.key == "r2_bucket_name" || it.key == "bucket_name" }

        if (accessKeySecret == null || secretKeySecret == null || accountIdSecret == null) {
            println("${RED}Error:${RESET} Required secrets not found in Secret Manager.")
            println()
            println("${YELLOW}Required secret keys:${RESET}")
            println("  - r2_access_key or access_key")
            println("  - r2_secret_key or secret_key")
            println("  - r2_account_id or account_id")
            return false
        }

        val accessKey = accessKeySecret.value
        val secretKey = secretKeySecret.value
        val accountId = accountIdSecret.value
        val bucketName = bucketNameSecret?.value ?: "kigawa-infra-state"

        println("${GREEN}✓${RESET} Credentials retrieved from Secret Manager")

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
