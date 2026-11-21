package com.minimal.location_reminder.location_reminder

import android.app.AlertDialog
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.os.Bundle
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import java.io.File

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        showLastCrash()
    }

    /** Viser den seneste fejl (hvis appen gik ned sidst) med en kopiér-knap. */
    private fun showLastCrash() {
        val file = File(filesDir, "last_crash.txt")
        if (!file.exists()) return
        val text = try { file.readText() } catch (_: Throwable) { return }
        AlertDialog.Builder(this)
            .setTitle("Appen gik ned sidste gang")
            .setMessage("Tryk Kopiér og send teksten til Claude.\n\n" + text.take(6000))
            .setPositiveButton("Kopiér") { _, _ ->
                val cm = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                cm.setPrimaryClip(ClipData.newPlainText("Fejl", text))
                Toast.makeText(this, "Kopieret", Toast.LENGTH_SHORT).show()
                file.delete()
            }
            .setNegativeButton("Luk") { _, _ -> file.delete() }
            .show()
    }
}
