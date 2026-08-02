package com.togplay.vaimarcia.wear.domain

/** The five "Modo Jogo" categories — fixed set for the glanceable big-button grid. */
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
