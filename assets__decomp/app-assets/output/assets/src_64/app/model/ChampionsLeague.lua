local var_0_0 = class("ChampionsLeague", import(".BaseModel"))
local var_0_1 = xyd.tables.misc
local var_0_2 = xyd.tables.championsLeagueAwardInfo

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activities = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.isChangeGroup = false
	arg_1_0.stage = 1
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.loadInfo(arg_3_0, arg_3_1)
	xyd.Backend.get():request(xyd.mid.CHAMPIONS_LEAGUE_GET_INFO, nil, function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK then
			arg_3_0.stage = arg_4_1.stage

			if arg_4_1.rank_info and arg_4_1.rank_info.group_check == 1 then
				arg_3_0.isChangeGroup = true
			else
				arg_3_0.isChangeGroup = false
			end

			if arg_4_1.base_info then
				arg_3_0.seasonCount = arg_4_1.base_info.season_count
			end
		end

		if arg_3_1 then
			arg_3_1(arg_4_0, arg_4_1)
		end
	end, nil, nil, false)
end

function var_0_0.getStage(arg_5_0)
	return arg_5_0.stage
end

function var_0_0.getEnemy(arg_6_0, arg_6_1, arg_6_2)
	xyd.Backend.get():request(xyd.mid.CHAMPIONS_LEAGUE_GET_ENEMY, arg_6_1, function(arg_7_0, arg_7_1)
		if arg_7_0 == xyd.error.OK then
			-- block empty
		end

		if arg_6_2 then
			arg_6_2(arg_7_0, arg_7_1)
		end
	end, nil, nil, false)
end

function var_0_0.startFight(arg_8_0, arg_8_1, arg_8_2)
	xyd.Backend.get():request(xyd.mid.CHAMPIONS_LEAGUE_GET_INFO, arg_8_1, function(arg_9_0, arg_9_1)
		if arg_9_0 == xyd.error.OK then
			-- block empty
		end

		if arg_8_2 then
			arg_8_2(arg_9_0, arg_9_1)
		end
	end, nil, nil, false)
end

function var_0_0.getRecord(arg_10_0, arg_10_1)
	xyd.Backend.get():request(xyd.mid.CHAMPIONS_GET_FIGHT_RECORD, nil, function(arg_11_0, arg_11_1)
		if arg_11_0 == xyd.error.OK then
			-- block empty
		end

		if arg_10_1 then
			arg_10_1(arg_11_0, arg_11_1)
		end
	end, nil, nil, false)
end

function var_0_0.getDailyAward(arg_12_0, arg_12_1)
	xyd.Backend.get():request(xyd.mid.CHAMPIONS_GET_DAILY_AWARD, nil, function(arg_13_0, arg_13_1)
		if arg_13_0 == xyd.error.OK then
			-- block empty
		end

		if arg_12_1 then
			arg_12_1(arg_13_0, arg_13_1)
		end
	end, nil, nil, false)
end

function var_0_0.setDefense(arg_14_0, arg_14_1, arg_14_2)
	local var_14_0 = {}

	for iter_14_0 = 1, #arg_14_1.defenseHeroes do
		if #var_14_0 >= 5 then
			break
		elseif arg_14_1.defenseHeroes[iter_14_0] then
			table.insert(var_14_0, arg_14_1.defenseHeroes[iter_14_0]:getHeroID())
		end
	end

	local var_14_1 = {
		formation = tostring(var_14_0[1])
	}

	for iter_14_1 = 2, #var_14_0 do
		var_14_1.formation = var_14_1.formation .. "|" .. tostring(var_14_0[iter_14_1])
	end

	if arg_14_1.pet_id then
		var_14_1.pet_id = arg_14_1.pet_id
	end

	xyd.Backend.get():request(xyd.mid.CHAMPIONS_SET_DEFENSE_INFO, var_14_1, function(arg_15_0, arg_15_1)
		if arg_15_0 == xyd.error.OK then
			-- block empty
		end

		if arg_14_2 then
			arg_14_2(arg_15_0, arg_15_1)
		end
	end, nil, nil, false)
end

function var_0_0.selectAwardGroup(arg_16_0, arg_16_1, arg_16_2)
	xyd.Backend.get():request(xyd.mid.CHAMPIONS_SELECT_AWARD_GROUP, arg_16_1, function(arg_17_0, arg_17_1)
		if arg_17_0 == xyd.error.OK then
			local var_17_0 = xyd.WindowManager.get():getWindow("champions_league")

			if var_17_0 and not tolua.isnull(var_17_0) then
				var_17_0:updateInfo()
			end

			arg_16_0.isChangeGroup = false
		end

		if arg_16_2 then
			arg_16_2(arg_17_0, arg_17_1)
		end
	end, nil, nil, false)
end

function var_0_0.getAwardPreviewInfo(arg_18_0, arg_18_1, arg_18_2)
	if arg_18_1 <= 0 or arg_18_2 <= 0 then
		return var_0_1:getValue("cross_arena_special_first_win")
	end

	return (var_0_2:getGiftIdByInfo(arg_18_1, arg_18_2))
end

function var_0_0.getHonorRankInfo(arg_19_0, arg_19_1)
	xyd.Backend.get():request(xyd.mid.CHAMPIONS_GET_SEASON_TOP, nil, function(arg_20_0, arg_20_1)
		if arg_20_0 == xyd.error.OK then
			-- block empty
		end

		if arg_19_1 then
			arg_19_1(arg_20_0, arg_20_1)
		end
	end, nil, nil, false)
end

return var_0_0
