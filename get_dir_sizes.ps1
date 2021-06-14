#Enter the Directory Name which contains the list of folder (and nested folders)
$folderName = $PSScriptRoot
 
#Finding Parent Folder Size
$parentFolder = Get-ChildItem $folderName -recurse -force | Where-Object {$_.PSIsContainer -eq $false} | Measure-Object -property Length -sum | Select-Object Sum
$folderName + ";" + "{0:N2}" -f ($parentFolder.sum / 1MB) + ";MB"
 
#Finding all the Child Folders Size
$childFolders = Get-ChildItem $folderName -recurse -force | Where-Object {$_.PSIsContainer -eq $true} | Sort-Object
foreach ($i in $childFolders){
    $eachChild = Get-ChildItem $i.FullName -recurse -force | Where-Object {$_.PSIsContainer -eq $false} | Measure-Object -property Length -sum | Select-Object Sum
    $i.FullName + ";" + "{0:N2}" -f ($eachChild.sum / 1MB) + ";MB"
}
