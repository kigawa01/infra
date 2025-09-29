package net.kigawa.kinfra.commands

import net.kigawa.kinfra.domain.Command
import java.io.IOException

class ValidateCommand : Command {
    override fun execute(args: Array<String>): Int {
        return try {
            val process = ProcessBuilder("terraform", "validate")
                .inheritIO()
                .start()
            process.waitFor()
        } catch (e: IOException) {
            println("\u001B[31mError executing terraform validate: ${e.message}\u001B[0m")
            1
        }
    }

    override fun getDescription(): String {
        return "Validate the configuration files"
    }

    override fun requiresEnvironment(): Boolean {
        return false
    }
}
