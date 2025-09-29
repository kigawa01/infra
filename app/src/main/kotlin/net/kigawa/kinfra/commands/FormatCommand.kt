package net.kigawa.kinfra.commands

import net.kigawa.kinfra.Command
import java.io.IOException

class FormatCommand : Command {
    override fun execute(args: Array<String>): Int {
        return try {
            val process = ProcessBuilder("terraform", "fmt", "-recursive")
                .inheritIO()
                .start()
            process.waitFor()
        } catch (e: IOException) {
            println("\u001B[31mError executing terraform fmt: ${e.message}\u001B[0m")
            1
        }
    }

    override fun getDescription(): String {
        return "Reformat configuration files to canonical format"
    }

    override fun requiresEnvironment(): Boolean {
        return false
    }
}