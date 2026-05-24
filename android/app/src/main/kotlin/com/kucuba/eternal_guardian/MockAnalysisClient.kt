package com.kucuba.eternal_guardian

object MockAnalysisClient {
    fun analyze(textPayload: String): HttpAnalysisClient.AnalysisResult {
        Thread.sleep(1_500)

        val lowerText = textPayload.lowercase()
        return when {
            listOf(
                "congratulations",
                "won",
                "prize",
                "claim",
                "reward",
                "selected",
                "grant",
                "fee",
                "hadiah",
                "menang",
                "memenangi",
                "tuntut"
            ).any { lowerText.contains(it) } ->
                HttpAnalysisClient.AnalysisResult(
                    riskScore = 88,
                    analysisMessage = "This message matches a prize or reward scam pattern using a fake windfall and an upfront fee or claim request."
                )
            listOf("transfer", "tac", "polis", "lhdn").any { lowerText.contains(it) } ->
                HttpAnalysisClient.AnalysisResult(
                    riskScore = 88,
                    analysisMessage = "This message contains hallmarks of a known Malaysian scam involving authority impersonation and financial requests."
                )
            listOf("http", "www", "click").any { lowerText.contains(it) } ->
                HttpAnalysisClient.AnalysisResult(
                    riskScore = 65,
                    analysisMessage = "This message contains a suspicious link. Exercise caution before clicking."
                )
            else ->
                HttpAnalysisClient.AnalysisResult(
                    riskScore = 8,
                    analysisMessage = "This message appears to be a normal, safe conversation."
                )
        }
    }
}
