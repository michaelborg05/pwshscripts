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

$run = $true
while ($run) {
    #Get stats
    $response = Invoke-RestMethod 'https://api-mainnet.magiceden.io/v2/xc/collections/eth/0xb99e4e9b8fd99c2c90ad5382dbc6adfdfe3a33f3/stats' -Method 'GET' -Headers $headers

    $response  | Get-ObjectMember | foreach {
                 if ($_.key -eq 'floorPrice') {
                    $floorPr = $_.value
                    }
                 if ($_.key -eq 'listedCount') {
                    $listed = $_.value
                    }

    }
    $floorPr = $Floorpr / 1000000000

    write-host "Listed: $Listed"
    write-host "Floor Price: " $floorPr
    start-sleep 15
}
#Get listings
#$response = Invoke-RestMethod 'api-mainnet.magiceden.dev/v2/collections/defi_land_seeds/listings?offset=0&limit=20' -Method 'GET' -Headers $headers
#$temp = $response | ConvertTo-Json 



    #[System.IO.File]::WriteAllLines("c:\temp\json.txt", $temp)

    
