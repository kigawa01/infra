plugins {
    kotlin("plugin.serialization") version "1.9.0"
}

// Bitwarden SDK (bws CLI を使用するため不要)
// repositories {
//     maven {
//         url = uri("https://maven.pkg.github.com/bitwarden/sdk-sm")
//         credentials {
//             username = project.findProperty("gpr.user") as String? ?: System.getenv("GITHUB_USERNAME") ?: "dummy"
//             password = project.findProperty("gpr.key") as String? ?: System.getenv("GITHUB_TOKEN") ?: "dummy"
//         }
//     }
// }

dependencies {
    implementation(project(":model"))
    implementation(project(":action"))
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.0")
    implementation("com.google.code.gson:gson:2.10.1")
    // Bitwarden Secret Manager: bws CLI を使用（自動インストール機能あり）
    // implementation("com.bitwarden:sdk-secrets:1.0.1")
}
