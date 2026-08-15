local var_0_0 = class("Incubus", import(".BaseModel"))

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.times = 0
	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.incubusEnergy = xyd.tables.misc.incubusEnergy
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.loadIncubusInfos(arg_3_0, arg_3_1)
	xyd.Backend.get():request(xyd.mid.INCUBUS_LOAD_INFO, nil, function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK then
			arg_3_0.times = arg_4_1.left_times
			arg_3_0.buyPre = arg_4_1.buy_times
			arg_3_0.infos = arg_4_1.fight_counts
		end

		if arg_3_1 then
			arg_3_1(arg_4_0)
		end
	end)
end

function var_0_0.buyTimes(arg_5_0, arg_5_1)
	xyd.Backend.get():request(xyd.mid.INCUBUS_BUY_TIMES, nil, function(arg_6_0, arg_6_1)
		if arg_6_0 == xyd.error.OK then
			arg_5_0.times = arg_6_1.left_times
			arg_5_0.buyPre = arg_6_1.buy_times
		end

		if arg_5_1 then
			arg_5_1(arg_6_0)
		end
	end)
end

function var_0_0.sweep(arg_7_0, arg_7_1, arg_7_2)
	xyd.Backend.get():request(xyd.mid.INCUBUS_SWEEP, arg_7_1, function(arg_8_0, arg_8_1)
		if arg_8_0 == xyd.error.OK then
			local var_8_0 = arg_7_0:getInfoById(arg_7_1.incubus_id)

			var_8_0.count = var_8_0.count + 1
			arg_7_0.times = arg_7_0.times - 1

			local var_8_1 = {
				{}
			}
			local var_8_2 = {}
			local var_8_3 = arg_7_0.player:getBackpack()

			for iter_8_0, iter_8_1 in ipairs(arg_8_1.items) do
				for iter_8_2, iter_8_3 in pairs(iter_8_1) do
					for iter_8_4, iter_8_5 in ipairs(iter_8_3) do
						if var_8_2[iter_8_5.item_id] then
							var_8_2[iter_8_5.item_id] = var_8_2[iter_8_5.item_id] + iter_8_5.item_num
						else
							var_8_2[iter_8_5.item_id] = iter_8_5.item_num
						end

						var_8_3:addItemsByID(tonumber(iter_8_5.item_id), tonumber(iter_8_5.item_num))
					end
				end
			end

			for iter_8_6, iter_8_7 in pairs(var_8_2) do
				table.insert(var_8_1[1], {
					item_id = iter_8_6,
					item_num = iter_8_7
				})
			end

			if arg_7_2 then
				arg_7_2(var_8_1)
			end
		end
	end)
end

function var_0_0.getInfoById(arg_9_0, arg_9_1)
	for iter_9_0, iter_9_1 in ipairs(arg_9_0.infos) do
		if iter_9_1.id == arg_9_1 then
			return iter_9_1
		end
	end
end

return var_0_0
