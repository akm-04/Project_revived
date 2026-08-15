local var_0_0 = class("Treasure", import(".BaseModel"))

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)

	arg_2_0.teams = {}
	arg_2_0.currentAwards = {}
	arg_2_0.tempAwards = {}
	arg_2_0.isDisabelAll = false
	arg_2_0.matchInfo = {}
	arg_2_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.loadTreasureInfo(arg_3_0, arg_3_1)
	if arg_3_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_TREASURE) then
		xyd.Backend.get():request(xyd.mid.TREASURE_LOAD_INFO, {}, function(arg_4_0, arg_4_1)
			local var_4_0 = arg_4_1.teams_info
			local var_4_1 = arg_4_1.sp_info

			arg_3_0.teams = {}

			if var_4_0 then
				for iter_4_0, iter_4_1 in pairs(var_4_0) do
					arg_3_0.teams[iter_4_1.team_id] = iter_4_1

					if not arg_3_0.firstLoad then
						local var_4_2 = iter_4_1.partners or {}

						arg_3_0:savedMemoryTeams(iter_4_1.team_id, var_4_2)
					end
				end
			end

			if var_4_1 then
				arg_3_0.selfPlayer.treasureSP = var_4_1.sp or 0
				arg_3_0.selfPlayer.lastTreasureSP = var_4_1.sp_last_refresh_time or 0

				local var_4_3 = xyd.WindowManager.get():getWindow("treasure_window")

				if var_4_3 ~= nil then
					var_4_3:updateSPNumTxt()
				end
			end

			arg_3_0.firstLoad = true

			arg_3_1(arg_4_0)
		end)
	else
		arg_3_1(xyd.error.ERROR)
	end
end

function var_0_0.getTreasureDiary(arg_5_0, arg_5_1)
	xyd.Backend.get():request(xyd.mid.TREASURE_LOG, {}, function(arg_6_0, arg_6_1)
		if arg_5_1 then
			arg_5_1(arg_6_0, arg_6_1)
		end
	end)
end

function var_0_0.finishOneTeam(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = arg_7_2 or {}

	xyd.Backend.get():request(xyd.mid.TREASURE_FINISH_ONE_TEAM, {
		team_id = var_7_0.teamId
	}, function(arg_8_0, arg_8_1)
		if arg_8_0 == xyd.error.OK and arg_8_1.team_info then
			arg_7_0.teams[tonumber(arg_8_1.team_info.team_id)] = arg_8_1.team_info

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.TREASURE_UPDATE_WINDOW
			})
		end

		if arg_7_1 then
			arg_7_1(arg_8_0, arg_8_1)
		end
	end)
end

function var_0_0.setTreasurePartner(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = arg_9_2 or {}

	xyd.Backend.get():request(xyd.mid.TREASURE_SET_PARTNER, var_9_0, function(arg_10_0, arg_10_1)
		if arg_10_0 == xyd.error.OK then
			arg_9_0.selfPlayer.treasureSP = arg_9_0.selfPlayer.treasureSP - var_9_0.sp_num
			arg_9_0.teams[tonumber(arg_10_1.team_id)] = arg_10_1

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.TREASURE_UPDATE_WINDOW
			})
		end

		if arg_9_1 then
			arg_9_1(arg_10_0, arg_10_1)
		end
	end)
end

function var_0_0.savedMemoryTeams(arg_11_0, arg_11_1, arg_11_2)
	if not arg_11_0.MemeoryTeams then
		arg_11_0.MemeoryTeams = {}
	end

	arg_11_0.MemeoryTeams[arg_11_1] = arg_11_2
end

function var_0_0.onLoadTreasureInfo_(arg_12_0, arg_12_1)
	local var_12_0 = arg_12_1.params.teams_info
	local var_12_1 = arg_12_1.params.sp_info

	arg_12_0.teams = {}

	if var_12_0 then
		for iter_12_0, iter_12_1 in pairs(var_12_0) do
			arg_12_0.teams[iter_12_1.team_id] = iter_12_1
		end
	end

	arg_12_0:checkRed()
end

