package net.kigawa.kinfra.infrastructure.bitwarden

import net.kigawa.kinfra.model.BitwardenSecret

/**
 * Bitwarden Secret Manager SDK を使ったシークレット管理リポジトリ
 */
interface BitwardenSecretManagerRepository {
    /**
     * すべてのシークレットを取得
     */
    fun listSecrets(): List<BitwardenSecret>

    /**
     * ID でシークレットを取得
     */
    fun getSecret(id: String): BitwardenSecret?

    /**
     * キー名でシークレットを検索
     */
    fun findSecretByKey(key: String): BitwardenSecret?

    /**
     * リソースをクリーンアップ
     */
    fun close()
}
