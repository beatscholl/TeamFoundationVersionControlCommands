<#
    .SYNOPSIS
       creates a new workspacd ans associated mappings.
    .PARAMETER Version
        Specifies the version of Visaual Studio installed. This is used to find the tf.exe
    .PARAMETER TeamProjectCollectionUrl
        The URL of the team project collection that contains the workspace about which you want to create, edit, delete, or display information (for example, http://myserver:8080/tfs/DefaultCollection).
    .PARAMETER Name
        Specifies a name for the workspace to create.
    .PARAMETER Folder
        Specifies the root folder to map the project to
    .PARAMETER Repositories
        Specifies an array of hashtables containing serverFolder and localFolder.
        @(@{serverFolder = "$/MyProject/Trunk"; localFolder="trunk"},
    .EXAMPLE
        Set-TFSWorkspace -Name MyWorkspace -Folder c:\tfs\MyProject
#>
function New-TFSWorkspace {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(mandatory=$false)]
        [string]
        $TeamProjectCollectionUrl = "https://tfs.itsystems.ch/tfs/Projects",

        [Parameter(mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [Parameter(mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path -Path $_ -PathType Container })]
        [string]
        $Folder,

        [Parameter(mandatory=$false)]
        [hashtable[]]
        $Repositories
    )
       
    Set-Location -Path "$Folder"

    # check if workspace already exists
    $exists = -not $(tf workspaces $Name).Contains("No workspace matching $Name")

    if($exists -eq $true) {
        Write-Warning "Workspace $Name already exists."
        tf workspaces
        return
    }

    if ($PSCmdlet.ShouldProcess("$TeamProjectCollectionUrl","tf workspace /new $Name")) {
        Write-Host "create new workspace $Name"
        tf workspace /new "$Name" /noprompt /collection:"$TeamProjectCollectionUrl"
    }

    $Repositories | Where-Object {$_} | Foreach-Object {
        $repository = [hashtable]$_
        if($PSCmdlet.ShouldProcess($repository.localfolder,"Set-TFSFolderMapping")) {
            Set-TFSFolderMapping -Workspace $Name -ServerFolder $repository.serverFolder -Localfolder $(Join-Path -Path $folder -ChildPath $repository.localFolder)
        }
    }

    # unmap rootfolder
    if ($PSCmdlet.ShouldProcess("$/","tf workfold /unmap")){	
        tf workfold /unmap "$/" 
    }

    Write-Host "DONE!"
}

function Test-TFSWorkspace {
	[CmdletBinding()]
	param(
		[Parameter(mandatory=$false)]
        [string]
        $TeamProjectCollectionUrl = "https://tfs.itsystems.ch/tfs/Projects",

        [Parameter(mandatory=$true, ValueFromPipeline, ValueFromPipelineByPropertyName)]		
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
	)
	
	Process {
		$exist = -not $(tf workspaces $Name).Contains("No workspace matching $Name")
		$exist
	}
}

function Get-TFSWorkspaces {
	[CmdletBinding()]
    param (
        [Parameter(mandatory=$false)]
        [string]
        $TeamProjectCollectionUrl = "https://tfs.itsystems.ch/tfs/Projects"
	)
	
	$workspaces = $(tf workspaces) -split '[\r\n]'
	
}

function Remove-TFSWorkspace {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    param (
        [Parameter(mandatory=$false)]
        [string]
        $TeamProjectCollectionUrl = "https://tfs.itsystems.ch/tfs/Projects",

        [Parameter(mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
    )
	
	if (-not (Test-TFSWorkspace -TeamProjectCollectionUrl $TeamProjectCollectionUrl -Name $Name)){
		Write-Warning "Workspace $Name could not be found!"
		return
	}
	
	if( $PSCmdlet.ShouldProcess($Name,"tf workspace /delete")){
		Write-Host "deleting workspace $Name"
		tf workspace /delete /collection:"$TeamProjectCollectionUrl" $Name
	}
}

function Set-TFSFolderMapping {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Workspace,
		
		[Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ServerFolder,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $LocalFolder
    )

    if ($PSCmdlet.ShouldProcess("$LocalFolder","tf workfold /map $ServerFolder")) {	
        Write-Host ("mapping {0} to {1}" -f $ServerFolder, $LocalFolder)
        tf workfold /map "$ServerFolder" "$LocalFolder" /workspace:"$Workspace"
    }
}

function Set-TFSAlias {
	# VS2017
	if($env:VS150COMNTOOLS -ne $null) {
		Set-Alias -Name tf -Value "$env:VS150COMNTOOLS..\IDE\tf.exe" -Scope Global -ErrorAction Stop -Verbose
		return
	}

	#VS2015
	if($env:VS140COMNTOOLS -ne $null) {
		Set-Alias -Name tf -Value "$env:VS140COMNTOOLS..\IDE\tf.exe" -Scope Global -ErrorAction Stop -Verbose
		return
	}

	#VS2013
	if($env:VS120COMNTOOLS -ne $null) {
		Set-Alias -Name tf -Value "$env:VS120COMNTOOLS..\IDE\tf.exe" -Scope Global -ErrorAction Stop -Verbose
		return
	}

	#VS2012
	if($env:VS110COMNTOOLS -ne $null) {
		Set-Alias -Name tf -Value "$env:VS110COMNTOOLS..\IDE\tf.exe" -Scope Global -ErrorAction Stop -Verbose
		return
	}
	
	Write-Error "tf.exe could not be found!"
}

Set-TFSAlias