function var_0_0.checkRed(arg_13_0)
	if not arg_13_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_TREASURE) then
		return
	end

	local var_13_0 = false
	local var_13_1 = arg_13_0.has_red

	if not arg_13_0.teams then
		arg_13_0.has_red = false

		return
	end

	for iter_13_0, iter_13_1 in pairs(arg_13_0.teams) do
		local var_13_2 = xyd.ServerTime.get():getServerTime()

		if iter_13_1.start_time > 0 and var_13_2 > iter_13_1.need_time + iter_13_1.start_time then
			arg_13_0.has_red = true
			var_13_0 = true

			break
		end
	end

	if var_13_0 == false then
		arg_13_0.has_red = false
	end

	if var_13_1 == nil or var_13_1 ~= arg_13_0.has_red then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.CHECK_MIDDLE_RED_MARK,
			params = xyd.CheckMiddleRed.TREASURE
		})
	end
end

function var_0_0.onFinishOneTeam_(arg_14_0, arg_14_1)
	local var_14_0 = arg_14_1.params
	local var_14_1 = var_14_0.award

	if var_14_1.type == xyd.TreasureAwardType.Gold then
		if arg_14_0.tempAwards.gold == nil then
			arg_14_0.tempAwards.gold = {
				table_id = -1,
				mana = var_14_1.mana,
				item_num = var_14_1.mana
			}
		else
			arg_14_0.tempAwards.gold.mana = arg_14_0.tempAwards.gold.mana + var_14_1.mana
			arg_14_0.tempAwards.gold.item_num = arg_14_0.tempAwards.gold.item_num + var_14_1.mana
		end
	elseif var_14_1.type == xyd.TreasureAwardType.Drink then
		if arg_14_0.tempAwards["drink_" .. var_14_1.item_id] == nil then
			arg_14_0.tempAwards["drink_" .. var_14_1.item_id] = {
				table_id = var_14_1.item_id,
				item_num = var_14_1.item_num
			}
		else
			arg_14_0.tempAwards["drink_" .. var_14_1.item_id].item_num = arg_14_0.tempAwards["drink_" .. var_14_1.item_id].item_num + var_14_1.item_num
		end

		arg_14_0.selfPlayer:getBackpack():addItemsByID(tonumber(var_14_1.item_id), tonumber(var_14_1.item_num))
	elseif var_14_1.type == xyd.TreasureAwardType.Stone then
		for iter_14_0, iter_14_1 in pairs(var_14_1.items) do
			if arg_14_0.tempAwards["stone_" .. iter_14_1.item_id] == nil then
				arg_14_0.tempAwards["stone_" .. iter_14_1.item_id] = {
					table_id = iter_14_1.item_id,
					item_num = iter_14_1.item_num
				}
			else
				arg_14_0.tempAwards["stone_" .. iter_14_1.item_id].item_num = arg_14_0.tempAwards["stone_" .. iter_14_1.item_id].item_num + iter_14_1.item_num
			end

			arg_14_0.selfPlayer:getBackpack():addItemsByID(tonumber(iter_14_1.item_id), tonumber(iter_14_1.item_num))
		end
	elseif var_14_1.type == xyd.TreasureAwardType.Dust then
		if arg_14_0.tempAwards.dust == nil then
			arg_14_0.tempAwards.dust = {
				table_id = -1,
				dust = var_14_1.magic_dust,
				item_num = var_14_1.magic_dust
			}
		else
			arg_14_0.tempAwards.dust.dust = arg_14_0.tempAwards.dust.dust + var_14_1.magic_dust
			arg_14_0.tempAwards.dust.item_num = arg_14_0.tempAwards.dust.item_num + var_14_1.magic_dust
		end
	elseif var_14_1.type == xyd.TreasureAwardType.Liquid then
		if arg_14_0.tempAwards.liquid == nil then
			arg_14_0.tempAwards.liquid = {
				table_id = -1,
				liquid = var_14_1.magic_liquid,
				item_num = var_14_1.magic_liquid
			}
		else
			arg_14_0.tempAwards.liquid.liquid = arg_14_0.tempAwards.liquid.liquid + var_14_1.magic_liquid
			arg_14_0.tempAwards.liquid.item_num = arg_14_0.tempAwards.liquid.item_num + var_14_1.magic_liquid
		end
	end

	if var_14_0.crystal_num then
		if arg_14_0.tempAwards.crystal == nil then
			arg_14_0.tempAwards.crystal = {
				table_id = -1,
				crystal = var_14_0.crystal_num,
				item_num = var_14_0.crystal_num
			}
		else
			arg_14_0.tempAwards.crystal.crystal = arg_14_0.tempAwards.crystal.crystal + var_14_0.crystal_num
			arg_14_0.tempAwards.crystal.item_num = arg_14_0.tempAwards.crystal.item_num + var_14_0.crystal_num
		end
	end
