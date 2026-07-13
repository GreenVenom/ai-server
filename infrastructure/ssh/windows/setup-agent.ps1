Set-Service ssh-agent -StartupType Automatic
Start-Service ssh-agent

Write-Host "Run the following once to add your key:"
Write-Host "ssh-add $HOME\.ssh\macmini_ai"