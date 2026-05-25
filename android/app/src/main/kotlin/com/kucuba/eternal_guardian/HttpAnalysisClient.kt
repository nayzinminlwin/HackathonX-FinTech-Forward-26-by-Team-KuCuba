package com.kucuba.eternal_guardian

import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

object HttpAnalysisClient {
    private const val ANALYSIS_TIMEOUT_MS = 12_000

    data class AnalysisResult(
        val riskScore: Int,
        val analysisMessage: String
    )

    fun analyze(backendUrl: String, textPayload: String): AnalysisResult {
        val normalizedBackendUrl = backendUrl.trim().trimEnd('/')
        require(normalizedBackendUrl.isNotBlank()) { "Backend URL is empty" }

        val url = URL("$normalizedBackendUrl/analyze")
        val connection = (url.openConnection() as HttpURLConnection).apply {
            requestMethod = "POST"
            connectTimeout = ANALYSIS_TIMEOUT_MS
            readTimeout = ANALYSIS_TIMEOUT_MS
            setRequestProperty("Content-Type", "application/json")
            setRequestProperty("Accept", "application/json")
            doOutput = true
        }

        val responseText: String
        val responseCode: Int
        try {
            val requestBody = JSONObject()
                .put("text_payload", textPayload)
                .toString()

            connection.outputStream.use { output ->
                output.write(requestBody.toByteArray(Charsets.UTF_8))
            }

            responseCode = connection.responseCode
            responseText = if (responseCode in 200..299) {
                connection.inputStream.bufferedReader().use { it.readText() }
            } else {
                connection.errorStream?.bufferedReader()?.use { it.readText() }.orEmpty()
            }
        } finally {
            connection.disconnect()
        }

        if (responseCode !in 200..299) {
            val backendMessage = runCatching {
                JSONObject(responseText).optString("analysis_message")
                    .ifBlank { JSONObject(responseText).optString("error") }
            }.getOrDefault("")
            val message = backendMessage.ifBlank {
                "Backend returned HTTP $responseCode."
            }
            throw IllegalStateException(message)
        }

        val json = JSONObject(responseText)
        return AnalysisResult(
            riskScore = json.getInt("risk_score"),
            analysisMessage = json.getString("analysis_message")
        )
    }
}
