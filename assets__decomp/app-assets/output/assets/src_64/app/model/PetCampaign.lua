local var_0_0 = class("PetCampaign", import(".BaseModel"))
local var_0_1 = 16
local var_0_2 = xyd.tables.petCampaign
local var_0_3 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.begin_sweep_time = 0
	arg_1_0.challenge_times = 0
	arg_1_0.mission_sweep_times = 0
	arg_1_0.super = {}
	arg_1_0.normal = {}
	arg_1_0.testFormation = {}
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.getCampaignInfo(arg_3_0, arg_3_1)
	xyd.Backend.get():request(xyd.mid.PET_CAMPAIGN_LOAD_INFO, {}, function(arg_4_0, arg_4_1, arg_4_2)
		if arg_4_0 == xyd.error.OK then
			arg_3_0.super = arg_4_1.super
			arg_3_0.normal = arg_4_1.normal

			if arg_4_1.is_super_open and arg_4_1.is_super_open == 1 then
				arg_3_0.openSuper = true
			end

			if not arg_3_0.state then
				if arg_4_1.super and arg_4_1.super.state and arg_4_1.super.state == xyd.PetCampaignFloorType.SUPER then
					arg_3_0.state = xyd.PetCampaignFloorType.SUPER
				else
					arg_3_0.state = xyd.PetCampaignFloorType.NORMAL
				end
			end

			if arg_4_1.super and arg_3_0.state == xyd.PetCampaignFloorType.SUPER then
				arg_3_0:initData(arg_3_0.super)

				if not arg_3_0.superFloor then
					arg_3_0.superFloor = arg_3_0.super.now_floor
				end
			elseif arg_4_1.normal and arg_3_0.state == xyd.PetCampaignFloorType.NORMAL then
				arg_3_0:initData(arg_3_0.normal)
			end

			if arg_4_1.super then
				if arg_4_1.super.awards then
					xyd.WindowManager.get():openWindow("alert_award", {
						awards = arg_4_1.super.awards,
						name = var_0_3:translation("SKYCITY_HARD_OPEN_TIP_1")
					})

					for iter_4_0, iter_4_1 in ipairs(arg_4_1.super.awards) do
						arg_3_0.selfPlayer:getBackpack():addItemsByID(tonumber(iter_4_1.table_id), tonumber(iter_4_1.item_num))
					end
				end

				if arg_4_1.super.test_formation then
					for iter_4_2, iter_4_3 in pairs(arg_4_1.super.test_formation) do
						local var_4_0 = xyd.split(iter_4_3, "@")

						arg_3_0.testFormation[tonumber(iter_4_2)] = {}
						arg_3_0.testFormation[tonumber(iter_4_2)].heros = xyd.splitToNumber(var_4_0[1], "|") or {}

						if var_4_0[2] then
							arg_3_0.testFormation[tonumber(iter_4_2)].pet = tonumber(var_4_0[2])
						end
					end
				end
			end
		end

		if arg_3_1 then
			arg_3_1(arg_4_0, arg_4_1)
		end
	end)
end

