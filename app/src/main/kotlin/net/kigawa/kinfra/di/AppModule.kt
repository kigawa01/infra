package net.kigawa.kinfra.di

import net.kigawa.kinfra.TerraformRunner
import net.kigawa.kinfra.action.EnvironmentValidator
import net.kigawa.kinfra.action.TerraformService
import net.kigawa.kinfra.commands.*
import net.kigawa.kinfra.domain.Command
import net.kigawa.kinfra.infrastructure.file.FileRepository
import net.kigawa.kinfra.infrastructure.file.FileRepositoryImpl
import net.kigawa.kinfra.infrastructure.process.ProcessExecutor
import net.kigawa.kinfra.infrastructure.process.ProcessExecutorImpl
import net.kigawa.kinfra.infrastructure.service.TerraformServiceImpl
import net.kigawa.kinfra.infrastructure.terraform.TerraformRepository
import net.kigawa.kinfra.infrastructure.terraform.TerraformRepositoryImpl
import net.kigawa.kinfra.infrastructure.bitwarden.BitwardenRepository
import net.kigawa.kinfra.infrastructure.bitwarden.BitwardenRepositoryImpl
import net.kigawa.kinfra.infrastructure.bitwarden.BitwardenSecretManagerRepository
import net.kigawa.kinfra.infrastructure.bitwarden.BitwardenSecretManagerRepositoryImpl
import net.kigawa.kinfra.infrastructure.validator.EnvironmentValidatorImpl
import org.koin.core.qualifier.named
import org.koin.dsl.module

val appModule = module {
    // Infrastructure layer
    single<FileRepository> { FileRepositoryImpl() }
    single<ProcessExecutor> { ProcessExecutorImpl() }
    single<TerraformRepository> { TerraformRepositoryImpl(get()) }
    single<EnvironmentValidator> { EnvironmentValidatorImpl() }
    single<TerraformService> { TerraformServiceImpl(get(), get()) }
    single<BitwardenRepository> { BitwardenRepositoryImpl(get()) }

    // Bitwarden Secret Manager (環境変数 BWS_ACCESS_TOKEN がある場合のみ初期化)
    val bwsAccessToken = System.getenv("BWS_ACCESS_TOKEN")
    val hasBwsToken = bwsAccessToken != null && bwsAccessToken.isNotBlank()

    if (hasBwsToken) {
        single<BitwardenSecretManagerRepository> {
            BitwardenSecretManagerRepositoryImpl(bwsAccessToken!!, get())
        }
    }

    // Presentation layer
    single<TerraformRunner> { TerraformRunner() }

    // Commands that don't require environment
    single<Command>(named("fmt")) { FormatCommand(get()) }
    single<Command>(named("validate")) { ValidateCommand(get()) }
    single<Command>(named("setup-r2")) { SetupR2Command(get()) }

    // SDK-based commands (only if BWS_ACCESS_TOKEN is available)
    if (hasBwsToken) {
        single<Command>(named("setup-r2-sdk")) { SetupR2CommandWithSDK(get()) }
    }

    // Commands that require environment
    single<Command>(named("init")) { InitCommand(get(), get()) }
    single<Command>(named("plan")) { PlanCommand(get(), get()) }
    single<Command>(named("apply")) { ApplyCommand(get(), get()) }
    single<Command>(named("destroy")) { DestroyCommand(get(), get()) }
    single<Command>(named("deploy")) { DeployCommand(get(), get(), get()) }

    // SDK-based deploy (only if BWS_ACCESS_TOKEN is available)
    if (hasBwsToken) {
        single<Command>(named("deploy-sdk")) { DeployCommandWithSDK(get(), get(), get()) }
    }

    // Help command needs access to all commands
    single<Command>(named("help")) {
        val commandMap = mutableMapOf(
            "fmt" to get<Command>(named("fmt")),
            "validate" to get<Command>(named("validate")),
            "setup-r2" to get<Command>(named("setup-r2")),
            "init" to get<Command>(named("init")),
            "plan" to get<Command>(named("plan")),
            "apply" to get<Command>(named("apply")),
            "destroy" to get<Command>(named("destroy")),
            "deploy" to get<Command>(named("deploy"))
        )

        // SDK-based commands (only if BWS_ACCESS_TOKEN is available)
        if (hasBwsToken) {
            commandMap["setup-r2-sdk"] = get<Command>(named("setup-r2-sdk"))
            commandMap["deploy-sdk"] = get<Command>(named("deploy-sdk"))
        }

        HelpCommand(commandMap)
    }
}