package com.dlinii.app

import android.content.Intent
import android.content.pm.ApplicationInfo
import androidx.car.app.CarAppService
import androidx.car.app.CarContext
import androidx.car.app.Screen
import androidx.car.app.Session
import androidx.car.app.model.Action
import androidx.car.app.model.Pane
import androidx.car.app.model.PaneTemplate
import androidx.car.app.model.Row
import androidx.car.app.model.Template
import androidx.car.app.validation.HostValidator
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner

/** Companion HUD. Map rendering and NavigationManager trip integration are separate. */
class DliniiCarService : CarAppService() {
    override fun createHostValidator(): HostValidator =
        if ((applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0) {
            HostValidator.ALLOW_ALL_HOSTS_VALIDATOR
        } else {
            HostValidator.Builder(this)
                .addAllowedHosts(androidx.car.app.R.array.hosts_allowlist_sample)
                .build()
        }

    override fun onCreateSession(): Session = object : Session() {
        override fun onCreateScreen(intent: Intent): Screen = DliniiHudScreen(carContext)
    }
}

private class DliniiHudScreen(context: CarContext) : Screen(context), DefaultLifecycleObserver {
    private val refresh: () -> Unit = { invalidate() }
    init { lifecycle.addObserver(this) }
    override fun onStart(owner: LifecycleOwner) {
        DliniiCarHudStore.addListener(refresh)
        invalidate()
    }
    override fun onStop(owner: LifecycleOwner) {
        DliniiCarHudStore.removeListener(refresh)
    }
    override fun onGetTemplate(): Template {
        val hud = DliniiCarHudStore.state
        val pane = Pane.Builder()
            .addRow(Row.Builder()
                .setTitle(if (hud.navigating) hud.arrow + " " + hud.instruction else "دلّيني جاهز")
                .addText(if (hud.navigating) hud.street.ifBlank { "تابع التوجيه على الهاتف" }
                    else "ابدأ الرحلة من تطبيق دلّيني على الهاتف")
                .build())
        if (hud.navigating) {
            pane.addRow(Row.Builder().setTitle("الوقت والمسافة")
                .addText(hud.remainingMinutes + " دقيقة · " + hud.remainingKm + " كم · " + hud.eta).build())
            pane.addRow(Row.Builder().setTitle("السرعة الحالية")
                .addText(hud.speedKmh.toString() + " كم/س").build())
        }
        return PaneTemplate.Builder(pane.build()).setTitle("دلّيني")
            .setHeaderAction(Action.APP_ICON).build()
    }
}
