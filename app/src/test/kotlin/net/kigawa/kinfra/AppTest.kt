package net.kigawa.kinfra

import kotlin.test.Test
import kotlin.test.assertNotNull

class AppTest {
    @Test fun terraformRunnerCanBeCreated() {
        val terraformRunner = TerraformRunner()
        assertNotNull(terraformRunner, "TerraformRunner should be created")
    }
}
