$AlertPrice= 0.175
$global:MAxAlerts=4
$global:AlertCount=0

Function Send-Telegram {
    Param([Parameter(Mandatory=$true)][String]$Message)
    $Telegramtoken = "594185771:AAEGBNDncM3455gyutHlwjTlnPIdeRs0dYE"
    #$Telegramchatid = "416082917"
    $Telegramchatid = "-773724465"#NFTSniper
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $Response = Invoke-RestMethod -Uri "https://api.telegram.org/bot$($Telegramtoken)/sendMessage?chat_id=$($Telegramchatid)&text=$($Message)"
    $global:AlertCount= $global:AlertCount + 1
    if ($global:AlertCount -ge $global:MaxAlerts) {
        $Message="3 alerts received in short time. Pausing script for 30mins"
        $Response = Invoke-RestMethod -Uri "https://api.telegram.org/bot$($Telegramtoken)/sendMessage?chat_id=$($Telegramchatid)&text=$($Message)"
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
        $key = $_.Name
        [PSCustomObject]@{Key = $key; Value = $obj."$key"}
    }
}

function CheckFloorPrice() {
    #Get stats
   # $response = Invoke-RestMethod 'api-mainnet.magiceden.io/v2/xc/collections/eth/0xb99e4e9b8fd99c2c90ad5382dbc6adfdfe3a33f3/stats' -Method 'GET' -Headers $headers


    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36"
    $response = Invoke-WebRequest -UseBasicParsing -Uri "https://api-mainnet.magiceden.io/v2/xc/collections/eth/0xb99e4e9b8fd99c2c90ad5382dbc6adfdfe3a33f3/stats" `
    -WebSession $session `
    -Headers @{
    "authority"="api-mainnet.magiceden.io"
      "method"="GET"
      "path"="/v2/xc/collections/eth/0xb99e4e9b8fd99c2c90ad5382dbc6adfdfe3a33f3/stats"
      "scheme"="https"
      "accept"="application/json, text/plain, */*"
      "accept-encoding"="gzip, deflate, br"
      "accept-language"="en-US,en;q=0.7"
      "if-none-match"="W/`"16e-Gp7RODMZsJ+E4F10szZWNX/XjO4`""
      "origin"="https://magiceden.io"
      "referer"="https://magiceden.io/"
      "sec-fetch-dest"="empty"
      "sec-fetch-mode"="cors"
      "sec-fetch-site"="same-site"
      "sec-gpc"="1"
    }

    $response  | Get-ObjectMember | foreach {
                 if ($_.key -eq 'floorPrice') {
                    $floorPr = $_.value
                    }
                 if ($_.key -eq 'totalListedCount') {
                    $listed = $_.value
                    }

    }
    write-host "Floor price before divide: $floorpr"
    $floorPr = $Floorpr / 1000000000000000000

    if ($floorPr -le $AlertPrice)
    {
        $desc = "Hashverse Floor price: " + $floorPr
        Send-Telegram $desc

    } else {$global:AlertCount=0}

    write-host "Listed: $Listed"
    write-host "Floor Price: " $floorPr

}


function FindCheapNFTs() {
    #Get stats
    $Offset = 0
    $NFTSBelowAlert=0
    $Limit = 20
    $cheapNFTsList = @{}
    
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36"
    $response = Invoke-WebRequest -UseBasicParsing -Uri "https://api-mainnet.magiceden.io/v2/xc/collections/eth/0xb99e4e9b8fd99c2c90ad5382dbc6adfdfe3a33f3/orders?sort=askAmountNum&limit=20" `
    -WebSession $session `
    -Headers @{
    "authority"="api-mainnet.magiceden.io"
      "method"="GET"
      "path"="/v2/xc/collections/eth/0xb99e4e9b8fd99c2c90ad5382dbc6adfdfe3a33f3/orders?sort=askAmountNum&limit=20"
      "scheme"="https"
      "accept"="application/json, text/plain, */*"
      "accept-encoding"="gzip, deflate, br"
      "accept-language"="en-US,en;q=0.7"
      "if-none-match"="W/`"139b2-RFn/OI//8t1rwdAYSVOtEuRcNvs`""
      "origin"="https://magiceden.io"
      "referer"="https://magiceden.io/"
      "sec-fetch-dest"="empty"
      "sec-fetch-mode"="cors"
      "sec-fetch-site"="same-site"
      "sec-gpc"="1"
    }
    
    $counter = 0
    foreach ($i in $response.items) {
        $i | Get-ObjectMember | foreach {
                if ($_.key -eq "askAmountNum" -and [decimal]$_.value -le $AlertPrice) {
                $NFTSBelowAlert= $NFTSBelowAlert + 1
                $cheapNFTsList[$NFTSBelowAlert] = $_.value  
                write-host "$NFTSBelowAlert : " $_.value
                }
                 
        }
    }
    $text= ""
    if ($cheapNFTsList.Count -gt 0) {
        $cheapNFTsList.GetEnumerator() | ForEach-Object {
            $text = $text + $_.key + " - " + $_.value + " `r`n"
        }
        
        Send-Telegram $text
    } else {$global:AlertCount=0}

}

$run = $true
while ($run) {
    $Time = Get-Date
    write-host  $time
    
    CheckFloorPrice
    FindCheapNFTs
    start-sleep 15
}




