package net.kigawa.kinfra.di

import net.kigawa.kinfra.TerraformRunner
import net.kigawa.kinfra.action.EnvironmentValidator
import net.kigawa.kinfra.action.TerraformService
import net.kigawa.kinfra.commands.*
import net.kigawa.kinfra.model.Command
import net.kigawa.kinfra.model.CommandType
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
import net.kigawa.kinfra.infrastructure.config.EnvFileLoader
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
            // .env から BW_PROJECT を読み込む
            val projectId = EnvFileLoader.get("BW_PROJECT")
            BitwardenSecretManagerRepositoryImpl(bwsAccessToken!!, get(), projectId)
        }
    }

    // Presentation layer
    single<TerraformRunner> { TerraformRunner() }

    // Commands that don't require environment
    single<Command>(named(CommandType.FMT.commandName)) { FormatCommand(get()) }
    single<Command>(named(CommandType.VALIDATE.commandName)) { ValidateCommand(get()) }
    single<Command>(named(CommandType.LOGIN.commandName)) { LoginCommand(get()) }
    single<Command>(named(CommandType.SETUP_R2.commandName)) { SetupR2Command(get()) }

    // SDK-based commands (only if BWS_ACCESS_TOKEN is available)
    if (hasBwsToken) {
        single<Command>(named(CommandType.SETUP_R2_SDK.commandName)) { SetupR2CommandWithSDK(get()) }
    }

    // Commands that require environment
    single<Command>(named(CommandType.INIT.commandName)) { InitCommand(get(), get()) }
    single<Command>(named(CommandType.PLAN.commandName)) { PlanCommand(get(), get()) }
    single<Command>(named(CommandType.APPLY.commandName)) { ApplyCommand(get(), get()) }
    single<Command>(named(CommandType.DESTROY.commandName)) { DestroyCommand(get(), get()) }
    single<Command>(named(CommandType.DEPLOY.commandName)) { DeployCommand(get(), get(), get()) }

    // SDK-based deploy (only if BWS_ACCESS_TOKEN is available)
    if (hasBwsToken) {
        single<Command>(named(CommandType.DEPLOY_SDK.commandName)) { DeployCommandWithSDK(get(), get(), get()) }
    }

    // Help command needs access to all commands
    single<Command>(named(CommandType.HELP.commandName)) {
        val commandMap = buildMap<String, Command> {
            CommandType.entries.forEach { commandType ->
                if (commandType != CommandType.HELP) {
                    runCatching {
                        put(commandType.commandName, get<Command>(named(commandType.commandName)))
                    }
                }
            }
        }

        HelpCommand(commandMap)
    }
}