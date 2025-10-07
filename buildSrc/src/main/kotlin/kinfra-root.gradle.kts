plugins {
    application
    id("com.github.johnrengelman.shadow")
}
allprojects {
    group = "net.kigawa.kinfra"
    apply(plugin = "kinfra-common")
}

application {
    mainClass = "net.kigawa.kinfra.AppKt"
}