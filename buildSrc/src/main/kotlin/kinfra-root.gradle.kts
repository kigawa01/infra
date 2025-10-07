plugins {
    application
    id("com.github.johnrengelman.shadow") version "8.1.1"
}
allprojects {
    group = "net.kigawa.kinfra"
    apply(plugin = "kinfra-common")
}
