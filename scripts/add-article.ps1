param(
  [Parameter(Mandatory=$false)][string]$Id,
  [Parameter(Mandatory=$true)][string]$Title,
  [Parameter(Mandatory=$true)][string]$Filename,
  [Parameter(Mandatory=$true)][string]$Description,
  [string[]]$Tags = @('深度学习'),
  [string[]]$DisplayTags = $null,
  [string]$Icon = 'M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10',
  [string]$Gradient = $null,
  [string]$ButtonColor = $null,
  [string]$JsonPath = $null
)

function New-ArticleIdFromTitle {
  param([string]$Title)
  # 生成 slug：小写、用短横线连接，移除非字母数字字符
  $slug = $Title.ToLower() -replace '[^\p{L}\d]+','-'
  $slug = $slug.Trim('-')
  return $slug
}

function Get-StyleFromTags {
  param([string[]]$Tags)
  $style = @{ Gradient = 'from-blue-500 to-indigo-600'; ButtonColor = 'blue-500' }
  if ($Tags -contains '深度学习') {
    $style.Gradient = 'from-warm-secondary to-warm-accent'
    $style.ButtonColor = 'warm-accent'
  } elseif ($Tags -contains '数学物理') {
    $style.Gradient = 'from-warm-primary to-warm-accent'
    $style.ButtonColor = 'warm-primary'
  } elseif ($Tags -contains '理论研究') {
    $style.Gradient = 'from-green-500 to-teal-600'
    $style.ButtonColor = 'green-500'
  }
  return $style
}

if (-not $JsonPath) {
  $JsonPath = Join-Path $PSScriptRoot '..\articles.json'
}

if (-not (Test-Path $JsonPath)) {
  Write-Error "找不到 JSON 文件：$JsonPath"
  exit 1
}

try {
  $data = Get-Content -Raw -Path $JsonPath -Encoding UTF8 | ConvertFrom-Json

  if (-not $Id -or $Id.Trim() -eq '') {
    $Id = New-ArticleIdFromTitle -Title $Title
    Write-Host "自动生成 id：$Id"
  }

  if (-not $DisplayTags) { $DisplayTags = $Tags }

  if (-not $Gradient -or -not $ButtonColor) {
    $style = Get-StyleFromTags -Tags $Tags
    if (-not $Gradient) { $Gradient = $style.Gradient }
    if (-not $ButtonColor) { $ButtonColor = $style.ButtonColor }
    Write-Host "自动设置风格：gradient=$Gradient, buttonColor=$ButtonColor"
  }

  $article = [pscustomobject]@{
    id = $Id
    title = $Title
    description = $Description
    filename = $Filename
    tags = $Tags
    displayTags = $DisplayTags
    icon = $Icon
    gradient = $Gradient
    buttonColor = $ButtonColor
  }

  $index = -1
  for ($i = 0; $i -lt $data.articles.Count; $i++) {
    if ($data.articles[$i].id -eq $Id) { $index = $i; break }
  }

  if ($index -ge 0) {
    $data.articles[$index] = $article
    Write-Host "已更新文章：$Id"
  } else {
    $data.articles += $article
    Write-Host "已添加文章：$Id"
  }

  # 备份原文件
  Copy-Item -Path $JsonPath -Destination ($JsonPath + '.bak') -Force

  $jsonOut = $data | ConvertTo-Json -Depth 20
  Set-Content -Path $JsonPath -Value $jsonOut -Encoding UTF8
  Write-Host "已写入：$JsonPath"
}
catch {
  Write-Error $_
  exit 1
}