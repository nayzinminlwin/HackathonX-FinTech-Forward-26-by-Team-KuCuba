package com.kucuba.eternal_guardian

import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

object HttpAnalysisClient {
    data class AnalysisResult(
        val riskScore: Int,
        val analysisMessage: String
    )

    fun analyze(backendUrl: String, textPayload: String): AnalysisResult {
        val url = URL("${backendUrl.trimEnd('/')}/analyze")
        val connection = url.openConnection() as HttpURLConnection

        connection.requestMethod = "POST"
        connection.connectTimeout = 5000
        connection.readTimeout = 10000
        connection.setRequestProperty("Content-Type", "application/json")
        connection.doOutput = true

        val requestBody = JSONObject()
            .put("text_payload", textPayload)
            .toString()

        connection.outputStream.use { output ->
            output.write(requestBody.toByteArray(Charsets.UTF_8))
        }

        val responseCode = connection.responseCode
        val responseText = if (responseCode in 200..299) {
            connection.inputStream.bufferedReader().use { it.readText() }
        } else {
            connection.errorStream?.bufferedReader()?.use { it.readText() }.orEmpty()
        }

        connection.disconnect()

        if (responseCode !in 200..299) {
            throw IllegalStateException("Backend returned HTTP $responseCode")
        }

        val json = JSONObject(responseText)
        return AnalysisResult(
            riskScore = json.getInt("risk_score"),
            analysisMessage = json.getString("analysis_message")
        )
    }
}
