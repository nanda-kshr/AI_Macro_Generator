package com.example.ai_macro_generator

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioManager
import android.os.Build
import android.provider.AlarmClock
import android.provider.Settings
import androidx.annotation.NonNull
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.ai_macro_generator/execution"
    private val NOTIFICATION_CHANNEL_ID = "macro_notifications"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        createNotificationChannel()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setSoundMode" -> {
                    val mode = call.argument<String>("mode") ?: "normal"
                    val durationMinutes = call.argument<Int>("durationMinutes")
                    val success = handleSoundMode(mode, durationMinutes)
                    result.success(success)
                }
                "setTimer" -> {
                    val minutes = call.argument<Int>("durationMinutes") ?: 1
                    val label = call.argument<String>("label") ?: "Macro Timer"
                    val success = handleSetTimer(minutes, label)
                    result.success(success)
                }
                "openApp" -> {
                    val appName = call.argument<String>("appName") ?: ""
                    val packageName = call.argument<String>("packageName")
                    val success = handleOpenApp(appName, packageName)
                    result.success(success)
                }
                "showNotification" -> {
                    val title = call.argument<String>("title") ?: "Macro Notification"
                    val message = call.argument<String>("message") ?: ""
                    val success = handleShowNotification(title, message)
                    result.success(success)
                }
                "checkDndPermission" -> {
                    val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                    result.success(nm.isNotificationPolicyAccessGranted)
                }
                "requestDndPermission" -> {
                    val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    startActivity(intent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun handleSoundMode(mode: String, durationMinutes: Int?): Boolean {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        return try {
            when (mode.lowercase()) {
                "dnd" -> {
                    if (notificationManager.isNotificationPolicyAccessGranted) {
                        notificationManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_PRIORITY)
                        if (durationMinutes != null && durationMinutes > 0) {
                            scheduleDndReset(durationMinutes)
                        }
                        true
                    } else {
                        // Request user to grant DND access if not already granted
                        val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        startActivity(intent)
                        false
                    }
                }
                "silent" -> {
                    if (notificationManager.isNotificationPolicyAccessGranted) {
                        audioManager.ringerMode = AudioManager.RINGER_MODE_SILENT
                    } else {
                        audioManager.ringerMode = AudioManager.RINGER_MODE_VIBRATE
                    }
                    if (durationMinutes != null && durationMinutes > 0) {
                        scheduleDndReset(durationMinutes)
                    }
                    true
                }
                "vibrate" -> {
                    audioManager.ringerMode = AudioManager.RINGER_MODE_VIBRATE
                    if (durationMinutes != null && durationMinutes > 0) {
                        scheduleDndReset(durationMinutes)
                    }
                    true
                }
                "normal" -> {
                    if (notificationManager.isNotificationPolicyAccessGranted) {
                        notificationManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
                    }
                    audioManager.ringerMode = AudioManager.RINGER_MODE_NORMAL
                    true
                }
                else -> false
            }
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun scheduleDndReset(durationMinutes: Int) {
        val delayMillis = durationMinutes * 60 * 1000L
        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
            try {
                val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                if (nm.isNotificationPolicyAccessGranted) {
                    nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
                }
                am.ringerMode = AudioManager.RINGER_MODE_NORMAL
                handleShowNotification(
                    "Macro Complete",
                    "Do Not Disturb disabled after $durationMinutes minutes."
                )
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }, delayMillis)
    }

    private fun handleSetTimer(durationMinutes: Int, label: String): Boolean {
        return try {
            val seconds = durationMinutes * 60
            val intent = Intent(AlarmClock.ACTION_SET_TIMER).apply {
                putExtra(AlarmClock.EXTRA_LENGTH, seconds)
                putExtra(AlarmClock.EXTRA_MESSAGE, label)
                putExtra(AlarmClock.EXTRA_SKIP_UI, false)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                true
            } else {
                false
            }
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun handleOpenApp(appName: String, explicitPkg: String?): Boolean {
        return try {
            val pm = packageManager
            if (!explicitPkg.isNullOrEmpty()) {
                val launchIntent = pm.getLaunchIntentForPackage(explicitPkg)
                if (launchIntent != null) {
                    launchIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    startActivity(launchIntent)
                    return true
                }
            }

            // Search installed apps by name
            val installedApps = pm.getInstalledApplications(PackageManager.GET_META_DATA)
            val query = appName.lowercase().trim()

            for (app in installedApps) {
                val label = pm.getApplicationLabel(app).toString().lowercase()
                if (label.contains(query) || query.contains(label)) {
                    val launchIntent = pm.getLaunchIntentForPackage(app.packageName)
                    if (launchIntent != null) {
                        launchIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        startActivity(launchIntent)
                        return true
                    }
                }
            }

            // Fallback: search common system apps
            val commonPackages = mapOf(
                "notes" to listOf("com.google.android.keep", "com.samsung.android.app.notes", "com.miui.notes"),
                "calendar" to listOf("com.google.android.calendar", "com.samsung.android.calendar"),
                "spotify" to listOf("com.spotify.music"),
                "music" to listOf("com.spotify.music", "com.google.android.apps.youtube.music"),
                "gmail" to listOf("com.google.android.gm"),
                "youtube" to listOf("com.google.android.youtube")
            )

            for ((key, packages) in commonPackages) {
                if (query.contains(key)) {
                    for (pkg in packages) {
                        val intent = pm.getLaunchIntentForPackage(pkg)
                        if (intent != null) {
                            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            startActivity(intent)
                            return true
                        }
                    }
                }
            }

            false
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun handleShowNotification(title: String, message: String): Boolean {
        return try {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle(title)
                .setContentText(message)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
                .build()

            notificationManager.notify(System.currentTimeMillis().toInt(), notification)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Macro Generator Notifications"
            val descriptionText = "Notifications generated by AI Macro workflows"
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(NOTIFICATION_CHANNEL_ID, name, importance).apply {
                description = descriptionText
            }
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}
