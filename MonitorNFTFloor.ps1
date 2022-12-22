#$global:AlertPrice= 0.175
#$global:MAxAlerts=4
$global:AlertCount=0
$global:settingsObject = ""
$global:collections = @()
$global:DailyReport = $false
$global:DailyReportText = ""

$global:Time = Get-Date
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
    
    $alertPrice = 0

    #check if a custom alert exists for this collection
    foreach ($alrt in $global:settingsObject.Alerts) {
        if ($alrt.collection -eq $coll.collection) {
            $alertPrice = $alrt.alert
            
        }
    }
    #If no custom alert, use default alert from $coll object
    if ($alertPrice -eq 0) {
        $alertPrice = $coll.alertPrice
        write-host "Alert price not found, using default collection alert price " $AlertPrice
    } 

    $name = $coll.collection
    write-host $name.PadLeft(25) "  Floor: $Floorpr    Alert: $alertPrice - Total Listed: $listed - Total Coll" $Coll.totalcollection
    IF ($global:DailyReport -eq $false -and $global:Time.timeofday -gt "00:15") {
        $global:DailyReportText =  $global:DailyReportText + "`r`n" + $Coll.Collection + "`r`nFloor: " + $Floorpr  + " Alert: " + $alertPrice + "`r`nTotal Listed: " + $listed + " Collection: " + $Coll.totalcollection + "`r`n"
    }
    if ($floorPr -le $alertPrice)
    {
        $desc = $coll.collection + " Floor: " + $floorPr + " total NFTs: " + $coll.totalcollection 
        Send-Telegram $desc

    } else {$global:AlertCount=0}


    #write-host "Listed: $Listed"
    #write-host "Floor Price: " $floorPr

}


function IterateNFTs() {
    Param([Parameter(Mandatory=$true)][object]$coll)
    $Offset = 0
    $NFTSBelowAlert=0
    $Limit = 20
    $cheapNFTsList = @{}
    foreach ($alrt in $global:settingsObject.Alerts) {
        if ($alrt.collection -eq $coll.collection) {
            $alertPrice = $alrt.alert
        }
    }
    #If no custom alert, use default alert from $coll object
    if ($alertPrice -eq 0) {
        $alertPrice = $coll.alertPrice
        write-host "Alert price not found, using default collection alert price " $AlertPrice
    } 

    
    $response = Invoke-RestMethod $coll.listApi -Method 'GET' -Headers $headers
#    $response = Invoke-RestMethod "api-mainnet.magiceden.dev/v2/xc/collections/eth/0xb99e4e9b8fd99c2c90ad5382dbc6adfdfe3a33f3/orders?sort=askAmountNum&limit=20" -Method 'GET' -Headers $headers
    if ($coll.platform.ToLower() -eq "exchangeart") {
        $NFTS = $response.contractGroups
    } Else {
        $NFTS = $response.items
    }
    $counter = 0
    $Floorpr = 0
    foreach ($i in $NFTS) {
        if ($coll.platform.ToLower() -eq "exchangeart") {
            $listprice = $i.availablecontracts.listings.data.listingAmount / 1000000000

            #write-host "Price: " $listprice " Start: " $i.availablecontracts.listings.data.start
            
            #If floor price not set yet, set to current
            if ($Floorpr -eq 0) {$floorpr = $listprice}
            #If current is less than floor, set floor to current price
            if ($Floorpr -ge $listprice) {
                $floorpr = $listprice

                #Get Unix time and compare to start time of NFT sale
                $DateTime = (Get-Date).ToUniversalTime()
                $UnixTimeStamp = [System.Math]::Truncate((Get-Date -Date $DateTime -UFormat %s))

                #If current time greater than NFT buy now time AND list price is below alert price
                if ($UnixTimeStamp -gt $i.availablecontracts.listings.data.start -and $listprice -lt $alertPrice ) {
                    $NFTSBelowAlert= $NFTSBelowAlert + 1
                    $cheapNFTsList[$NFTSBelowAlert] = $listPrice
                    write-host $coll.Collection "Below Alert Price: " $listprice " - Raising alert"
                }
            }
        } else {
            $i | Get-ObjectMember | foreach {
                if ($_.key -eq "askAmountNum" -and [decimal]$_.value -le $global:settingsObject.alertPrice) {
                   $NFTSBelowAlert= $NFTSBelowAlert + 1
                    $cheapNFTsList[$NFTSBelowAlert] = $_.value  
                    #write-host "$NFTSBelowAlert : " $_.value
                }
             }    
        }
    }
    write-host $Coll.Collection.PadLeft(25) "  Floor: $Floorpr    Alert: $alertPrice - Total Listed: " $Coll.numListings " - Total Coll" $Coll.totalcollection
    #If it is past 8am and report has not been run today yet, it will run and set indicator to true
    IF ($global:DailyReport -eq $false -and $global:Time.timeofday -gt "00:15") {
        $global:DailyReportText =  $global:DailyReportText + "`r`n" + $Coll.Collection + "`r`nFloor: " + $Floorpr  + " Alert: " + $alertPrice + "`r`nTotal Listed: " + $Coll.numListings + " Collection: " + $Coll.totalcollection + "`r`n"
    }

    $text= ""
    if ($cheapNFTsList.Count -gt 0) {
        if ($coll.platform.Tolower() -eq "exchangeart") {
             $text = $coll.collection + " Floor: " + $floorPr + " Alert Prc: " + $alertPrice + " total NFTs: " + $coll.totalcollection 
        } else {
            $cheapNFTsList.GetEnumerator() | ForEach-Object {
                $text = $text + $_.key + " - " + $_.value + " `r`n"
            }
        }
        Send-Telegram $text
    } else {$global:AlertCount=0}

}

