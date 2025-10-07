plugins {
    kotlin("plugin.serialization") version "1.9.0"
}
dependencies {
    implementation(project(":model"))
    implementation(project(":action"))
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.0")
    implementation("com.google.code.gson:gson:2.10.1")
}
