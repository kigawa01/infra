package net.kigawa.kinfra.commands

import net.kigawa.kinfra.infrastructure.config.ConfigRepository
import net.kigawa.kinfra.infrastructure.logging.Logger
import net.kigawa.kinfra.infrastructure.terraform.TerraformVarsManager
import net.kigawa.kinfra.model.Command
import net.kigawa.kinfra.model.HostConfig
import net.kigawa.kinfra.model.HostsConfig

class ConfigCommand(
    private val configRepository: ConfigRepository,
    private val logger: Logger,
    private val terraformVarsManager: TerraformVarsManager
) : Command {

    companion object {
        const val RESET = "\u001B[0m"
        const val RED = "\u001B[31m"
        const val GREEN = "\u001B[32m"
        const val YELLOW = "\u001B[33m"
        const val BLUE = "\u001B[34m"
        const val CYAN = "\u001B[36m"
    }

    override fun execute(args: Array<String>): Int {
        logger.info("Executing config command with args: ${args.joinToString(" ")}")

        if (args.isEmpty()) {
            printUsage()
            return 1
        }

        return when (args[0]) {
            "list" -> listHosts()
            "enable" -> {
                if (args.size < 2) {
                    println("${RED}Error:${RESET} Host name is required")
                    println("Usage: config enable <host-name>")
                    return 1
                }
                enableHost(args[1])
            }
            "disable" -> {
                if (args.size < 2) {
                    println("${RED}Error:${RESET} Host name is required")
                    println("Usage: config disable <host-name>")
                    return 1
                }
                disableHost(args[1])
            }
            else -> {
                println("${RED}Error:${RESET} Unknown subcommand: ${args[0]}")
                printUsage()
                1
            }
        }
    }

    override fun getDescription(): String {
        return "Manage host configuration (enable/disable hosts)"
    }

    override fun requiresEnvironment(): Boolean {
        return false
    }

    private fun printUsage() {
        println("${BLUE}Usage:${RESET}")
        println("  config list                  - List all hosts and their status")
        println("  config enable <host-name>    - Enable a host")
        println("  config disable <host-name>   - Disable a host")
        println()
        println("${BLUE}Available hosts:${RESET}")
        HostsConfig.DEFAULT_HOSTS.keys.forEach { host ->
            println("  - $host")
        }
    }

    private fun listHosts(): Int {
        val config = configRepository.loadHostsConfig()
        val configPath = configRepository.getConfigFilePath()

        println("${BLUE}Host Configuration${RESET}")
        println("${CYAN}Config file: $configPath${RESET}")
        println()

        val hosts = mutableListOf<HostConfig>()
        HostsConfig.DEFAULT_HOSTS.keys.forEach { hostName ->
            val enabled = config.hosts[hostName] ?: HostsConfig.DEFAULT_HOSTS[hostName] ?: false
            val description = HostsConfig.HOST_DESCRIPTIONS[hostName] ?: "No description"
            hosts.add(HostConfig(hostName, enabled, description))
        }

        hosts.forEach { host ->
            val status = if (host.enabled) "${GREEN}enabled${RESET}" else "${YELLOW}disabled${RESET}"
            println("  ${host.name.padEnd(15)} [$status]  ${host.description}")
        }

        return 0
    }

    private fun enableHost(hostName: String): Int {
        if (!HostsConfig.DEFAULT_HOSTS.containsKey(hostName)) {
            println("${RED}Error:${RESET} Unknown host: $hostName")
            println()
            println("${BLUE}Available hosts:${RESET}")
            HostsConfig.DEFAULT_HOSTS.keys.forEach { host ->
                println("  - $host")
            }
            return 1
        }

        val config = configRepository.loadHostsConfig()
        val updatedHosts = config.hosts.toMutableMap()
        updatedHosts[hostName] = true

        configRepository.saveHostsConfig(HostsConfig(updatedHosts))
        logger.info("Host $hostName enabled")

        // Terraform変数ファイルを更新
        terraformVarsManager.updateHostsVars()
        val varsPath = terraformVarsManager.getVarsFilePath()
        logger.info("Updated Terraform vars file: $varsPath")

        println("${GREEN}✓${RESET} Host ${CYAN}$hostName${RESET} has been ${GREEN}enabled${RESET}")
        println("${CYAN}Updated Terraform vars: $varsPath${RESET}")
        println("${BLUE}Note:${RESET} Run 'init' and 'apply' to apply changes to Terraform infrastructure")

        return 0
    }

    private fun disableHost(hostName: String): Int {
        if (!HostsConfig.DEFAULT_HOSTS.containsKey(hostName)) {
            println("${RED}Error:${RESET} Unknown host: $hostName")
            println()
            println("${BLUE}Available hosts:${RESET}")
            HostsConfig.DEFAULT_HOSTS.keys.forEach { host ->
                println("  - $host")
            }
            return 1
        }

        val config = configRepository.loadHostsConfig()
        val updatedHosts = config.hosts.toMutableMap()
        updatedHosts[hostName] = false

        configRepository.saveHostsConfig(HostsConfig(updatedHosts))
        logger.info("Host $hostName disabled")

        // Terraform変数ファイルを更新
        terraformVarsManager.updateHostsVars()
        val varsPath = terraformVarsManager.getVarsFilePath()
        logger.info("Updated Terraform vars file: $varsPath")

        println("${GREEN}✓${RESET} Host ${CYAN}$hostName${RESET} has been ${YELLOW}disabled${RESET}")
        println("${CYAN}Updated Terraform vars: $varsPath${RESET}")
        println("${BLUE}Note:${RESET} Run 'init' and 'apply' to apply changes to Terraform infrastructure")

        return 0
    }
}