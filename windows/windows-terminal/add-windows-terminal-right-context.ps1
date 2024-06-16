
$current_user = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty UserName

$source_dir = "C:\Users\$($current_user)\AppData\Local\wt"

echo "Windows Registry Editor Version 5.00

[-HKEY_CLASSES_ROOT\Directory\Background\shell\wt]
[-HKEY_CLASSES_ROOT\Directory\Background\shell\runas]

[HKEY_CLASSES_ROOT\Directory\Background\shell\wt]
@='Windows terminal here'
`"Icon`"=`"$($source_dir)\terminal.ico`"

[HKEY_CLASSES_ROOT\Directory\Background\shell\wt\command]
@='C:\\Users\\$($current_user)\\AppData\\Local\\Microsoft\\WindowsApps\\wt.exe'

[HKEY_CLASSES_ROOT\Directory\Background\shell\runas]
@='Windows terminal here(Administrator)'
`"Icon`"=`"$($source_dir)\terminal.ico`"
`"ShowBasedOnVelocityId`"=dword:00639bc8

[HKEY_CLASSES_ROOT\Directory\Background\shell\runas\command]
@='C:\\Users\\$($current_user)\\AppData\\Local\\Microsoft\\WindowsApps\\wt.exe'" | Out-File -FilePath add-windows-terminal-right-context.reg

New-Item -ItemType Directory -Force -Path $source_dir
Copy-Item terminal.ico $source_dir
Copy-Item add-windows-terminal-right-context.reg $source_dir

Invoke-Expression -Command "reg import $($source_dir)\add-windows-terminal-right-context.reg"