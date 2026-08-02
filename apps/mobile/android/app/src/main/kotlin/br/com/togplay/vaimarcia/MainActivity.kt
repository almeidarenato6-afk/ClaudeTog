package br.com.togplay.vaimarcia

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        BluetoothTransportPlugin(this).attach(flutterEngine)
        WatchCompanionPlugin(this).attach(flutterEngine)
    }
}