function ExtractSeriesData() {
    Param([Parameter(Mandatory=$true)][object]$series)
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36"
    
    $response = Invoke-RestMethod $Series.SeriesAPI -Method 'GET' -Headers $headers

    #$response = $response | convertfrom-Json
    foreach ($coll in $response.contractGroups) {
        $name = $coll.mint.symbol + " - " + $coll.mint.name

        $statsURL = "https://api.exchange.art/v2/mints/editions/stats?masterEditionMintKey=" + $coll.mint.id + "&masterEditionPDA=" + $coll.mint.masterEditionAccountPDA
        $listURL =  "https://api.exchange.art/v2/mints/contracts?from=0&limit=10&filters%5BmasterEditionPDAs%5D=" + $coll.mint.masterEditionAccountPDA + "&filters%5BnftType%5D=editions&filters%5BcontractType%5D=buyNow&sort=price-lowToHigh"
        $collection = new-object PSObject -Property @{ 
            collection = $name
            platform = "exchangeArt"
            statsApi = $statsURL
            ListAPI = $listURL
            QueryType = $series.QueryType
            TotalCollection = $coll.mint.masterEditionAccount.currentSupply
            numListings = $coll.mint.stats.numListings
            lowestListingPrice = $coll.mint.stats.lowestListingPrice/1000000000
            alertPrice = ($coll.mint.stats.lowestListingPrice/1000000000)*0.8
        }
        
       # write-host $collection
        #Add collection from series into main collection list
        $global:Settingsobject.collections += $collection
    }
}

$run = $true
while ($run) {
    Get-Settings #check updated settings each loop
    $global:Time = Get-Date
    write-host  $global:Time
        
    foreach ($a in $global:settingsObject.Series){
        ExtractSeriesData $a
    }
    foreach ($i in $global:settingsObject.collections) {
        if ($i.QueryType.ToLower() -eq "statsapi") {
            CheckFloorPrice $i
        }
        if ($i.QueryType.ToLower() -eq "listapi") {
            IterateNFTs $i
        }
        start-sleep -Milliseconds 200
    }
    write-host "Daily Report Status1: "  $global:DailyReport " Time: " $global:Time
    IF ($global:DailyReport -eq $false -and $global:Time.TimeOfDay -ge "00:15") { 
        $global:DailyReport = $true
        Send-Telegram  $global:DailyReportText
    }
    write-host "Daily Report Status2: "  $global:DailyReport " Time: " $global:Time

    #Once new day ticks over, reset param to false
    IF ($global:DailyReport -eq $true -and $global:Time.TimeOfDay -lt "00:15") { 
        $global:DailyReport = $false
        $global:DailyReportText = ""
    }

    start-sleep $global:settingsObject.sleepTimer
}

