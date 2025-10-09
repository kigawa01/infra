package net.kigawa.kinfra.infrastructure.config

import com.google.gson.Gson
import com.google.gson.GsonBuilder
import net.kigawa.kinfra.model.HostsConfig
import java.io.File

class ConfigRepositoryImpl(
    configDir: String = System.getProperty("user.home") + "/.kinfra"
) : ConfigRepository {

    private val gson: Gson = GsonBuilder().setPrettyPrinting().create()
    private val configFile = File(configDir, "hosts.json")

    init {
        // 設定ディレクトリが存在しない場合は作成
        val dir = File(configDir)
        if (!dir.exists()) {
            dir.mkdirs()
        }
    }

    override fun loadHostsConfig(): HostsConfig {
        return if (configFile.exists()) {
            try {
                val json = configFile.readText()
                gson.fromJson(json, HostsConfig::class.java)
            } catch (e: Exception) {
                // ファイルの読み込みに失敗した場合はデフォルト設定を返す
                HostsConfig(HostsConfig.DEFAULT_HOSTS)
            }
        } else {
            // ファイルが存在しない場合はデフォルト設定を返す
            HostsConfig(HostsConfig.DEFAULT_HOSTS)
        }
    }

    override fun saveHostsConfig(config: HostsConfig) {
        val json = gson.toJson(config)
        configFile.writeText(json)
    }

    override fun getConfigFilePath(): String {
        return configFile.absolutePath
    }
}