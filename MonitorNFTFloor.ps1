#$global:AlertPrice= 0.175
#$global:MAxAlerts=4
$global:AlertCount=0
$global:settingsObject = ""
function Get-Settings {
    $global:settingsObject = Get-content -Path "config\settings.json" | ConvertFrom-Json 
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
    $Response = Invoke-RestMethod -Uri "https://api.telegram.org/bot$($Telegramtoken)/sendMessage?chat_id=$($Telegramchatid)&text=$($Message)"
    $global:AlertCount= $global:AlertCount + 1
    if ($global:AlertCount -ge $global:settingsObject.MaxAlerts) {
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

function CheckFloorPrice() {
    Param([Parameter(Mandatory=$true)][object]$coll)
    #Get stats
   # $response = Invoke-RestMethod 'api-mainnet.magiceden.io/v2/xc/collections/eth/0xb99e4e9b8fd99c2c90ad5382dbc6adfdfe3a33f3/stats' -Method 'GET' -Headers $headers


    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36"
    
#    $response = Invoke-RestMethod "api-mainnet.magiceden.dev/v2/xc/collections/eth/0xb99e4e9b8fd99c2c90ad5382dbc6adfdfe3a33f3/stats" -Method 'GET' -Headers $headers
   
    $response = Invoke-RestMethod $coll.statsApi -Method 'GET' -Headers $headers

    $response  | Get-ObjectMember | foreach {
                 if ($_.key -eq 'floorPrice' -or $_.key -eq 'floor_price') {
                    $floorPr = $_.value
                    }
                 if ($_.key -eq 'totalListedCount' -or $_.key -eq 'numListings') {
                    $listed = $_.value
                    }

    }

    if ($Floorpr -gt 10000000000000) {
        #write-host "Floor price before divide: $floorpr"
        $floorPr = $Floorpr / 1000000000000000000
    } 

    if ($coll.platform -eq "exchangeArt") {
        $floorpr = $floorpr / 1000000000
    }
    
    write-host "Collection: " $coll.collection "  Floor price: $Floorpr    - Total Listed: $listed - Total Coll" $Coll.totalcollection

    if ($floorPr -le $coll.alertPrice)
    {
        $desc = $coll.collection + " Floor price: " + $floorPr + " total NFTs: " + $coll.totalcollection + " Owned: " + $coll.owned
        Send-Telegram $desc

    } else {$global:AlertCount=0}


    #write-host "Listed: $Listed"
    #write-host "Floor Price: " $floorPr

}


function FindCheapNFTs() {
    #Get stats
    $Offset = 0
    $NFTSBelowAlert=0
    $Limit = 20
    $cheapNFTsList = @{}
    
    $response = Invoke-RestMethod $global:settingsObject.listApi -Method 'GET' -Headers $headers
#    $response = Invoke-RestMethod "api-mainnet.magiceden.dev/v2/xc/collections/eth/0xb99e4e9b8fd99c2c90ad5382dbc6adfdfe3a33f3/orders?sort=askAmountNum&limit=20" -Method 'GET' -Headers $headers
    
    $counter = 0
    foreach ($i in $response.items) {
        $i | Get-ObjectMember | foreach {
                if ($_.key -eq "askAmountNum" -and [decimal]$_.value -le $global:settingsObject.alertPrice) {
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
    Get-Settings #check updated settings each loop
    $Time = Get-Date
    write-host  $time
        
    foreach ($i in $global:settingsObject.collections) {
        if ($i.statsApi -ne "") {
            CheckFloorPrice $i
            start-sleep 1
        }
        if ($i.ListApi -ne "") {
            FindCheapNFTs
        }
    #    write-host $i.collection
    }
#    CheckFloorPrice
#    if ($global:settingsObject.listApi -ne $null) {
#        FindCheapNFTs
#     }

    start-sleep $global:settingsObject.sleepTimer
}

