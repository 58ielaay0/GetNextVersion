### Minimum powershell version required : 7.0 ###
param
(
    [Parameter(mandatory=$true)]
	[PSCredential] $Credential,
    [Parameter(mandatory=$true)]
    [string] $NexusURL,
    [Parameter(mandatory=$true)]
	[string] $Repository,
    [Parameter(mandatory=$true)]
    [string] $RepositoryDirectory,
    [string] $CommitHash
)

function Get-RepoComponents
{
    param
    (
	[Parameter(mandatory=$true)]
	[PSCredential] $Credential,
        [Parameter(mandatory=$true)]
	[string] $RepositoryUrl
    )

    try
    {
        $results = Invoke-RestMethod -Uri $RepositoryUrl -Authentication Basic -Credential $Credential
        $components = $results.items

        while (([string]::IsNullOrEmpty($results.continuationToken)) -eq $false) {

            $newURL = $RepositoryUrl+"&continuationToken="+$results.continuationToken

            $results = Invoke-RestMethod -Uri $newURL -Authentication Basic -Credential $Credential

            $components = $components + $results.items
        }
    }
    catch
    {
        $ErrorMessage = $_.Exception.Message
        Write-Error "Could not retrieve components from repository!"
        Write-Error "$ErrorMessage"

        return $null;
    }

    return $components
}

function Get-RepoGroupComponents
{
    param
    (
	[Parameter(mandatory=$true)]
	[PSCredential] $Credential,
        [Parameter(mandatory=$true)]
	[string] $NexusURL,
	[Parameter(mandatory=$true)]
	[string] $Repository,
	[Parameter(mandatory=$true)]
	[string] $Group
    )

    try
    {
    	$RepositoryURL = $NexusURL + '/service/rest/v1/search?repository=' + $Repository + '&group=/' + $Group
        $results = Invoke-RestMethod -Uri $RepositoryUrl -Authentication Basic -Credential $Credential
        $components = $results.items

        while (([string]::IsNullOrEmpty($results.continuationToken)) -eq $false) {

            $newURL = $RepositoryUrl+"&continuationToken="+$results.continuationToken

            $results = Invoke-RestMethod -Uri $newURL -Authentication Basic -Credential $Credential

            $components = $components + $results.items
        }
    }
    catch
    {
        $ErrorMessage = $_.Exception.Message
        Write-Error "Could not retrieve components from repository!"
        Write-Error "$ErrorMessage"

        return $null;
    }

    return $components
}

function Get-LastPackage
{
    param
    (
		[Parameter(mandatory=$true)]
		$Components,
        [Parameter(mandatory=$true)]
		[string] $Group
    )

    Write-Host "Filter to get the last $Group package"

    #$groupComponents = $Components | Where-Object {($_.group -like "/$Group")} 
    #$lastPackage = $groupComponents | Sort-Object {$_.assets.blobCreated} -Descending | Select-Object -First 1
    
    $lastPackage = $Components | Sort-Object {$_.assets.blobCreated} -Descending | Select-Object -First 1

    if(!$lastPackage)
    {
        return $null;
    }

    $lastPackageName = Read-Filename $lastPackage.name
    return $lastPackageName
}

function Get-PackageVersion
{
    param
    (
		[Parameter(mandatory=$true)]
		[string] $PackageName
    )

    $packageVersion = [io.path]::GetFileNameWithoutExtension($PackageName).Split("-")[1]

    if(!$packageVersion)
    {
        $packageVersion = [io.path]::GetFileNameWithoutExtension($PackageName).Split("_")[1]
    }

    return $packageVersion
}

function IncrementVersion
{
    param
    (
		[Parameter(mandatory=$true)]
		[string] $PackageVersion
    )

    $versions = $PackageVersion.Split(".")

    $major = $versions[0] -as [int]
    $minor = $versions[1] -as [int]
    $build = $versions[2] -as [int]

    $build++

    return "$major.$minor.$build"
    
}

function Read-Filename
{
	param([string] $Path)
	return Split-Path $Path -leaf
}

####################
### Script Start ###
####################

$components = Get-RepoGroupComponents -Credential $Credential -NexusURL $NexusURL -Repository $Repository -Group $RepositoryDirectory

if(!$components) 
{
    $Version= '0.0.0'
} else {
    $packageName = Get-LastPackage -Components $components -Group $RepositoryDirectory
    
    if(!$packageName) 
    {
        $Version= '0.0.0'
    } else {
        $packageVersion = Get-PackageVersion -PackageName $packageName 
        $Version = IncrementVersion -PackageVersion $packageVersion   
    }
}

if($CommitHash)
{
    $shortCommitHash = $CommitHash.SubString(0,7)
    $Version += ".$shortCommitHash"
}

return $Version
