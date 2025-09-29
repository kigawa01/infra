package net.kigawa.kinfra

import net.kigawa.kinfra.di.appModule
import org.koin.core.context.startKoin
import org.koin.core.context.stopKoin
import org.koin.java.KoinJavaComponent.inject

fun main(args: Array<String>) {
    startKoin {
        modules(appModule)
    }

    try {
        val terraformRunner by inject<TerraformRunner>(TerraformRunner::class.java)
        terraformRunner.run(args)
    } finally {
        stopKoin()
    }
}
