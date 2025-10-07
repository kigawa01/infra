package net.kigawa.kinfra.domain

/**
 * Bitwarden Secret Manager のシークレット
 */
data class BitwardenSecret(
    val id: String,
    val organizationId: String,
    val projectId: String?,
    val key: String,
    val value: String,
    val note: String,
    val creationDate: String,
    val revisionDate: String
)
