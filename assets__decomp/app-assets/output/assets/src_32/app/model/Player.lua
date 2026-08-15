local var_0_0 = class("Player", import(".BaseModel"))

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
	arg_2_0:registerEvent(xyd.event.HEROS, handler(arg_2_0, arg_2_0.herosEvent_))
	arg_2_0:registerEvent(xyd.event.PLAYER_INFO, handler(arg_2_0, arg_2_0.onPlayerInfo_))
	arg_2_0:registerEvent(xyd.event.LOAD_BATTLE_FORMATION, handler(arg_2_0, arg_2_0.onLoadBattleFormation_))
end

function var_0_0.load(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = {
		player_id = arg_3_2
	}

	xyd.Backend.get():request(xyd.mid.LOAD_PLAYER_INFO, var_3_0, arg_3_1)
end

function var_0_0.loadHeros(arg_4_0, arg_4_1, arg_4_2)
	if arg_4_0.herosLoaded_ then
		if arg_4_2 then
			arg_4_2(xyd.error.OK)
		end
	else
		local var_4_0 = arg_4_0.playerID

		if arg_4_1.player_id then
			var_4_0 = arg_4_1.player_id
		end

		xyd.Backend.get():request(xyd.mid.LOAD_HEROS, arg_4_1, function(arg_5_0, arg_5_1, arg_5_2)
			if arg_5_0 == xyd.error.OK then
				if not arg_4_0.heros_ then
					arg_4_0:herosEvent_({
						name = xyd.event.HEROS,
						params = arg_5_1,
						userdata = arg_5_2
					})
				end

				arg_4_0.herosLoaded_ = true
			end

			if arg_4_2 then
				arg_4_2(arg_5_0)
			end
		end, {
			player_id = var_4_0
		}, false, true)
	end
end

function var_0_0.loadBattleFormation(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4)
	if arg_6_4 == nil then
		arg_6_4 = arg_6_0.playerID
	end

	local var_6_0 = {
		type = arg_6_1,
		num = arg_6_2,
		player_id = arg_6_4
	}

	if arg_6_4 == arg_6_0.playerID and arg_6_0.battleFormation_ and arg_6_0.battleFormation_[arg_6_1] and arg_6_0.battleFormation_[arg_6_1][arg_6_4] then
		arg_6_3(xyd.error.OK)
	else
		xyd.Backend.get():request(xyd.mid.LOAD_BATTLE_FORMATION, var_6_0, function(arg_7_0)
			arg_6_3(arg_7_0)

			if arg_7_0 == xyd.error.OK then
				-- block empty
			end
		end, {
			type = arg_6_1,
			player_id = arg_6_4
		})
	end
end

function var_0_0.onLoadBattleFormation_(arg_8_0, arg_8_1)
	local var_8_0 = arg_8_1.userdata

	if var_8_0 == nil then
		return
	end

	if arg_8_0.battleFormation_ == nil then
		arg_8_0.battleFormation_ = {}
	end

	if var_8_0.type == xyd.FormationType.DEFENSE then
		if arg_8_0.battleFormation_[var_8_0.type] == nil then
			arg_8_0.battleFormation_[var_8_0.type] = {}
		end

		if xyd.StoryData.get():getGuideID() < xyd.GuideStoryType.GUIDE_ID_SET_DEFENSE then
			arg_8_0.battleFormation_[var_8_0.type][var_8_0.player_id] = {}
		else
			arg_8_0.battleFormation_[var_8_0.type][var_8_0.player_id] = arg_8_1.params.list or {}
		end
	end
end

function var_0_0.saveFormation(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4)
	xyd.Backend.get():request(xyd.mid.SET_FORMATION, arg_9_1, function(arg_10_0)
		arg_9_4(arg_10_0)

		if arg_10_0 == xyd.error.OK then
			if arg_9_0.battleFormation_ == nil then
				arg_9_0.battleFormation_ = {}
			end

			arg_9_0.battleFormation_[arg_9_2] = arg_9_1.partner_ids
		end
	end)
end

function var_0_0.herosEvent_(arg_11_0, arg_11_1)
	if arg_11_1.userdata.player_id ~= arg_11_0.playerID then
		return
	end

	arg_11_0.heros_ = {}
	arg_11_0.sortType = 0

	if arg_11_1.params.sort_type then
		arg_11_0.sortType = tonumber(arg_11_1.params.sort_type)
	end

	local var_11_0 = arg_11_1.userdata.conquer_lev or 0

	for iter_11_0, iter_11_1 in pairs(arg_11_1.params.heros) do
		local var_11_1 = import("app.model.Hero").new()

		var_11_1:populate(iter_11_1)
		var_11_1:setPlayerID(arg_11_0.playerID)
		var_11_1:setConquerSchoolLev(var_11_0)

		arg_11_0.heros_[#arg_11_0.heros_ + 1] = var_11_1
	end
end

function var_0_0.getHeroByID(arg_12_0, arg_12_1)
	if not arg_12_0.heros_ then
		return nil
	end

	for iter_12_0, iter_12_1 in pairs(arg_12_0.heros_) do
		if iter_12_1:getHeroID() == arg_12_1 then
			return iter_12_1
		end
	end

	return nil
end

function var_0_0.isDefenceHero(arg_13_0, arg_13_1)
	if not arg_13_0.battleFormation_ then
		return false
	elseif not arg_13_0.battleFormation_[xyd.FormationType.DEFENSE] then
		return false
	elseif not arg_13_0.battleFormation_[xyd.FormationType.DEFENSE][arg_13_0.playerID] then
		return false
	end

	for iter_13_0, iter_13_1 in pairs(arg_13_0.battleFormation_[xyd.FormationType.DEFENSE][arg_13_0.playerID]) do
		if iter_13_1 == arg_13_1 then
			return true
		end
	end

	return false
end

function var_0_0.getRepHero(arg_14_0)
	return arg_14_0.repHero_
end

function var_0_0.getHerosByIDs(arg_15_0, arg_15_1)
	local var_15_0 = {}

	for iter_15_0, iter_15_1 in ipairs(arg_15_1) do
		var_15_0[iter_15_1] = iter_15_0
	end

	local var_15_1 = {}

	for iter_15_2, iter_15_3 in ipairs(arg_15_0.heros_) do
		if iter_15_3 ~= nil then
			local var_15_2 = var_15_0[iter_15_3:getHeroID()]

			if var_15_2 ~= nil then
				var_15_1[var_15_2] = iter_15_3
			end
		end
	end

	return var_15_1
end

function var_0_0.populate(arg_16_0, arg_16_1)
	arg_16_0.playerID = tonumber(arg_16_1.player_id)
	arg_16_0.playerName = arg_16_1.player_name
	arg_16_0.lev = tonumber(arg_16_1.lev)
end

function var_0_0.onPlayerInfo_(arg_17_0, arg_17_1)
	if arg_17_0.playerID ~= nil and arg_17_0.playerID ~= tonumber(arg_17_1.params.player_id) then
		return
	end

	arg_17_0:populate(arg_17_1.params)
end

return var_0_0
