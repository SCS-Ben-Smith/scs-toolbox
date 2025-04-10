Add-Type -AssemblyName PresentationFramework

# === Set working folder ===
$scsPath = "$env:TEMP\SCS"
if (!(Test-Path $scsPath)) { New-Item -Path $scsPath -ItemType Directory | Out-Null }
$logFile = "$scsPath\scs-toolbox.log"
"" | Out-File $logFile

function Write-Log {
    param ([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $Message"
    $logEntry | Out-File -FilePath $logFile -Append
    $LogBox.Dispatcher.Invoke([action]{
        $LogBox.AppendText("$logEntry`n")
        $LogBox.ScrollToEnd()
    })
}

# === Define Items ===
$apps = @(
    @{ Name = "Dimension Pro (Direct Download)"; Type = "direct"; Url = "https://yourdomain.com/dimensionpro.exe" },
    @{ Name = "OBS Studio"; Type = "winget"; Id = "OBSProject.OBSStudio" },
    @{ Name = "Google Chrome"; Type = "winget"; Id = "Google.Chrome" },
    @{ Name = "7-Zip"; Type = "winget"; Id = "7zip.7zip" }
)

$tweaks = @(
    @{ Name = "Disable Telemetry"; Script = 'Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Force' },
    @{ Name = "Disable Cortana"; Script = 'Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0 -Force' },
    @{ Name = "Show File Extensions"; Script = 'Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0' },
    @{ Name = "Show Hidden Files"; Script = 'Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1' }
)

$repairs = @(
    @{ Name = "Repair Network Stack"; Script = 'netsh int ip reset; netsh winsock reset; ipconfig /flushdns' },
    @{ Name = "DISM Health Restore"; Script = 'DISM /Online /Cleanup-Image /RestoreHealth' },
    @{ Name = "SFC Scan"; Script = 'sfc /scannow' },
    @{ Name = "Clear Windows Update Cache"; Script = 'net stop wuauserv; net stop bits; Remove-Item -Path C:\Windows\SoftwareDistribution -Recurse -Force; net start wuauserv; net start bits' },
    @{ Name = "Fix Windows Store"; Script = 'wsreset.exe' },
    @{ Name = "Re-register Apps"; Script = 'Get-AppXPackage -AllUsers | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"}' }
)

# === XAML GUI Layout ===
[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="SCS Toolbox v2" Height="600" Width="800" WindowStartupLocation="CenterScreen"
        Background="#1E1E1E" Foreground="White" FontFamily="Segoe UI">
    <Grid>
        <TabControl Name="Tabs" Background="#2D2D30" Foreground="White" FontSize="14">
            <TabItem Header="Install Apps">
                <DockPanel Margin="10">
                    <StackPanel DockPanel.Dock="Top">
                        <ListBox Name="AppList" SelectionMode="Multiple" Background="#1E1E1E" Foreground="White" Height="300"/>
                        <Button Content="Install Selected Apps" Name="InstallAppsBtn" Margin="0,10,0,10" Height="35"/>
                    </StackPanel>
                    <TextBox Name="LogBox" DockPanel.Dock="Bottom" Height="140" Background="#1E1E1E" Foreground="White" FontSize="12" TextWrapping="Wrap" AcceptsReturn="True" IsReadOnly="True" VerticalScrollBarVisibility="Auto"/>
                </DockPanel>
            </TabItem>
            <TabItem Header="Apply Tweaks">
                <DockPanel Margin="10">
                    <StackPanel DockPanel.Dock="Top">
                        <ListBox Name="TweakList" SelectionMode="Multiple" Background="#1E1E1E" Foreground="White" Height="300"/>
                        <Button Content="Apply Selected Tweaks" Name="ApplyTweaksBtn" Margin="0,10,0,10" Height="35"/>
                    </StackPanel>
                    <TextBox Name="LogBox" DockPanel.Dock="Bottom" Height="140" Background="#1E1E1E" Foreground="White" FontSize="12" TextWrapping="Wrap" AcceptsReturn="True" IsReadOnly="True" VerticalScrollBarVisibility="Auto"/>
                </DockPanel>
            </TabItem>
            <TabItem Header="Repair Scripts">
                <DockPanel Margin="10">
                    <StackPanel DockPanel.Dock="Top">
                        <ListBox Name="RepairList" SelectionMode="Multiple" Background="#1E1E1E" Foreground="White" Height="300"/>
                        <Button Content="Run Selected Repairs" Name="RunRepairsBtn" Margin="0,10,0,10" Height="35"/>
                    </StackPanel>
                    <TextBox Name="LogBox" DockPanel.Dock="Bottom" Height="140" Background="#1E1E1E" Foreground="White" FontSize="12" TextWrapping="Wrap" AcceptsReturn="True" IsReadOnly="True" VerticalScrollBarVisibility="Auto"/>
                </DockPanel>
            </TabItem>
        </TabControl>
    </Grid>
</Window>
"@

# === Parse XAML and Bind Controls ===
$reader = (New-Object System.Xml.XmlNodeReader $XAML)
$Window = [Windows.Markup.XamlReader]::Load($reader)

$AppList = $Window.FindName("AppList")
$TweakList = $Window.FindName("TweakList")
$RepairList = $Window.FindName("RepairList")
$LogBox = $Window.FindName("LogBox")

$AppList.ItemsSource = $apps.Name
$TweakList.ItemsSource = $tweaks.Name
$RepairList.ItemsSource = $repairs.Name

# === Events ===
$Window.FindName("InstallAppsBtn").Add_Click({
    $selected = $AppList.SelectedItems
    foreach ($item in $selected) {
        $app = $apps | Where-Object { $_.Name -eq $item }
        Write-Log "Starting install for: $($app.Name)"
        if ($app.Type -eq "winget") {
            Write-Log "Running: winget install --id $($app.Id) -e --silent"
            Start-Process "winget" -ArgumentList "install --id $($app.Id) -e --silent" -Wait
        } elseif ($app.Type -eq "direct") {
            $fileName = [System.IO.Path]::GetFileName($app.Url)
            $filePath = Join-Path $scsPath $fileName
            Write-Log "Downloading from: $($app.Url)"
            Invoke-WebRequest -Uri $app.Url -OutFile $filePath
            Write-Log "Executing: $filePath"
            Start-Process $filePath
        }
        Write-Log "Finished install for: $($app.Name)"
    }
})

$Window.FindName("ApplyTweaksBtn").Add_Click({
    $selected = $TweakList.SelectedItems
    foreach ($item in $selected) {
        $tweak = $tweaks | Where-Object { $_.Name -eq $item }
        Write-Log "Applying tweak: $($tweak.Name)"
        Invoke-Expression $tweak.Script
        Write-Log "Finished tweak: $($tweak.Name)"
    }
})

$Window.FindName("RunRepairsBtn").Add_Click({
    $selected = $RepairList.SelectedItems
    foreach ($item in $selected) {
        $repair = $repairs | Where-Object { $_.Name -eq $item }
        Write-Log "Running repair: $($repair.Name)"
        Start-Process powershell -ArgumentList "-Command", $repair.Script -Verb RunAs -Wait
        Write-Log "Finished repair: $($repair.Name)"
    }
})

# === Cleanup on Close ===
$Window.Add_Closed({
    Write-Log "Cleaning up temporary files..."
    Start-Sleep -Seconds 2
    Remove-Item -Path $scsPath -Recurse -Force -ErrorAction SilentlyContinue
})

# === Show the Window ===
$Window.ShowDialog() | Out-Null
