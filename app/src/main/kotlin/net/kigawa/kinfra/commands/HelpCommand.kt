package net.kigawa.kinfra.commands

import net.kigawa.kinfra.model.Command

class HelpCommand(private val commands: Map<String, Command>) : Command {
    companion object {
        const val RESET = "\u001B[0m"
        const val BLUE = "\u001B[34m"
    }

    override fun execute(args: Array<String>): Int {
        println("${BLUE}Usage:${RESET} java -jar app.jar [command] [options]")
        println()
        println("${BLUE}Commands:${RESET}")

        commands.forEach { (name, command) ->
            val padding = " ".repeat(maxOf(0, 10 - name.length))
            println("  $name$padding - ${command.getDescription()}")
        }

        println()
        println("${BLUE}Environment:${RESET}")
        println("  prod       - Production environment (automatically selected)")
        println()
        println("${BLUE}Options:${RESET}")
        println("  -auto-approve  - Skip interactive approval (for apply/destroy)")
        println("  -var-file      - Specify a variable file")
        println()
        println("${BLUE}Examples:${RESET}")
        println("  java -jar app.jar init")
        println("  java -jar app.jar plan")
        println("  java -jar app.jar apply")
        println("  java -jar app.jar deploy")
        println("  java -jar app.jar deploy -auto-approve")
        println("  java -jar app.jar destroy -auto-approve")
        println("  java -jar app.jar fmt")
        println("  java -jar app.jar validate")

        return 0
    }

    override fun getDescription(): String {
        return "Show this help message"
    }

    override fun requiresEnvironment(): Boolean {
        return false
    }
}
