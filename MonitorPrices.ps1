
#$global:AlertPrice= 0.175
#$global:MAxAlerts=4
$global:AlertTime=Get-Date "00:00"
$global:AlertCount=0
$global:settingsObject = ""
$global:collections = @()
$global:DailyReport = $false
$global:DailyReportText = "DAILY REPORT`r`n"

$global:Time = Get-Date
function Get-Settings {
    $global:settingsObject = Get-content -Path "config\pricesettings.json" | ConvertFrom-Json 
    if ($global:settingsObject -eq $null -or $global:settingsobject -eq "" ) {
        write-host "unable to retrieve settings. Exiting return code 1" 
        Exit 1
        }
}

Function Send-Telegram {
    Param([Parameter(Mandatory=$true)][String]$Message)
    $Telegramtoken = $global:settingsObject.telegramToken
    #$Telegramchatid = "416082917"
    $Telegramchatid = $global:settingsObject.telegramChatId  #"-773724465"#NFTSniper
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $Response = RestCall "https://api.telegram.org/bot$($Telegramtoken)/sendMessage?chat_id=$($Telegramchatid)&text=$($Message)"
    if ((get-date) -lt $global:AlertTime.AddMinutes(2)) {
        $global:AlertCount= $global:AlertCount + 1
    }
    #Set current date/time to Alerttime var
    $global:AlertTime = Get-Date
    if ($global:AlertCount -ge $global:settingsObject.MaxAlerts) {
        $Message="3 alerts received in short time. Pausing script for 30mins"
        $Response = RestCall -Uri "https://api.telegram.org/bot$($Telegramtoken)/sendMessage?chat_id=$($Telegramchatid)&text=$($Message)"
        start-sleep 1800
        $global:AlertCount=0
    }
}


function Get-ObjectMember {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [PSCustomObject]$obj
    )
    $obj | Get-Member -MemberType NoteProperty | ForEach-Object {
        if ($_.Name -eq "stats") {
            $obj.stats | Get-Member -MemberType NoteProperty | ForEach-Object {
                $key = $_.Name
                [PSCustomObject]@{Key = $key; Value = $obj.stats."$key"}
            }
        } else { 
            $key = $_.Name
            [PSCustomObject]@{Key = $key; Value = $obj."$key"}
        }
    }
}

function CheckPrice() {
    Param([Parameter(Mandatory=$true)][object]$coin)

    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36"
    $response = RestCall $coin.URL 
    $price = [math]::round($response.data.price,8)
    $alertPr = $coin.alert
    
    $name = $coin.CoinName
    write-host $name.PadLeft(25) "  Price: $price    Alert: $alertPr"
    IF ($global:DailyReport -eq $false -and $global:Time.timeofday -gt "00:15") {
        $global:DailyReportText =  $global:DailyReportText + "`r`n" + $coin.CoinName + ": " + $Price+ " Alert: " + $alertPr 
    }
    if ($price -ge $alertPr) {
        $desc = "Alert: " + $coin.Coinname + " Price: " + $price + " Alert Pr: " + $AlertPr
        Send-Telegram $desc

    }

}

function RestCall() {
    Param([Parameter(Mandatory=$true)][string]$URI)
    try {
        Invoke-RestMethod $URI -Method 'GET' -Headers $headers -TimeoutSec 60
    }
    catch {
       Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
       Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
    }
}


$run = $true
while ($run) {
    Get-Settings #check updated settings each loop
    $global:Time = Get-Date
    write-host  $global:Time
        
    foreach ($i in $global:settingsObject.Coins) {
        CheckPrice $i
        start-sleep -Milliseconds 200
    }
    
    IF ($global:DailyReport -eq $false -and $global:Time.TimeOfDay -ge "00:15") { 
        $global:DailyReport = $true
        Send-Telegram  $global:DailyReportText
    }

    #Once new day ticks over, reset param to false
    IF ($global:DailyReport -eq $true -and $global:Time.TimeOfDay -lt "00:15") { 
        $global:DailyReport = $false
        $global:DailyReportText = "DAILY REPORT`r`n"
    }

    #if its been 10 mins since last alert and alert count is still not 0, set it to 0
    if ($global:Alertcount -gt 0 -and (get-date) -gt $global:alerttime.AddMinutes(15)) {
        $global:alertcount = 0
    }

    start-sleep $global:settingsObject.sleepTimer
}


 