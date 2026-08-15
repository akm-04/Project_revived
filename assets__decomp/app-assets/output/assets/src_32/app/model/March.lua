local var_0_0 = class("March", import(".BaseModel"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = import("app.model.Hero")

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.MarchInfos_ = {}
	arg_1_0.showList = 0
	arg_1_0.stageDone = false
	arg_1_0.isReborn = 0
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
	arg_2_0:registerEvent(xyd.event.LOAD_MARCH, handler(arg_2_0, arg_2_0.onLoadMarch_))
	arg_2_0:registerEvent(xyd.event.MARCH_UPDATE, handler(arg_2_0, arg_2_0.onUpdateMarch_))
	arg_2_0:registerEvent(xyd.event.MARCH_ADVANCE, handler(arg_2_0, arg_2_0.sweepMarch_))
end

function var_0_0.loadMarchInfo(arg_3_0, arg_3_1, arg_3_2)
	if xyd.isFunctionOpen(xyd.FunctionID.ID_MARCH) then
		xyd.Backend.get():request(xyd.mid.LOAD_MARCH, {}, function(arg_4_0)
			arg_3_2(arg_4_0)
		end)
	else
		arg_3_2(xyd.error.ERROR)
	end
end

function var_0_0.onLoadMarch_(arg_5_0, arg_5_1)
	local var_5_0 = arg_5_1.params

	arg_5_0.mapInfo = var_5_0.map_info
	arg_5_0.isReborn = tonumber(arg_5_0.mapInfo.is_reborn) or 0
	arg_5_0.heroStatus = var_5_0.hero_status
	arg_5_0.enemies = var_5_0.enemies
	arg_5_0.rewards = var_5_0.rewards
	arg_5_0.isGetExtraAward = arg_5_0.mapInfo.is_external_award

	if arg_5_0.mapInfo.stage_done == 1 then
		arg_5_0.lastDoneStage = arg_5_0.mapInfo.passed_stage + 1
	else
		arg_5_0.lastDoneStage = arg_5_0.mapInfo.passed_stage
	end

	if arg_5_0.lastDoneStage < 9 then
		arg_5_0.isOpenExtraChest = false
	else
		arg_5_0.isOpenExtraChest = true
	end

	if arg_5_0.mapInfo.passed_stage ~= nil and arg_5_0.rewards[arg_5_0.mapInfo.passed_stage + 1] ~= nil then
		arg_5_0.currentReward = arg_5_0.rewards[arg_5_0.mapInfo.passed_stage + 1]
	end

	if arg_5_0.mapInfo.stage_done == 1 then
		arg_5_0.stageDone = true
	else
		arg_5_0.stageDone = false
	end

	for iter_5_0 = 1, #arg_5_0.enemies do
		local var_5_1 = arg_5_0.enemies[iter_5_0]

		for iter_5_1, iter_5_2 in pairs(var_5_1.heroes) do
			if iter_5_2.health == nil or iter_5_2.health == 0 then
				iter_5_2.mp = xyd.tables.misc.marchInitMp[iter_5_0]
			end
		end
	end
end

function var_0_0.onUpdateMarch_(arg_6_0, arg_6_1)
	local var_6_0 = arg_6_1.params

	xyd.tableMerge(arg_6_0.mapInfo, var_6_0.map_info)
	xyd.tableMerge(arg_6_0.heroStatus, var_6_0.hero_status)
	xyd.tableMerge(arg_6_0.rewards, var_6_0.rewards)

	if var_6_0.reward then
		arg_6_0.currentReward = var_6_0.reward
	end

	if arg_6_0.mapInfo.stage_done == 1 then
		arg_6_0.stageDone = true
	elseif arg_6_0.mapInfo.stage_done == 0 then
		arg_6_0.stageDone = false
	end

	local var_6_1 = var_6_0.enemy_status
	local var_6_2 = arg_6_0.mapInfo.passed_stage + 1
	local var_6_3 = arg_6_0.enemies[var_6_2]

	if var_6_1 and next(var_6_1) then
		for iter_6_0, iter_6_1 in pairs(var_6_1) do
			local var_6_4 = tonumber(iter_6_1.hero_id) or iter_6_0

			var_6_3.heroes[var_6_4].health = iter_6_1.health
			var_6_3.heroes[var_6_4].hp = iter_6_1.hp
			var_6_3.heroes[var_6_4].mp = iter_6_1.mp
			var_6_3.heroes[var_6_4].is_reborn = iter_6_1.is_reborn
		end
	end

	local var_6_5 = var_6_0.rewards

	if var_6_5 and next(var_6_5) then
		local var_6_6 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

		for iter_6_2, iter_6_3 in pairs(var_6_5) do
			if iter_6_3.is_partner == true then
				local var_6_7 = var_0_2.new()

				var_6_7:populate(iter_6_3)
				var_6_6:addHero(var_6_7)
			elseif iter_6_3.is_partner == false then
				var_6_6:getBackpack():addItemsByID(tonumber(iter_6_3.table_id), tonumber(iter_6_3.item_num))
			end
		end
	end
end

function var_0_0.sweepMarch_(arg_7_0, arg_7_1)
	local var_7_0 = arg_7_1.params

	xyd.tableMerge(arg_7_0.mapInfo, var_7_0.map_info)
	xyd.tableMerge(arg_7_0.heroStatus, var_7_0.hero_status)

	local var_7_1 = var_7_0.award
	local var_7_2 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	for iter_7_0 = 1, #var_7_1 do
		for iter_7_1 = 1, #var_7_1[iter_7_0] do
			local var_7_3 = var_7_1[iter_7_0][iter_7_1]

			if var_7_3.is_partner == true then
				local var_7_4 = var_0_2.new()

				var_7_4:populate(var_7_3)
				var_7_2:addHero(var_7_4)
			elseif var_7_3.is_partner == false then
				var_7_2:getBackpack():addItemsByID(tonumber(var_7_3.table_id), tonumber(var_7_3.item_num))
			end
		end
	end
end

function var_0_0.getCurrentStage(arg_8_0)
	if arg_8_0.mapInfo and arg_8_0.mapInfo.passed_stage then
		return arg_8_0.mapInfo.passed_stage + 1
	else
		return 1
	end
end

function var_0_0.getEnemy(arg_9_0, arg_9_1)
	if arg_9_0.enemies then
		return arg_9_0.enemies[arg_9_1]
	end
end

function var_0_0.getHeroStatus(arg_10_0)
	return arg_10_0.heroStatus
end

function var_0_0.getMapInfo(arg_11_0)
	return arg_11_0.mapInfo
end

function var_0_0.getCurrentReward(arg_12_0)
	return arg_12_0.currentReward
end

return var_0_0
