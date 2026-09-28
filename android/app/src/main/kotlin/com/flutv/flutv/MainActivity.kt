package com.flutv.flutv

import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity: FlutterActivity() {
    // Match the exact channel name defined in app_service.dart
    private val CHANNEL = "com.flutv.flutv/apps"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> {
                    val apps = fetchInstalledApps()
                    result.success(apps)
                }
                "launchApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        val launched = launchApplication(packageName)
                        result.success(launched)
                    } else {
                        result.error("INVALID_PACKAGE", "Package name was null", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun fetchInstalledApps(): List<Map<String, Any>> {
        val pm: PackageManager = packageManager
        val intent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }
        
        val resolveInfos = pm.queryIntentActivities(intent, 0)
        val appList = mutableListOf<Map<String, Any>>()

        for (resolveInfo in resolveInfos) {
            val packageName = resolveInfo.activityInfo.packageName
            
            // Skip self
            if (packageName == context.packageName) continue

            val appName = resolveInfo.loadLabel(pm).toString()
            val bannerDrawable = resolveInfo.activityInfo.loadBanner(pm) ?: resolveInfo.loadIcon(pm)
            val base64Graphic = drawableToBase64(bannerDrawable)

            val appMap = mapOf(
                "name" to appName,
                "packageName" to packageName,
                "graphicBase64" to base64Graphic // Match the key expected by AppInfo.fromMap
            )
            appList.add(appMap)
        }
        return appList
    }

    private fun launchApplication(packageName: String): Boolean {
        val pm: PackageManager = packageManager
        val intent = pm.getLaunchIntentForPackage(packageName)
        return if (intent != null) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            true
        } else {
            false
        }
    }

    private fun drawableToBase64(drawable: Drawable): String {
        val bitmap = when (drawable) {
            is BitmapDrawable -> drawable.bitmap
            else -> {
                val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 100
                val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 100
                val bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                val canvas = Canvas(bmp)
                drawable.setBounds(0, 0, canvas.width, canvas.height)
                drawable.draw(canvas)
                bmp
            }
        }

        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        val byteArray = stream.toByteArray()
        return Base64.encodeToString(byteArray, Base64.NO_WRAP)
    }
}
