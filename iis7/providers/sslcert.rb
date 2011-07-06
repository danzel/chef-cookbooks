action :set do
	#http://stackoverflow.com/questions/1924217/powershell-load-webadministration-in-ps1-script-on-both-iis-7-and-iis-7-5
	#http://learn.iis.net/page.aspx/491/powershell-snap-in-configuring-ssl-with-the-iis-powershell-snap-in/

	powershell "setsslcert" do
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
		
		function EnsureSSLCert([string]$ip, [string]$port, [string]$certregex)
		{
			$thumbprint = (ls cert:\\LocalMachine\\MY\\ | where {$_.Subject -like $certregex}).Thumbprint
			if ((@(ls IIS:\\SslBindings | where {$_.IPAddress -eq $ip -and $_.Port -eq $port -and $_.ThumbPrint -eq $thumbprint })).Count -eq 0)
			{
				echo "Creating SSL Binding"
				ls cert:\\LocalMachine\\MY\\ | where {$_.Subject -like $certregex} | new-item IIS:\\SslBindings\\$ip!$port -force
			}
		}

		EnsureSSLCert "#{new_resource.ip}" #{new_resource.port} "#{new_resource.certregex}"
		EOH
	end
end