local var_0_0 = {}
local var_0_1 = require("framework.scheduler")
local var_0_2 = 30

function var_0_0.run(arg_1_0)
	arg_1_0:scheduleErrorLogUpload_()
	arg_1_0:scheduleCrashLogUpload_()
end

function var_0_0.scheduleErrorLogUpload_(arg_2_0)
	var_0_1.performWithDelayGlobal(function()
		local var_3_0 = xyd.db.errorLog:getAll()

		if var_3_0 == nil or #var_3_0 <= 0 then
			return arg_2_0:scheduleErrorLogUpload_()
		end

		local var_3_1 = json.encode(var_3_0)

		xyd.Backend.get():log(0, var_3_1, function(arg_4_0)
			if arg_4_0 then
				xyd.db.errorLog:delete(var_3_0)
			end

			arg_2_0:scheduleErrorLogUpload_()
		end)
	end, var_0_2)
end

function var_0_0.scheduleCrashLogUpload_(arg_5_0)
	var_0_1.performWithDelayGlobal(function()
		local var_6_0 = xyd.listFiles(cc.FileUtils:getInstance():getSupportPath())
		local var_6_1 = {}

		for iter_6_0, iter_6_1 in ipairs(var_6_0) do
			if iter_6_1:match("%.dmp$") ~= nil then
				table.insert(var_6_1, iter_6_1)
			end
		end

		if #var_6_1 <= 0 then
			return arg_5_0:scheduleCrashLogUpload_()
		end

		local function var_6_2(arg_7_0)
			local var_7_0 = var_6_1[arg_7_0]
			local var_7_1 = var_7_0:match(".*/(.*)")

			xyd.Backend.get():log(1, {
				filename = var_7_1,
				path = var_7_0
			}, function(arg_8_0)
				if arg_8_0 then
					cc.FileUtils:getInstance():removeFile(var_7_0)

					if arg_7_0 < #var_6_1 then
						var_6_2(arg_7_0 + 1)
					else
						arg_5_0:scheduleCrashLogUpload_()
					end
				else
					arg_5_0:scheduleCrashLogUpload_()
				end
			end)
		end

		var_6_2(1)
	end, var_0_2)
end

return var_0_0
