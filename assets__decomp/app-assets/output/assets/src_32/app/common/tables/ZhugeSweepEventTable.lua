local var_0_0 = class("ZhugeSweepEventTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.msg_ = {}
	arg_1_0.type_ = {}
	arg_1_0.rate_ = {}
	arg_1_0.isObtainItem_ = {}
	arg_1_0.events_ = {}
	arg_1_0.events_[xyd.ZhugeSweepEventType.START] = {}
	arg_1_0.events_[xyd.ZhugeSweepEventType.NORMAL] = {}
	arg_1_0.events_[xyd.ZhugeSweepEventType.DEATH] = {}
	arg_1_0.events_[xyd.ZhugeSweepEventType.END] = {}

	import("app.common.tables.TableParser").parse("zhuge_sweep_event.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.msg_[var_2_0] = xyd.split(arg_2_0.msg, "|")
		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.rate_[var_2_0] = tonumber(arg_2_0.rate)
		arg_1_0.isObtainItem_[var_2_0] = tonumber(arg_2_0.is_obtain_item)

		table.insert(arg_1_0.events_[tonumber(arg_2_0.type)], var_2_0)
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.msg(arg_4_0, arg_4_1)
	return arg_4_0.msg_[arg_4_1] or {}
end

function var_0_0.type(arg_5_0, arg_5_1)
	return arg_5_0.type_[arg_5_1] or 0
end

function var_0_0.rate(arg_6_0, arg_6_1)
	return arg_6_0.rate_[arg_6_1] or 0
end

function var_0_0.isObtainItem(arg_7_0, arg_7_1)
	return arg_7_0.isObtainItem_[arg_7_1] or 0
end

function var_0_0.getSingleEvent(arg_8_0, arg_8_1)
	local var_8_0 = arg_8_0.events_[arg_8_1] or {}
	local var_8_1 = math.random(1, 10000)
	local var_8_2 = 0

	for iter_8_0 = 1, #var_8_0 do
		local var_8_3 = var_8_0[iter_8_0]

		var_8_2 = var_8_2 + arg_8_0:rate(var_8_3) * 100

		if var_8_1 < var_8_2 then
			return var_8_3
		end
	end

	return var_8_0[#var_8_0] or 0
end

function var_0_0.getSweepEvents(arg_9_0)
	local var_9_0 = {}
	local var_9_1 = false
	local var_9_2 = 100

	while not var_9_1 do
		var_9_2 = var_9_2 - 1

		if var_9_2 == 0 then
			local var_9_3 = arg_9_0:getObtainEvent()

			table.insert(var_9_0, var_9_3)

			var_9_1 = true

			break
		end

		local var_9_4 = arg_9_0:getSingleEvent(xyd.ZhugeSweepEventType.NORMAL)

		table.insert(var_9_0, var_9_4)

		if arg_9_0:isObtainItem(var_9_4) == 1 then
			var_9_1 = true

			break
		end
	end

	return var_9_0
end

function var_0_0.getObtainEvent(arg_10_0)
	local var_10_0 = arg_10_0:ids()

	for iter_10_0 = 1, #var_10_0 do
		if arg_10_0:isObtainItem(var_10_0[iter_10_0]) == 1 then
			return var_10_0[iter_10_0]
		end
	end

	return #var_10_0
end

return var_0_0
