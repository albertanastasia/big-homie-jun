param([Boolean]$outputTestResultAsJunit=$false)

$rootPath = Get-Location
$extensionDirectory = Join-Path -Path $rootPath -ChildPath "azure-devops"

Set-Location $extensionDirectory
Write-Host "installing azure dev cli extension"
pip install --upgrade .
Write-Host "done"
Write-Host "creating wheel"
python setup.py sdist bdist_wheel
Write-Host "done"
Set-Location $rootPath

# only needed for running tests in environment with python version less that 3.3
pip install mock

$ErrorActionPreference = "Continue"
try {
    Write-Host "trying to uninstall extension of az devops extension was installed"
    $uninstallCommand = "az extension remove -n azure-devops **2>&1 | Write-Host**"
    Invoke-Expression $uninstallCommand
    Write-Host "extension was installed and it was removed"
}
catch {
    Write-Host "extension was not installed"
}

$ErrorActionPreference = "Stop"

Write-Host "installing azure dev cli extension"
$extensions = Get-ChildItem -Path $sourceDir -Filter "*.whl" -Recurse | Select-Object FullName
az extension add --source $extensions[0].FullName -y
Write-Host "done"

# Install this extension just so that we can compare the load time
az extension add -n azure-cli-iot-ext

az -h
az devops -h --debug

$testFailureFound = $false

if($outputTestResultAsJunit -eq $true)
{
    pytest 'azure-devops/' --junitxml "TEST-UT-results.xml" --cov=azext_devops --cov-report=xml --cov-report=html
}
else{
    pytest 'azure-devops/'
}

if ($LastExitCode -ne 0) {
    $testFailureFound = $true
}

if($outputTestResultAsJunit -eq $true)
{
    pytest 'tests/' --junitxml "TEST-recordings-results.xml" --cov=azext_devops --cov-report=xml --cov-report=html
}
else{
    pytest 'tests/'
}

if ($LastExitCode -ne 0) {
    $testFailureFound = $true
}

if($testFailureFound -eq $true){
    exit 1
}