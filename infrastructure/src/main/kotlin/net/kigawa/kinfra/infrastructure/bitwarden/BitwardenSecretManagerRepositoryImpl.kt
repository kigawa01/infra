package net.kigawa.kinfra.infrastructure.bitwarden

import com.google.gson.Gson
import com.google.gson.JsonObject
import net.kigawa.kinfra.domain.BitwardenSecret
import net.kigawa.kinfra.infrastructure.process.ProcessExecutor
import java.io.File
import java.net.URL
import java.nio.file.Files
import java.nio.file.StandardCopyOption

/**
 * Bitwarden Secret Manager CLI (bws) を使った実装
 */
class BitwardenSecretManagerRepositoryImpl(
    private val accessToken: String,
    private val processExecutor: ProcessExecutor,
    private val projectId: String? = null
) : BitwardenSecretManagerRepository {

    private val gson = Gson()
    private val bwsPath: String

    init {
        // bws CLI の自動インストールとパス取得
        bwsPath = ensureBwsInstalled()
    }

    /**
     * bws CLI がインストールされているか確認し、なければインストール
     */
    private fun ensureBwsInstalled(): String {
        // まず PATH から bws を探す
        val checkResult = processExecutor.execute(arrayOf("command", "-v", "bws"), null)
        if (checkResult.exitCode == 0) {
            return "bws"
        }

        // ローカルの bin ディレクトリに bws をインストール
        val homeDir = System.getProperty("user.home")
        val binDir = File(homeDir, ".local/bin")
        binDir.mkdirs()

        val bwsFile = File(binDir, "bws")
        if (bwsFile.exists() && bwsFile.canExecute()) {
            return bwsFile.absolutePath
        }

        println("bws CLI not found. Installing...")

        // OS とアーキテクチャを検出
        val os = System.getProperty("os.name").lowercase()
        val arch = System.getProperty("os.arch").lowercase()

        val (platform, extension) = when {
            os.contains("linux") && (arch.contains("amd64") || arch.contains("x86_64")) -> "x86_64-unknown-linux-gnu" to ""
            os.contains("linux") && arch.contains("aarch64") -> "aarch64-unknown-linux-gnu" to ""
            os.contains("mac") && arch.contains("aarch64") -> "aarch64-apple-darwin" to ""
            os.contains("mac") && (arch.contains("x86_64") || arch.contains("amd64")) -> "x86_64-apple-darwin" to ""
            os.contains("windows") -> "x86_64-pc-windows-msvc" to ".exe"
            else -> throw IllegalStateException("Unsupported platform: $os $arch")
        }

        // 最新バージョンをダウンロード
        val downloadUrl = "https://github.com/bitwarden/sdk-sm/releases/latest/download/bws-$platform$extension"
        println("Downloading bws from $downloadUrl...")

        try {
            val url = URL(downloadUrl)
            url.openStream().use { input ->
                Files.copy(input, bwsFile.toPath(), StandardCopyOption.REPLACE_EXISTING)
            }
            bwsFile.setExecutable(true)
            println("✓ bws CLI installed successfully to ${bwsFile.absolutePath}")
            return bwsFile.absolutePath
        } catch (e: Exception) {
            throw IllegalStateException("Failed to download bws CLI: ${e.message}", e)
        }
    }

    override fun listSecrets(): List<BitwardenSecret> {
        return try {
            val result = processExecutor.executeWithOutput(
                arrayOf(bwsPath, "secret", "list", "--access-token", accessToken, "--output", "json"),
                null
            )

            if (result.exitCode != 0) {
                println("Error listing secrets: ${result.error}")
                return emptyList()
            }

            val jsonArray = gson.fromJson(result.output, Array<JsonObject>::class.java)
            val allSecrets = jsonArray.map { json ->
                BitwardenSecret(
                    id = json.get("id").asString,
                    organizationId = json.get("organizationId")?.asString ?: "",
                    projectId = json.get("projectId")?.asString,
                    key = json.get("key").asString,
                    value = json.get("value").asString,
                    note = json.get("note")?.asString ?: "",
                    creationDate = json.get("creationDate")?.asString ?: "",
                    revisionDate = json.get("revisionDate")?.asString ?: ""
                )
            }

            // プロジェクトIDが指定されている場合はフィルタリング
            if (projectId != null) {
                allSecrets.filter { it.projectId == projectId }
            } else {
                allSecrets
            }
        } catch (e: Exception) {
            println("Exception listing secrets: ${e.message}")
            emptyList()
        }
    }

    override fun getSecret(id: String): BitwardenSecret? {
        return try {
            val result = processExecutor.executeWithOutput(
                arrayOf(bwsPath, "secret", "get", id, "--access-token", accessToken, "--output", "json"),
                null
            )

            if (result.exitCode != 0) {
                return null
            }

            val json = gson.fromJson(result.output, JsonObject::class.java)
            BitwardenSecret(
                id = json.get("id").asString,
                organizationId = json.get("organizationId")?.asString ?: "",
                projectId = json.get("projectId")?.asString,
                key = json.get("key").asString,
                value = json.get("value").asString,
                note = json.get("note")?.asString ?: "",
                creationDate = json.get("creationDate")?.asString ?: "",
                revisionDate = json.get("revisionDate")?.asString ?: ""
            )
        } catch (e: Exception) {
            null
        }
    }

    override fun findSecretByKey(key: String): BitwardenSecret? {
        return listSecrets().firstOrNull { it.key == key }
    }

    override fun close() {
        // bws CLI はステートレスなので特にクリーンアップ不要
    }
}
