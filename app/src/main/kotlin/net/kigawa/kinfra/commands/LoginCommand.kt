package net.kigawa.kinfra.commands

import net.kigawa.kinfra.domain.Command
import net.kigawa.kinfra.infrastructure.bitwarden.BitwardenRepository
import java.io.File

class LoginCommand(
    private val bitwardenRepository: BitwardenRepository
) : Command {

    companion object {
        const val RESET = "\u001B[0m"
        const val RED = "\u001B[31m"
        const val GREEN = "\u001B[32m"
        const val YELLOW = "\u001B[33m"
        const val BLUE = "\u001B[34m"
        private const val SESSION_FILE = ".bw_session"
    }

    override fun execute(args: Array<String>): Int {
        println("${BLUE}=== Bitwarden Login ===${RESET}")
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

        // Check if already logged in
        if (bitwardenRepository.isLoggedIn()) {
            println("${GREEN}✓${RESET} Already logged in to Bitwarden")
            println()
            println("${BLUE}Unlocking vault...${RESET}")
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

            // Save session to file
            try {
                val sessionFile = File(SESSION_FILE)
                sessionFile.writeText(session)
                sessionFile.setReadable(false, false)
                sessionFile.setReadable(true, true)
                sessionFile.setWritable(false, false)
                sessionFile.setWritable(true, true)
                println("${GREEN}✓${RESET} Vault unlocked successfully")
                println("${GREEN}✓${RESET} Session saved to ${sessionFile.absolutePath}")
                println()
                println("${BLUE}To use the session, run:${RESET}")
                println("  export BW_SESSION=\$(cat ${SESSION_FILE})")
            } catch (e: Exception) {
                println("${RED}Error:${RESET} Failed to save session: ${e.message}")
                return 1
            }
            return 0
        }

        println("${YELLOW}Not logged in to Bitwarden.${RESET}")
        println("${BLUE}Please run:${RESET} bw login")
        println()
        println("After logging in, run this command again to unlock your vault.")

        return 1
    }

    override fun requiresEnvironment(): Boolean = false

    override fun getDescription(): String {
        return "Login and unlock Bitwarden vault"
    }
}
