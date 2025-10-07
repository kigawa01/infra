plugins {
    `kotlin-dsl`
}

repositories {
    mavenCentral()
    gradlePluginPortal()
}
val kotlinVersion = "2.2.0"
fun pluginId(pluginName: String, version: String) = "$pluginName:$pluginName.gradle.plugin:$version"
fun kotlinPluginId(pluginName: String, version: String = kotlinVersion) =
    pluginId("org.jetbrains.kotlin.$pluginName", kotlinVersion)

fun kotlinId(id: String) = "org.jetbrains.kotlin:$id:$kotlinVersion"
dependencies {
    implementation(kotlinPluginId("jvm"))
    implementation(pluginId("com.github.johnrengelman.shadow", "8.1.1"))
}
