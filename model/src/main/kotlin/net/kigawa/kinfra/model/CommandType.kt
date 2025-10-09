package net.kigawa.kinfra.model

enum class CommandType(val commandName: String) {
    FMT("fmt"),
    VALIDATE("validate"),
    LOGIN("login"),
    SETUP_R2("setup-r2"),
    SETUP_R2_SDK("setup-r2-sdk"),
    CONFIG("config"),
    INIT("init"),
    PLAN("plan"),
    APPLY("apply"),
    DESTROY("destroy"),
    DEPLOY("deploy"),
    DEPLOY_SDK("deploy-sdk"),
    HELP("help");

    companion object {
        fun fromString(name: String): CommandType? {
            return entries.find { it.commandName == name }
        }
    }
}