end

function var_0_0.onSaveBattleResult_(arg_15_0, arg_15_1)
	local var_15_0 = arg_15_1.params
	local var_15_1 = xyd.WindowManager.get():getWindow("treasure_window")

	if var_15_0.sp then
		arg_15_0.selfPlayer.treasureSP = var_15_0.sp

		if var_15_1 ~= nil then
			var_15_1:updateSPNumTxt()
		end
	end

	arg_15_0.currentAwards = {}

	if var_15_0.award then
		local var_15_2 = var_15_0.award

		if var_15_2.type == xyd.TreasureAwardType.Gold then
			table.insert(arg_15_0.currentAwards, {
				table_id = -1,
				mana = var_15_2.mana,
				item_num = var_15_2.mana
			})
		elseif var_15_2.type == xyd.TreasureAwardType.Drink then
			table.insert(arg_15_0.currentAwards, {
				table_id = var_15_2.item_id,
				item_num = var_15_2.item_num
			})
			arg_15_0.selfPlayer:getBackpack():addItemsByID(tonumber(var_15_2.item_id), tonumber(var_15_2.item_num))
		elseif var_15_2.type == xyd.TreasureAwardType.Stone then
			for iter_15_0, iter_15_1 in pairs(var_15_2.items) do
				table.insert(arg_15_0.currentAwards, {
					table_id = iter_15_1.item_id,
					item_num = iter_15_1.item_num
				})
				arg_15_0.selfPlayer:getBackpack():addItemsByID(tonumber(iter_15_1.item_id), tonumber(iter_15_1.item_num))
			end
		elseif var_15_2.type == xyd.TreasureAwardType.Dust then
			table.insert(arg_15_0.currentAwards, {
				table_id = -1,
				dust = var_15_2.magic_dust,
				item_num = var_15_2.magic_dust
			})
		elseif var_15_2.type == xyd.TreasureAwardType.Liquid then
			table.insert(arg_15_0.currentAwards, {
				table_id = -1,
				liquid = var_15_2.magic_liquid,
				item_num = var_15_2.magic_liquid
			})
		end

		if var_15_0.crystal_award then
			table.insert(arg_15_0.currentAwards, {
				table_id = -1,
				crystal = var_15_0.crystal_award,
				item_num = var_15_0.crystal_award
			})
		end
	end
end

function var_0_0.queryBattleRecord(arg_16_0, arg_16_1)
	local var_16_0 = {}

	xyd.Backend.get():request(xyd.mid.TREASURE_GET_BATTLE_RECORD, var_16_0, function(arg_17_0, arg_17_1)
		if arg_17_0 == xyd.error.OK and arg_16_1 then
			arg_16_1(arg_17_0, arg_17_1)
		end
	end)
end

function var_0_0.queryBattleReport(arg_18_0, arg_18_1)
	local var_18_0 = {}

	xyd.Backend.get():request(xyd.mid.TREASURE_GET_BATTLE_REPORT, var_18_0, function(arg_19_0, arg_19_1)
		if arg_19_0 == xyd.error.OK and arg_18_1 then
			arg_18_1(arg_19_0, arg_19_1)
		end
	end)
end

function var_0_0.updateHeroStatus(arg_20_0, arg_20_1, arg_20_2)
	if arg_20_0.matchInfo == nil or not next(arg_20_0.matchInfo) then
		return
	end

	local var_20_0

	if arg_20_2 then
		var_20_0 = arg_20_0.matchInfo.herosStatus or {}
	else
		var_20_0 = arg_20_0.matchInfo.enymyStatus or {}
	end

	for iter_20_0, iter_20_1 in pairs(arg_20_1) do
		local var_20_1 = tostring(iter_20_1.hero_id)

		var_20_0[var_20_1] = var_20_0[var_20_1] or {}
		var_20_0[var_20_1].health = 1
		var_20_0[var_20_1].hp = iter_20_1.hp
		var_20_0[var_20_1].mp = iter_20_1.mp
	end
end

return var_0_0
