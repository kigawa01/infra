package net.kigawa.kinfra.infrastructure.config

import net.kigawa.kinfra.model.HostsConfig

interface ConfigRepository {
    fun loadHostsConfig(): HostsConfig
    fun saveHostsConfig(config: HostsConfig)
    fun getConfigFilePath(): String
}