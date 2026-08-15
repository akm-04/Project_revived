local var_0_0 = class("Dungeon", import(".BaseModel"))

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
	arg_2_0:registerEvent(xyd.event.BATTLE_ENDED, handler(arg_2_0, arg_2_0.battleEndedEvent_))
	arg_2_0:registerEvent(xyd.event.RELOAD, handler(arg_2_0, arg_2_0.reloadEvent_))
end

function var_0_0.load(arg_3_0, arg_3_1, arg_3_2)
	if arg_3_1 then
		arg_3_0.loaded_ = false
		arg_3_0.dungeonItems_ = {}
	end

	if arg_3_0.loaded_ then
		if arg_3_2 then
			arg_3_2(xyd.error.OK)
		end
	else
		xyd.Backend.get():request(xyd.mid.LOAD_DUNGEON, {}, function(arg_4_0, arg_4_1, arg_4_2)
			if arg_4_0 == xyd.error.OK then
				arg_3_0:dungeonEvent_({
					name = xyd.event.DUNGEON,
					params = arg_4_1,
					userdata = arg_4_2
				})
			end

			arg_3_0.loaded_ = true

			if arg_3_2 then
				arg_3_2(arg_4_0, arg_4_1)
			end
		end, {}, false, true)
	end
end

function var_0_0.dungeonEvent_(arg_5_0, arg_5_1)
	arg_5_0.dungeonItems_ = {}

	for iter_5_0, iter_5_1 in pairs(arg_5_1.params.list) do
		local var_5_0 = import("app.model.DungeonItem").new()

		var_5_0:populate(iter_5_1)
		table.insert(arg_5_0.dungeonItems_, var_5_0)
	end
end

function var_0_0.getOpenDungeonItems(arg_6_0)
	local var_6_0 = {}

	for iter_6_0, iter_6_1 in pairs(arg_6_0.dungeonItems_) do
		if iter_6_1.isOpen_ == 1 then
			table.insert(var_6_0, iter_6_1)
		end
	end

	return var_6_0
end

function var_0_0.getDungeonItemByID(arg_7_0, arg_7_1)
	for iter_7_0, iter_7_1 in pairs(arg_7_0.dungeonItems_) do
		if iter_7_1.mapID_ == arg_7_1 then
			return iter_7_1
		end
	end

	return nil
end

function var_0_0.battleEndedEvent_(arg_8_0, arg_8_1)
	if arg_8_1.instance_type ~= xyd.InstanceType.DUNGEON then
		return
	end

	if not arg_8_1.is_win then
		return
	end

	local var_8_0 = arg_8_1.instance_id
	local var_8_1 = xyd.tables.stage:mapID(var_8_0)
	local var_8_2 = arg_8_0:getDungeonItemByID(var_8_1)
	local var_8_3 = var_8_2.passedStageID_

	if var_8_3 > 0 then
		if var_8_3 == var_8_0 then
			return
		end

		local var_8_4 = var_8_0

		while var_8_4 ~= xyd.tables.stage:lastStageAtLevel(var_8_1, xyd.StageLevel.NORMAL) do
			var_8_4 = xyd.tables.stage:nextStageID(var_8_4)

			if var_8_3 == var_8_4 then
				return
			end
		end
	end

	var_8_2.passedstageID_ = var_8_0

	local var_8_5 = xyd.tables.stage:nextStageID(var_8_0)

	if var_8_5 == 0 then
		var_8_5 = xyd.tables.stage:lastStageAtLevel(var_8_1, xyd.StageLevel.NORMAL)
	end

	var_8_2.currentStageID_ = var_8_5
end

function var_0_0.reloadEvent_(arg_9_0, arg_9_1)
	if arg_9_1.params.secret_open == 1 then
		print("reload dungeon")

		arg_9_0.loaded_ = false
	end
end

return var_0_0
