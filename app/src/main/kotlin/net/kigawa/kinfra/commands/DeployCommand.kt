package net.kigawa.kinfra.commands

import net.kigawa.kinfra.action.EnvironmentValidator
import net.kigawa.kinfra.action.TerraformService
import net.kigawa.kinfra.infrastructure.bitwarden.BitwardenRepository
import net.kigawa.kinfra.model.R2BackendConfig
import java.io.File

class DeployCommand(
    private val terraformService: TerraformService,
    private val environmentValidator: EnvironmentValidator,
    private val bitwardenRepository: BitwardenRepository
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
        val initResult = terraformService.init(environment, quiet = false)
        if (initResult.isFailure) return initResult.exitCode

        println()

        // Step 2: Plan
        println("${BLUE}Step 2/3: Creating execution plan${RESET}")
        val planResult = terraformService.plan(environment, additionalArgs, quiet = false)
        if (planResult.isFailure) return planResult.exitCode

        println()

        // Step 3: Apply
        println("${BLUE}Step 3/3: Applying changes${RESET}")
        val applyArgsWithAutoApprove = if (additionalArgs.contains("-auto-approve")) {
            additionalArgs
        } else {
            additionalArgs + "-auto-approve"
        }
        val applyResult = terraformService.apply(environment, additionalArgs = applyArgsWithAutoApprove, quiet = false)

        if (applyResult.isSuccess) {
            println()
            println("${GREEN}✅ Deployment completed successfully!${RESET}")
        }

        return applyResult.exitCode
    }

    override fun getDescription(): String {
        return "Full deployment pipeline (init → plan → apply)"
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
        println("${BLUE}Fetching credentials from Bitwarden...${RESET}")

        // Check if bw is installed
        if (!bitwardenRepository.isInstalled()) {
            println("${RED}Error:${RESET} Bitwarden CLI (bw) is not installed.")
            println("${BLUE}Install with:${RESET} npm install -g @bitwarden/cli")
            return false
        }

        // Check if logged in
        if (!bitwardenRepository.isLoggedIn()) {
            println("${RED}Error:${RESET} Not logged in to Bitwarden.")
            println("${BLUE}Please run:${RESET} bw login")
            return false
        }

        // Get session token - prioritize file over environment variable
        val session = bitwardenRepository.getSessionFromFile()
            ?: bitwardenRepository.getSessionFromEnv()

        if (session == null) {
            println("${RED}Error:${RESET} No Bitwarden session found.")
            println()
            println("${BLUE}Please unlock Bitwarden:${RESET}")
            println("  ./gradlew run --args=\"login\"")
            println()
            println("${BLUE}Or set BW_SESSION manually:${RESET}")
            println("  export BW_SESSION=\$(bw unlock --raw)")
            println()
            println("${BLUE}Then run the deploy command again:${RESET}")
            println("  ./gradlew run --args=\"deploy\"")
            return false
        }

        val sessionSource = if (bitwardenRepository.getSessionFromFile() != null) "session file" else "environment"
        println("${GREEN}✓${RESET} Using BW_SESSION from $sessionSource")

        // Get the item (using default name)
        val itemName = "Cloudflare R2 Terraform Backend"
        val item = bitwardenRepository.getItem(itemName, session)

        if (item == null) {
            println("${RED}Error:${RESET} Item '$itemName' not found in Bitwarden.")
            println()
            println("${YELLOW}Options:${RESET}")
            println("1. Create the item manually in Bitwarden with the following fields:")
            println("   - Name: $itemName")
            println("   - Fields: access_key, secret_key, account_id, bucket_name")
            println()
            println("2. Run the setup command:")
            println("   ${BLUE}./gradlew run --args=\"setup-r2\"${RESET}")
            println()
            println("3. Or use the SDK-based deploy command (recommended if using BW_PROJECT):")
            println("   ${BLUE}export BWS_ACCESS_TOKEN=<your-token>${RESET}")
            println("   ${BLUE}./gradlew run --args=\"deploy-sdk prod\"${RESET}")
            return false
        }

        // Extract credentials
        val accessKey = item.getFieldValue("access_key")
        val secretKey = item.getFieldValue("secret_key")
        val accountId = item.getFieldValue("account_id")
        val bucketName = item.getFieldValue("bucket_name") ?: "kigawa-infra-state"

        // Validate credentials
        if (accessKey == null || secretKey == null || accountId == null) {
            println("${RED}Error:${RESET} Missing required fields in Bitwarden item.")
            return false
        }

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