#Provider


action :create do
	bindings = "@(" + new_resource.bindings.map{|v| "\"" + v + "\""}.join(", ") + ")"
	sslbindings = "@(" + new_resource.sslbindings.map{|v| "\"" + v + "\""}.join(", ") + ")"

	#http://stackoverflow.com/questions/1924217/powershell-load-webadministration-in-ps1-script-on-both-iis-7-and-iis-7-5

	powershell "createwebsite" do
		code <<-EOH
		$iisVersion = Get-ItemProperty "HKLM:\\software\\microsoft\\InetStp";
		if ($iisVersion.MajorVersion -eq 7)
		{
			if ($iisVersion.MinorVersion -ge 5)
			{
				Import-Module WebAdministration;
			}           
			else
			{
				if (-not (Get-PSSnapIn | Where {$_.Name -eq "WebAdministration";})) {
					Add-PSSnapIn WebAdministration;
				}
			}
		}
		
		function EnsureAppPoolExists([string]$appPoolName)
		{
			if (@(ls IIS:\\AppPools | Where {$_.Name -eq $appPoolName}).Count -eq 0)
			{
				echo "Creating app pool"
				New-WebAppPool -Name $appPoolName
			}
		}

		function EnsureAppPoolDotNetVersion([string]$appPoolName, [string]$version)
		{
			if ((Get-ItemProperty IIS:\\AppPools\\$appPoolName managedRuntimeVersion).Value -ne "v$version")
			{
				echo "setting app pool version"
				Set-ItemProperty IIS:\\AppPools\\$appPoolName managedRuntimeVersion "v$version"
			}
		}

		function EnsureWebsiteExists([string]$sitename, [string]$path)
		{
			if ((@(get-website | where {$_.Name -eq $sitename -and $_.PhysicalPath -eq $path})).Count -eq 0)
			{
				echo "creating $sitename $path"
				New-Website -Name $sitename -PhysicalPath $path
			}
		}

		function EnsureWebSiteAppPool([string]$websiteName, [string]$appPoolName)
		{
			if ((get-website | Where {$_.Name -eq $websiteName}).applicationPool -ne $appPoolName)
			{
				echo "setting websiteapppool"
				Set-ItemProperty IIS:\\Sites\\$websiteName applicationPool $appPoolName
			}
		}

		function SyncBindings([string]$sitename, [string]$protocol, [Array]$bindings)
		{
			$existingBindings = New-Object System.Collections.ArrayList
			$existingBindings.AddRange((get-website | where {$_.Name -eq $sitename}).Bindings.Collection)

			#search for wanted bindings
			foreach ($binding in $bindings)
			{
				$found = 0
				foreach ($existing in $existingBindings)
				{
					if ($existing.protocol -eq $protocol -and $existing.bindingInformation -eq $binding)
					{
						$found = 1
						break
					}
				}
				if ($found -eq 0)
				{
					"Couldn't find $protocol binding: $binding"
					$s = $binding.Split(':')
					New-WebBinding -Name $sitename -Protocol $protocol -IPAddress $s[0] -HostHeader $s[2] -Port $s[1]
				}
			}

			#search for unwanted bindings
			foreach ($existing in $existingBindings)
			{
				if ($existing.protocol -ne $protocol)
				{
					continue
				}

				$found = 0
				foreach ($binding in $bindings)
				{
					if ($existing.bindingInformation -eq $binding)
					{
						$found = 1
						break
					}
				}
				if ($found -eq 0)
				{
					"Unwanted $protocol binding: {0}" -f $existing.bindingInformation
					$s = $existing.bindingInformation.Split(':')
					Remove-WebBinding -Name $sitename -Protocol $protocol -IPAddress $s[0] -HostHeader $s[2] -Port $s[1]
				}
			}
		}

		function EnsureFullWebsite([string]$sitename, [string]$path, [string]$dotNetVersion, [Array]$httpBindings, [Array]$httpsBindings)
		{
			EnsureWebsiteExists $sitename $path

			EnsureAppPoolExists $sitename
			EnsureAppPoolDotNetVersion $sitename $dotNetVersion

			EnsureWebsiteAppPool $sitename $sitename

			SyncBindings $sitename "http" $httpBindings
			SyncBindings $sitename "https" $httpsBindings
		}
		EnsureFullWebsite "#{new_resource.name}" "#{new_resource.path}" "#{new_resource.dotnet}" #{bindings} #{sslbindings}
		EOH
	end
end

action :delete do
	#FIXME Delete stuff here
end