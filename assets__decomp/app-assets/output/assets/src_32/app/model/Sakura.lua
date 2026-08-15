local var_0_0 = class("Sakura", import(".BaseModel"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("app.model.Pet")
local var_0_3 = #xyd.Color2Level
local var_0_4 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.outlineColor = cc.c4b(108, 24, 187, 255)
	arg_1_0.outlineSize = 1.2
	arg_1_0.preHerosFormation = xyd.db.stateVariable:getState(arg_1_0.selfPlayer.playerID, xyd.state.SAKURA_PRE_HEROS_FORMATION)

	if arg_1_0.preHerosFormation == 0 then
		arg_1_0.preHerosFormation = nil
	end

	arg_1_0.prePetFormation = xyd.db.stateVariable:getState(arg_1_0.selfPlayer.playerID, xyd.state.SAKURA_PRE_PET_FORMATION)

	if arg_1_0.prePetFormation == 0 then
		arg_1_0.prePetFormation = nil
	end
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.loadInfo(arg_3_0, arg_3_1)
	local var_3_0 = {
		activity_id = xyd.Activities.Sakura
	}

	xyd.Backend.get():request(xyd.mid.LOAD_SINGLE_ACTIVITY, var_3_0, function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK then
			if arg_4_1 then
				arg_3_0.activity = arg_4_1
				arg_3_0.details = arg_3_0.activity.details
			end

			if arg_3_1 then
				arg_3_1(arg_4_0, arg_4_1)
			end
		end
	end)
end

function var_0_0.updateUsedItems(arg_5_0, arg_5_1)
	local var_5_0 = arg_5_0.details.used_items

	for iter_5_0 = 1, #var_5_0 do
		if var_5_0[iter_5_0] == arg_5_1 then
			return
		end
	end

	table.insert(arg_5_0.details.used_items, arg_5_1)
end

function var_0_0.isItemMaked(arg_6_0, arg_6_1)
	local var_6_0 = arg_6_0.details.used_items

	for iter_6_0 = 1, #var_6_0 do
		if var_6_0[iter_6_0] == arg_6_1 then
			return true
		end
	end

	return false
end

function var_0_0.composeItem(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = arg_7_1 or {}

	xyd.Backend.get():request(xyd.mid.COMPOSE_SAKURA_ITEM, var_7_0, function(arg_8_0, arg_8_1)
		if arg_8_0 == xyd.error.OK then
			arg_7_0:updateUsedItems(var_7_0.item_id)

			local var_8_0 = xyd.tables.activitySakura2Cook:material(var_7_0.item_id)

			for iter_8_0 = 1, #var_8_0 do
				local var_8_1 = {
					itemNum = 1,
					itemID = var_8_0[iter_8_0]
				}

				arg_7_0.backpack:removeItem(var_8_1)
			end
		end

		if arg_7_2 then
			arg_7_2(arg_8_0, arg_8_1)
		end
	end)
end

function var_0_0.openEvent(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = arg_9_1 or {}

	xyd.Backend.get():request(xyd.mid.OPEN_SAKURA_EVENT, var_9_0, function(arg_10_0, arg_10_1)
		if arg_10_0 == xyd.error.OK then
			local var_10_0 = {
				itemNum = 1,
				itemID = var_9_0.item_id
			}

			arg_9_0.backpack:removeItem(var_10_0)
		end

		if arg_9_2 then
			arg_9_2(arg_10_0, arg_10_1)
		end
	end)
end

function var_0_0.startFight(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = arg_11_1 or {}

	xyd.Backend.get():request(xyd.mid.START_SAKURA_FIGHT, var_11_0, function(arg_12_0, arg_12_1)
		if arg_11_2 then
			arg_11_2(arg_12_0, arg_12_1)
		end
	end)
end

function var_0_0.fightResult(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0 = arg_13_1 or {}

	xyd.Backend.get():request(xyd.mid.SAKURA_FIGHT_RESULT, var_13_0, function(arg_14_0, arg_14_1)
		if arg_13_2 then
			arg_13_2(arg_14_0, arg_14_1)
		end
	end)
end

function var_0_0.createMaterialsItemContent(arg_15_0, arg_15_1)
	local var_15_0 = display.newNode()
	local var_15_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/sakura/fruit_factory/material_item.csb")
	local var_15_2 = var_15_1:getChildByName("container")

	if arg_15_0.backpack:getItemNumByID(arg_15_1) > 0 then
		var_15_2:getChildByName("cover"):setVisible(false)
		xyd.setItemBorder(var_15_2:getChildByName("icon_container"), arg_15_1)
	else
		xyd.setItemBorder(var_15_2:getChildByName("icon_container"), arg_15_1, nil, true)
	end

	var_15_2:getChildByName("name_txt"):setString(xyd.tables.item:name(arg_15_1))
	var_15_2:getChildByName("own_text"):setString(var_0_4:translation("OWN_TEXT1"))
	var_15_2:getChildByName("own_num_txt"):setString(arg_15_0.backpack:getItemNumByID(arg_15_1))
	var_15_2:getChildByName("name_txt"):enableOutline(arg_15_0.outlineColor, arg_15_0.outlineSize)
	var_15_2:getChildByName("own_text"):enableOutline(arg_15_0.outlineColor, arg_15_0.outlineSize)
	var_15_2:getChildByName("own_num_txt"):enableOutline(arg_15_0.outlineColor, arg_15_0.outlineSize)
	var_15_1:addTo(var_15_0)
	var_15_1:setAnchorPoint(cc.p(0, 0))
	var_15_0:setContentSize(var_15_2:getContentSize())
	var_15_1:setName("source")

	return var_15_0
end

function var_0_0.getReward(arg_16_0, arg_16_1, arg_16_2)
	local var_16_0 = arg_16_1 or {}

	var_16_0.activity_id = xyd.Activities.Sakura

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_REWARD, var_16_0, function(arg_17_0, arg_17_1)
		if arg_16_2 then
			arg_16_2(arg_17_0, arg_17_1)
		end
	end)
end

function var_0_0.populateMonsterWithTableID(arg_18_0, arg_18_1)
	local var_18_0 = {}
	local var_18_1 = arg_18_0.selfPlayer.lev

	var_18_0.level = var_18_1
	var_18_0.color = xyd.tables.activitySakura2Monster:getColorByLevel(var_18_1)
	var_18_0.star = xyd.tables.activitySakura2Monster:star(var_18_0.color)
	var_18_0.equips = {
		0,
		0,
		0,
		0,
		0,
		0
	}
	var_18_0.skills = {
		var_18_1,
		var_18_1,
		var_18_1 - 20,
		var_18_1 - 40,
		var_18_1 - 60,
		var_18_1 - 60
	}

	for iter_18_0 = 1, #var_18_0.skills do
		if var_18_0.skills[iter_18_0] < 0 then
			var_18_0.skills[iter_18_0] = 0
		end
	end

	if var_18_1 > xyd.tables.activitySakura2Monster:level(var_0_3) then
		var_18_0.equips = {
			1,
			1,
			1,
			1,
			1,
			1
		}
	end

	local var_18_2 = var_0_1.new()

	var_18_2:populateWithTableID(arg_18_1, var_18_0)

	return var_18_2
end

function var_0_0.populatePetWithTableID(arg_19_0, arg_19_1)
	local var_19_0 = arg_19_0.selfPlayer.lev
	local var_19_1 = {
		level = var_19_0,
		color = xyd.tables.activitySakura2Monster:getColorByLevel(var_19_0)
	}

	var_19_1.star = xyd.tables.activitySakura2Monster:star(var_19_1.color)
	var_19_1.is_sakura2 = true
	var_19_1.skills = {
		var_19_0,
		var_19_0,
		var_19_0 - 20,
		var_19_0 - 40,
		var_19_0 - 60
	}

	for iter_19_0 = 1, #var_19_1.skills do
		if var_19_1.skills[iter_19_0] < 0 then
			var_19_1.skills[iter_19_0] = 0
		end
	end

	var_19_1.equips = {
		0,
		0,
		0
	}

	if var_19_0 > xyd.tables.activitySakura2Monster:level(var_0_3) then
		var_19_1.equips = {
			1,
			1,
			1
		}
	end

	local var_19_2 = var_0_2.new()

	var_19_2:initUnCollected(arg_19_1, nil, var_19_1)

	return var_19_2
end

function var_0_0.setPreHerosFormation(arg_20_0, arg_20_1)
	arg_20_0.preHerosFormation = arg_20_1

	local var_20_0 = {
		playerID = arg_20_0.selfPlayer.playerID,
		name = xyd.state.SAKURA_PRE_HEROS_FORMATION,
		state = arg_20_1
	}

	xyd.db.stateVariable:setState(var_20_0)
end

function var_0_0.getPreHerosFormation(arg_21_0)
	return arg_21_0.preHerosFormation
end

function var_0_0.getPreHeroIDs(arg_22_0)
	if arg_22_0.preHerosFormation then
		return xyd.splitToNumber(arg_22_0.preHerosFormation, "|")
	end
end

function var_0_0.getPreHeros(arg_23_0)
	local var_23_0 = arg_23_0:getPreHeroIDs()
	local var_23_1 = {}

	if var_23_0 then
		for iter_23_0, iter_23_1 in pairs(var_23_0) do
			table.insert(var_23_1, arg_23_0.selfPlayer:getHeroByID(iter_23_1))
		end
	end

	return var_23_1
end

function var_0_0.setPrePetFormation(arg_24_0, arg_24_1)
	arg_24_0.prePetFormation = arg_24_1

	local var_24_0 = {
		playerID = arg_24_0.selfPlayer.playerID,
		name = xyd.state.SAKURA_PRE_PET_FORMATION,
		state = tostring(arg_24_1)
	}

	xyd.db.stateVariable:setState(var_24_0)
end

function var_0_0.getPrePetFormation(arg_25_0)
	return arg_25_0.prePetFormation
end

function var_0_0.getPrePetIDs(arg_26_0)
	if arg_26_0.prePetFormation then
		return xyd.splitToNumber(arg_26_0.prePetFormation, "|")
	end
end

function var_0_0.getPrePet(arg_27_0)
	local var_27_0 = arg_27_0:getPrePetIDs()
	local var_27_1 = {}

	if var_27_0 then
		for iter_27_0, iter_27_1 in pairs(var_27_0) do
			table.insert(var_27_1, arg_27_0.selfPlayer:getPetByID(iter_27_1))
		end
	end

	return var_27_1
end

function var_0_0.hideWindows(arg_28_0)
	local var_28_0 = {
		"main_scene_top",
		"main_scene_bottom"
	}

	for iter_28_0, iter_28_1 in pairs(var_28_0) do
		local var_28_1 = xyd.WindowManager.get():getWindow(iter_28_1)

		if var_28_1 and not tolua.isnull(var_28_1) then
			var_28_1:setVisible(false)
		end
	end
end

return var_0_0
