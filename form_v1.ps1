# vCloud Virtual Machine Manual Power Management Script
# Version:       0.01
# Version Date:  06/11/2018
# Author:        Dean Collins (dcollins@mds.gb.net)
# Created:       06/11/2018
 
# Version Control
# Version   # Date        # By   # Change
# 0.01        06/11/2018    DAC    Script Creation.
# 0.02        12/11/2018    DAC    Overhaulled UI, cleaner look and feel.
# 0.03        13/11/2018    DAC    Added status messages throughout process.

# Features to be developed
#             Refresh button to update list of available VMs.
#             Ability to input the API URL to allow to connect to different vORGs.
 
# Load System Reflection Options
Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.windows.forms
[Windows.Forms.Application]::EnableVisualStyles()

# Defined Functions
# # VMware vCloud API Load Modules Function
function LoadModules(){
   $loaded = Get-Module -Name $moduleList -ErrorAction Ignore | % {$_.Name}
   $registered = Get-Module -Name $moduleList -ListAvailable -ErrorAction Ignore | % {$_.Name}
   $notLoaded = $registered | ? {$loaded -notcontains $_}

   foreach ($module in $registered) {
      if ($loaded -notcontains $module) {
      Import-Module -Name $module
      }
   }
}

# # VMware vCloud API Load Start Function
function ReportStartOfActivity($activity) {
   $script:currentActivity = $activity
}

# # VMware vCloud API Load Finished Function
function ReportFinishedActivity() {
   $script:completedActivities++
   $script:percentComplete = (100.0 / $totalActivities) * $script:completedActivities
   $script:percentComplete = [Math]::Min(99, $percentComplete)
}

# Loading VMware vCloud API Modules
$moduleList = @(
    'VMware.VimAutomation.Core',
    'VMware.VimAutomation.Vds',
    'VMware.VimAutomation.Cloud',
    'VMware.VimAutomation.PCloud',
    'VMware.VimAutomation.Cis.Core',
    'VMware.VimAutomation.Storage',
    'VMware.VimAutomation.HorizonView',
    'VMware.VimAutomation.HA',
    'VMware.VimAutomation.vROps',
    'VMware.VumAutomation',
    'VMware.DeployAutomation',
    'VMware.ImageBuilder',
    'VMware.VimAutomation.License'
    )

$productName = 'PowerCLI'
$productShortName = 'PowerCLI'

