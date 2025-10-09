package net.kigawa.kinfra.model

data class HostConfig(
    val name: String,
    val enabled: Boolean,
    val description: String
)

data class HostsConfig(
    val hosts: Map<String, Boolean>
) {
    companion object {
        val DEFAULT_HOSTS = mapOf(
            "one_sakura" to true,
            "k8s4" to true,
            "lxc_nginx" to false
        )

        val HOST_DESCRIPTIONS = mapOf(
            "one_sakura" to "Nginx installation on Sakura VPS",
            "k8s4" to "Node Exporter installation on k8s4",
            "lxc_nginx" to "LXC Nginx installation"
        )
    }
}