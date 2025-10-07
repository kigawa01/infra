package net.kigawa.kinfra.domain

data class BitwardenItem(
    val id: String,
    val name: String,
    val fields: List<BitwardenField>
) {
    fun getFieldValue(fieldName: String): String? {
        return fields.find { it.name == fieldName }?.value
    }
}

data class BitwardenField(
    val name: String,
    val value: String,
    val type: Int = 0  // 0 = text, 1 = hidden
)
