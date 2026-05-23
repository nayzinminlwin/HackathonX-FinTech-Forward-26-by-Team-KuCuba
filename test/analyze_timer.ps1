param(
  [string]$Url = "http://localhost:8080/analyze",
  [string]$TestCasesPath = ".\\test_cases.json",
  [int]$IntervalSeconds = 20
)

function Parse-Range {
  param([string]$RangeText)
  # Expected format: "start - end"
  $parts = $RangeText -split '\s*-\s*'
  if ($parts.Count -ne 2) { return $null }
  return @{
    Start = [int]$parts[0].Trim()
    End = [int]$parts[1].Trim()
  }
}

function Label-From-Score {
  param(
    [int]$Score,
    [hashtable]$Ranges
  )
  if ($Score -lt 0) { return "unavailable" }

  foreach ($key in $Ranges.Keys) {
    $range = $Ranges[$key]
    if ($Score -ge $range.Start -and $Score -le $range.End) {
      return $key
    }
  }
  return "unknown"
}

if (-not (Test-Path $TestCasesPath)) {
  Write-Error "Test cases file not found at: $TestCasesPath"
  exit 1
}

$testJson = Get-Content -Raw -Path $TestCasesPath | ConvertFrom-Json

# Build ranges map from the JSON config
$ranges = @{}
foreach ($key in $testJson.risk_score_ranges.PSObject.Properties.Name) {
  $rangeText = $testJson.risk_score_ranges.$key
  $parsed = Parse-Range -RangeText $rangeText
  if ($null -eq $parsed) {
    Write-Error "Invalid range format for '$key': $rangeText"
    exit 1
  }
  $ranges[$key] = $parsed
}

$countInput = Read-Host "Enter number of test cases to run (1-53)"
if (-not [int]::TryParse($countInput, [ref]$null)) {
  Write-Error "Input must be an integer."
  exit 1
}
$count = [int]$countInput
if ($count -lt 1 -or $count -gt 53) {
  Write-Error "Input must be between 1 and 53."
  exit 1
}

# Shuffle and take N
$allCases = @($testJson.test_cases)
$selected = $allCases | Sort-Object { Get-Random } | Select-Object -First $count

$results = @()
$index = 0
$lastStartTime = $null

foreach ($case in $selected) {
  $index++
  Write-Output "Running test $index/$count (id=$($case.id))..."

  $body = @{ text_payload = $case.text_payload } | ConvertTo-Json -Compress

  if ($null -ne $lastStartTime) {
    $elapsedSinceLastStart = (Get-Date) - $lastStartTime
    $remaining = $IntervalSeconds - $elapsedSinceLastStart.TotalSeconds
    if ($remaining -gt 0) {
      $sleepSeconds = [int][Math]::Ceiling($remaining)
      Start-Sleep -Seconds $sleepSeconds
    }
  }

  $requestStartTime = Get-Date
  try {
    $response = Invoke-WebRequest `
      -Method Post `
      -Uri $Url `
      -ContentType "application/json" `
      -Body $body `
      -TimeoutSec 90

    $returnJson = $response.Content | ConvertFrom-Json
  } catch {
    $returnJson = @{
      risk_score = -1
      analysis_message = "Request failed before a JSON response was returned."
      analysis_source = "backend"
    }
  }
  $responseReceivedTime = Get-Date
  $lastStartTime = $requestStartTime

  $score = -1
  if ($null -ne $returnJson.risk_score) {
    $score = [int]$returnJson.risk_score
  }

  $predictedLabel = Label-From-Score -Score $score -Ranges $ranges
  $expectedLabel = $case.expected_label
  $match = if ($predictedLabel -eq $expectedLabel) { 1 } else { 0 }

  $results += [ordered]@{
    id = $case.id
    text_payload = $case.text_payload
    expected_label = $expectedLabel
    predicted_label = $predictedLabel
    return_json = $returnJson
    request_start_time = $requestStartTime.ToString("o")
    response_received_time = $responseReceivedTime.ToString("o")
    request_duration_ms = [int]($responseReceivedTime - $requestStartTime).TotalMilliseconds
    match = $match
  }
}

$timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$outPath = "test_results_$timestamp.json"
$outDoc = [ordered]@{
  run_at = (Get-Date).ToString("s")
  url = $Url
  count = $count
  interval_seconds = $IntervalSeconds
  results = $results
}

$outDoc | ConvertTo-Json -Depth 6 | Set-Content -Path $outPath -Encoding UTF8

Write-Output "Saved: $outPath"
