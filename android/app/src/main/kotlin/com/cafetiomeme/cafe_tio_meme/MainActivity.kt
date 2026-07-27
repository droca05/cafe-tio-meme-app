package com.cafetiomeme.cafe_tio_meme

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val canal = "com.cafetiomeme.cafe_tio_meme/descargas"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, canal).setMethodCallHandler { call, result ->
            if (call.method == "guardarEnDescargas") {
                val nombreArchivo = call.argument<String>("nombreArchivo")
                val bytes = call.argument<ByteArray>("bytes")
                if (nombreArchivo == null || bytes == null) {
                    result.error("ARGUMENTOS_INVALIDOS", "Faltan nombreArchivo o bytes", null)
                    return@setMethodCallHandler
                }
                try {
                    result.success(guardarEnDescargas(nombreArchivo, bytes))
                } catch (e: Exception) {
                    result.error("ERROR_GUARDADO", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun guardarEnDescargas(nombreArchivo: String, bytes: ByteArray): String {
        val mimeType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = applicationContext.contentResolver
            val valores = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, nombreArchivo)
                put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
            }
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, valores)
                ?: throw IllegalStateException("No se pudo crear el archivo en Descargas")
            resolver.openOutputStream(uri)?.use { it.write(bytes) }
                ?: throw IllegalStateException("No se pudo abrir el archivo para escritura")
            return "Descargas/$nombreArchivo"
        }

        val carpeta = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        if (!carpeta.exists()) carpeta.mkdirs()
        val archivo = File(carpeta, nombreArchivo)
        FileOutputStream(archivo).use { it.write(bytes) }
        return archivo.absolutePath
    }
}
