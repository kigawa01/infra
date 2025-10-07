package net.kigawa.kinfra.domain

data class R2BackendConfig(
    val bucket: String,
    val key: String,
    val region: String = "auto",
    val endpoint: String,
    val accessKey: String,
    val secretKey: String
) {
    fun toTfvarsContent(): String {
        return """
            bucket     = "$bucket"
            key        = "$key"
            region     = "$region"
            endpoint   = "$endpoint"
            access_key = "$accessKey"
            secret_key = "$secretKey"
        """.trimIndent()
    }
}
