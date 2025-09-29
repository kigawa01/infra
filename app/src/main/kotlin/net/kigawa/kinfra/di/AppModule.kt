package net.kigawa.kinfra.di

import net.kigawa.kinfra.TerraformRunner
import net.kigawa.kinfra.commands.*
import net.kigawa.kinfra.domain.Command
import org.koin.core.qualifier.named
import org.koin.dsl.module

val appModule = module {
    single<TerraformRunner> { TerraformRunner() }

    // Commands that don't require environment
    single<Command>(named("fmt")) { FormatCommand() }
    single<Command>(named("validate")) { ValidateCommand() }

    // Commands that require environment
    single<Command>(named("init")) { InitCommand() }
    single<Command>(named("plan")) { PlanCommand() }
    single<Command>(named("apply")) { ApplyCommand() }
    single<Command>(named("destroy")) { DestroyCommand() }
    single<Command>(named("deploy")) { DeployCommand() }

    // Help command needs access to all commands
    single<Command>(named("help")) {
        val commandMap = mapOf(
            "fmt" to get<Command>(named("fmt")),
            "validate" to get<Command>(named("validate")),
            "init" to get<Command>(named("init")),
            "plan" to get<Command>(named("plan")),
            "apply" to get<Command>(named("apply")),
            "destroy" to get<Command>(named("destroy")),
            "deploy" to get<Command>(named("deploy"))
        )
        HelpCommand(commandMap)
    }
}