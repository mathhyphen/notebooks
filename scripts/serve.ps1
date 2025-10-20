param(
  [int]$Port = 8000,
  [string]$RootPath = '.'
)

Add-Type -AssemblyName System.Net
$listener = [System.Net.HttpListener]::new()
$prefix = "http://localhost:$Port/"
$listener.Prefixes.Add($prefix)
$listener.Start()

Write-Host "Preview URL: $prefix"
Write-Host "Serving static files from: $(Resolve-Path $RootPath)"

function Get-ContentType($ext) {
  switch ($ext.ToLower()) {
    '.html' { return 'text/html; charset=utf-8' }
    '.json' { return 'application/json; charset=utf-8' }
    '.css'  { return 'text/css; charset=utf-8' }
    '.js'   { return 'application/javascript; charset=utf-8' }
    '.svg'  { return 'image/svg+xml; charset=utf-8' }
    default { return 'application/octet-stream' }
  }
}

while ($true) {
  try {
    $context = $listener.GetContext()
    $request = $context.Request
    $path = $request.Url.AbsolutePath.TrimStart('/')
    if ([string]::IsNullOrEmpty($path)) { $path = 'index.html' }
    $file = Join-Path $RootPath $path
    if (-not (Test-Path $file)) {
      $context.Response.StatusCode = 404
      $bytes404 = [System.Text.Encoding]::UTF8.GetBytes("Not Found: $path")
      $context.Response.OutputStream.Write($bytes404, 0, $bytes404.Length)
      $context.Response.Close()
      continue
    }
    $bytes = [System.IO.File]::ReadAllBytes($file)
    $context.Response.ContentType = Get-ContentType ([System.IO.Path]::GetExtension($file))
    $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    $context.Response.Close()
  } catch {
    Write-Host $_
  }
}