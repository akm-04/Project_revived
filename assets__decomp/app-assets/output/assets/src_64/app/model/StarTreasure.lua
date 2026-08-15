local var_0_0 = class("StarTreasure", import(".BaseModel"))

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.self_record = {}
	arg_1_0.world_record = {}
	arg_1_0.isFirstOpen = 1
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.loadInfo(arg_3_0, arg_3_1)
	xyd.Backend.get():request(xyd.mid.STAR_TREASURE_INFO, {}, function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK then
			arg_3_0.info = arg_4_1

			local var_4_0 = 1

			arg_3_0.hasHole = false
			arg_3_0.shadowMap = {}

			for iter_4_0 = 1, 5 do
				arg_3_0.shadowMap[iter_4_0] = {}

				for iter_4_1 = 1, 6 do
					arg_3_0.shadowMap[iter_4_0][iter_4_1] = arg_4_1.details.shadow_map[var_4_0]

					if arg_3_0.shadowMap[iter_4_0][iter_4_1] == -1 then
						arg_3_0.hasHole = true
					end

					var_4_0 = var_4_0 + 1
				end
			end

			arg_3_0.maxFloor = arg_4_1.details.max_floor
			arg_3_0.currentFloor = arg_4_1.details.current_floor
			arg_3_0.awardStatus = arg_4_1.details.award_status
		end

		arg_3_1(arg_4_0, arg_4_1)
	end)
end

function var_0_0.entreNextFloor(arg_5_0, arg_5_1, arg_5_2)
	xyd.Backend.get():request(xyd.mid.STAR_TREASURE_NEXT, arg_5_1, function(arg_6_0, arg_6_1)
		if arg_5_2 then
			local var_6_0 = 1

			arg_5_0.hasHole = false
			arg_5_0.shadowMap = {}

			for iter_6_0 = 1, 5 do
				arg_5_0.shadowMap[iter_6_0] = {}

				for iter_6_1 = 1, 6 do
					arg_5_0.shadowMap[iter_6_0][iter_6_1] = arg_6_1.shadow_map[var_6_0]

					if arg_5_0.shadowMap[iter_6_0][iter_6_1] == -1 then
						arg_5_0.hasHole = true
					end

					var_6_0 = var_6_0 + 1
				end
			end

			arg_5_0.maxFloor = arg_6_1.max_floor
			arg_5_0.currentFloor = arg_6_1.current_floor
			arg_5_0.awardStatus = arg_6_1.award_status

			arg_5_2(arg_6_0, arg_6_1)
		end
	end)
end

function var_0_0.reStart(arg_7_0, arg_7_1)
	xyd.Backend.get():request(xyd.mid.STAR_TREASURE_RESTART, {}, function(arg_8_0, arg_8_1)
		if arg_7_1 then
			local var_8_0 = 1

			arg_7_0.hasHole = false
			arg_7_0.shadowMap = {}

			for iter_8_0 = 1, 5 do
				arg_7_0.shadowMap[iter_8_0] = {}

				for iter_8_1 = 1, 6 do
					arg_7_0.shadowMap[iter_8_0][iter_8_1] = arg_8_1.shadow_map[var_8_0]

					if arg_7_0.shadowMap[iter_8_0][iter_8_1] == -1 then
						arg_7_0.hasHole = true
					end

					var_8_0 = var_8_0 + 1
				end
			end

			arg_7_0.maxFloor = arg_8_1.max_floor
			arg_7_0.currentFloor = arg_8_1.current_floor
			arg_7_0.awardStatus = arg_8_1.award_status

			arg_7_1(arg_8_0, arg_8_1)
		end
	end)
end

function var_0_0.buyGameTool(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = arg_9_1 or {}

	xyd.Backend.get():request(xyd.mid.STAR_TREASURE_BUY, var_9_0, function(arg_10_0, arg_10_1)
		if arg_9_2 then
			arg_9_2(arg_10_0, arg_10_1)
		end
	end)
end

function var_0_0.setShadowMap(arg_11_0, arg_11_1)
	arg_11_0.shadowMap = {}

	local var_11_0 = 1

	for iter_11_0 = 1, 5 do
		arg_11_0.shadowMap[iter_11_0] = {}

		for iter_11_1 = 1, 6 do
			arg_11_0.shadowMap[iter_11_0][iter_11_1] = arg_11_1[var_11_0]
			var_11_0 = var_11_0 + 1
		end
	end
end

function var_0_0.getAwardRecord(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = arg_12_1 or {}

	xyd.Backend.get():request(xyd.mid.STAR_TREASURE_RECORD, var_12_0, function(arg_13_0, arg_13_1)
		if arg_13_0 == xyd.error.OK then
			arg_12_0.self_record = {}

			for iter_13_0, iter_13_1 in pairs(arg_13_1.self_record) do
				if #iter_13_1.awards ~= 0 then
					table.insert(arg_12_0.self_record, iter_13_1)
				end
			end

			table.sort(arg_12_0.self_record, function(arg_14_0, arg_14_1)
				return arg_14_0.floor < arg_14_1.floor
			end)

			arg_12_0.world_record = arg_13_1.world_record
		end

		if arg_12_2 then
			arg_12_2(arg_13_0, arg_13_1)
		end
	end)
end

function var_0_0.getSelfRecord(arg_15_0)
	return arg_15_0.self_record
end

function var_0_0.getWorldRecord(arg_16_0)
	return arg_16_0.world_record
end

function var_0_0.getFirstOpenFlag(arg_17_0)
	return arg_17_0.isFirstOpen
end

function var_0_0.setFirstOpenFlag(arg_18_0, arg_18_1)
	if not arg_18_1 then
		return
	end

	arg_18_0.isFirstOpen = arg_18_1
end

function var_0_0.getInfo(arg_19_0)
	return arg_19_0.info
end

function var_0_0.setAwardStatus(arg_20_0, arg_20_1)
	arg_20_0.awardStatus = {}

	local var_20_0 = xyd.tables.starTreasureExplore:specialItem(arg_20_0.currentFloor)

	for iter_20_0, iter_20_1 in pairs(var_20_0) do
		arg_20_0.awardStatus[tostring(iter_20_1)] = arg_20_1[iter_20_0]
	end
end

return var_0_0
