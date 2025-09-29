package net.kigawa.kinfra

interface Command {
    fun execute(args: Array<String>): Int
    fun getDescription(): String
    fun requiresEnvironment(): Boolean
}