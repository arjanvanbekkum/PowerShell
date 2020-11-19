# check at 06:15 UTC if the FSD records are created
    $date = New-Object "System.DateTime" -ArgumentList (Get-Date).Year, (Get-Date).Month, (Get-Date).Day
    $date = $date.ToUniversalTime().AddHours(6).AddMinutes(15).ToString("s") + "Z"
