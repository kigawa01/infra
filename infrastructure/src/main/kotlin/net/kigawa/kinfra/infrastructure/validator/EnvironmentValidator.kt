package net.kigawa.kinfra.infrastructure.validator

import net.kigawa.kinfra.action.EnvironmentValidator
import net.kigawa.kinfra.model.Environment

/**
 * 環境名のバリデーションを担当
 */
class EnvironmentValidatorImpl : EnvironmentValidator {
    override fun validate(environmentName: String): Environment? {
        return Environment.fromString(environmentName)
    }

    override fun isValid(environmentName: String): Boolean {
        return Environment.isValid(environmentName)
    }
}