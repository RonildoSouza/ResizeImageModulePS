function Resize-Image {
    <#
    .SYNOPSIS
        Resize-Image resizes an image file.

    .DESCRIPTION
        This function uses the native .NET API to resize an image file and save it to a file.
        It supports the following image formats: BMP, GIF, JPEG, PNG, TIFF

    .PARAMETER InputFile
        Type [string]
        The parameter InputFile is used to define the value of image name or path to resize.

    .PARAMETER OutputFile
        Type [string]
        The parameter OutputFile is used to define the value of output image resize.

    .PARAMETER Width
        Type [int32]
        The parameter Width is used to define the value of new width to image.

    .PARAMETER Height
        Type [int32]
        The parameter Height is used to define the value of new height to image.

    .PARAMETER ProportionalResize
        Type [bool]
        The optional parameter ProportionalResize is used to define if execute proportional resize.

    .EXAMPLE
        Resize-Image -InputFile "C:/image.png" -OutputFile "C:/image2.png" -Width 300 -Height 300

    .NOTES
        Author: Ronildo Souza
        Last Edit: 2018-10-09
        Version 1.0.0 - initial release
        Version 1.0.1 - add proportional resize
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$InputFile,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputFile,
        [Parameter(Mandatory = $true)]
        [int32]$Width,
        [Parameter(Mandatory = $true)]
        [int32]$Height,
        [Parameter(Mandatory = $false)]
        [bool]$ProportionalResize = $true)

    # Add assemblies
    Add-Type -AssemblyName System
    Add-Type -AssemblyName System.Drawing

    $image = [System.Drawing.Image]::FromFile((Get-Item $InputFile))

    $ratioX = $Width / $image.Width;
    $ratioY = $Height / $image.Height;
    $ratio = [System.Math]::Min($ratioX, $ratioY);

    [int32]$newWidth = If ($ProportionalResize) { $image.Width * $ratio } Else { $Width }
    [int32]$newHeight = If ($ProportionalResize) { $image.Height * $ratio } Else { $Height }

    $destImage = New-Object System.Drawing.Bitmap($newWidth, $newHeight)

    # Draw new image on the empty canvas
    $graphics = [System.Drawing.Graphics]::FromImage($destImage)
    $graphics.DrawImage($image, 0, 0, $newWidth, $newHeight)
    $graphics.Dispose()

    # Save the image
    $destImage.Save($OutputFile)
}

function Resize-ImagesInFolder {
    <#
    .SYNOPSIS
        Resize-ImagesInFolder resizes an image files in folder.

    .DESCRIPTION
        This function uses the native .NET API to resize an image file and save it to a file.
        It supports the following image formats: BMP, GIF, JPEG, PNG, TIFF

    .PARAMETER Width
        Type [int32]
        The parameter Width is used to define the value of new width to image.

    .PARAMETER Height
        Type [int32]
        The parameter Height is used to define the value of new height to image.

    .PARAMETER FolderPath
        Type [string]
        The optional parameter FolderPath is used to define the value of image files folder path.

    .PARAMETER ProportionalResize
        Type [bool]
        The optional parameter ProportionalResize is used to define if execute proportional resize.

    .EXAMPLE
        Resize-ImagesInFolder -Width 300 -Height 300 [-FolderPath]

    .NOTES
        Author: Ronildo Souza
        Last Edit: 2018-10-09
        Version 1.0.0 - initial release
        Version 1.0.1 - add proportional resize
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)][int32]$Width,
        [Parameter(Mandatory = $true)][int32]$Height,
        [Parameter(Mandatory = $false)]
        [string]$FolderPath = "",
        [Parameter(Mandatory = $false)]
        [bool]$ProportionalResize = $true)

    $imageList = Get-ChildItem -Path $FolderPath | Where-Object {$_.Extension -in (".png", ".jpg", ".jpeg", ".bmp", ".gif", ".tiff")}

    if ($imageList.Length -gt 0) {
        foreach ($image in $imageList) {
            $pathWindowsTemp = $env:SystemRoot + "\temp\pictures-rim_ps\"
            $extension = $image.Extension
            $imageInputFullName = $image.FullName
            $imageInputBaseName = $image.BaseName
            $imageOutput = $FolderPath + "\" + $imageInputBaseName + "_RESIZE-RIM_PS" + $extension
            $imageInput = $pathWindowsTemp + $imageInputBaseName + $extension
            $imageNameBKP = $FolderPath + "\" + $imageInputBaseName + $extension + ".bkp"

            # Create temp folder and image file copy
            New-Item -ItemType Directory -Path $pathWindowsTemp -Force
            Copy-Item $imageInputFullName $pathWindowsTemp -Force

            # Create backup image file
            if (!(Test-Path "$imageNameBKP" -PathType Leaf)) {
                Rename-Item -Path "$imageInputFullName" -NewName "$imageNameBKP" -Force
            }

            # Resize the current image file of loop
            Resize-Image -InputFile "$imageInput" -OutputFile "$imageOutput" -Width $Width -Height $Height -ProportionalResize $ProportionalResize

            # "Rename" item with override
            $Destination = Join-Path -Path $image.Directory.FullName -ChildPath "$imageInputBaseName$extension"
            Move-Item -Path $imageOutput -Destination $Destination -Force

            Write-Output $image.Name
        }

        Read-Host -Prompt "Success Resize!"
        Exit-PSHostProcess
    }
    else {
        Write-Error "*** Folder not contain image files! ***"
    }
}

Export-ModuleMember -Function Resize-Image, `
                              Resize-ImagesInFolder