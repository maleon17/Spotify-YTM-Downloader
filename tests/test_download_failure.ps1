$ErrorActionPreference = "Stop"
$fixture = Join-Path ([IO.Path]::GetTempPath()) ("spotify-ytm-test-" + [guid]::NewGuid())

try {
    $redistributables = Join-Path $fixture "Redistributables"
    New-Item -ItemType Directory -Force (Join-Path $redistributables "YouTube-DL") | Out-Null
    New-Item -ItemType Directory -Force (Join-Path $redistributables "FFMPEG\bin") | Out-Null
    New-Item -ItemType Directory -Force (Join-Path $redistributables "AlbumArtDownloader") | Out-Null
    Copy-Item "Redistributables\Downloader.cmd" $redistributables

    Set-Content (Join-Path $redistributables "ProgressBar.cmd") '@exit /b 0' -Encoding ASCII
    Set-Content (Join-Path $redistributables "ProgressTicker.cmd") '@exit /b 0' -Encoding ASCII
    Set-Content (Join-Path $fixture "timeout.cmd") '@exit /b 0' -Encoding ASCII
    Set-Content (Join-Path $redistributables "dlProgress") '0' -Encoding ASCII

    # where.exe returns a non-zero exit code for yt-dlp-style arguments, making
    # it a deterministic stand-in for a downloader that fails immediately.
    Copy-Item "$env:SystemRoot\System32\where.exe" `
        (Join-Path $redistributables "YouTube-DL\youtube-dl.exe")

    Push-Location $fixture
    try {
        $oldRetries = $env:YTM_MAX_RETRIES
        $oldDelay = $env:YTM_RETRY_STEP_SECONDS
        $env:YTM_MAX_RETRIES = "0"
        $env:YTM_RETRY_STEP_SECONDS = "0"
        & cmd.exe /d /c 'call "Redistributables\Downloader.cmd" failingId01 1'
        $exitCode = $LASTEXITCODE
    } finally {
        $env:YTM_MAX_RETRIES = $oldRetries
        $env:YTM_RETRY_STEP_SECONDS = $oldDelay
        Pop-Location
    }

    if ($exitCode -ne 1) { throw "Expected exit code 1, got $exitCode" }
    $failed = Join-Path $fixture "FailedDownloads.txt"
    if (-not (Test-Path $failed)) { throw "FailedDownloads.txt was not created" }
    if ((Get-Content -Raw $failed).Trim() -ne "failingId01") {
        throw "Failed download ID was not recorded correctly"
    }
    if (Test-Path (Join-Path $fixture "done_ids.txt")) {
        throw "A failed track was incorrectly recorded as downloaded"
    }
    Write-Host "Download failure-path test passed"
} finally {
    if (Test-Path $fixture) { Remove-Item -Recurse -Force $fixture }
}
