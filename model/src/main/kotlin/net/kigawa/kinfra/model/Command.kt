package net.kigawa.kinfra.model

interface Command {
    fun execute(args: Array<String>): Int
    fun getDescription(): String
    fun requiresEnvironment(): Boolean
}
