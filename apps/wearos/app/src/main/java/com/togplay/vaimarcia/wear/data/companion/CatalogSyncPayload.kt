package com.togplay.vaimarcia.wear.data.companion

import com.togplay.vaimarcia.wear.domain.AudioClip
import org.json.JSONArray

/** Wire format for the DataLayer catalog-sync payload sent by the phone companion app. */
object CatalogSyncPayload {
    fun parse(bytes: ByteArray): List<AudioClip> {
        val json = JSONArray(String(bytes, Charsets.UTF_8))
        return buildList {
            for (i in 0 until json.length()) {
                val obj = json.getJSONObject(i)
                add(
                    AudioClip(
                        id = obj.getString("id"),
                        categoryId = obj.getString("categoryId"),
                        title = obj.getString("title"),
                        localFilePath = obj.optString("localFilePath", null),
                        durationMs = obj.optInt("durationMs", 0),
                        isFavorite = obj.optBoolean("isFavorite", false),
                    ),
                )
            }
        }
    }
}
