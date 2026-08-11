package com.togplay.vaimarcia.wear.domain

/** As cinco categorias do "Modo Jogo" — conjunto fixo para a grade de botões grandes de leitura rápida. */
enum class Category(val id: String, val emoji: String) {
    ENERGIA("energia", "🔥"),
    BORA("bora", "💪"),
    PALMAS("palmas", "👏"),
    HUMOR("humor", "😂"),
    FAVORITOS("favoritos", "❤️");

    companion object {
        fun fromId(id: String): Category? = entries.firstOrNull { it.id == id }
    }
}
