package net.kigawa.kinfra.infrastructure.bitwarden

import net.kigawa.kinfra.model.BitwardenItem

interface BitwardenRepository {
    fun isInstalled(): Boolean
    fun isLoggedIn(): Boolean
    fun unlock(password: String): String?
    fun getItem(itemName: String, session: String): BitwardenItem?
    fun listItems(session: String): List<BitwardenItem>
    fun getSessionFromFile(): String?
    fun getSessionFromEnv(): String?
}
