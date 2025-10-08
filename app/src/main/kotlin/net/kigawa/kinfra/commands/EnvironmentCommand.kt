package net.kigawa.kinfra.commands

import net.kigawa.kinfra.model.Command

abstract class EnvironmentCommand : Command {
    companion object {
        const val RESET = "\u001B[0m"
        const val RED = "\u001B[31m"
        const val GREEN = "\u001B[32m"
        const val YELLOW = "\u001B[33m"
        const val BLUE = "\u001B[34m"
    }

    override fun requiresEnvironment(): Boolean = true

    protected fun printInfo(message: String) {
        println("${BLUE}$message${RESET}")
    }
}