$loadingActivity = "Loading $productName"
$script:completedActivities = 0
$script:percentComplete = 0
$script:currentActivity = ''
$script:totalActivities = `
   $moduleList.Count + 1

LoadModules

$powerCliFriendlyVersion = [VMware.VimAutomation.Sdk.Util10.ProductInfo]::PowerCLIFriendlyVersion
$host.ui.RawUI.WindowTitle = $powerCliFriendlyVersion

$null = Set-PowerCLIConfiguration -Scope User -ParticipateInCeip $false -Confirm:$false

Add-Type -AssemblyName VMware.VimAutomation.Sdk.Util10

# Get User List From CSV
$CIUsers = Import-CSV -Path "$env:HOMEDRIVE\script_config\api_users..csv"

# Build & Display Logon Form     
Add-Type -AssemblyName System.Windows.Forms 
Add-Type -AssemblyName System.Drawing 
$MyForm = New-Object -TypeName System.Windows.Forms.Form 
$MyForm.Text='UserLogonForm' 
$MyForm.Text='VM Power On Manager - MDS Technologies LTD'
$MyForm.BackColor='#FFFFFF'
$MyForm.MaximizeBox = $false
$MyForm.MinimizeBox = $false
$MyForm.ControlBox = $false
$MyForm.SizeGripStyle = 'Hide'
$MyForm.StartPosition = 'CenterScreen'
$MyForm.FormBorderStyle = 'FixedDialog'
$MyForm.Icon = [drawing.icon]::ExtractAssociatedIcon("$env:HOMEDRIVE\script_config\mds.ico")
$MyForm.Size = New-Object -TypeName System.Drawing.Size -ArgumentList (365,410)
  
$mLabel1 = New-Object -TypeName System.Windows.Forms.Label 
    $mLabel1.Text='Choose User:' 
    $mLabel1.Top='65' 
    $mLabel1.Left='15' 
    $mLabel1.Anchor='Left,Top' 
$mLabel1.Size = New-Object -TypeName System.Drawing.Size -ArgumentList (100,38) 
$MyForm.Controls.Add($mLabel1) 

$mLabel2 = New-Object -TypeName System.Windows.Forms.Label 
    $mLabel2.Text='Username:' 
    $mLabel2.Top='105' 
    $mLabel2.Left='15' 
    $mLabel2.Anchor='Left,Top' 
$mLabel2.Size = New-Object -TypeName System.Drawing.Size -ArgumentList (100,38) 
$MyForm.Controls.Add($mLabel2) 

$mLabel3 = New-Object -TypeName System.Windows.Forms.Label 
    $mLabel3.Text='Password:' 
    $mLabel3.Top='145' 
    $mLabel3.Left='15' 
    $mLabel3.Anchor='Left,Top' 
$mLabel3.Size = New-Object -TypeName System.Drawing.Size -ArgumentList (100,38) 
$MyForm.Controls.Add($mLabel3) 

$mLabel4 = New-Object -TypeName System.Windows.Forms.Label 
    $mLabel4.Text='API URL:' 
    $mLabel4.Top='185' 
    $mLabel4.Left='15' 
    $mLabel4.Anchor='Left,Top' 
$mLabel4.Size = New-Object -TypeName System.Drawing.Size -ArgumentList (100,38) 
$MyForm.Controls.Add($mLabel4) 

$mLabel5 = New-Object -TypeName System.Windows.Forms.Label 
    $mLabel5.Text='vOrg:' 
    $mLabel5.Top='225' 
    $mLabel5.Left='15' 
    $mLabel5.Anchor='Left,Top' 
$mLabel5.Size = New-Object -TypeName System.Drawing.Size -ArgumentList (100,38) 
$MyForm.Controls.Add($mLabel5) 

$mUserBox = New-Object -TypeName System.Windows.Forms.TextBox
    $mUserBox.Text='...'
    $mUserBox.Top='102'
    $mUserBox.Left='120'
    $mUserBox.Anchor='Left,Top'
    $mUserBox.ReadOnly='true'
$mUserBox.Size = New-Object -TypeName System.Drawing.Size -ArgumentList (210,38)
$MyForm.Controls.Add($mUserBox)

$mPassBox = New-Object -TypeName System.Windows.Forms.MaskedTextBox
    $mPassBox.Text=''
    $mPassBox.Top='142'
    $mPassBox.Left='120'
    $mPassBox.Anchor='Left,Top'
    $mPassBox.PasswordChar='●'
$mPassBox.Size = New-Object -TypeName System.Drawing.Size -ArgumentList (210,38)
$MyForm.Controls.Add($mPassBox)

$mCIServBox = New-Object -TypeName System.Windows.Forms.TextBox
    $mCIServBox.Text='...'
    $mCIServBox.Top='182'
    $mCIServBox.Left='120'
    $mCIServBox.Anchor='Left,Top'
    $mCIServBox.ReadOnly='true'
$mCIServBox.Size = New-Object -TypeName System.Drawing.Size -ArgumentList (210,38)
$MyForm.Controls.Add($mCIServBox)

$mVORGBox = New-Object -TypeName System.Windows.Forms.TextBox
    $mVORGBox.Text='...'
    $mVORGBox.Top='222'
    $mVORGBox.Left='120'
    $mVORGBox.Anchor='Left,Top'
    $mVORGBox.ReadOnly='true'
$mVORGBox.Size = New-Object -TypeName System.Drawing.Size -ArgumentList (210,38)
$MyForm.Controls.Add($mVORGBox)

$mStatusBox = New-Object -TypeName System.Windows.Forms.TextBox
    $mStatusBox.Text='Ready...' 
    $mStatusBox.Top='310' 
    $mStatusBox.Left='15' 
    $mStatusBox.Anchor='Left,Top'
    $mStatusBox.ReadOnly='true'
    $mStatusBox.Multiline='true'
$mStatusBox.Size = New-Object -TypeName System.Drawing.Size -ArgumentList (320,46) 
$MyForm.Controls.Add($mStatusBox) 

$mChooseBoX = New-Object -TypeName System.Windows.Forms.ComboBoX
    $mChooseBoX.Text='Select...'
    $mChooseBoX.Top='62'
    $mChooseBoX.Left='120'
    $mChooseBoX.Anchor='Left,Top'
    $mChooseBoX.Sorted=$true
    $mChooseBoX.AutoCompleteSource = 'ListItems'
    $mChooseBoX.AutoCompleteMode = 'Append'
    $mChooseBoX.DropDownStyle = [Windows.Forms.ComboBoxStyle]::DropDown
    $mChooseBoX.Size = New-Object -TypeName System.Drawing.Size -ArgumentList (210,23)
        foreach($CIUser in $CIUsers)
        {
        $null = $mChooseBoX.Items.add($CIUser.Name)
        }
    $mChooseBoX.add_TextChanged({
        foreach($CIUser in $CIUsers){
            if ($mChooseBoX.SelectedItem -eq $CIUser.Name){
                $mUserBox.Text = $CIUser.API
                $mPassBox.Text = ''
                $mCIServBox.Text = $CIUser.CIServer
                $mVORGBox.Text = $CIUser.vORG
            }
        }
    })
$MyForm.Controls.Add($mChooseBoX)

$mPictureBox1 = New-Object -TypeName System.Windows.Forms.PictureBox 
    $image = [Drawing.Image]::Fromfile("$env:HOMEDRIVE\script_config\mds.jpg")
    $mPictureBox1.Text='PictureBox1' 
    $mPictureBox1.Top='10' 
    $mPictureBox1.Left='15' 
    $mPictureBox1.Anchor='Left,Top' 
    $mPictureBox1.Image=$image
$mPictureBox1.Size = New-Object -TypeName System.Drawing.Size -ArgumentList (118,38) 
$MyForm.Controls.Add($mPictureBox1) 

$mButtonCon = New-Object -TypeName System.Windows.Forms.Button 
    $mButtonCon.Text='Connect' 
    $mButtonCon.Top='263' 
    $mButtonCon.Left='105' 
    $mButtonCon.Anchor='Left,Top' 
    $mButtonCon.Add_Click({
        If ($mPassBox.TextLength -ne 0){
            $mStatusBox.Text = "Connecting to UKCloud API... `r`nPlease Wait..."
            $CIConnect = Connect-CIServer -Server $mCIServBox.Text -User $mUserBox.Text -Password $mPassBox.Text -Org $mVORGBox.Text
            If ($CIConnect.IsConnected -eq 'true'){
              $mStatusBox.Text = 'Connected to UKCloud...'
              $mChooseBoX.Enabled=$false            
              $mUserBox.Enabled=$false
              $mPassBox.Enabled=$false
              $mCIServBox.Enabled=$false
              $mVORGBox.Enabled=$false
              $timer1 = New-Object -TypeName System.Windows.Forms.Timer
              $timer1.Interval = 3000
              $timer1.Start()
              $timer1.add_Tick({$null = $MyForm.Close()})
            }
            else{
              $mStatusBox.Text = "Connection failed... `r`nPlease check your password is correct."
              $mChooseBoX.Enabled=$true            
              $mUserBox.Enabled=$true
              $mPassBox.Enabled=$true
              $mCIServBox.Enabled=$true
              $mVORGBox.Enabled=$true
            }
        }
        Else{
            $mStatusBox.Text = 'Please enter a password before continuing'
            $mChooseBoX.Enabled=$true
            $mUserBox.Enabled=$true
            $mPassBox.Enabled=$true
            $mCIServBox.Enabled=$true
            $mVORGBox.Enabled=$true
        }
    })
    
$mButtonCon.Size = New-Object -TypeName System.Drawing.Size -ArgumentList (75,23) 
$MyForm.Controls.Add($mButtonCon) 

$mButtonCan = New-Object -TypeName System.Windows.Forms.Button 
    $mButtonCan.Text='Cancel' 
    $mButtonCan.Top='263' 
    $mButtonCan.Left='180' 
    $mButtonCan.Anchor='Left,Top'
    $mButtonCan.Add_Click({
        If ($CIConnect.IsConnected -eq 'true'){
            $null = Disconnect-CIServer -Force -Confirm:$false
            $null = [Environment]::Exit(0)
        }
        Else{
            $null = [Environment]::Exit(0)
        }
    }) 
$mButtonCan.Size = New-Object -TypeName System.Drawing.Size -ArgumentList (75,23) 
$MyForm.Controls.Add($mButtonCan)

$MyForm.Add_Shown({$MyForm.Activate()
 $mChooseBoX.focus()})
$MyForm.ShowDialog()

# Load Second Form for VM Gathering Status
$MyForm2 = New-Object -TypeName System.Windows.Forms.Form 
$MyForm2.Text='VMGatheringForm' 
$MyForm2.Size = New-Object -TypeName System.Drawing.Size -ArgumentList (365,300)
$MyForm2.Text='VM Power On Manager - MDS Technologies LTD'
$MyForm2.BackColor='#FFFFFF'
$MyForm2.MaximizeBox = $false
$MyForm2.MinimizeBox = $false
$MyForm2.ControlBox = $false
$MyForm2.SizeGripStyle = 'Hide'
$MyForm2.StartPosition = 'CenterScreen'
$MyForm2.FormBorderStyle = 'FixedDialog'
$MyForm2.Icon = [drawing.icon]::ExtractAssociatedIcon("$env:HOMEDRIVE\script_config\mds.ico")
     
$mStatusBox2 = New-Object -TypeName System.Windows.Forms.TextBox 
    $mStatusBox2.Text='Click "Fetch VMs" to retrieve available VMs.' 
    $mStatusBox2.Top='60' 
    $mStatusBox2.Left='15' 
    $mStatusBox2.Anchor='Left,Top'
    $mStatusBox2.Multiline='true'
    $mStatusBox2.Size = New-Object -TypeName System.Drawing.Size -ArgumentList (320,180) 
$MyForm2.Controls.Add($mStatusBox2)

$mPictureBox1 = New-Object -TypeName System.Windows.Forms.PictureBox 
    $image = [Drawing.Image]::Fromfile("$env:HOMEDRIVE\script_config\mds.jpg")
    $mPictureBox1.Text='PictureBox1' 
    $mPictureBox1.Top='10' 
    $mPictureBox1.Left='15' 
    $mPictureBox1.Anchor='Left,Top' 
    $mPictureBox1.Image=$image
$mPictureBox1.Size = New-Object -TypeName System.Drawing.Size -ArgumentList (118,38) 
$MyForm2.Controls.Add($mPictureBox1) 

$mButtonFetch = New-Object -TypeName System.Windows.Forms.Button 
    $mButtonFetch.Text='Fetch VMs' 
    $mButtonFetch.Top='20' 
    $mButtonFetch.Left='180' 
    $mButtonFetch.Anchor='Left,Top'
    $mButtonFetch.TabIndex=0
    $mButtonFetch.Add_Click({
        $mStatusBox2.Text=''
        $mStatusBox2.AppendText("Getting list of Virtual Machines available to power on...`r`n")
        $mStatusBox2.AppendText("This may take several minutes...`r`n")
        $CIServers = Get-CIVM | where-object{ ($_.Name -ilike '*URUS*') -and ($_.Status -eq 'PoweredOff') }
        If ($CIServers -ne $null){
            $CIServerCount = $CIServers.count
            $mStatusBox2.AppendText("$CIServerCount Virtual Machines found.`r`n")
            $mStatusBox2.AppendText("Loading Power On Control form.`r`n")
            $timer2 = New-Object -TypeName System.Windows.Forms.Timer
            $timer2.Interval = 3000
            $timer2.Start()
            $timer2.add_Tick({$null = $MyForm2.Close()})
        }
        Else{
            $mStatusBox2.AppendText("Connection Timeout! Please try again`r`n")
            $mStatusBox2.AppendText("Closing in 10 seconds!`r`n")
        }
    }) 
$mButtonFetch.Size = New-Object -TypeName System.Drawing.Size -ArgumentList (75,23) 
$MyForm2.Controls.Add($mButtonFetch)

$mButtonCan = New-Object -TypeName System.Windows.Forms.Button 
    $mButtonCan.Text='Cancel' 
    $mButtonCan.Top='20' 
    $mButtonCan.Left='255' 
    $mButtonCan.Anchor='Left,Top'
    $mButtonCan.Add_Click({
        If ($CIConnect.IsConnected -eq 'true'){
            $null = Disconnect-CIServer -Force -Confirm:$false
            $null = [Environment]::Exit(0)
        }
        Else{
            $null = [Environment]::Exit(0)
        }
    }) 
$mButtonCan.Size = New-Object -TypeName System.Drawing.Size -ArgumentList (75,23) 
$MyForm2.Controls.Add($mButtonCan)

$MyForm2.ShowDialog()

# Load Power Management Form
$MyForm3 = New-Object -TypeName System.Windows.Forms.Form 
$MyForm3.Text='PowerManagementForm' 
$MyForm3.Size = New-Object -TypeName System.Drawing.Size -ArgumentList (365,300)
$MyForm3.Text='VM Power On Manager - MDS Technologies LTD'
$MyForm3.BackColor='#FFFFFF'
$MyForm3.MaximizeBox = $false
$MyForm3.MinimizeBox = $false
$MyForm3.ControlBox = $true
$MyForm3.SizeGripStyle = 'Hide'
$MyForm3.StartPosition = 'CenterScreen'
$MyForm3.FormBorderStyle = 'FixedDialog'
$MyForm3.Icon = [drawing.icon]::ExtractAssociatedIcon("$env:HOMEDRIVE\script_config\mds.ico")
     
$mStatusBox2 = New-Object -TypeName System.Windows.Forms.TextBox 
    $mStatusBox2.Text='' 
    $mStatusBox2.Top='60' 
    $mStatusBox2.Left='15' 
    $mStatusBox2.Anchor='Left,Top'
    $mStatusBox2.Multiline='true'
    $mStatusBox2.Size = New-Object -TypeName System.Drawing.Size -ArgumentList (320,180) 
$MyForm3.Controls.Add($mStatusBox2)

$mPictureBox1 = New-Object -TypeName System.Windows.Forms.PictureBox 
    $image = [Drawing.Image]::Fromfile("$env:HOMEDRIVE\script_config\mds.jpg")
    $mPictureBox1.Text='PictureBox1' 
    $mPictureBox1.Top='10' 
    $mPictureBox1.Left='15' 
    $mPictureBox1.Anchor='Left,Top' 
    $mPictureBox1.Image=$image
$mPictureBox1.Size = New-Object -TypeName System.Drawing.Size -ArgumentList (118,38) 
$MyForm3.Controls.Add($mPictureBox1) 

$mButtonFetch = New-Object -TypeName System.Windows.Forms.Button 
    $mButtonFetch.Text='Fetch VMs' 
    $mButtonFetch.Top='20' 
    $mButtonFetch.Left='180' 
    $mButtonFetch.Anchor='Left,Top'
    $mButtonFetch.TabIndex=0
    $mButtonFetch.Add_Click({
        $mStatusBox2.Text=''
        $mStatusBox2.AppendText("Getting list of Virtual Machines available to power on...`r`n")
        $mStatusBox2.AppendText("This may take several minutes...`r`n")
        $CIServers = Get-CIVM | where-object{ ($_.Name -ilike '*URUS*') -and ($_.Status -eq 'PoweredOff') }
        If ($CIServers -ne $null){
            $CIServerCount = $CIServers.count
            $mStatusBox2.AppendText("$CIServerCount Virtual Machines found.`r`n")
            $mStatusBox2.AppendText("Loading Power Control form.`r`n")
            $timer2 = New-Object -TypeName System.Windows.Forms.Timer
            $timer2.Interval = 3000
            $timer2.Start()
            $timer2.add_Tick({$null = $MyForm2.Close()})
        }
        Else{
            $mStatusBox2.AppendText("Connection Timeout! Please try again`r`n")
            $mStatusBox2.AppendText("Closing in 10 seconds!`r`n")
        }
    }) 
$mButtonFetch.Size = New-Object -TypeName System.Drawing.Size -ArgumentList (75,23) 
$MyForm3.Controls.Add($mButtonFetch)

$mButtonCan = New-Object -TypeName System.Windows.Forms.Button 
    $mButtonCan.Text='Cancel' 
    $mButtonCan.Top='20' 
    $mButtonCan.Left='255' 
    $mButtonCan.Anchor='Left,Top'
    $mButtonCan.Add_Click({
        If ($CIConnect.IsConnected -eq 'true'){
            $null = Disconnect-CIServer -Force -Confirm:$false
            $null = [Environment]::Exit(0)
        }
        Else{
            $null = [Environment]::Exit(0)
        }
    }) 
$mButtonCan.Size = New-Object -TypeName System.Drawing.Size -ArgumentList (75,23) 
$MyForm3.Controls.Add($mButtonCan)

$MyForm3.ShowDialog()