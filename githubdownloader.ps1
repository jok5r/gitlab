$StartTime = $(get-date)
Write-Host $StartTime
$startLocation      = Get-Location
$progressPreference = 'silentlyContinue'
$api                = "https://gitlab.domain.com/api/v4"
$groupUrl           = "$api/groups"
$clone              = "true"
$pull               = "true"
$token              = "your-token"
$root               = "C:\git" # where you want git downloaded to
$g                  = 0
while($g -le ((Invoke-WebRequest -Headers @{ 'PRIVATE-TOKEN'=$token } -Uri $groupUrl -UseBasicParsing).headers).'X-Total-Pages') {
    Set-Location $root
    $request = Invoke-WebRequest -Headers @{ 'PRIVATE-TOKEN'=$token } -Uri "$api/groups?page=$g" -UseBasicParsing
    $data = ConvertFrom-Json $request.content
    $data | ForEach-Object {
        $path = $($_.full_path).replace("/","\")
        $id = $_.id
        $dir = "$root\$path"
        Write-Host $dir -ForegroundColor Green
        if (!(test-path $dir)){
            New-Item -ItemType directory $dir -Force
        }
        Set-Location $dir
        $pRequest = Invoke-WebRequest -Headers @{ 'PRIVATE-TOKEN'=$token } -Uri "$api/groups/$id/projects?per_page=100" -UseBasicParsing
        $pData = ConvertFrom-Json $pRequest.content
        foreach ($p in $pData){
            $pPath = $($p.path_with_namespace).replace("/","\")
            $projectPath = "$root\$pPath"
            Write-Host $projectPath
            if (test-path $projectPath){
                if ($pull -eq "true"){
                    write-host "Pulling: $projectPath" -ForegroundColor Cyan
                    set-location $projectPath
                    git checkout master
                    git pull
                    git checkout -
                }
            }
            else {
                if ($clone -eq "true"){
                    write-host "Cloning: $projectPath" -ForegroundColor Cyan
                    Set-Location $dir
                    git clone $p.http_url_to_repo
                }
            }
        }
    }
    $g++
}

Set-Location $startLocation
$progressPreference = 'Continue'
$elapsedTime        = $(get-date) - $StartTime
$totalTime          = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
write-host $totalTime
