Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Global:ToolkitVersion = "2.1.0"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Test-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-CategoryDefinitions {
    return @(
        [pscustomobject]@{
            Name       = "Maintenance"
            GroupTitle = "Auto Maintenance"
            FolderName = "maintenance-configs"
        },
        [pscustomobject]@{
            Name       = "Networking"
            GroupTitle = "Auto Networking"
            FolderName = "networking-configs"
        },
        [pscustomobject]@{
            Name       = "Security"
            GroupTitle = "Auto Security"
            FolderName = "security-configs"
        },
        [pscustomobject]@{
            Name       = "Update"
            GroupTitle = "Auto Update"
            FolderName = "update-configs"
        }
    )
}

function Get-ConfigPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FolderName
    )

    return Join-Path $PSScriptRoot $FolderName
}

function Get-CategoryEntries {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FolderName
    )

    $configPath = Get-ConfigPath -FolderName $FolderName
    if (-not (Test-Path -Path $configPath)) {
        return @()
    }

    $entries = @()
    $configFiles = Get-ChildItem -Path $configPath -Filter "*.ps1" | Sort-Object Name

    foreach ($file in $configFiles) {
        try {
            $metadata = & $file.FullName
            if ($null -eq $metadata) {
                continue
            }

            if ([string]::IsNullOrWhiteSpace($metadata.Id) -or [string]::IsNullOrWhiteSpace($metadata.Label)) {
                continue
            }

            $entries += [pscustomobject]@{
                Id            = $metadata.Id
                Label         = $metadata.Label
                Group         = if ($metadata.PSObject.Properties.Name -contains "Group") { [string]$metadata.Group } else { "Basic" }
                RequiresAdmin = [bool]$metadata.RequiresAdmin
                FilePath      = $file.FullName
            }
        }
        catch {
            # Skip invalid config scripts and keep app running.
        }
    }

    return $entries
}

function Add-Log {
    param(
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.TextBox]$OutputBox,
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    $timestamp = (Get-Date).ToString("HH:mm:ss")
    $OutputBox.AppendText("[$timestamp] $Message$([Environment]::NewLine)")
}

function Invoke-CategorySelection {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CategoryName,
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$SelectedEntries,
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.TextBox]$OutputBox,
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.Label]$StatusLabel
    )

    if ($SelectedEntries.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            "Pilih minimal 1 item pada kategori $CategoryName.",
            "IT Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
        return
    }

    $adminRequired = @($SelectedEntries | Where-Object { $_.RequiresAdmin })
    if ($adminRequired.Count -gt 0 -and -not (Test-Admin)) {
        [System.Windows.Forms.MessageBox]::Show(
            "Beberapa aksi di kategori $CategoryName butuh Run as Administrator.",
            "Need Administrator",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        return
    }

    $StatusLabel.Text = "Status: Running $CategoryName..."
    Add-Log -OutputBox $OutputBox -Message "$CategoryName started."

    foreach ($entry in $SelectedEntries) {
        Add-Log -OutputBox $OutputBox -Message "Running: $($entry.Label)"
        try {
            $result = & $entry.FilePath -Execute 2>&1 | Out-String
            if (-not [string]::IsNullOrWhiteSpace($result)) {
                $result.TrimEnd().Split([Environment]::NewLine) | ForEach-Object {
                    if (-not [string]::IsNullOrWhiteSpace($_)) {
                        Add-Log -OutputBox $OutputBox -Message "  $_"
                    }
                }
            }

            Add-Log -OutputBox $OutputBox -Message "Done: $($entry.Label)"
        }
        catch {
            Add-Log -OutputBox $OutputBox -Message "Failed: $($entry.Label) -> $($_.Exception.Message)"
        }
    }

    Add-Log -OutputBox $OutputBox -Message "$CategoryName finished."
    $StatusLabel.Text = "Status: Idle"
}

