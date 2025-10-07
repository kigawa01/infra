package net.kigawa.kinfra.infrastructure.bitwarden

import kotlinx.serialization.json.*
import net.kigawa.kinfra.domain.BitwardenField
import net.kigawa.kinfra.domain.BitwardenItem
import net.kigawa.kinfra.infrastructure.process.ProcessExecutor
import java.io.File

class BitwardenRepositoryImpl(
    private val processExecutor: ProcessExecutor
) : BitwardenRepository {

    override fun isInstalled(): Boolean {
        val result = processExecutor.execute(args = arrayOf("command", "-v", "bw"))
        return result.exitCode == 0
    }

    override fun isLoggedIn(): Boolean {
        val result = processExecutor.execute(args = arrayOf("bw", "login", "--check"))
        return result.exitCode == 0
    }

    override fun unlock(password: String): String? {
        // Create a temporary file with password
        val passwordFile = File.createTempFile("bw_password", ".tmp")
        try {
            passwordFile.writeText(password)
            passwordFile.setReadable(true, true)  // Owner read only

            val result = processExecutor.execute(
                args = arrayOf("sh", "-c", "cat ${passwordFile.absolutePath} | bw unlock --raw")
            )

            return if (result.exitCode == 0) {
                result.output.trim()
            } else {
                null
            }
        } finally {
            passwordFile.delete()
        }
    }

    override fun getItem(itemName: String, session: String): BitwardenItem? {
        val result = processExecutor.execute(
            args = arrayOf("bw", "get", "item", itemName, "--session", session)
        )

        if (result.exitCode != 0) {
            return null
        }

        return try {
            parseItem(result.output)
        } catch (e: Exception) {
            null
        }
    }

    override fun listItems(session: String): List<BitwardenItem> {
        val result = processExecutor.execute(
            args = arrayOf("bw", "list", "items", "--session", session)
        )

        if (result.exitCode != 0) {
            return emptyList()
        }

        return try {
            val json = Json.parseToJsonElement(result.output)
            json.jsonArray.mapNotNull { parseItem(it.toString()) }
        } catch (e: Exception) {
            emptyList()
        }
    }

    private fun parseItem(jsonString: String): BitwardenItem? {
        return try {
            val json = Json.parseToJsonElement(jsonString).jsonObject

            val id = json["id"]?.jsonPrimitive?.content ?: return null
            val name = json["name"]?.jsonPrimitive?.content ?: return null

            val fields = json["fields"]?.jsonArray?.mapNotNull { fieldElement ->
                val fieldObj = fieldElement.jsonObject
                val fieldName = fieldObj["name"]?.jsonPrimitive?.content ?: return@mapNotNull null
                val fieldValue = fieldObj["value"]?.jsonPrimitive?.content ?: return@mapNotNull null
                val fieldType = fieldObj["type"]?.jsonPrimitive?.int ?: 0

                BitwardenField(fieldName, fieldValue, fieldType)
            } ?: emptyList()

            BitwardenItem(id, name, fields)
        } catch (e: Exception) {
            null
        }
    }
}
