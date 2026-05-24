param(
  [string]$Url = "http://localhost:8080/analyze"
)

$text = Read-Host "Enter text to analyze"

if ([string]::IsNullOrWhiteSpace($text)) {
  Write-Error "Input text cannot be empty."
  exit 1
}

$body = @{
  text_payload = $text
} | ConvertTo-Json -Compress

$timer = [System.Diagnostics.Stopwatch]::StartNew()

try {
  $response = Invoke-WebRequest `
    -Method Post `
    -Uri $Url `
    -ContentType "application/json" `
    -Body $body `
    -TimeoutSec 90

  $timer.Stop()

  Write-Output "JSON:"
  Write-Output $response.Content
  Write-Output ""
  Write-Output "Time:"
  Write-Output ("{0} ms" -f $timer.ElapsedMilliseconds)
  Write-Output ("{0:N3} seconds" -f $timer.Elapsed.TotalSeconds)
} catch {
  $timer.Stop()

  Write-Output "JSON:"
  if ($_.Exception.Response) {
    $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
    Write-Output $reader.ReadToEnd()
  } else {
    Write-Output '{"risk_score":-1,"analysis_message":"Request failed before a JSON response was returned.","analysis_source":"backend"}'
  }

  Write-Output ""
  Write-Output "Time:"
  Write-Output ("{0} ms" -f $timer.ElapsedMilliseconds)
  Write-Output ("{0:N3} seconds" -f $timer.Elapsed.TotalSeconds)

  Write-Error $_.Exception.Message
  exit 1
}
