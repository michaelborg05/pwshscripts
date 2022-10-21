$ItemNo = "124626"
$ItemDescription = "PS5 Digital Console"
#$ItemNo = "124628"
#$ItemDescription="PS5 DualSense charging station"

#$BigWURL = "https://api.bigw.com.au/api/availability/v0/product/$ItemNo?storeId=0117&deliveryPostcode=2137&deliverySuburb=NORTH%20STRATHFIELD"
$outputfile = "bigwSite2.txt" 
$global:MaxAlerts = 1
$global:AlertCount=0

Function Send-Telegram {
    Param([Parameter(Mandatory=$true)][String]$Message)
    $Telegramtoken = "594185771:AAEGBNDncM3455gyutHlwjTlnPIdeRs0dYE"
    #$Telegramchatid = "416082917"
    $Telegramchatid = "-773724465"#NFTSniper
    write-host $Message
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $Response = Invoke-RestMethod -Uri "https://api.telegram.org/bot$($Telegramtoken)/sendMessage?chat_id=$($Telegramchatid)&text=$($Message)"
    $global:AlertCount= $global:AlertCount + 1
    if ($global:AlertCount -ge $global:MaxAlerts) {
        $Message="Alerts received in short time. Pausing script for 30mins"
#        $Response = Invoke-RestMethod -Uri "https://api.telegram.org/bot$($Telegramtoken)/sendMessage?chat_id=$($Telegramchatid)&text=$($Message)"
        start-sleep 1800
        $global:AlertCount=0
    }
}

Function write-log {
Param([Parameter(Mandatory=$true)][String]$msg)
   $CurrTime = Get-Date
    Write-Output "$CurrTime $msg" >> $outputfile

}


