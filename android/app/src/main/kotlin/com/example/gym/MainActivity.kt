package com.example.gym

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.gym/app_launcher"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "launchApp") {
                val packageName = call.argument<String>("packageName")
                if (packageName != null) {
                    val launched = launchAppByPackage(packageName)
                    result.success(launched)
                } else {
                    result.error("INVALID_ARGUMENT", "Package name is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun launchAppByPackage(packageName: String): Boolean {
        val pm = packageManager
        // Método 1: Tenta obter o intent de lançamento padrão do app
        val intent = pm.getLaunchIntentForPackage(packageName)
        if (intent != null) {
            return try {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                true
            } catch (e: Exception) {
                false
            }
        }

        // Método 2: Constrói manualmente um intent de launcher para o pacote
        // (Isso contorna restrições de visibilidade no Android 11+ caso o pacote não esteja listado nas queries)
        return try {
            val manualIntent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_LAUNCHER)
                setPackage(packageName)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(manualIntent)
            true
        } catch (e: Exception) {
            false
        }
    }
}
