## DAILY TOOLING ##

# Use this to show the most current logfile content, filtered by the searchstring
Function sky-showloglive {
    [CmdletBinding()]
    Param(
    [string]$searchstring=""
    )

    # find logfile /Dev/web/App_Data/Logs/???
    $rootPath = git rev-parse --show-toplevel
    $logPath = "$rootPath/Dev/web/App_Data/Logs"

    Write-Host $logPath  
    cd $logPath

    $filename = Get-ChildItem -Path $logPath | Sort-Object LastAccessTime -Descending | Select -First 1

    Write-Host "$logPath/$filename"

    if([string]::IsNullOrEmpty($searchstring)) {
        cat "$logPath/$filename" -wait
    } else {
        cat "$logPath/$filename" -wait | select-string $searchstring
    }
}


# Function to automate most used git-workflow
Function sky-git-add {
    # sky-git -c "Besked kommer her"
    [CmdletBinding()]
    Param(
    [string]$commitMsg="",
    [switch]$ppOnly
    )

    # find aktuelle sti og gem til senere
    $currentPath = (Get-Item -Path ".\" -Verbose).FullName

    # gå til root-folder
    $rootPath = git rev-parse --show-toplevel
    cd $rootPath

    # udfør ikke commit hvis ppOnly er sat (pull/push only)
    if(-not $ppOnly) {

        if([string]::IsNullOrEmpty($commitMsg)) {
            Write-Warning "Du mangler commitmessage" 
            $commitMsg = Read-Host -Promt "Skriv commitmessage: "
        }

        # find sagsnr fra js-fil
        $filename = Get-ChildItem | Where-Object  {$_.Name -match "[0-9999][a-å][a-å].js"}
        $cm = "[$($filename.Name.Split(".")[0])] $commitMsg"
        
        # add alle ikke tracked filer
        git add --all

        # commit lortet 
        git commit -m $cm 
    }
    

    git pull

    git push

    # gå tilbage til den oprindelige folder
    cd $currentPath
}


# Function to pull from origin and grunt dev
Function sky-git-grunt {

    $pull = git pull

    if(-not $pull.Equals("Already up-to-date.")) {
        grunt dev
    } else {
        Write-Host "No news, no grunt!"
    }
}


# Function to pull from origin, npm install and grunt dev
Function sky-git-npmgrunt {

    $pull = git pull

    if(-not $pull.Equals("Already up-to-date.")) {
        npm install
        grunt dev
    }else {
        Write-Host "No news, no grunt!"
    }
}


## SETUP TOOLING ##

# Sets up repo from BitBucket, renames folder, runs npm install, grunt, sets up local IIS and starts VS Solution
Function sky-setup-local {
    [CmdletBinding()]
    Param(
    [string]$repourl="",
    [string]$customer="",
    [int]$umbracoMainVersion=7,
    [string]$casenumber=""
    )

    #tjek paramsvalues
    if([string]::IsNullOrEmpty($repourl)) {
        Write-Warning "Du mangler repourl" 
        $repourl = Read-Host -Promt "Angiv repourl"
    }

    if([string]::IsNullOrEmpty($customer)) {
        Write-Warning "Du mangler kundenavn" 
        $customer = Read-Host -Promt "Angiv kundenavn"
    }

    if([string]::IsNullOrEmpty($casenumber)) {
        Write-Warning "Du mangler sagsnummer" 
        $casenumber = Read-Host -Promt "Angiv sagsnummer (kun tal)"
    }



    #clone git
    Write-Host "Cloning..."
    git clone $repourl

    #find current foldername
    #https://rpjengaard@bitbucket.org/skybrud/kora-website-umbraco-6.git
    $cloneUrlArray = $repourl.Split("/")
    $cloneFolderName = $cloneUrlArray[$cloneUrlArray.Length-1].Split(".")[0]
    $newFolderName = "$casenumber $customer - Website - Umbraco $umbracoMainVersion"

    #rename folder
    #Write-Host "$cloneFolderName" "$newFolderName"
    Write-Host "Renaming..."
    Rename-Item "$cloneFolderName" "$newFolderName"

    cd $newFolderName

    #npm install
    Write-Host "npm install..."
    npm install

    #grunt dev
    Write-Host "grunt that pig..."
    grunt dev

    #setup local iss
    $caseNameSuffix = $customer.Substring(0,2).ToLower()
    $caseName = "$casenumber$caseNameSuffix"

    $location = Get-Location
    $gitRoot = git rev-parse --show-toplevel
    cd $gitRoot
    sky-setup-local-iis -inputCasenumber $caseName -inputFolderName $newFolderName -inputPath $location
    



    #start solutionfile
    cd "d:"
    cd "dev"


    $solutionFile = Get-ChildItem | Where-Object  {$_.Name -match ".sln"}
    $solutionFileName = $solutionFile.Name

    #Write-Host $solutionFileName
    Write-Host "Start solution (VS)..."
    Invoke-Item ".\$solutionFileName"

    cd ..

}


# Sets up local IIS + AppPool
Function sky-setup-local-iis {
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory = $true)][string]$inputCasenumber,
    [Parameter(Mandatory = $true)][string]$inputFolderName,
    [Parameter(Mandatory = $true)][string]$inputPath
    )

    Write-Host "opretter IIS"
    Import-Module WebAdministration
    $iisAppPoolName = $inputCasenumber
    $iisAppPoolDotNetVersion = "v4.0"
    $iisAppName = $inputCasenumber
    $directoryPath = "$inputPath\Dev\web"

    cd IIS:\AppPools\

    #check if the app pool exists
    if (!(Test-Path $iisAppPoolName -pathType container))
    {
        #create the app pool
        $appPool = New-Item $iisAppPoolName
        $appPool | Set-ItemProperty -Name "managedRuntimeVersion" -Value $iisAppPoolDotNetVersion
    }

    #navigate to the sites root
    cd IIS:\Sites\

    #check if the site exists
    if (Test-Path $iisAppName -pathType container)
    {
        return
    }

    #create the site
    $iisApp = New-Item $iisAppName -bindings @{protocol="http";bindingInformation=":80:" + "$iisAppName.rpjengaard"} -physicalPath $directoryPath
    $iisApp | Set-ItemProperty -Name "applicationPool" -Value $iisAppPoolName
}