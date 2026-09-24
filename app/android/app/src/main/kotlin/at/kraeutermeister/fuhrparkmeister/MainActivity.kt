package at.kraeutermeister.fuhrparkmeister

import android.content.Intent
import android.net.Uri
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

/**
 * Empfaengt eine per Android-Teilen-Dialog ("Teilen ueber..." / "Oeffnen
 * mit...") geschickte .zip-Backup-Datei und kopiert sie in den App-Cache,
 * damit Flutter-Code sie mit einem normalen Dateipfad importieren kann -
 * ohne dafuer ein zusaetzliches Datei-Dialog-Plugin zu brauchen.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "at.kraeutermeister.fuhrparkmeister/import"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "consumeSharedZip" -> result.success(consumeIncomingZip(intent))
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val path = consumeIncomingZip(intent)
        if (path != null) {
            methodChannel?.invokeMethod("sharedZipReceived", path)
        }
    }

    private fun consumeIncomingZip(intent: Intent?): String? {
        if (intent == null) return null
        @Suppress("DEPRECATION")
        val uri: Uri? = when (intent.action) {
            Intent.ACTION_SEND -> intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
            Intent.ACTION_VIEW -> intent.data
            else -> null
        }
        if (uri == null) return null
        return try {
            contentResolver.openInputStream(uri)?.use { input ->
                val outFile = File(cacheDir, "shared_import.zip")
                FileOutputStream(outFile).use { output -> input.copyTo(output) }
                outFile.absolutePath
            }
        } catch (e: Exception) {
            null
        }
    }
}
