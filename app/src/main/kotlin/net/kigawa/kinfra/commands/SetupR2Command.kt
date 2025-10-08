package net.kigawa.kinfra.commands

import net.kigawa.kinfra.model.Command
import net.kigawa.kinfra.model.R2BackendConfig
import net.kigawa.kinfra.infrastructure.bitwarden.BitwardenRepository
import java.io.File

class SetupR2Command(
    private val bitwardenRepository: BitwardenRepository
) : Command {

    companion object {
        const val RESET = "\u001B[0m"
        const val RED = "\u001B[31m"
        const val GREEN = "\u001B[32m"
        const val YELLOW = "\u001B[33m"
        const val BLUE = "\u001B[34m"
    }

    override fun execute(args: Array<String>): Int {
        println("${BLUE}=== Cloudflare R2 Backend Setup ===${RESET}")
        println()

        // Check if bw is installed
        if (!bitwardenRepository.isInstalled()) {
            println("${RED}Error:${RESET} Bitwarden CLI (bw) is not installed.")
            println("${BLUE}Install with:${RESET}")
            println("  npm install -g @bitwarden/cli")
            println("  # or")
            println("  snap install bw")
            return 1
        }

        // Check if logged in
        if (!bitwardenRepository.isLoggedIn()) {
            println("${YELLOW}Not logged in to Bitwarden.${RESET}")
            println("${BLUE}Please run:${RESET} bw login")
            return 1
        }

        // Get session token
        println("${BLUE}Unlocking Bitwarden vault...${RESET}")
        print("Enter your Bitwarden master password: ")
        val password = System.console()?.readPassword()?.let { String(it) } ?: run {
            println("${RED}Error:${RESET} Failed to read password")
            return 1
        }

        val session = bitwardenRepository.unlock(password)
        if (session == null) {
            println("${RED}Error:${RESET} Failed to unlock Bitwarden vault.")
            return 1
        }

        println("${GREEN}✓${RESET} Vault unlocked successfully")
        println()

        // Prompt for item name
        print("${BLUE}Enter the name of the Bitwarden item containing R2 credentials${RESET}\n(default: 'Cloudflare R2 Terraform Backend'): ")
        val itemName = readLine()?.takeIf { it.isNotBlank() } ?: "Cloudflare R2 Terraform Backend"

        // Get the item
        println("${BLUE}Fetching credentials from Bitwarden...${RESET}")
        val item = bitwardenRepository.getItem(itemName, session)

        if (item == null) {
            println("${RED}Error:${RESET} Item '$itemName' not found in Bitwarden.")
            println()
            println("${YELLOW}Available items (first 10):${RESET}")
            val items = bitwardenRepository.listItems(session)
            items.take(10).forEach { println("  - ${it.name}") }
            println()
            println("${BLUE}Note:${RESET} If you're using Bitwarden projects (BW_PROJECT in .env),")
            println("consider using the SDK-based command instead:")
            println("  ${BLUE}export BWS_ACCESS_TOKEN=<your-token>${RESET}")
            println("  ${BLUE}./gradlew run --args=\"setup-r2-sdk\"${RESET}")
            return 1
        }

        // Extract credentials
        val accessKey = item.getFieldValue("access_key")
        val secretKey = item.getFieldValue("secret_key")
        val accountId = item.getFieldValue("account_id")
        val bucketName = item.getFieldValue("bucket_name") ?: "kigawa-infra-state"

        // Validate credentials
        if (accessKey == null || secretKey == null || accountId == null) {
            println("${RED}Error:${RESET} Missing required fields in Bitwarden item.")
            println()
            println("${YELLOW}Required fields:${RESET}")
            println("  - access_key")
            println("  - secret_key")
            println("  - account_id")
            println("  - bucket_name (optional, defaults to 'kigawa-infra-state')")
            println()
            println("${BLUE}Current fields:${RESET}")
            item.fields.forEach { field ->
                val displayValue = if (field.type == 1) "***" else field.value
                println("  - ${field.name}: $displayValue")
            }
            return 1
        }

        println("${GREEN}✓${RESET} Credentials retrieved successfully")
        println()

        // Prompt for environment
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

        // Create backend config
        val config = R2BackendConfig(
            bucket = bucketName,
            key = stateKey,
            endpoint = "https://$accountId.r2.cloudflarestorage.com",
            accessKey = accessKey,
            secretKey = secretKey
        )

        // Save to file
        println("${BLUE}Creating backend configuration file...${RESET}")
        val backendConfigFile = File(backendFile)
        backendConfigFile.parentFile?.mkdirs()
        backendConfigFile.writeText(config.toTfvarsContent())

        // Set file permissions (owner read/write only)
        backendConfigFile.setReadable(true, true)
        backendConfigFile.setWritable(true, true)

        println("${GREEN}✓${RESET} Backend configuration saved to: $backendFile")
        println()

        // Show next steps
        println("${BLUE}=== Next Steps ===${RESET}")
        println()
        println("1. Initialize Terraform with R2 backend:")
        println("   ${GREEN}./terraform.sh init prod${RESET}")
        println()
        println("2. If migrating from local state, Terraform will ask:")
        println("   ${YELLOW}\"Do you want to copy existing state to the new backend?\"${RESET}")
        println("   Answer: ${GREEN}yes${RESET}")
        println()
        println("3. Verify the setup:")
        println("   ${GREEN}./terraform.sh plan prod${RESET}")
        println()

        println("${GREEN}Setup complete!${RESET}")

        return 0
    }

    override fun requiresEnvironment(): Boolean = false

    override fun getDescription(): String {
        return "Setup Cloudflare R2 backend using Bitwarden credentials"
    }
}
