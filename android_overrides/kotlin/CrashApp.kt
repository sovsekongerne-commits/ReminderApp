package com.minimal.location_reminder.location_reminder

import android.app.Application
import java.io.File
import java.io.PrintWriter
import java.io.StringWriter
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Gemmer den seneste fejl, hvis appen går ned (også i baggrunden),
 * så den kan vises næste gang appen åbnes.
 */
class CrashApp : Application() {
    override fun onCreate() {
        super.onCreate()
        val previous = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, error ->
            try {
                val sw = StringWriter()
                error.printStackTrace(PrintWriter(sw))
                val time = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US).format(Date())
                File(filesDir, "last_crash.txt").writeText(
                    "Tid: $time\nTråd: ${thread.name}\nAndroid: ${android.os.Build.VERSION.SDK_INT} " +
                        "${android.os.Build.MANUFACTURER} ${android.os.Build.MODEL}\n\n$sw"
                )
            } catch (_: Throwable) {
            }
            previous?.uncaughtException(thread, error)
        }
    }
}
