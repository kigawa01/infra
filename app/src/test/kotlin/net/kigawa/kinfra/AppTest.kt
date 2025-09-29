package net.kigawa.kinfra

import net.kigawa.kinfra.di.appModule
import org.koin.core.context.startKoin
import org.koin.core.context.stopKoin
import org.koin.test.KoinTest
import org.koin.test.inject
import kotlin.test.Test
import kotlin.test.assertNotNull

class AppTest : KoinTest {
    @Test fun terraformRunnerCanBeCreated() {
        startKoin {
            modules(appModule)
        }

        try {
            val terraformRunner by inject<TerraformRunner>()
            assertNotNull(terraformRunner, "TerraformRunner should be created")
        } finally {
            stopKoin()
        }
    }
}
