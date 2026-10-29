package com.dlinii.app

data class DliniiHudState(
    val navigating: Boolean = false,
    val arrow: String = "↑",
    val instruction: String = "افتح دلّيني وابدأ الملاحة",
    val street: String = "",
    val eta: String = "—",
    val remainingKm: String = "—",
    val remainingMinutes: String = "—",
    val speedKmh: Int = 0,
    val destination: String = ""
)

object DliniiCarHudStore {
    private val listeners = mutableSetOf<() -> Unit>()
    var state = DliniiHudState()
        private set

    fun update(arguments: Map<String, Any?>?) {
        if (arguments == null) return
        fun text(key: String, fallback: String): String =
            arguments[key]?.toString() ?: fallback
        state = DliniiHudState(
            navigating = arguments["navigating"] as? Boolean ?: false,
            arrow = text("arrow", "↑"),
            instruction = text("instruction", "—"),
            street = text("street", ""),
            eta = text("eta", "—"),
            remainingKm = text("remainingKm", "—"),
            remainingMinutes = text("remainingMinutes", "—"),
            speedKmh = (arguments["speedKmh"] as? Number)?.toInt() ?: 0,
            destination = text("destination", "")
        )
        listeners.toList().forEach { it() }
    }

    fun clear() {
        state = DliniiHudState()
        listeners.toList().forEach { it() }
    }

    fun addListener(listener: () -> Unit) = listeners.add(listener)
    fun removeListener(listener: () -> Unit) = listeners.remove(listener)
}