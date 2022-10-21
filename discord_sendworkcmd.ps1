$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36"
$session.Cookies.Add((New-Object System.Net.Cookie("__dcfduid", "f93cab7a2de111edb6d4f6faa37599f1", "/", "discord.com")))
$session.Cookies.Add((New-Object System.Net.Cookie("__sdcfduid", "f93cab7a2de111edb6d4f6faa37599f18d8e5dff8caff8bcca3a3f459582c0b75f5d9f2c3a56f3613d9eb3c88ec6ee59", "/", "discord.com")))
$session.Cookies.Add((New-Object System.Net.Cookie("locale", "en-GB", "/", "discord.com")))
$session.Cookies.Add((New-Object System.Net.Cookie("__cfruid", "4860713c7923e61bf2aa142ec20e5c9e6c0f1d67-1665183448", "/", ".discord.com")))
$session.Cookies.Add((New-Object System.Net.Cookie("__cf_bm", "Bm0A0hQh9ggP1wZ7S5WeWWAZZ63Qhfo7S62vUAiHy14-1665183451-0-ARuoKRgJnDZlS08DReZ8cKarm7jzPMFoSZ6KMdiHwCQTW77RkJyyJEJEnd9lMSO1aTgz5nfMvz3NclP0yq1GN3+4N2/+YVKs3bzsWvWFW3tdZSuA6N+LOoUAyC1FL/MN/w==", "/", ".discord.com")))

function SendToDiscord {
    Param([Parameter(Mandatory=$true)][String]$Message)
      try {
        Invoke-WebRequest -UseBasicParsing -Uri "https://discord.com/api/v9/channels/972212745657274410/messages" `
        -Method "POST" `
        -WebSession $session `
        -Headers @{
        "authority"="discord.com"
          "method"="POST"
          "path"="/api/v9/channels/972212745657274410/messages"
          "scheme"="https"
          "accept"="*/*"
          "accept-encoding"="gzip, deflate, br"
          "accept-language"="en-US,en;q=0.9"
          "authorization"="MzgxNTgzNjY1NDEyNTcxMTM2.YKcwrQ.vTMHLp-gj0-k4t5oIDPmcQQgJYw"
          "origin"="https://discord.com"
          "referer"="https://discord.com/channels/971847939456639047/972212745657274410"
          "sec-fetch-dest"="empty"
          "sec-fetch-mode"="cors"
          "sec-fetch-site"="same-origin"
          "sec-gpc"="1"
          "x-debug-options"="bugReporterEnabled"
          "x-discord-locale"="en-GB"
          "x-super-properties"="eyJvcyI6IldpbmRvd3MiLCJicm93c2VyIjoiQ2hyb21lIiwiZGV2aWNlIjoiIiwic3lzdGVtX2xvY2FsZSI6ImVuLVVTIiwiYnJvd3Nlcl91c2VyX2FnZW50IjoiTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzEwNi4wLjAuMCBTYWZhcmkvNTM3LjM2IiwiYnJvd3Nlcl92ZXJzaW9uIjoiMTA2LjAuMC4wIiwib3NfdmVyc2lvbiI6IjEwIiwicmVmZXJyZXIiOiJodHRwczovL2FwcC5wb2xrYW1hcmtldHMuY29tLyIsInJlZmVycmluZ19kb21haW4iOiJhcHAucG9sa2FtYXJrZXRzLmNvbSIsInJlZmVycmVyX2N1cnJlbnQiOiIiLCJyZWZlcnJpbmdfZG9tYWluX2N1cnJlbnQiOiIiLCJyZWxlYXNlX2NoYW5uZWwiOiJzdGFibGUiLCJjbGllbnRfYnVpbGRfbnVtYmVyIjoxNTE2MzgsImNsaWVudF9ldmVudF9zb3VyY2UiOm51bGx9"
        } `
        -ContentType "application/json" `
        -Body "{`"content`":`"$message`",`"nonce`":`"$nonce`",`"tts`":false}"
  }
   catch {
    write-host "error"
   }

}

$date = Get-date
$date = $date.ToUniversalTime().addDays(-1).Date

$nonce = 1028080132276889614
$run = $true
while ($run) {
    $nonce= $nonce + 1
    $currdate = Get-date
    $CurrDate = $currdate.ToUniversalTime().date
    IF ($currdate -gt $date )
    {
       write-host "$(Get-date) - Trigger daily command"
       start-sleep 60
       SendToDiscord "!daily" 
       $date = $currdate
       $nonce= $nonce + 1

    }

   $rndm= Get-Random -Maximum 60
   write-host "$(Get-date) - Sleep for $rndm seconds"
   start-sleep $rndm    
   write-host "$(Get-date) - Trigger daily command"
 
   SendToDiscord "!work" 
    write-host "$(Get-date) - Sleep for 1hr"
   start-sleep 15000
}

