# TODO: Update to the teams-js\src directory
$folderPath = "PathTo\teams-js\src"

#csv file will be in the same folderpath by default
$csvFilePath = "$folderpath\output.csv"



$betaFunctions = New-Object System.Collections.ArrayList

foreach ($filePath in (Get-ChildItem $folderPath -Recurse -Filter *.ts).FullName) {
    $fileContent = Get-Content $filePath
    $inCommentBlock = $false
    $inBetaFunction = $false
    $functionName = ""
    $namespace = ""

    foreach ($line in $fileContent) {
        if ($line -match "namespace\s+(\w+)") {
            $namespace = $Matches.Item(1)
        }
        if ($line -match "\/\*\*") {
            $inCommentBlock = $true
        }
        if ($inCommentBlock -and $line -match "\@beta") {
            $inBetaFunction = $true
        }
        if ($line -match "\*\/") {
            $inCommentBlock = $false
        }
        if ($inBetaFunction -and $line -match "function\s+(\w+)") {
            $functionName = $Matches.Item(1)
            $relativepath = $filePath.Substring($filePath.IndexOf("src")+4);
            $betaFunctions.Add([PSCustomObject]@{FilePath=$relativepath; Namespace=$namespace; Function=$functionName}) | Out-Null
            $inBetaFunction = $false
        }
    }
}

$betaFunctions | Export-Csv -Path $csvFilePath -NoTypeInformation -Force

Write-Output "CSV file exported to $csvFilePath"