function New-CategoryPage {
    param(
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.Panel]$ParentPanel,
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Category
    )

    $entries = New-Object System.Collections.ArrayList
    $getCategoryEntriesFn = ${function:Get-CategoryEntries}
    $addLogFn = ${function:Add-Log}
    $invokeCategorySelectionFn = ${function:Invoke-CategorySelection}

    $page = New-Object System.Windows.Forms.Panel
    $page.Dock = [System.Windows.Forms.DockStyle]::Fill
    $page.BackColor = [System.Drawing.Color]::FromArgb(23, 29, 38)
    $page.Visible = $false
    $ParentPanel.Controls.Add($page)

    $groupAuto = New-Object System.Windows.Forms.Panel
    $groupAuto.BackColor = [System.Drawing.Color]::FromArgb(23, 29, 38)
    $groupAuto.Location = New-Object System.Drawing.Point(16, 4)
    $groupAuto.Size = New-Object System.Drawing.Size(468, 420)
    $page.Controls.Add($groupAuto)

    $groupAutoTitle = New-Object System.Windows.Forms.Label
    $groupAutoTitle.Text = $Category.GroupTitle
    $groupAutoTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 11)
    $groupAutoTitle.ForeColor = [System.Drawing.Color]::FromArgb(89, 205, 255)
    $groupAutoTitle.AutoSize = $true
    $groupAutoTitle.Location = New-Object System.Drawing.Point(0, 0)
    $groupAuto.Controls.Add($groupAutoTitle)

    $checkLists = New-Object System.Collections.ArrayList
    $basicEntries = New-Object System.Collections.ArrayList
    $advancedEntries = New-Object System.Collections.ArrayList
    $mainEntries = New-Object System.Collections.ArrayList
    $checkListBasic = $null
    $checkListAdvanced = $null
    $checkListMain = $null

    $isMaintenanceCategory = ($Category.Name -eq "Maintenance")

    if ($isMaintenanceCategory) {
        $basicTitle = New-Object System.Windows.Forms.Label
        $basicTitle.Text = "Basic"
        $basicTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9.5)
        $basicTitle.ForeColor = [System.Drawing.Color]::FromArgb(166, 227, 255)
        $basicTitle.AutoSize = $true
        $basicTitle.Location = New-Object System.Drawing.Point(18, 20)
        $groupAuto.Controls.Add($basicTitle)

        $checkListBasic = New-Object System.Windows.Forms.CheckedListBox
        $checkListBasic.CheckOnClick = $true
        $checkListBasic.BorderStyle = [System.Windows.Forms.BorderStyle]::None
        $checkListBasic.BackColor = [System.Drawing.Color]::FromArgb(23, 29, 38)
        $checkListBasic.ForeColor = [System.Drawing.Color]::FromArgb(224, 231, 239)
        $checkListBasic.Font = New-Object System.Drawing.Font("Segoe UI", 8.4)
        $checkListBasic.Location = New-Object System.Drawing.Point(18, 40)
        $checkListBasic.Size = New-Object System.Drawing.Size(430, 120)
        $groupAuto.Controls.Add($checkListBasic)
        [void]$checkLists.Add($checkListBasic)

        $advancedTitle = New-Object System.Windows.Forms.Label
        $advancedTitle.Text = "Advanced"
        $advancedTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9.5)
        $advancedTitle.ForeColor = [System.Drawing.Color]::FromArgb(166, 227, 255)
        $advancedTitle.AutoSize = $true
        $advancedTitle.Location = New-Object System.Drawing.Point(18, 154)
        $groupAuto.Controls.Add($advancedTitle)

        $checkListAdvanced = New-Object System.Windows.Forms.CheckedListBox
        $checkListAdvanced.CheckOnClick = $true
        $checkListAdvanced.BorderStyle = [System.Windows.Forms.BorderStyle]::None
        $checkListAdvanced.BackColor = [System.Drawing.Color]::FromArgb(23, 29, 38)
        $checkListAdvanced.ForeColor = [System.Drawing.Color]::FromArgb(224, 231, 239)
        $checkListAdvanced.Font = New-Object System.Drawing.Font("Segoe UI", 7.8)
        $checkListAdvanced.Location = New-Object System.Drawing.Point(18, 174)
        $checkListAdvanced.Size = New-Object System.Drawing.Size(430, 186)
        $checkListAdvanced.MultiColumn = $true
        $checkListAdvanced.ColumnWidth = 208
        $checkListAdvanced.ScrollAlwaysVisible = $false
        $groupAuto.Controls.Add($checkListAdvanced)
        [void]$checkLists.Add($checkListAdvanced)
    }
    else {
        $checkListMain = New-Object System.Windows.Forms.CheckedListBox
        $checkListMain.CheckOnClick = $true
        $checkListMain.BorderStyle = [System.Windows.Forms.BorderStyle]::None
        $checkListMain.BackColor = [System.Drawing.Color]::FromArgb(23, 29, 38)
        $checkListMain.ForeColor = [System.Drawing.Color]::FromArgb(224, 231, 239)
        $checkListMain.Font = New-Object System.Drawing.Font("Segoe UI", 8.8)
        $checkListMain.Location = New-Object System.Drawing.Point(18, 33)
        $checkListMain.Size = New-Object System.Drawing.Size(430, 326)
        $groupAuto.Controls.Add($checkListMain)
        [void]$checkLists.Add($checkListMain)
    }

    $btnPresetStandard = $null
    $btnPresetMinimal = $null
    $btnPresetClear = $null
    $btnSelectAll = $null
    $btnClear = $null
    $btnRefresh = $null

    if ($isMaintenanceCategory) {
        $recommendedLabel = New-Object System.Windows.Forms.Label
        $recommendedLabel.Text = "Recommended Selection"
        $recommendedLabel.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 8.6)
        $recommendedLabel.ForeColor = [System.Drawing.Color]::FromArgb(166, 227, 255)
        $recommendedLabel.BackColor = [System.Drawing.Color]::Transparent
        $recommendedLabel.AutoSize = $true
        $recommendedLabel.Location = New-Object System.Drawing.Point(18, 360)
        $groupAuto.Controls.Add($recommendedLabel)

        $btnPresetStandard = New-Object System.Windows.Forms.Button
        $btnPresetStandard.Text = "Standart"
        $btnPresetStandard.BackColor = [System.Drawing.Color]::FromArgb(34, 71, 98)
        $btnPresetStandard.ForeColor = [System.Drawing.Color]::White
        $btnPresetStandard.FlatStyle = "Flat"
        $btnPresetStandard.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(71, 122, 165)
        $btnPresetStandard.FlatAppearance.BorderSize = 1
        $btnPresetStandard.Location = New-Object System.Drawing.Point(18, 380)
        $btnPresetStandard.Size = New-Object System.Drawing.Size(122, 24)
        $groupAuto.Controls.Add($btnPresetStandard)

        $btnPresetMinimal = New-Object System.Windows.Forms.Button
        $btnPresetMinimal.Text = "Minimal"
        $btnPresetMinimal.BackColor = [System.Drawing.Color]::FromArgb(34, 71, 98)
        $btnPresetMinimal.ForeColor = [System.Drawing.Color]::White
        $btnPresetMinimal.FlatStyle = "Flat"
        $btnPresetMinimal.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(71, 122, 165)
        $btnPresetMinimal.FlatAppearance.BorderSize = 1
        $btnPresetMinimal.Location = New-Object System.Drawing.Point(149, 380)
        $btnPresetMinimal.Size = New-Object System.Drawing.Size(122, 24)
        $groupAuto.Controls.Add($btnPresetMinimal)

        $btnPresetClear = New-Object System.Windows.Forms.Button
        $btnPresetClear.Text = "Clear"
        $btnPresetClear.BackColor = [System.Drawing.Color]::FromArgb(34, 71, 98)
        $btnPresetClear.ForeColor = [System.Drawing.Color]::White
        $btnPresetClear.FlatStyle = "Flat"
        $btnPresetClear.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(71, 122, 165)
        $btnPresetClear.FlatAppearance.BorderSize = 1
        $btnPresetClear.Location = New-Object System.Drawing.Point(280, 380)
        $btnPresetClear.Size = New-Object System.Drawing.Size(130, 24)
        $groupAuto.Controls.Add($btnPresetClear)
    }
    else {
        $btnSelectAll = New-Object System.Windows.Forms.Button
        $btnSelectAll.Text = "Select All"
        $btnSelectAll.BackColor = [System.Drawing.Color]::FromArgb(34, 71, 98)
        $btnSelectAll.ForeColor = [System.Drawing.Color]::White
        $btnSelectAll.FlatStyle = "Flat"
        $btnSelectAll.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(71, 122, 165)
        $btnSelectAll.FlatAppearance.BorderSize = 1
        $btnSelectAll.Location = New-Object System.Drawing.Point(18, 370)
        $btnSelectAll.Size = New-Object System.Drawing.Size(122, 32)
        $groupAuto.Controls.Add($btnSelectAll)

        $btnClear = New-Object System.Windows.Forms.Button
        $btnClear.Text = "Clear"
        $btnClear.BackColor = [System.Drawing.Color]::FromArgb(34, 71, 98)
        $btnClear.ForeColor = [System.Drawing.Color]::White
        $btnClear.FlatStyle = "Flat"
        $btnClear.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(71, 122, 165)
        $btnClear.FlatAppearance.BorderSize = 1
        $btnClear.Location = New-Object System.Drawing.Point(149, 370)
        $btnClear.Size = New-Object System.Drawing.Size(122, 32)
        $groupAuto.Controls.Add($btnClear)

        $btnRefresh = New-Object System.Windows.Forms.Button
        $btnRefresh.Text = "Refresh Config"
        $btnRefresh.BackColor = [System.Drawing.Color]::FromArgb(34, 71, 98)
        $btnRefresh.ForeColor = [System.Drawing.Color]::White
        $btnRefresh.FlatStyle = "Flat"
        $btnRefresh.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(71, 122, 165)
        $btnRefresh.FlatAppearance.BorderSize = 1
        $btnRefresh.Location = New-Object System.Drawing.Point(280, 370)
        $btnRefresh.Size = New-Object System.Drawing.Size(130, 32)
        $groupAuto.Controls.Add($btnRefresh)
    }

    $groupOutput = New-Object System.Windows.Forms.Panel
    $groupOutput.BackColor = [System.Drawing.Color]::FromArgb(23, 29, 38)
    $groupOutput.Location = New-Object System.Drawing.Point(500, 4)
    $groupOutput.Size = New-Object System.Drawing.Size(420, 420)
    $page.Controls.Add($groupOutput)

    $groupOutputTitle = New-Object System.Windows.Forms.Label
    $groupOutputTitle.Text = "Execution Log"
    $groupOutputTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 11)
    $groupOutputTitle.ForeColor = [System.Drawing.Color]::FromArgb(89, 205, 255)
    $groupOutputTitle.AutoSize = $true
    $groupOutputTitle.Location = New-Object System.Drawing.Point(0, 0)
    $groupOutput.Controls.Add($groupOutputTitle)

    $outputBox = New-Object System.Windows.Forms.TextBox
    $outputBox.Multiline = $true
    $outputBox.ReadOnly = $true
    $outputBox.ScrollBars = "Vertical"
    $outputBox.BackColor = [System.Drawing.Color]::FromArgb(17, 22, 30)
    $outputBox.ForeColor = [System.Drawing.Color]::FromArgb(186, 221, 255)
    $outputBox.Font = New-Object System.Drawing.Font("Consolas", 9.5)
    $outputBox.Location = New-Object System.Drawing.Point(16, 33)
    $outputBox.Size = New-Object System.Drawing.Size(388, 370)
    $groupOutput.Controls.Add($outputBox)

    $btnRun = New-Object System.Windows.Forms.Button
    $btnRun.Text = "Run Selected $($Category.Name)"
    $btnRun.BackColor = [System.Drawing.Color]::FromArgb(28, 95, 146)
    $btnRun.ForeColor = [System.Drawing.Color]::White
    $btnRun.FlatStyle = "Flat"
    $btnRun.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(95, 166, 214)
    $btnRun.FlatAppearance.BorderSize = 1
    $btnRun.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10)
    $btnRun.Location = New-Object System.Drawing.Point(16, 446)
    $btnRun.Size = New-Object System.Drawing.Size(250, 35)
    $page.Controls.Add($btnRun)

    $statusLabel = New-Object System.Windows.Forms.Label
    $statusLabel.Text = "Status: Idle"
    $statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(163, 176, 192)
    $statusLabel.AutoSize = $true
    $statusLabel.Location = New-Object System.Drawing.Point(282, 454)
    $page.Controls.Add($statusLabel)

    $updateFooterLayout = {
        $bottomPadding = 8
        $btnY = [Math]::Max(0, ($page.ClientSize.Height - $btnRun.Height - $bottomPadding))
        $btnRun.Location = New-Object System.Drawing.Point(16, $btnY)
        $statusLabel.Location = New-Object System.Drawing.Point(282, ($btnY + 8))
    }.GetNewClosure()

    $page.Add_Resize({
        & $updateFooterLayout
    }.GetNewClosure())

    & $updateFooterLayout

    $loadConfigs = {
        foreach ($list in $checkLists) {
            $list.Items.Clear()
        }

        $entries.Clear()
        $basicEntries.Clear()
        $advancedEntries.Clear()
        $mainEntries.Clear()

        $loaded = & $getCategoryEntriesFn -FolderName $Category.FolderName
        foreach ($entry in $loaded) {
            [void]$entries.Add($entry)

            if ($isMaintenanceCategory) {
                if ($entry.Group -eq "Advanced") {
                    [void]$advancedEntries.Add($entry)
                    [void]$checkListAdvanced.Items.Add($entry.Label)
                }
                else {
                    [void]$basicEntries.Add($entry)
                    [void]$checkListBasic.Items.Add($entry.Label)
                }
            }
            else {
                [void]$mainEntries.Add($entry)
                [void]$checkListMain.Items.Add($entry.Label)
            }
        }

        & $addLogFn -OutputBox $outputBox -Message "Loaded $($entries.Count) config(s) from $($Category.FolderName)."
    }.GetNewClosure()

    if ($isMaintenanceCategory) {
        $clearAllSelections = {
            foreach ($list in $checkLists) {
                for ($i = 0; $i -lt $list.Items.Count; $i++) {
                    $list.SetItemChecked($i, $false)
                }
            }
        }.GetNewClosure()

        $btnPresetMinimal.Add_Click({
            & $clearAllSelections
            for ($i = 0; $i -lt $checkListBasic.Items.Count; $i++) {
                $checkListBasic.SetItemChecked($i, $true)
            }
        }.GetNewClosure())

        $btnPresetStandard.Add_Click({
            & $clearAllSelections
            for ($i = 0; $i -lt $checkListBasic.Items.Count; $i++) {
                $checkListBasic.SetItemChecked($i, $true)
            }

            $targetIds = @("remove-xbox-gaming-components", "remove-onedrive", "disable-microsoft-copilot")
            for ($i = 0; $i -lt $advancedEntries.Count; $i++) {
                if ($targetIds -contains $advancedEntries[$i].Id) {
                    $checkListAdvanced.SetItemChecked($i, $true)
                }
            }
        }.GetNewClosure())

        $btnPresetClear.Add_Click({
            & $clearAllSelections
        }.GetNewClosure())
    }
    else {
        $btnSelectAll.Add_Click({
            foreach ($list in $checkLists) {
                for ($i = 0; $i -lt $list.Items.Count; $i++) {
                    $list.SetItemChecked($i, $true)
                }
            }
        }.GetNewClosure())

        $btnClear.Add_Click({
            foreach ($list in $checkLists) {
                for ($i = 0; $i -lt $list.Items.Count; $i++) {
                    $list.SetItemChecked($i, $false)
                }
            }
        }.GetNewClosure())

        $btnRefresh.Add_Click({
            & $loadConfigs
        }.GetNewClosure())
    }

    $btnRun.Add_Click({
        $selectedEntries = New-Object System.Collections.ArrayList

        if ($isMaintenanceCategory) {
            foreach ($idx in $checkListBasic.CheckedIndices) {
                [void]$selectedEntries.Add($basicEntries[[int]$idx])
            }
            foreach ($idx in $checkListAdvanced.CheckedIndices) {
                [void]$selectedEntries.Add($advancedEntries[[int]$idx])
            }
        }
        else {
            foreach ($idx in $checkListMain.CheckedIndices) {
                [void]$selectedEntries.Add($mainEntries[[int]$idx])
            }
        }

        & $invokeCategorySelectionFn -CategoryName $Category.Name -SelectedEntries $selectedEntries -OutputBox $outputBox -StatusLabel $statusLabel
    }.GetNewClosure())

    & $loadConfigs

    return [pscustomobject]@{
        Name = $Category.Name
        Page = $page
    }
}

