package org.uyghurlatin.keyboard

import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import org.uyghurlatin.engine.LexiconStore
import org.uyghurlatin.keyboard.databinding.ActivityHostBinding

class HostMainActivity : AppCompatActivity() {
    private lateinit var binding: ActivityHostBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityHostBinding.inflate(layoutInflater)
        setContentView(binding.root)

        binding.openSettings.setOnClickListener {
            startActivity(Intent(Settings.ACTION_INPUT_METHOD_SETTINGS))
            Toast.makeText(this, R.string.host_step2, Toast.LENGTH_SHORT).show()
        }

        try {
            val store = LexiconStore.load(this)
            binding.lexiconMeta.text =
                "Lexicon ${store.meta.version} · ${store.meta.wordCount} words · offline"
        } catch (e: Exception) {
            binding.lexiconMeta.text = "Lexicon not loaded: ${e.message}"
        }
    }
}
