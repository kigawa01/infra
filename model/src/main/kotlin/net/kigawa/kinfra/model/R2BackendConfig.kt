package net.kigawa.kinfra.model

data class R2BackendConfig(
    val bucket: String,
    val key: String,
    val endpoint: String,
    val accessKey: String,
    val secretKey: String
) {
    fun toTfvarsContent(): String {
        return """
            |bucket     = "$bucket"
            |key        = "$key"
            |region     = "auto"
            |endpoints = {
            |  s3 = "$endpoint"
            |}
            |access_key = "$accessKey"
            |secret_key = "$secretKey"
        """.trimMargin()
    }
}
