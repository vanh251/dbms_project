$dir = "c:\Users\Admin\dbms_project\src\main\resources\static"
$files = Get-ChildItem -Path $dir -Filter "*.html"

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $newContent = $content -replace '<div id="navAuth"></div>\s*</div>\s*</nav>', "</div>`n    <div id=`"navAuth`"></div>`n</nav>"
    if ($content -ne $newContent) {
        Set-Content -Path $file.FullName -Value $newContent
        Write-Host "Fixed $($file.Name)"
    }
}
