# Fill in this course's slug and title after creating a repository from the template.
#   ./scripts/new-course.ps1 -Slug intro_geospatial_archaeology -Title "Introduction to Geospatial Archaeology"
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[a-z0-9][a-z0-9_]*$')]
    [string]$Slug,
    [Parameter(Mandatory)]
    [string]$Title
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$yamlTitle = $Title.Replace('\', '\\').Replace('"', '\"')
$utf8 = New-Object Text.UTF8Encoding $false
$changed = 0

foreach ($relative in @("_quarto.yml", "index.qmd", "docs/_redirects")) {
    $path = Join-Path $repoRoot $relative
    $text = [IO.File]::ReadAllText($path)
    $updated = $text.Replace("COURSE_SLUG", $Slug).Replace("COURSE_TITLE", $yamlTitle)
    if ($updated -ne $text) {
        [IO.File]::WriteAllText($path, $updated, $utf8)
        Write-Host "Updated $relative"
        $changed += 1
    }
}

if ($changed -eq 0) { Write-Warning "No placeholders found; this course may already be set up." }
Write-Host ""
Write-Host "Course URL:   https://teaching.wccarleton.org/$Slug/"
Write-Host "Image base:   https://teaching-assets.wccarleton.org/$Slug/"
Write-Host "Next: add the route to teaching_home (see README.md, 'Publish a new course')."