function var_0_0.toInnerArr(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = {}

	if arg_5_2 == xyd.PetCampaignFloorType.NORMAL then
		var_5_0 = arg_5_0.normal
	else
		var_5_0 = arg_5_0.super
	end

	local function var_5_1(arg_6_0)
		if arg_5_1[arg_6_0] then
			var_5_0[arg_6_0] = arg_5_1[arg_6_0]
		end
	end

	var_5_1("now_floor")
	var_5_1("max_floor")
	var_5_1("begin_sweep_time")
	var_5_1("is_can_sweep")
	var_5_1("mission_sweep_times")
	var_5_1("can_sweep_times")
	var_5_1("challenge_times")
end

function var_0_0.initData(arg_7_0, arg_7_1)
	local var_7_0 = arg_7_1

	if arg_7_0.state == xyd.PetCampaignFloorType.NORMAL then
		if var_7_0 == nil then
			var_7_0 = arg_7_0.normal
		end

		if tonumber(var_7_0.now_floor) < var_0_2:getMaxLimitFloor(arg_7_0.state) then
			arg_7_0.now_floor = tonumber(var_7_0.now_floor) + 1
		else
			arg_7_0.now_floor = tonumber(var_7_0.now_floor)
		end

		arg_7_0.real_now_floor = var_7_0.now_floor + 1
		arg_7_0.max_floor = tonumber(var_7_0.max_floor) + 1
		arg_7_0.begin_sweep_time = tonumber(var_7_0.begin_sweep_time)
		arg_7_0.is_can_sweep = tonumber(var_7_0.is_can_sweep)
		arg_7_0.mission_sweep_times = tonumber(var_7_0.mission_sweep_times)
		arg_7_0.can_sweep_times = tonumber(var_7_0.can_sweep_times) or 0
		arg_7_0.challenge_times = tonumber(var_7_0.challenge_times) or 0
		arg_7_0.last_now_floor = arg_7_0.now_floor
	else
		if var_7_0 == nil then
			var_7_0 = arg_7_0.super
		end

		if tonumber(var_7_0.now_floor) < var_0_2:getMaxLimitFloor(arg_7_0.state) then
			arg_7_0.now_floor = tonumber(var_7_0.now_floor) + 1
		else
			arg_7_0.now_floor = tonumber(var_7_0.now_floor)
		end

		arg_7_0.real_now_floor = var_7_0.now_floor + 1
		arg_7_0.max_floor = tonumber(var_7_0.max_floor) + 1
		arg_7_0.mission_sweep_times = tonumber(var_7_0.mission_sweep_times)
		arg_7_0.last_now_floor = arg_7_0.now_floor

		if var_7_0.buy_info then
			arg_7_0.superBuyInfo = var_7_0.buy_info
		end

		if var_7_0.sweep_info then
			arg_7_0.superSweepInfo = var_7_0.sweep_info
		end
	end
end

function var_0_0.onLoadPetCampaignAwards(arg_8_0, arg_8_1)
	local var_8_0 = arg_8_1.params

	arg_8_0.max_floor = tonumber(var_8_0.max_floor) + 1

	if tonumber(var_8_0.now_floor) < var_0_2:getMaxLimitFloor(xyd.PetCampaignFloorType.NORMAL) then
		arg_8_0.now_floor = tonumber(var_8_0.now_floor) + 1
	else
		arg_8_0.now_floor = tonumber(var_8_0.now_floor)
	end

	arg_8_0.real_now_floor = var_8_0.now_floor + 1
	arg_8_0.begin_sweep_time = tonumber(var_8_0.begin_sweep_time)
	arg_8_0.is_can_sweep = tonumber(var_8_0.is_can_sweep)
	arg_8_0.can_sweep_times = tonumber(var_8_0.can_sweep_times) or 0
	arg_8_0.mission_sweep_times = tonumber(var_8_0.mission_sweep_times) or 0
	arg_8_0.challenge_times = tonumber(var_8_0.challenge_times) or 0
	arg_8_0.last_now_floor = arg_8_0.now_floor
	arg_8_0.normal = var_8_0

	if var_8_0 and var_8_0.awards and next(var_8_0.awards) then
		arg_8_0.awards = var_8_0.awards
		arg_8_0.has_red = true
		arg_8_0.begin_sweep_time = 1
	end
end

function var_0_0.battleResult(arg_9_0, arg_9_1, arg_9_2)
	if arg_9_2.is_win == false and arg_9_0.state == xyd.PetCampaignFloorType.NORMAL then
		arg_9_1(nil, {})

		return
	end

	xyd.Backend.get():request(xyd.mid.PET_CAMPAIGN_BATTLE_RESULT, arg_9_2, function(arg_10_0, arg_10_1, arg_10_2)
		if arg_10_0 == xyd.error.OK then
			if arg_9_2.is_win == true then
				if arg_9_0.state == xyd.PetCampaignFloorType.NORMAL then
					arg_9_0.normal.now_floor = arg_10_1.now_floor
					arg_9_0.normal.max_floor = arg_10_1.max_floor
				else
					arg_9_0.super.max_floor = arg_10_1.max_floor
					arg_9_0.super.now_floor = arg_10_1.now_floor
				end

				if arg_10_1.info then
					if arg_10_1.info.normal and arg_9_0.state == xyd.PetCampaignFloorType.NORMAL then
						arg_9_0:initData(arg_10_1.info.normal)
					end

					if arg_10_1.info.super and arg_9_0.state == xyd.PetCampaignFloorType.SUPER then
						arg_9_0:initData(arg_10_1.info.super)
					end

					arg_9_0.super = arg_10_1.info.super
					arg_9_0.normal = arg_10_1.info.normal

					if arg_9_0.super and arg_9_0.super.awards then
						xyd.WindowManager.get():openWindow("alert_award", {
							awards = arg_9_0.super.awards,
							name = var_0_3:translation("SKYCITY_HARD_OPEN_TIP_1")
						})

						for iter_10_0, iter_10_1 in ipairs(arg_9_0.super.awards) do
							arg_9_0.selfPlayer:getBackpack():addItemsByID(tonumber(iter_10_1.table_id), tonumber(iter_10_1.item_num))
						end
					end

					if arg_10_1.info.is_super_open and arg_10_1.info.is_super_open == 1 then
						arg_9_0.openSuper = true
					end
				end

				if arg_9_0.now_floor < var_0_2:getMaxLimitFloor(arg_9_0.state) then
					arg_9_0.now_floor = arg_10_1.now_floor + 1
				else
					arg_9_0.now_floor = arg_10_1.now_floor
				end

				if arg_9_0.state == xyd.PetCampaignFloorType.SUPER then
					arg_9_0.lastSuperMaxFloor = arg_9_0.max_floor
				end

				arg_9_0.real_now_floor = arg_10_1.now_floor + 1
				arg_9_0.max_floor = arg_10_1.max_floor + 1
			elseif arg_9_0.state == xyd.PetCampaignFloorType.SUPER then
				arg_9_0.lastSuperMaxFloor = arg_9_0.max_floor
			end
		end

		arg_9_1(arg_10_0, arg_10_1)
	end)
end

function var_0_0.awakeSweep(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = arg_11_2 or {
		floor = 50
	}

	xyd.Backend.get():request(xyd.mid.PET_CAMPAIGN_AWAKE_SWEEP, var_11_0, function(arg_12_0, arg_12_1)
		if arg_12_0 == xyd.error.OK then
			local var_12_0 = arg_12_1.info

			if not var_12_0 or not next(var_12_0) then
				return
			end

			arg_11_0:toInnerArr(var_12_0.normal, xyd.PetCampaignFloorType.NORMAL)

			arg_11_0.mission_sweep_times = var_12_0.normal.mission_sweep_times

			arg_11_1(arg_12_0, arg_12_1)
		end
	end)
end

function var_0_0.finishSweep(arg_13_0, arg_13_1, arg_13_2)
	xyd.Backend.get():request(xyd.mid.PET_CAMPAIGN_SWEEP, arg_13_2, function(arg_14_0, arg_14_1, arg_14_2)
		if arg_14_0 == xyd.error.OK then
			arg_13_0:toInnerArr(arg_14_1, xyd.PetCampaignFloorType.NORMAL)

			if arg_13_0.state == xyd.PetCampaignFloorType.NORMAL then
				if tonumber(arg_14_1.now_floor) < var_0_2:getMaxLimitFloor(xyd.PetCampaignFloorType.NORMAL) then
					arg_13_0.now_floor = tonumber(arg_14_1.now_floor) + 1
				else
					arg_13_0.now_floor = tonumber(arg_14_1.now_floor)
				end

				arg_13_0.real_now_floor = arg_14_1.now_floor + 1
				arg_13_0.begin_sweep_time = tonumber(arg_14_1.begin_sweep_time)
				arg_13_0.can_sweep_times = tonumber(arg_14_1.can_sweep_times) or 0
				arg_13_0.last_now_floor = arg_13_0.now_floor
			end
		end

		arg_13_1(arg_14_0, arg_14_1)
	end)
end

function var_0_0.restart(arg_15_0, arg_15_1)
	xyd.Backend.get():request(xyd.mid.PET_CAMPAIGN_RESTART, {}, function(arg_16_0, arg_16_1, arg_16_2)
		if arg_16_0 == xyd.error.OK then
			arg_15_0:toInnerArr(arg_16_1, xyd.PetCampaignFloorType.NORMAL)

			arg_15_0.begin_sweep_time = tonumber(arg_16_1.begin_sweep_time)
			arg_15_0.now_floor = tonumber(arg_16_1.now_floor) + 1
			arg_15_0.real_now_floor = tonumber(arg_16_1.now_floor) + 1
			arg_15_0.last_now_floor = arg_15_0.now_floor
			arg_15_0.challenge_times = tonumber(arg_16_1.challenge_times) or 0
			arg_15_0.can_sweep_times = tonumber(arg_16_1.can_sweep_times) or 0
		end

		arg_15_1(arg_16_0, arg_16_1)
	end)
end

function var_0_0.beginSweep(arg_17_0, arg_17_1)
	xyd.Backend.get():request(xyd.mid.PET_CAMPAIGN_RECORD_SWEEP_TIME, {}, function(arg_18_0, arg_18_1, arg_18_2)
		if arg_18_0 == xyd.error.OK then
			arg_17_0:toInnerArr(arg_18_1, xyd.PetCampaignFloorType.NORMAL)

			arg_17_0.begin_sweep_time = tonumber(arg_18_1.begin_sweep_time)
			arg_17_0.can_sweep_times = tonumber(arg_18_1.can_sweep_times) or 0
		end

		if arg_17_1 then
			arg_17_1(arg_18_0, arg_18_1)
		end
	end)
end

function var_0_0.sweepSuper(arg_19_0, arg_19_1, arg_19_2)
	local var_19_0 = arg_19_1 or {}

	xyd.Backend.get():request(xyd.mid.PET_CAMPAIGN_SWEEP_SUPER, var_19_0, function(arg_20_0, arg_20_1)
		if arg_20_0 == xyd.error.OK then
			arg_19_0.selfPlayer:getBackpack():removeItem({
				itemNum = 1,
				itemID = xyd.tables.misc.skyCitySuperPaper
			})

			arg_19_0.superSweepInfo = arg_20_1.sweep_info
		end

		if arg_19_2 then
			arg_19_2(arg_20_0, arg_20_1)
		end
	end)
end

function var_0_0.buySuper(arg_21_0, arg_21_1, arg_21_2)
	xyd.Backend.get():request(xyd.mid.PET_CAMPAIGN_BUY_SUPER, arg_21_1, function(arg_22_0, arg_22_1)
		if arg_22_0 == xyd.error.OK then
			arg_21_0.superSweepInfo = arg_22_1.sweep_info
			arg_21_0.superBuyInfo = arg_22_1.buy_info
		end

		if arg_21_2 then
			arg_21_2(arg_22_0, arg_22_1)
		end
	end)
end

function var_0_0.saveSuperFloor(arg_23_0, arg_23_1)
	xyd.Backend.get():request(xyd.mid.PET_CAMPAIGN_SAVE_SUPER, arg_23_1, function(arg_24_0, arg_24_1)
		if arg_24_0 == xyd.error.OK then
			arg_23_0.state = arg_23_1.state
			arg_23_0.super.now_floor = arg_23_1.floor + 1

			if arg_23_0.state == xyd.PetCampaignFloorType.SUPER then
				arg_23_0.now_floor = arg_23_1.floor + 1
			end
		end
	end)
end

function var_0_0.setStateBaseOnCampaignID(arg_25_0, arg_25_1)
	if xyd.tables.campaign:campaignType(arg_25_1) == xyd.CampaignType.PET and arg_25_0.openSuper and xyd.tables.campaign:getFloorType(arg_25_1) == 2 then
		arg_25_0.state = xyd.PetCampaignFloorType.SUPER
		arg_25_0.now_floor = xyd.tables.campaign:getFloor(arg_25_1)
	end

	arg_25_0:initData()
end

return var_0_0
