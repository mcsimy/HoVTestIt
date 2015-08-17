[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
       Title="HoVTestIt!" Height="226" Width="565" Foreground="Black">
    <Grid x:Name="bckg" Background="#FF535353">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="115*"/>
            <ColumnDefinition Width="280*"/>
            <ColumnDefinition Width="115*"/>
        </Grid.ColumnDefinitions>
        <Button Name="kill_button" Content="Kill" Margin="10,75,15,0" Background="#FF633441"
            Foreground="#FFD1D1D1" Height="40" VerticalAlignment="Top"/>
        <Button Name="launch_button" Content="Launch" Margin="10,30,15,0" Background="#FF346350"
            Foreground="#FFD1D1D1" Height="40" VerticalAlignment="Top"/>
        <Button Name="reload_button" Content="Reload" Margin="10,120,15,0" Background="#FF4B3463"
        	Foreground="#FFD1D1D1" Height="40" VerticalAlignment="Top"/>
        <Button Name="install_button" Content="Install" Margin="19,30,10,0" Background="#FF346350"
        	Foreground="#FFD1D1D1" Height="40" VerticalAlignment="Top" Grid.Column="2"/>
        <Button Name="uninstal_button" Content="Uninstall" Margin="19,75,10,0" Background="#FF633441"
        	Foreground="#FFD1D1D1" Height="40" VerticalAlignment="Top" Grid.Column="2"/>
        <Button Name="pull_button" Content="Pull APK" Margin="19,120,10,0" Background="#FF4B3463"
        	Foreground="#FFD1D1D1" Height="40" VerticalAlignment="Top" Grid.Column="2"/>
        <TextBox Name="deviceid_box" Grid.Column="1" Height="23" Margin="87,30,10,0" TextWrapping="Wrap" Text="Device ID" VerticalAlignment="Top"/>
        <TextBox Name="androidid_box" Grid.Column="1" Height="23" Margin="87,58,10,0" TextWrapping="Wrap" Text="Android ID" VerticalAlignment="Top"/>
        <TextBox Name="osversion_box" Grid.Column="1" Height="23" Margin="87,86,10,0" TextWrapping="Wrap" Text="OS version" VerticalAlignment="Top"/>
        <TextBox Name="fireosversion_box" Grid.Column="1" Height="23" Margin="87,114,10,0" TextWrapping="Wrap" Text="Fire OS" VerticalAlignment="Top"/>
        <TextBox Name="appbuild_box" Grid.Column="1" Height="23" Margin="87,142,10,0" TextWrapping="Wrap" Text="App Build" VerticalAlignment="Top"/>
        <Label Content="DeviceID" Grid.Column="1" HorizontalAlignment="Left" Margin="10,27,0,0" VerticalAlignment="Top" Foreground="#FFCFCFCF"/>
        <Label Content="Android ID" Grid.Column="1" HorizontalAlignment="Left" Margin="10,55,0,0" VerticalAlignment="Top" Foreground="#FFCFCFCF"/>
        <Label Content="Android OS" Grid.Column="1" HorizontalAlignment="Left" Margin="10,83,0,0" VerticalAlignment="Top" Background="#00000000" Foreground="#FFCFCFCF"/>
        <Label Content="Fire OS" Grid.Column="1" HorizontalAlignment="Left" Margin="11,111,0,0" VerticalAlignment="Top" Background="#00000000" Foreground="#FFCFCFCF"/>        
        <Label Content="HoV Build" Grid.Column="1" HorizontalAlignment="Left" Margin="10,139,0,0" VerticalAlignment="Top" Background="#00000000" Foreground="#FFCFCFCF"/>
    </Grid>
</Window>

'@       

#===========================================================================
#Read XAML
#===========================================================================

$reader=(New-Object System.Xml.XmlNodeReader $xaml) 
try{$Form=[Windows.Markup.XamlReader]::Load( $reader )}
catch{Write-Host "Unable to load Windows.Markup.XamlReader. Some possible causes for this problem include: 
.NET Framework is missing PowerShell must be launched with PowerShell -sta, invalid XAML code was encountered."; exit}

#===========================================================================
# Store Form Objects In PowerShell
#===========================================================================

$xaml.SelectNodes("//*[@Name]") | %{Set-Variable -Name ($_.Name) -Value $Form.FindName($_.Name)}

#===========================================================================
# Stores Android properties from adb shell getprop
#===========================================================================

$propDeviceID = adb shell settings get secure android_id #adb shell getprop ro.serialno
$propAndroidID = adb shell getprop ro.product.model
$propAndroidOS = adb shell getprop ro.build.version.release
$propFireOS = adb shell getprop ro.build.version.fireos
$propAppBuild = adb shell dumpsys package com.productmadness.hovmobile | Select-String -Pattern "versionName";

$pathPullFrom = adb shell pm path com.productmadness.hovmobile

#For future use
#---------------------------------------------------------------------------
#$pathToInstall
#$pathPullTo
#---------------------------------------------------------------------------

#===========================================================================
# Add events to Form Objects
#===========================================================================

$kill_button.Add_Click({
                        adb shell am force-stop com.productmadness.hovmobile;
                        adb shell input keyevent 82                               #unlocks the screen
                        })
                        
$launch_button.Add_Click({                        
                        adb shell am start -n com.productmadness.hovmobile/com.productmadness.hovmobile.AppEntry
                        })

$reload_button.Add_Click({
                        adb shell am force-stop com.productmadness.hovmobile;
                        Start-Sleep -s 2;
                        adb shell am start -n com.productmadness.hovmobile/com.productmadness.hovmobile.AppEntry
                        })

$install_button.Add_Click({
                        adb install D:\_McS\AndroidProjects\com.productmadness.hovmobile-2.apk
                        })
                        
$uninstal_button.Add_Click({                        
                        adb shell pm uninstall com.productmadness.hovmobile
                        })

$pull_button.Add_Click({                      
                        adb pull ($pathPullFrom -replace "package:", "") "d:\"
                        })

#Depricated pull function
#---------------------------------------------------------------------------
#$pull_button.Add_Click({
#                       adb pull /data/app/com.productmadness.hovmobile-2.apk "d:\_McS"
#                        })
#---------------------------------------------------------------------------

$deviceid_box.Text = $propDeviceID
$androidid_box.Text = $propAndroidID
$osversion_box.Text = $propAndroidOS
$fireosversion_box.Text = $propFireOS
$appbuild_box.Text = $propAppBuild -replace "versionName=", "" -replace '(^\s+|\s+$)','' -replace '\s+',' '
 
#===========================================================================
# Shows the form
#===========================================================================

$Form.ShowDialog() | out-null