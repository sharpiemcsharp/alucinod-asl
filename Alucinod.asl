state("Alucinod-Win32-Shipping")
{
	float InGameTimer  : 0x02328180, 0x338, 0xE4, 0x148, 0x254, 0x10C, 0x1C;
	int   CheckPointId : 0x02328180, 0x338, 0xE4, 0x148, 0x254, 0x10C, 0x24;
}

startup
{
	settings.Add("WithoutLoadTime", true, "Subtract initial load from IGT");
	settings.Add("Debug", false, "Debug logging");
}

init
{
	refreshRate = 30;
	vars.LoadTime = 0;
	vars.CheckPointsConst = new int[] { 0,19,17,18,21,20,44,47,43,45,46,13,12,38,37,27,25,26,15,16,14,35,34,33,9,6,7,8,39,2,10,11,31,30,32,29,28,4,56,5,41,40,42,3,55,51,54,49,50,53,52,48,0,22,24,23 };
	vars.CheckPoints = new List<int>();
	vars.EndGame = 0;
}

update
{
	if (current.CheckPointId == 19 && old.CheckPointId == 0)
	{
		vars.LoadTime = current.InGameTimer;
		print("LOADTIME: " + TimeSpan.FromSeconds(vars.LoadTime).ToString());
	}
}

start
{
	if (current.CheckPointId == 0 && old.CheckPointId != 0)
	{
		vars.CheckPoints.Clear();
		vars.CheckPoints.AddRange(vars.CheckPointsConst);
		if (settings["Debug"])
		{
			print("START: " + String.Join(",", vars.CheckPoints));
		}
		vars.LoadTime = 0;
		vars.EndGame = 0;
		return true;
	}
}

reset
{
	if (current.CheckPointId == 0 && old.CheckPointId != 0 && (current.InGameTimer < old.InGameTimer || old.InGameTimer == 0))
	{
		if (settings["Debug"])
		{
			print("RESET");
		}
		return true;
	}
}

split
{
	if (vars.CheckPoints.Count==0)
	{
		return false;
	}

	if (current.CheckPointId != vars.CheckPoints[0] && vars.CheckPoints.Contains(current.CheckPointId))
	{
		vars.CheckPoints.RemoveAt(0);
		if (settings["Debug"])
		{
			print("SPLIT [" + TimeSpan.FromSeconds(current.InGameTimer).ToString() + "] [" + TimeSpan.FromSeconds(current.InGameTimer - vars.LoadTime) + "] " + old.CheckPointId.ToString() + " -> " + current.CheckPointId.ToString());
			print("SPLIT: First element now: " + vars.CheckPoints[0].ToString());
		}
		return true;
	}

	// The end
	if (current.CheckPointId == 23)
	{
		// CheckPointId doesn't change when timer stops.
		// We'll use the IGT not changing for one second (30 livesplit ticks - see refreshRate above), to avoid race condition with IGT not
		// updating between ticks even though run isn't finished.
		if(current.InGameTimer == old.InGameTimer)
		{
			vars.EndGame++;
			if(vars.EndGame>=30)
			{
				if (settings["Debug"])
				{
					print("SPLIT: Game End [" + TimeSpan.FromSeconds(current.InGameTimer).ToString() + "] [" + TimeSpan.FromSeconds(current.InGameTimer - vars.LoadTime) + "] " + old.CheckPointId.ToString() + " -> " + current.CheckPointId.ToString());
				}
				return true;
			}
		}
		else
		{
			vars.EndGame = 0;
		}
	}
}

gameTime
{
	if (settings["WithoutLoadTime"])
	{
		// Loading has checkpoint id 0, which is also the id for the outdoor "bridge" section near the end. We use the timer to distinguish.
		// This assumes no-one will get to that outdoor section in under three minutes :-)
		if ( (current.CheckPointId == 0 && current.InGameTimer < 180.0) || (current.CheckPointId == 19 && current.InGameTimer == old.InGameTimer) )
		{
			// Loading ...
			return TimeSpan.FromSeconds(current.InGameTimer * - 1.0);
		}
		else
		{
			return TimeSpan.FromSeconds(current.InGameTimer - vars.LoadTime);
		}
	}
	else
	{
		return TimeSpan.FromSeconds(current.InGameTimer);
	}
}

isLoading
{
	return true;
}