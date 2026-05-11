package com.alawqat.al_awqat

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Relance l'application au boot de la box. Combiné avec la déclaration
 * `category.HOME` dans le manifest, l'app devient le launcher de la box
 * et reste affichée en permanence.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
            )
        }
        context.startActivity(launchIntent)
    }
}
