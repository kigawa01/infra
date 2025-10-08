package net.kigawa.kinfra.model

data class BitwardenItem(
    val id: String,
    val name: String,
    val fields: List<Field>
) {
    data class Field(
        val name: String,
        val value: String?,
        val type: Int // 0 = text, 1 = hidden
    )

    fun getFieldValue(fieldName: String): String? {
        return fields.find { it.name == fieldName }?.value
    }
}
