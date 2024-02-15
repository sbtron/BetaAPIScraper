# TODO: Update to the packages\teams-js\src directory
$folderPath = "LocalPathTo\microsoft-teams-library-js\packages\teams-js\src"

#csv file will be in the same folderpath by default
$csvFilePath = "$folderpath\APIs.csv"



$trackedFunctions = New-Object System.Collections.ArrayList

foreach ($filePath in (Get-ChildItem $folderPath -Recurse -Filter *.ts).FullName) {
    $fileContent = Get-Content $filePath
    $relativepath = $filePath.Substring($filePath.IndexOf("src")+4);
    if ($relativepath.IndexOf("\") -gt 0)
        {
            $type = $relativepath.Substring(0,$relativepath.IndexOf("\"));
        }
    $tsfilename = $relativepath.Substring($relativepath.IndexOf("\")+1,($relativepath.Length - ($relativepath.IndexOf("\")+1)));
            
    $inCommentBlock = $false
    $inBetaFunction = $false
    $inDeprecatedFunction = $false
    $functionName = ""
    $namespace = ""

    foreach ($line in $fileContent) {
        if ($line -match "export namespace\s+(\w+)") {
            if ($namespace -eq ""){
            $namespace = $Matches.Item(1)
            }
            else {
            $namespace = $namespace+"."+$Matches.Item(1); 
            }
        }
        if ($line -match "\/\*\*") {
            $inCommentBlock = $true
            $inBetaFunction = $false
            $inDeprecatedFunction = $false
        }
        if ($inCommentBlock -and $line -match "\@beta") {
            $inBetaFunction = $true
        }
        if ($inCommentBlock -and $line -match "\@deprecated") {
            $inDeprecatedFunction = $true
        }
        if ($line -match "\*\/") {
            $inCommentBlock = $false
        }
        if ($inBetaFunction -and $line -match "export function\s+(\w+)") {
            $functionName = $Matches.Item(1);
            $trackedFunctions.Add([PSCustomObject]@{FilePath=$relativepath; Type=$type; tsfilename=$tsfilename; Namespace=$namespace; State='Beta'; Function=$functionName}) | Out-Null
            $inBetaFunction = $false

        }
        if ($inDeprecatedFunction -and $line -match "export function\s+(\w+)") {
            $functionName = $Matches.Item(1)
            $trackedFunctions.Add([PSCustomObject]@{FilePath=$relativepath; Type=$type; tsfilename=$tsfilename; Namespace=$namespace; State='Deprecated'; Function=$functionName}) | Out-Null
            $inDeprecatedFunction = $false
        }
    }
}

$trackedFunctions | Export-Csv -Path $csvFilePath -NoTypeInformation -Force

Write-Output "CSV file exported to $csvFilePath"
