package net.kigawa.kinfra.model

/**
 * Terraform環境を表すドメインモデル
 */
data class Environment(
    val name: String
) {
    companion object {
        val PROD = Environment("prod")

        fun fromString(name: String): Environment? {
            return when (name) {
                "prod" -> PROD
                else -> null
            }
        }

        fun isValid(name: String): Boolean {
            return name == "prod"
        }
    }
}