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

    // Presentation layer
    single<TerraformRunner> { TerraformRunner() }

    // Commands that don't require environment
    single<Command>(named("fmt")) { FormatCommand(get()) }
    single<Command>(named("validate")) { ValidateCommand(get()) }
    single<Command>(named("setup-r2")) { SetupR2Command(get()) }

    // Commands that require environment
    single<Command>(named("init")) { InitCommand(get(), get()) }
    single<Command>(named("plan")) { PlanCommand(get(), get()) }
    single<Command>(named("apply")) { ApplyCommand(get(), get()) }
    single<Command>(named("destroy")) { DestroyCommand(get(), get()) }
    single<Command>(named("deploy")) { DeployCommand(get(), get()) }

    // Help command needs access to all commands
    single<Command>(named("help")) {
        val commandMap = mapOf(
            "fmt" to get<Command>(named("fmt")),
            "validate" to get<Command>(named("validate")),
            "setup-r2" to get<Command>(named("setup-r2")),
            "init" to get<Command>(named("init")),
            "plan" to get<Command>(named("plan")),
            "apply" to get<Command>(named("apply")),
            "destroy" to get<Command>(named("destroy")),
            "deploy" to get<Command>(named("deploy"))
        )
        HelpCommand(commandMap)
    }
}