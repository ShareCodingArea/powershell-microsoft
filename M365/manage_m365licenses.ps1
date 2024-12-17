# �ϥΥ��n���v���s���� Microsoft Graph
Connect-MgGraph -Scopes "Group.Read.All", "Directory.Read.All", "RoleManagement.Read.Directory"

# ����Ҧ��w�q�\�� SKU �ëإ� SKU ID �M�W�٪�������
$skus = Get-MgSubscribedSku
$skuIdToNameMap = @{ }
foreach ($sku in $skus) {
    $skuIdToNameMap[$sku.SkuId.ToString()] = $sku.SkuPartNumber
}

# ����Ҧ��ϥΪ̡A�]�t�һݪ��ݩ�
$allUsers = Get-MgUser -All -Property 'UserPrincipalName', 'GivenName', 'DisplayName', 'AssignedLicenses', 'UserType', 'AccountEnabled', 'Department', 'JobTitle', 'CreatedDateTime'

# ��l�Ƥ@�Ӷ��X�Ӧs�x�ϥΪ̩M���v��T
$LicensesUseList = @()

foreach ($user in $allUsers) {
    # �P�_�O�_���ӻ��ϥΪ�
    $isGuest = $user.UserType -eq "Guest"
    # �P�_�b���O�_�w����
    $isBlocked = -not $user.AccountEnabled
    # �B�z�����M¾�٬��Ū����p
    $department = if ($user.Department) { $user.Department } else { "None" }
    $jobTitle = if ($user.JobTitle) { $user.JobTitle } else { "None" }
    $createdDate = $user.CreatedDateTime
    # �ϥΦW�r�@�� Name
    $name = if ($user.GivenName) { $user.GivenName } else { "Unknown" }

    # �ˬd�ϥΪ̬O�_�����v
    if ($user.AssignedLicenses.Count -eq 0) {
        # �L���v
        $LicensesUseList += [PSCustomObject]@{
            UserPrincipalName = $user.UserPrincipalName
            Name              = $name
            DisplayName       = $user.DisplayName
            LicenseName       = "No License"
            Department        = $department
            JobTitle          = $jobTitle
            IsGuest           = $isGuest
            IsBlocked         = $isBlocked
            CreatedDate       = $createdDate
        }
    }
    else {
        foreach ($license in $user.AssignedLicenses) {
            try {
                # ��� SKU �O�_�b�q�\��
                $licenseName = if ($skuIdToNameMap.ContainsKey($license.SkuId.ToString())) {
                    $skuIdToNameMap[$license.SkuId.ToString()]
                } else {
                    $license.SkuId # ��� SKU ID ��@���v�W��
                }

                $LicensesUseList += [PSCustomObject]@{
                    UserPrincipalName = $user.UserPrincipalName
                    Name              = $name
                    DisplayName       = $user.DisplayName
                    LicenseName       = $licenseName
                    Department        = $department
                    JobTitle          = $jobTitle
                    IsGuest           = $isGuest
                    IsBlocked         = $isBlocked
                    CreatedDate       = $createdDate
                }
            } catch {
                Write-Host "�B�z�ϥΪ� $($user.DisplayName) �����v�ɥX�{���~�G$_"
            }
        }
    }
}

# ���] $groupDetails �O�z�n�ץX���ܼ�
if ($null -eq $LicensesUseList) {
    Write-Host "�S���i�ץX����ơC"
} else {
    # �T�O csv ��Ƨ��s�b
    $csvFolderPath = Join-Path -Path $PSScriptRoot -ChildPath ".csv"
    if (-not (Test-Path -Path $csvFolderPath)) {
        New-Item -ItemType Directory -Path $csvFolderPath
    }

    # �ץX�� CSV �ýT�{��X���|
    $outputPath = Join-Path -Path $csvFolderPath -ChildPath "M365LicensesUseList.csv"
    $LicensesUseList | Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8

    # ��ܶץX�����T��
    Write-Host "���G�w�ץX�� $outputPath"
}

# �_�}�P Microsoft Graph ���s��
Disconnect-MgGraph

# ����_�}���\������
Write-Host "�w���\�_�}�P Microsoft Graph ���s���C"
