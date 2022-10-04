

function Search-ADUser {
    param (
        $searchFilter
    )
    Get-ADUser -LDAPFilter "(& (samaccountname=$($searchFilter)))" -properties description, ExtensionAttribute12, ExtensionAttribute4, Description, manager, passwordlastset, passwordneverexpires
}

function Search-ADGroup {
    param (
        $searchFilter
    )
    Get-ADGroup -LDAPFilter "(& (cn=$($searchFilter)))" -properties description, manager
}