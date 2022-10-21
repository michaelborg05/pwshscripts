param ($timeout = 7200)

$outputfile = "output.log" 

$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36"
$session.Cookies.Add((New-Object System.Net.Cookie("__dcfduid", "f696619050fa11edbde6f7157974d91c", "/", "discord.com")))
$session.Cookies.Add((New-Object System.Net.Cookie("__sdcfduid", "f696619150fa11edbde6f7157974d91c52f9ef5bc22f3d862a25e10260513cc2d74408b805910d0c96c01e0d959f8783", "/", "discord.com")))
$session.Cookies.Add((New-Object System.Net.Cookie("__cfruid", "a8b82e8fd9fe5a7cb2c46a66128918685b4942e6-1666327432", "/", ".discord.com")))
$session.Cookies.Add((New-Object System.Net.Cookie("__cf_bm", "IFcaf6xv7.Yu7zqaepf3robHMb_3D306IJgoe6gdrhc-1666327435-0-AQoQnxooMMvFJdlGPVDzCQXB9ZuPCslFWZbGMjsMJegLFlgO1hLN91UJdBDGxN0NB24sc99+Xmbi5ehWcD1aesQSQuCFR7cageP1ACAYSzXXW6J1U2oxBQsl0ae0HrOUbA==", "/", ".discord.com")))
$session.Cookies.Add((New-Object System.Net.Cookie("OptanonConsent", "isIABGlobal=false&datestamp=Fri+Oct+21+2022+15%3A43%3A56+GMT%2B1100+(Australian+Eastern+Daylight+Time)&version=6.33.0&hosts=&landingPath=https%3A%2F%2Fdiscord.com%2F&groups=C0001%3A1%2CC0002%3A1%2CC0003%3A1", "/", ".discord.com")))
$session.Cookies.Add((New-Object System.Net.Cookie("locale", "en-GB", "/", "discord.com")))

Function write-log {
Param([Parameter(Mandatory=$true)][String]$msg)
   $CurrTime = Get-Date
    Write-Output "$CurrTime - $msg" >> $outputfile

}


function SendToDiscord {
    Param([Parameter(Mandatory=$true)][String]$Message)
      write-log $Message
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
          "accept-language"="en-US,en;q=0.6"
          "authorization"="MzgxNTgzNjY1NDEyNTcxMTM2.GNpnzT.noCmkYJLCrGPabL5j81PyNFGiieb4rCCWAjyMQ"
          "origin"="https://discord.com"
          "referer"="https://discord.com/channels/971847939456639047/972212745657274410"
          "sec-fetch-dest"="empty"
          "sec-fetch-mode"="cors"
          "sec-fetch-site"="same-origin"
          "sec-gpc"="1"
          "x-debug-options"="bugReporterEnabled"
          "x-discord-locale"="en-GB"
          "x-super-properties"="eyJvcyI6IldpbmRvd3MiLCJicm93c2VyIjoiQ2hyb21lIiwiZGV2aWNlIjoiIiwic3lzdGVtX2xvY2FsZSI6ImVuLVVTIiwiYnJvd3Nlcl91c2VyX2FnZW50IjoiTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzEwNi4wLjAuMCBTYWZhcmkvNTM3LjM2IiwiYnJvd3Nlcl92ZXJzaW9uIjoiMTA2LjAuMC4wIiwib3NfdmVyc2lvbiI6IjEwIiwicmVmZXJyZXIiOiIiLCJyZWZlcnJpbmdfZG9tYWluIjoiIiwicmVmZXJyZXJfY3VycmVudCI6IiIsInJlZmVycmluZ19kb21haW5fY3VycmVudCI6IiIsInJlbGVhc2VfY2hhbm5lbCI6InN0YWJsZSIsImNsaWVudF9idWlsZF9udW1iZXIiOjE1MzQ4MSwiY2xpZW50X2V2ZW50X3NvdXJjZSI6bnVsbH0="
        } `
        -ContentType "application/json" `
        -Body "{`"content`":`"$message`",`"nonce`":`"$nonce`",`"tts`":false}"
  }
   catch {
    write-host "error"
    write-log "Error"
   }
}

$date = Get-date
$date = $date.ToUniversalTime().addDays(-1).Date

$nonce = 1032877698441019398
$run = $true
while ($run) {
    $nonce= $nonce + 1
    $currdate = Get-date
    $CurrDate = $currdate.ToUniversalTime().date
    IF ($currdate -gt $date )
    {
       write-log "Daily command - Wait 60 seconds"
       write-host "$(Get-date) - Trigger daily command"
       start-sleep 60
       write-log "Trigger daily command"
       SendToDiscord "!daily" 
       $date = $currdate
       $nonce= $nonce + 1

    }

   $rndm= Get-Random -Maximum 60
   write-log "Sleep for $rndm seconds"
   write-host "$(Get-date) - Sleep for $rndm seconds"
   start-sleep $rndm    
 
   write-log "Send work command"
   SendToDiscord "!work" 
   write-host "$(Get-date) - Sleep for $timeout seconds"
   write-host "Sleep for $timeout seconds"
   start-sleep $timeout
}

