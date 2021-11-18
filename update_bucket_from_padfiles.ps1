# This file will get the full list of PAD files from nirsoft.net
# and download each PAD file, _for all_ of the utilities available
# and create a scoop JSON file from it.

$tempFile = "./tempfile.zip"
$outpath = "./bucket"
if (!(Test-Path -Path $outpath)) {
  mkdir $outpath | Out-Null
}
$unzipPath = "./unzipped_file"
if (!(Test-Path -Path $unzipPath)) {
  mkdir $unzipPath | Out-Null
}

$padurl = "https://www.nirsoft.net/pad/pad-links.txt"
$padfiles = (New-Object System.Net.WebClient).DownloadString($padurl)

ForEach ($xmlurl in $($padfiles -split "`n")) {
  if ($xmlurl -eq "") {
    continue
  }

  # HACK for testing!!
  # $xmlurl = "http://www.nirsoft.net/pad/shexview.xml"

  "- $xmlurl"

  $doc = New-Object System.Xml.XmlDocument
  $doc.Load($xmlurl)

  $fullName = $doc.XML_DIZ_INFO.Program_Info.Program_Name.ToString().Trim()
  $zipName = [System.IO.Path]::GetFileNameWithoutExtension($doc.XML_DIZ_INFO.Web_Info.Download_URLs.Primary_Download_URL)
  $outFileName = $fullName.ToLower()
  $outFileName = $outFileName -replace " ", ""
  $outFileName = $outFileName -replace "-", ""

  $json = [ordered]@{}

  $json.homepage = $doc.XML_DIZ_INFO.Web_Info.Application_URLs.Application_Info_URL -Replace "http://", "https://"
  $json.checkver = "$fullName v(\d+\.\d+)"
  $json.version = $doc.XML_DIZ_INFO.Program_Info.Program_Version
  $json.license = $doc.XML_DIZ_INFO.Program_Info.Program_Type.ToString().ToLower()
  $json.description = $doc.XML_DIZ_INFO.Program_Descriptions.English.Char_Desc_2000.ToString().TrimEnd()
  $json.description = $json.description -replace "\r", " "
  $json.description = $json.description -replace "\n", " "
  $json.description = $json.description -replace "  ", " "

  $x32url = $doc.XML_DIZ_INFO.Web_Info.Download_URLs.Primary_Download_URL -Replace "http://", "https://"
  try {
    Invoke-WebRequest -Uri $x32url -OutFile "./$tempFile" #-ErrorAction Stop
  } catch {
    Write-Host -ForegroundColor Red "**** The url pointed to by the PAD file was not found.."
    continue
  }
  $x32hash = (Get-FileHash -Path "./$tempFile" -Algorithm 'sha256').Hash.ToLower()

  # Unzip the downloaded file, so we can get the exe's file name.
  try {
    $exeName = ""

    Expand-Archive $tempFile -DestinationPath $unzipPath
    $exeName = Get-ChildItem -Path $unzipPath -Filter *.exe -File -Name
  } catch {
    Write-Host -ForegroundColor Red "**** The zip file could not be opened.."
  }
  Remove-Item -LiteralPath $unzipPath -Force -Recurse
  if ($exeName -eq "" -or $null -eq $exeName) {
    # > The zip file couldn't be opened by PowerShell. For now I'll ignore it,
    #   because the built-in PowerShell Archive namespace is pretty weak.
    $exeName = "$zipName.exe"
  }
  "  exeName = $exeName"

  Remove-Item $tempFile

  $x64url = $x32url.ToString().Replace(".zip", "-x64.zip")
  try {
    Invoke-WebRequest -Uri $x64url -OutFile "./$tempFile" #-ErrorAction Stop
  } catch {}

  If (Test-Path -Path "./$tempFile") {
    # has a 64bit (and 32bit file)
    $x64hash = (Get-FileHash -Path "./$tempFile" -Algorithm 'sha256').Hash.ToLower()
    Remove-Item $tempFile

    $json.architecture = [ordered]@{ "64bit" = [ordered]@{ "url" = $x64url; "hash" = $x64hash; }; "32bit" = [ordered]@{ "url" = $x32url; "hash" = $x32hash; }; }
    $json.autoupdate = [ordered]@{ "architecture" = [ordered]@{ "64bit" = @{ "url" = $x64url; }; "32bit" = @{ "url" = $x32url; }; }; }
  } else {
    # only has a 32bit file
    # $json.architecture = [ordered]@{ "32bit" = [ordered]@{ "url" = $x32url; "hash" = $x32hash ; }; }
    # $json.autoupdate = [ordered]@{ "architecture" = @{ "32bit" = @{ "url" = $x32url; }; }; }
    $json.url = $x32url
    $json.hash = $x32hash
    $json.autoupdate = @{ "url" = $x32url; }
  }

  $json.bin = "$exeName"
  $json.shortcuts = @(, @("$exeName", "NirSoft\$fullName"))

  $json | ConvertTo-Json -Depth 100 | jq -M --indent 4 . | Out-File "$outpath/$outFileName.json"

  # break
}
