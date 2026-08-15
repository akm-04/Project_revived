local var_0_0 = class("SilencePriorityTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.prio_ = {}
	arg_1_0.match_ = {}

	import("app.common.tables.TableParser").parse("silence_priority.lua", function(arg_2_0)
		local var_2_0 = xyd.split(arg_2_0.version, "|")
		local var_2_1

		for iter_2_0, iter_2_1 in ipairs(var_2_0 or {}) do
			if iter_2_1 == "all" or iter_2_1 == "en" then
				var_2_1 = true

				break
			end
		end

		if not var_2_1 then
			return
		end

		local var_2_2 = arg_2_0.path
		local var_2_3 = tonumber(arg_2_0.type)

		if var_2_3 == 1 then
			arg_1_0.prio_[var_2_2] = tonumber(arg_2_0.priority)
		elseif var_2_3 == 2 then
			arg_1_0.prio_[var_2_2 .. ".atlas"] = tonumber(arg_2_0.priority)
			arg_1_0.prio_[var_2_2 .. ".json"] = tonumber(arg_2_0.priority)
			arg_1_0.prio_[var_2_2 .. ".png"] = tonumber(arg_2_0.priority)
		elseif var_2_3 == 3 then
			for iter_2_2 = 1, 9 do
				arg_1_0.prio_[var_2_2 .. iter_2_2 .. ".mp3"] = tonumber(arg_2_0.priority)
			end
		elseif var_2_3 == 100 then
			table.insert(arg_1_0.match_, {
				path = var_2_2,
				prio = tonumber(arg_2_0.priority)
			})
		end
	end)
end

function var_0_0.priority(arg_3_0, arg_3_1)
	for iter_3_0, iter_3_1 in ipairs(arg_3_0.match_) do
		if arg_3_1:match(iter_3_1.path) then
			return iter_3_1.prio
		end
	end

	return arg_3_0.prio_[arg_3_1] or 0
end

return var_0_0