$run = $true
while ($run) {
    write-log "Starting WS Call"
    try 
    {
        $URL = "https://api.bigw.com.au/api/availability/v0/product/" + $ItemNo + "?storeId=0117&deliveryPostcode=2137&deliverySuburb=NORTH%20STRATHFIELD"
        $Path = "/api/availability/v0/product/" + $ItemNo  + "?storeId=0117&deliveryPostcode=2137&deliverySuburb=NORTH%20STRATHFIELD"
        write-host $URL
        $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
        $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.5112.81 Safari/537.36"
        #$session.Cookies.Add((New-Object System.Net.Cookie("rr_rcs", "eF5j4cotK8lM4bM0N9Y11DVkKU32MEk0MzFOMjfRTbSwMNI1SUlJ1DVKM0rSNU01TU1NSTFJTLFIAgCLmw73", "/", ".bigw.com.au")))
        $session.Cookies.Add((New-Object System.Net.Cookie("X-Correlation-ID", "e1bcfe83-77ae-42e3-b93a-526fc4fb76d9", "/", "api.bigw.com.au")))
        #$session.Cookies.Add((New-Object System.Net.Cookie("AWSELB", "05899F9F144D6921751B7C597B830B2FF46FF797A86BF0124D4794146D22F0904FE9FD2AA571120DF3BC81117F078C7D2ADF85F0E7C912DCC51D0D6FFAB8B7AC4C9DD512EB", "/", "api.bigw.com.au")))
        #$session.Cookies.Add((New-Object System.Net.Cookie("AWSELBCORS", "05899F9F144D6921751B7C597B830B2FF46FF797A86BF0124D4794146D22F0904FE9FD2AA571120DF3BC81117F078C7D2ADF85F0E7C912DCC51D0D6FFAB8B7AC4C9DD512EB", "/", "api.bigw.com.au")))
        #$session.Cookies.Add((New-Object System.Net.Cookie("bm_sz", "8335A77A7FF0C88DFC24A1AAD4ECBC10~YAAQHQUgF3I/5+2CAQAAttEn9xCaVfsUvoXTFHView2YjuLXceo5pHO252tCEA32geDWesmVIE2/zzFWG8lIXYT0B42+AYxCID6sBWyx37AUejjGgFZCLJ2xdbpGYUqAse0FVVOeBFBtUB8kDs+xksTtfDOjoGyhfOQ/MFhcKROc/yo3Xu/r1Kw3CBM9ci6OFBtA1HWuoP2J1+skJD6bi9uZKrXulncQkBu9QFAbwb0FsdRY53AC0e/FC5f1beNroV5eG+elDoXaDOo8O+41TAkfhpwmUC3SC+46W33eVdvTNIRr~4273219~4604227", "/", ".bigw.com.au")))
        #$session.Cookies.Add((New-Object System.Net.Cookie("JSESSIONID", "963422129221BF4A036922FFDB518D56", "/", "api.bigw.com.au")))
        #$session.Cookies.Add((New-Object System.Net.Cookie("ak_bmsc", "4A4B12F1D0126561CC8C25EAC389ECE7~000000000000000000000000000000~YAAQHQUgF3dA5+2CAQAAAdkn9xB0ExV2ZHvcXmMAehV0PzgGyz9q+DH5Vp5wkTUbfdZYA72npn2lnlqvKhQUjyA3t2tvTIoZqm0WJDJMaqsvC/dJW5180QJRgoYJSwzIqwzaPHU+q0VqQtDlA3RnXYbeEJxOMDtX7vJ4cYHUqYaU891h88tsILV4e6yI83WCrOFGbtxwFNVQlGA0sfS8jbGfC88LXDQO1NUb1vyQQ+QqTbbKDlx0uYAqDZRz/XbM/OkoYT24O2L1S8Fd/HCjHmVVtH8i7WoPkaMyPqhEv7sQYS2/xPOBiATRXNXlC7plvAgUopTmO81OfzO8rSGT1vvh9Cs1HUI1JsxFDaRgJWzAUGkMG3VIHgl8HYfVtnfPyKrUpOVYD6ak2WZZGT0+xLTujr/kb3Qa9b71sS8dYRg0Vmyal9R+FZTykOM+7eziK9JKrkAzgaKabu1yv44vHbnEDAw9DJG+eTKxWR9O+iflIpanriU80uafvgw=", "/", ".bigw.com.au")))
        #$session.Cookies.Add((New-Object System.Net.Cookie("_abck", "681194C3A1C543B0F8CB4276DC6AE7BB~0~YAAQLAUgFxjCF9KCAQAAWPYq9wh+TMhfGnTTdtHVeGo7svjyTweD61hWHms+uhU8XGt+4ulTIpKoe8bx4ibr17F8j6SVSK5Pt58/ZkzmFEl2Bla6w0JhpVV0knDuDC0EPgvGkEZaKh+6gnRgRFSgxyFV/jcFfzgOxg3ChShRYkWzAWWFV6qDYNnJs7xF4wZjRL5414xpTK8QK2zX+Ae4YUfbbMfONtxyO37gEGmQayRSbxU5hnlS6M97nhKliGNJJe2JUa6xqmbo/cbuSRDhnakNrujqzBu5ttpZc7tHDuPOanpqJjzKwDG9syIzdmdE673ZM2dN+qaBDU7X2/AqWAEsGeuJaWsY8+iOnrGQ0kb3fjrOsyQjjPS4wgoM0yYw+x0B4dmI7j3jSCxP9aOUv4hcUgbT1myLvQ==~-1~-1~-1", "/", ".bigw.com.au")))
        #$session.Cookies.Add((New-Object System.Net.Cookie("AKA_A2", "A", "/", ".bigw.com.au")))
        #$session.Cookies.Add((New-Object System.Net.Cookie("bm_sv", "28C472BA9AAEB918FDB3D900207AE045~YAAQHQUgF6Zi9u2CAQAAEdJy9xCO1XcUGxwhSiCmit3+jF8BIq17yyiIAwiW9K7bn1+N2cILSSjZ8aEMi3pkUgibczNLosfrsn1exxEsJDHJHdg12X3vc1Fr0YNjZdwSlE/+mbs0XIxYiOrAB5U9LGrPF/EUHhEaniyWEXZOLkvH9g2Sk/2W3ZlGtknuDbrwxMlk9/VftoJsdlZXEpB+BKx60vSeNFyFfJa/BBGuib5naWxs659SDyROaNPGPNyWi/Y=~1", "/", ".bigw.com.au")))
        $Response = Invoke-WebRequest -UseBasicParsing -Uri $URL `
        -WebSession $session `
        -Headers @{
        "authority"="api.bigw.com.au"
          "method"="GET"
          "path"=$Path
          "scheme"="https"
          "accept"="application/json, text/plain, */*"
          "accept-encoding"="gzip, deflate, br"
          "accept-language"="en-US,en;q=0.9"
          "origin"="https://www.bigw.com.au"
          "referer"="https://www.bigw.com.au/"
          "sec-fetch-dest"="empty"
          "sec-fetch-mode"="cors"
          "sec-fetch-site"="same-site"
          "sec-gpc"="1"
        }
        #$Response = Invoke-WebRequest $BigWURL -TimeoutSec 60
        write-host $response
        #write-host $Response

        #write-host $response

        $obj= $response | ConvertFrom-Json 

        $instoreresult = $obj.products.$ItemNo.instore.'0117'.available
        $stddelresult  = $obj.products.$ItemNo.delivery.'Standard Delivery'.available

        #write-host $result

        if ($instoreresult -eq $false -and $stddelresult -eq $false) 
        {  
            $desc = "Item $ItemDescription - Item No $ItemNo. NOT AVAILABLE"
    #        Send-Telegram $desc
            write-log $desc

            write-host "Not available"
        }
        if ($instoreresult -eq $true -or $stddelresult -eq $true) { 
            write-host "available"
            $desc = "Item $ItemDescription - Item No $ItemNo. `n Instore - $instoreresult `n Std Delivery - $stddelresult"
            write-log $desc
            Send-Telegram $desc

        }


    }
    catch
    {
        $_.Exception.Message
        write-log $_.Exception.Message
    }

    start-sleep 60
}


