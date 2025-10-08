package net.kigawa.kinfra.infrastructure.bitwarden

import com.google.gson.Gson
import com.google.gson.JsonObject
import com.google.gson.JsonParser
import net.kigawa.kinfra.infrastructure.process.ProcessExecutor
import net.kigawa.kinfra.model.BitwardenItem
import java.io.File

class BitwardenRepositoryImpl(
    private val processExecutor: ProcessExecutor
) : BitwardenRepository {

    companion object {
        private const val SESSION_FILE = ".bw_session"
    }

    private val gson = Gson()

    override fun isInstalled(): Boolean {
        val result = processExecutor.executeWithOutput(
            arrayOf("bw", "--version")
        )
        return result.exitCode == 0
    }

    override fun isLoggedIn(): Boolean {
        val result = processExecutor.executeWithOutput(
            arrayOf("bw", "status")
        )

        if (result.exitCode != 0) return false

        return try {
            val status = JsonParser.parseString(result.output).asJsonObject
            val statusValue = status.get("status")?.asString
            // "locked" or "unlocked" means logged in
            // "unauthenticated" means not logged in
            statusValue == "locked" || statusValue == "unlocked"
        } catch (e: Exception) {
            false
        }
    }

    override fun unlock(password: String): String? {
        val result = processExecutor.executeWithOutput(
            arrayOf("bw", "unlock", password, "--raw")
        )

        return if (result.exitCode == 0 && result.output.isNotBlank()) {
            result.output.trim()
        } else {
            null
        }
    }

    override fun getItem(itemName: String, session: String): BitwardenItem? {
        val result = processExecutor.executeWithOutput(
            arrayOf("bw", "get", "item", itemName),
            environment = mapOf("BW_SESSION" to session)
        )

        if (result.exitCode != 0) return null

        return try {
            parseItem(JsonParser.parseString(result.output).asJsonObject)
        } catch (e: Exception) {
            null
        }
    }

    override fun listItems(session: String): List<BitwardenItem> {
        val result = processExecutor.executeWithOutput(
            arrayOf("bw", "list", "items"),
            environment = mapOf("BW_SESSION" to session)
        )

        if (result.exitCode != 0) return emptyList()

        return try {
            val items = JsonParser.parseString(result.output).asJsonArray
            items.mapNotNull { element ->
                try {
                    parseItem(element.asJsonObject)
                } catch (e: Exception) {
                    null
                }
            }
        } catch (e: Exception) {
            emptyList()
        }
    }

    override fun getSessionFromFile(): String? {
        return try {
            val sessionFile = File(SESSION_FILE)
            if (sessionFile.exists() && sessionFile.canRead()) {
                sessionFile.readText().trim().takeIf { it.isNotBlank() }
            } else {
                null
            }
        } catch (e: Exception) {
            null
        }
    }

    override fun getSessionFromEnv(): String? {
        return System.getenv("BW_SESSION")?.takeIf { it.isNotBlank() }
    }

    private fun parseItem(json: JsonObject): BitwardenItem {
        val id = json.get("id")?.asString ?: ""
        val name = json.get("name")?.asString ?: ""

        val fields = mutableListOf<BitwardenItem.Field>()

        json.get("fields")?.asJsonArray?.forEach { fieldElement ->
            val fieldObj = fieldElement.asJsonObject
            val fieldName = fieldObj.get("name")?.asString ?: ""
            val fieldValue = fieldObj.get("value")?.asString
            val fieldType = fieldObj.get("type")?.asInt ?: 0

            fields.add(BitwardenItem.Field(fieldName, fieldValue, fieldType))
        }

        return BitwardenItem(id, name, fields)
    }
}
