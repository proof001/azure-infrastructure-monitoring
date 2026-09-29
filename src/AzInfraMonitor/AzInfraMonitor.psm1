$public = Join-Path $PSScriptRoot 'Public'
$private = Join-Path $PSScriptRoot 'Private'

Get-ChildItem -Path $private -Filter '*.ps1' -ErrorAction SilentlyContinue | ForEach-Object {
    . $_.FullName
}

Get-ChildItem -Path $public -Filter '*.ps1' -ErrorAction SilentlyContinue | ForEach-Object {
    . $_.FullName
}

Export-ModuleMember -Function (Get-ChildItem -Path $public -Filter '*.ps1' | ForEach-Object { $_.BaseName })
