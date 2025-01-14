# �ϥΥ��n���v���s���� Microsoft Graph
Connect-MgGraph -Scopes "Group.Read.All", "Directory.Read.All", "RoleManagement.Read.Directory"

# ����Ҧ��w�q�\�� SKU �ëإ� SKU ID �M�W�٪�������
$skus = Get-MgSubscribedSku
$skuIdToNameMap = @{ }
foreach ($sku in $skus) {
    $skuIdToNameMap[$sku.SkuId.ToString()] = $sku.SkuPartNumber
}

# ����Ҧ��ϥΪ̡A�]�t�һݪ��ݩ�
$allUsers = Get-MgUser -All -Property 'UserPrincipalName', 'GivenName', 'DisplayName', 'AssignedLicenses'

# ��l�Ƥ@�Ӷ��X�Ӧs�x�㦳 Copilot ���v���ϥΪ̸�T
$CopilotLicensesUseList = @()

foreach ($user in $allUsers) {
    # �ˬd�ϥΪ̬O�_�����v
    if ($user.AssignedLicenses.Count -gt 0) {
        foreach ($license in $user.AssignedLicenses) {
            # �ˬd�O�_�� Copilot ���v
            if ($skuIdToNameMap[$license.SkuId.ToString()] -like "*Copilot*") {
                $CopilotLicensesUseList += [PSCustomObject]@{
                    UserPrincipalName = $user.UserPrincipalName
                    GivenName         = $user.GivenName
                    DisplayName       = $user.DisplayName
                    LicenseName       = $skuIdToNameMap[$license.SkuId.ToString()] # ��ܱ��v�W��
                }
            }
        }
    }
}

# ���] $groupDetails �O�z�n�ץX���ܼ�
if ($null -eq $CopilotLicensesUseList) {
    Write-Host "�S���i�ץX����ơC"
} else {
    # �T�O csv ��Ƨ��s�b
    $csvFolderPath = Join-Path -Path $PSScriptRoot -ChildPath ".csv"
    if (-not (Test-Path -Path $csvFolderPath)) {
        New-Item -ItemType Directory -Path $csvFolderPath
    }

    # �ץX�� CSV �ýT�{��X���|
    $outputPath = Join-Path -Path $csvFolderPath -ChildPath "CopilotLicensesUseList.csv"
    $CopilotLicensesUseList | Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8

    # ��ܶץX�����T��
    Write-Host "���G�w�ץX�� $outputPath"
}

# �_�}�P Microsoft Graph ���s��
Disconnect-MgGraph

# ����_�}���\������
Write-Host "�w���\�_�}�P Microsoft Graph ���s���C"
