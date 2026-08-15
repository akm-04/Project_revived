local var_0_0 = require(cc.PACKAGE_NAME .. ".scheduler")
local var_0_1 = {
	new = function()
		local var_1_0 = {}

		cc(var_1_0):addComponent("components.behavior.EventProtocol"):exportMethods()

		local var_1_1
		local var_1_2 = {}
		local var_1_3 = 0

		local function var_1_4(arg_2_0)
			var_1_3 = var_1_3 + arg_2_0

			for iter_2_0, iter_2_1 in pairs(var_1_2) do
				iter_2_1.countdown = iter_2_1.countdown - arg_2_0
				iter_2_1.nextstep = iter_2_1.nextstep - arg_2_0

				if iter_2_1.countdown <= 0 then
					print(string.format("[finish] %s", iter_2_0))
					var_1_0:dispatchEvent({
						countdown = 0,
						name = iter_2_0
					})
					var_1_0:removeCountdown(iter_2_0)
				elseif iter_2_1.nextstep <= 0 then
					print(string.format("[step] %s", iter_2_0))

					iter_2_1.nextstep = iter_2_1.nextstep + iter_2_1.interval

					var_1_0:dispatchEvent({
						name = iter_2_0,
						countdown = iter_2_1.countdown
					})
				end
			end
		end

		function var_1_0.addCountdown(arg_3_0, arg_3_1, arg_3_2, arg_3_3)
			arg_3_1 = tostring(arg_3_1)

			assert(not var_1_2[arg_3_1], "eventName '" .. arg_3_1 .. "' exists")
			assert(type(arg_3_2) == "number" and arg_3_2 >= 30, "invalid countdown")

			if type(arg_3_3) ~= "number" then
				arg_3_3 = 30
			else
				arg_3_3 = math.floor(arg_3_3)

				if arg_3_3 < 2 then
					arg_3_3 = 2
				elseif arg_3_3 > 120 then
					arg_3_3 = 120
				end
			end

			var_1_2[arg_3_1] = {
				countdown = arg_3_2,
				interval = arg_3_3,
				nextstep = arg_3_3
			}
		end

		function var_1_0.removeCountdown(arg_4_0, arg_4_1)
			arg_4_1 = tostring(arg_4_1)
			var_1_2[arg_4_1] = nil

			arg_4_0:removeEventListenersByEvent(arg_4_1)
		end

		function var_1_0.start(arg_5_0)
			if not var_1_1 then
				var_1_1 = var_0_0.scheduleGlobal(var_1_4, 1, false)
			end
		end

		function var_1_0.stop(arg_6_0)
			if var_1_1 then
				var_0_0.unscheduleGlobal(var_1_1)

				var_1_1 = nil
			end
		end

		return var_1_0
	end
}

cc = cc or {}
cc.utils = cc.utils or {}
cc.utils.Timer = var_0_1

return var_0_1
