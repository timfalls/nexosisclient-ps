Function Get-Session {
<# 
 .Synopsis
  Gets the list of sessions that have been created for the company associated with your account.

 .Description
  Gets the list of sessions that have been created for the company associated with your account.

 .Parameter DataSetName
  Limits sessions to those for a particular dataset

 .Parameter EventName
  Limits impact sessions to those for a particular event

 .Parameter RequestedAfterDate
  Limits sessions to those requested on or after the specified date  as date-time in ISO8601 format.

 .Parameter RequestedBeforeDate
  Limits sessions to those requested on or before the specified date as date-time in ISO8601 format.

 .Parameter Page
  Zero-based page number of results to retrieve.

 .Parameter PageSize
  Count of datasets to retrieve in each page (max 1000).

 .Example
  

 .Example
  

 .Example
  
#>[CmdletBinding()]
	Param(
        [Parameter(Mandatory=$false, ValueFromPipeline=$True)]
        [string]$dataSetName,
		[Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
		[DateTime]$requestedAfterDate,
		[Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
		[DateTime]$requestedBeforeDate,
		[Parameter(Mandatory=$false)]
		[int]$page=0,
		[Parameter(Mandatory=$false)]
        [int]$pageSize=$script:PSNexosisVars.DefaultPageSize
	)
    process {
        if (($page -ge $script:MaxPageSize) -or ($page -lt 0)) {
            throw "Parameter '-page' must be an integer between 0 and $script:MaxPageSize."
        }

        if (($pageSize -ge $script:MaxPageSize) -or ($pageSize -lt 0)) {
            throw "Parameter '-pageSize' must be an integer between 0 and $script:MaxPageSize."
        }

        $params = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)

        if (($dataSetName -ne $null) -or ($dataSetName.Trim().Length -gt 0)) {
            $params['dataSetName'] = $dataSetName
        }

        if ($page -ne 0) {
            $params['page'] = $page
        }
        if ($pageSize -ne ($script:PSNexosisVars.DefaultPageSize)) {
            $params['pageSize'] = $pageSize
        }

        if ($requestedAfterDate -ne $null) { 
			$params['requestedAfterDate'] = $requestedAfterDate
		}
		if ($requestedBeforeDate -ne $null) {
			$params['requestedBeforeDate'] = $requestedBeforeDate
        }
        
        $response = Invoke-Http -method Get -path 'sessions' -params $params
        $hasResponseCode = $null -ne $response.StatusCode
        
        if ($hasResponseCode -eq $true) {
            $response
        } else {
            $response.items
        }

    }
}