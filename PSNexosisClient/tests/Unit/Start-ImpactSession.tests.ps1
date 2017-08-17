$Verbose = @{}
# For build automation to enable verbose
if($ENV:NCBranchName -notlike "master" -or $env:NCCommitMessage -match "!verbose")
{
	$Verbose.add("Verbose",$True)
}

Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\PSNexosisClient"

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Start-ImpactSession" {
	Context "Unit Tests" {
		Set-StrictMode -Version latest
		
		BeforeEach {
			$moduleVersion = (Test-ModuleManifest -Path $PSScriptRoot\..\..\PSNexosisClient\PSNexosisClient.psd1).Version
			$TestVars = @{
				ApiKey       = $Env:NEXOSIS_API_KEY
				UserAgent	 = "Nexosis-PS-API-Client/$moduleVersion"
				ApiEndPoint	 = 'https://api.uat.nexosisdev.com/v1'
				MaxPageSize  = "1000"
			}
		}

		Mock -ModuleName PSNexosisClient Invoke-WebRequest { 
			param($Uri, $Method, $Headers, $Body, $needHeaders) 
			if ($needHeaders) {
				$json = 
@"
{
	"Transfer-Encoding":  "chunked",
	"Nexosis-Request-Cost":  "0.01 USD",
	"Nexosis-Account-Balance":  "107.58 USD",
	"Content-Type":  "application/json; charset=utf-8",
	"Date":  "Wed, 16 Aug 2017 21:08:29 GMT"
}
"@
			}
        } -Verifiable
		
		It "starts an impact session with all parameters - no estimate" {
			Start-ImpactSession -dataSetName 'name' -eventName '50percentoff' -targetColumn 'sales' -startDate 2017-01-01T00:00:00Z -endDate 2017-01-20T00:00:00Z -resultInterval Day -callbackUrl 'http://slackme.com'
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope It
		}

  		It "calls the correct URI" {		
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				$Uri -eq "$($TestVars.ApiEndPoint)/sessions/impact?dataSetName=name&startDate=12%2f31%2f2016+19%3a00%3a00&endDate=01%2f19%2f2017+19%3a00%3a00&resultInterval=Day"
			}		
		}

		It "throws exception when dataSetName is invalid" {
			{ Start-ImpactSession -dataSetName '       ' -eventName 'test' -startDate 01-01-2017 -endDate 01-20-2017 } | Should throw "Argument '-DataSetName' cannot be null or empty."
		} 

        It "calls with the proper HTTP verb" {
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				$method -eq [Microsoft.PowerShell.Commands.WebRequestMethod]::Post
			}
        }

        It "calls with the proper content-type" {
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				$ContentType -eq 'application/json'
			}
        }

        It "has proper HTTP headers" {
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				(
					($Headers.Contains("accept")) -and 
					($Headers.Contains("api-key")) -and
					($Headers.Contains("User-Agent")) -and
					($Headers.Get_Item("accept") -eq 'application/json') -and
					($Headers.Get_Item("api-key") -eq $TestVars.ApiKey) -and
					($Headers.Get_Item("User-Agent") -eq $TestVars.UserAgent)
				)
			}
		}
		
		It "starts an impact session with all parameters" {
			Start-ImpactSession -dataSetName 'name' -eventName '50percentoff' -targetColumn 'sales' -startDate 2017-01-01 -endDate 2017-01-20 -resultInterval Day -callbackUrl 'http://slackme.com' -isEstimate
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				$Uri -eq "$($TestVars.ApiEndPoint)/sessions/impact?dataSetName=name&startDate=01%2f01%2f2017+00%3a00%3a00&endDate=01%2f20%2f2017+00%3a00%3a00&isEstimate=true&resultInterval=Day"
			}	
		}

		It "starts an impact session with all parameters except estimate" {
			Start-ImpactSession -dataSetName 'name' -eventName '50percentoff' -targetColumn 'sales' -startDate 2017-01-01 -endDate 2017-01-20 -resultInterval Day -callbackUrl 'http://slackme.com'
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				$Uri -eq "$($TestVars.ApiEndPoint)/sessions/impact?dataSetName=name&startDate=12%2f31%2f2016+19%3a00%3a00&endDate=01%2f19%2f2017+19%3a00%3a00&resultInterval=Day"
			}	
		}
	}
}