Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# Main Window
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="SCS Toolbox" Height="500" Width="400" Background="#1e1e1e" WindowStartupLocation="CenterScreen">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="100"/>
        </Grid.RowDefinitions>

        <Image Name="LogoImage" Source="https://southcoastsystems.co.uk/wp-content/uploads/2020/12/scs-logo.jpg" Height="80" Margin="0,10" Grid.Row="0" HorizontalAlignment="Center"/>

        <!-- Main Menu -->
        <StackPanel Name="MainMenu" Grid.Row="1" Margin="0,10" HorizontalAlignment="Center">
            <Button Name="btnRepairScripts" Content="Windows Repair Scripts" Width="200" Margin="0,5"/>
            <Button Name="btnDownloads" Content="Downloads" Width="200" Margin="0,5"/>
        </StackPanel>

        <!-- Dynamic Content Panel -->
        <StackPanel Name="contentPanel" Grid.Row="2" Margin="0,10" Visibility="Collapsed"/>

        <!-- Exit Button -->
        <Button Name="btnExit" Grid.Row="3" Content="Exit" Width="200" HorizontalAlignment="Center" Margin="0,10"/>

        <!-- Logs -->
        <TextBox Name="logBox" Grid.Row="4" Background="Black" Foreground="White" IsReadOnly="True" VerticalScrollBarVisibility="Auto" TextWrapping="Wrap" />
    </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

$MainMenu       = $window.FindName("MainMenu")
$btnRepairScripts = $window.FindName("btnRepairScripts")
$btnDownloads   = $window.FindName("btnDownloads")
$btnExit        = $window.FindName("btnExit")
$contentPanel   = $window.FindName("contentPanel")
$logBox         = $window.FindName("logBox")

function Show-Log {
    param($message)
    $logBox.AppendText("$(Get-Date -Format "HH:mm:ss") - $message`n")
    $logBox.ScrollToEnd()
}

function Show-WindowsRepairScripts {
    $MainMenu.Visibility = 'Collapsed'
    $contentPanel.Children.Clear()
    $contentPanel.Visibility = 'Visible'

    $scripts = @(
        @{ Name = "Fix Network Issues"; Desc = "Resets Winsock and IP stack" },
        @{ Name = "Clear Windows Update Cache"; Desc = "Deletes SoftwareDistribution folder" },
        @{ Name = "Repair System Files"; Desc = "Runs SFC and DISM to fix system files" },
        @{ Name = "Reset Permissions"; Desc = "Resets file and registry permissions" },
        @{ Name = "Flush DNS Cache"; Desc = "Flushes DNS Resolver Cache" },
        @{ Name = "Restart Explorer"; Desc = "Restarts Windows Explorer process" }
    )

    foreach ($script in $scripts) {
        $panel = New-Object System.Windows.Controls.StackPanel
        $panel.Orientation = "Horizontal"
        $panel.Margin = "0,5"

        $btn = New-Object System.Windows.Controls.Button
        $btn.Content = $script.Name
        $btn.Width = 160
        $btn.Margin = "0,0,10,0"
        $btn.Tag = $script.Name
        $btn.Add_Click({
            $cmd = switch ($btn.Tag) {
                "Fix Network Issues"           { 'netsh winsock reset & netsh int ip reset' }
                "Clear Windows Update Cache"  { 'net stop wuauserv & net stop bits & del /s /q %windir%\SoftwareDistribution\*' }
                "Repair System Files"         { 'sfc /scannow & DISM /Online /Cleanup-Image /RestoreHealth' }
                "Reset Permissions"           { 'icacls * /T /Q /C /RESET' }
                "Flush DNS Cache"             { 'ipconfig /flushdns' }
                "Restart Explorer"            { 'taskkill /f /im explorer.exe & start explorer.exe' }
                default                       { '' }
            }

            if ($cmd) {
                Show-Log "Running '$($btn.Tag)' in new CMD window."
                Start-Process "cmd.exe" -ArgumentList "/k $cmd"
            } else {
                Show-Log "Command not found for: $($btn.Tag)"
            }
        })

        $desc = New-Object System.Windows.Controls.TextBlock
        $desc.Text = $script.Desc
        $desc.Foreground = 'White'
        $desc.VerticalAlignment = 'Center'

        $panel.Children.Add($btn)
        $panel.Children.Add($desc)
        $contentPanel.Children.Add($panel)
    }
    Show-Log "Loaded Windows Repair Scripts."
}

function Show-Downloads {
    $MainMenu.Visibility = 'Collapsed'
    $contentPanel.Children.Clear()
    $contentPanel.Visibility = 'Visible'

    $label = New-Object System.Windows.Controls.TextBlock
    $label.Text = "Downloads page coming soon..."
    $label.Foreground = 'White'
    $label.FontSize = 14
    $label.Margin = "0,10"
    $label.HorizontalAlignment = "Center"
    $contentPanel.Children.Add($label)

    Show-Log "Downloads page loaded."
}

$btnRepairScripts.Add_Click({ Show-WindowsRepairScripts })
$btnDownloads.Add_Click({ Show-Downloads })
$btnExit.Add_Click({ $window.Close() })

Show-Log "SCS Toolbox loaded."
$window.ShowDialog()
