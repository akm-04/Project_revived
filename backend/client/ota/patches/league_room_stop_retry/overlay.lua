		else
			print("enter league error")
			if arg_10_1 and arg_10_1.error_code and arg_10_1.error_code ~= 35033 then
				arg_9_0:closeLeagueRoom()
				return
			end
			var_0_0.performWithDelayGlobal(function()
				arg_9_0:enterLeagueRoom()
			end, var_0_5)
		end