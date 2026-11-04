Get-ChildItem -Recurse -Path force-app\main\default -File | Select-Object FullName, Extension | Sort-Object FullName | ForEach-Object { $_.FullName } | Set-Content -Path .filelist.txt -Encoding UTF8
Get-Content .filelist.txt | Measure-Object -Line
Write-Host 'TOTAL: ' $(Get-Content .filelist.txt | Measure-Object -Line).Line