function Show-ToolkitGui {
    [System.Windows.Forms.Application]::EnableVisualStyles()

    $contentBg = [System.Drawing.Color]::FromArgb(23, 29, 38)

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "IT Toolkit"
    $form.Size = New-Object System.Drawing.Size(980, 680)
    $form.StartPosition = "CenterScreen"
    $form.BackColor = $contentBg
    $form.ForeColor = [System.Drawing.Color]::White
    $form.Font = New-Object System.Drawing.Font("Segoe UI", 10)

    $headerPanel = New-Object System.Windows.Forms.Panel
    $headerPanel.Dock = "Top"
    $headerPanel.Height = 86
    $headerPanel.BackColor = [System.Drawing.Color]::FromArgb(27, 33, 42)
    $form.Controls.Add($headerPanel)

    $headerLine = New-Object System.Windows.Forms.Panel
    $headerLine.Dock = "Bottom"
    $headerLine.Height = 1
    $headerLine.BackColor = [System.Drawing.Color]::FromArgb(65, 126, 174)
    $headerPanel.Controls.Add($headerLine)

    $topGapPanel = New-Object System.Windows.Forms.Panel
    $topGapPanel.Location = New-Object System.Drawing.Point(0, 86)
    $topGapPanel.Size = New-Object System.Drawing.Size(980, 10)
    $topGapPanel.Anchor = "Top,Left,Right"
    $topGapPanel.BackColor = $contentBg
    $form.Controls.Add($topGapPanel)

    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "IT Toolkit"
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI Black", 18, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(239, 246, 252)
    $titleLabel.AutoSize = $true
    $titleLabel.Location = New-Object System.Drawing.Point(24, 12)
    $headerPanel.Controls.Add($titleLabel)

    $subtitleLabel = New-Object System.Windows.Forms.Label
    $subtitleLabel.Text = "by AndraFM_ · v$Global:ToolkitVersion"
    $subtitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $subtitleLabel.ForeColor = [System.Drawing.Color]::FromArgb(162, 178, 194)
    $subtitleLabel.AutoSize = $true
    $subtitleLabel.Location = New-Object System.Drawing.Point(28, 50)
    $headerPanel.Controls.Add($subtitleLabel)

    $accessLabel = New-Object System.Windows.Forms.Label
    $accessLabel.Text = "Access"
    $accessLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
    $accessLabel.ForeColor = [System.Drawing.Color]::FromArgb(162, 178, 194)
    $accessLabel.AutoSize = $true
    $accessLabel.Location = New-Object System.Drawing.Point(840, 16)
    $accessLabel.Anchor = "Top,Right"
    $headerPanel.Controls.Add($accessLabel)

    $isAdmin = Test-Admin
    $accessBadge = New-Object System.Windows.Forms.Label
    $accessBadge.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $accessBadge.AutoSize = $false
    $accessBadge.Size = New-Object System.Drawing.Size(108, 28)
    $accessBadge.Location = New-Object System.Drawing.Point(810, 36)
    $accessBadge.Anchor = "Top,Right"
    $accessBadge.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
    $accessBadge.ForeColor = [System.Drawing.Color]::White
    $accessBadge.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

    if ($isAdmin) {
        $accessBadge.Text = "Administrator"
        $accessBadge.BackColor = [System.Drawing.Color]::FromArgb(189, 127, 0)
    }
    else {
        $accessBadge.Text = "User"
        $accessBadge.BackColor = [System.Drawing.Color]::FromArgb(58, 67, 79)
    }

    $headerPanel.Controls.Add($accessBadge)

    $navPanel = New-Object System.Windows.Forms.Panel
    $navPanel.Location = New-Object System.Drawing.Point(17, 96)
    $navPanel.Size = New-Object System.Drawing.Size(944, 42)
    $navPanel.Anchor = "Top,Left,Right"
    $navPanel.BackColor = $contentBg
    $form.Controls.Add($navPanel)

    $contentPanel = New-Object System.Windows.Forms.Panel
    $contentPanel.Location = New-Object System.Drawing.Point(17, 144)
    $contentPanel.Size = New-Object System.Drawing.Size(944, 490)
    $contentPanel.Anchor = "Top,Bottom,Left,Right"
    $contentPanel.BackColor = $contentBg
    $form.Controls.Add($contentPanel)

    $categoryViews = New-Object System.Collections.ArrayList
    $navButtons = New-Object System.Collections.ArrayList

    $categories = Get-CategoryDefinitions
    $btnWidth = 110
    $btnGap = 6
    $btnX = 16

    foreach ($category in $categories) {
        $view = New-CategoryPage -ParentPanel $contentPanel -Category $category
        [void]$categoryViews.Add($view)

        $navButton = New-Object System.Windows.Forms.Button
        $navButton.Text = $category.Name
        $navButton.Tag = $category.Name
        $navButton.Location = New-Object System.Drawing.Point($btnX, 4)
        $navButton.Size = New-Object System.Drawing.Size($btnWidth, 34)
        $navButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $navButton.FlatAppearance.BorderSize = 1
        $navButton.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10)
        $navButton.ForeColor = [System.Drawing.Color]::FromArgb(217, 227, 238)
        $navButton.BackColor = $contentBg
        $navButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(78, 93, 109)
        $navPanel.Controls.Add($navButton)
        [void]$navButtons.Add($navButton)

        $btnX += ($btnWidth + $btnGap)
    }

    $setActiveCategory = {
        param([string]$CategoryName)

        foreach ($view in $categoryViews) {
            $view.Page.Visible = ($view.Name -eq $CategoryName)
        }

        foreach ($button in $navButtons) {
            $isActive = ($button.Tag -eq $CategoryName)
            if ($isActive) {
                $button.BackColor = $contentBg
                $button.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(132, 190, 240)
                $button.ForeColor = [System.Drawing.Color]::FromArgb(241, 248, 255)
            }
            else {
                $button.BackColor = $contentBg
                $button.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(78, 93, 109)
                $button.ForeColor = [System.Drawing.Color]::FromArgb(217, 227, 238)
            }
        }
    }.GetNewClosure()

    foreach ($button in $navButtons) {
        $button.Add_Click({
            param($sourceButton, $clickArgs)
            & $setActiveCategory $sourceButton.Tag
        }.GetNewClosure())
    }

    if ($categories.Count -gt 0) {
        & $setActiveCategory $categories[0].Name
    }

    $form.Add_Shown({ $form.Activate() })
    
    $form.Add_FormClosing({
        $tempRoot = Join-Path $env:TEMP "ITToolkit-AndraFM"
        if (Test-Path -Path $tempRoot) {
            try {
                Write-Host "Cleaning up temporary files..." -ForegroundColor Cyan
                Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "Cleanup completed." -ForegroundColor Green
            }
            catch {
                Write-Host "Warning: Could not clean temp folder - $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    })
    
    [void]$form.ShowDialog()
}

Show-ToolkitGui
