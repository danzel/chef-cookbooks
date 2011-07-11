#Provider

action :create do

	powershell "create" do
		code <<-EOH
		#taskname: Name for the scheduled task, cannot contain any white space
		#command: Command for the scheduled task to execute, can have command line parameters
		#startTime: 24 hour format time to start this task. ex: "00:00", "23:10"
		#schedule: "Daily" or "xMinutes"
		#minutesRepeat: How often (in minute) to repeat the task, only used if schedule is "xMinutes"
		function EnsureScheduledTaskExists([string]$taskname, [string]$command, [string]$startTime, [string]$schedule, [int]$minutesRepeat)
		{
			$t = (schtasks.exe /query /tn $taskname /fo list /v 2>&1)
			$needsCreating = $false
			
			if ($t[0].GetType().Name -eq "ErrorRecord")
			{
				echo "Didn't find task"
				$needsCreating = $true
			}
			else #Task exists, check it is the same
			{
				#Task To Run:                          notepad.exe
				$commandEscaped = [regex]::escape($command)
				if (!($t | select-string "Task To Run:\s*$commandEscaped"))
				{
					echo "Command doesn't match"
					$needsCreating = $true
				}
				
				#Start Time:                           10:20:00 a.m.
				$formattedStartTime = (get-date $startTime).ToString("h:mm:ss tt")
				if (!($t | select-string "Start Time:\s*$formattedStartTime"))
				{
					echo "Start Time doesn't match"
					$needsCreating = $true
				}
				
				#Days:                                 Every 1 day(s)
				#Repeat: Every:                        1 Hour(s), 0 Minute(s)
				if ($schedule -eq "Daily")
				{
					if (!($t | select-string "Days:\s*Every 1 day\(s\)") -or
						!($t | select-string "Repeat: Every:\s*Disabled"))
					{
						echo "Not daily"
						$needsCreating = $true
					}
				}
				elseif ($schedule -eq "xMinutes")
				{
					$hours = [system.math]::floor($minutesRepeat / 60)
					$minutes = $minutesRepeat % 60
					$timeMatch = [regex]::escape("$hours Hour(s), $minutes Minute(s)")
					if (!($t | select-string "Days:\s*N/A") -or
						!($t | select-string "Repeat: Every:\s*$timeMatch"))
					{
						echo "Not xMinutes"
						$needsCreating = $true
					}
				}
				else
				{
					echo "ERROR: Cannot validate task: Not a known schedule type"
				}
			}
			
			if ($needsCreating)
			{
				echo "Creating"
				if ($schedule -eq "Daily")
				{
					schtasks.exe /create /f /np /tn $taskname /tr "$command" /st $startTime /sc Daily 
				}
				elseif ($schedule -eq "xMinutes")
				{
					schtasks.exe /create /f /np /tn $taskname /tr "$command" /st $startTime /sc Minute /mo $minutesRepeat
				}
				else
				{
					echo "ERROR: Cannot create task: Unknown schedule type"
				}
			}
		}
		
		EnsureScheduledTaskExists "#{new_resource.name}" "#{new_resource.command}" "#{new_resource.start}" "#{new_resource.repeat}" "#{new_resource.minutes}"
		
		EOH
	end
end