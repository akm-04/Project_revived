local var_0_0 = class("HeroEquipItem", import("app.common.ui.BaseNode"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = xyd.tables.item
local var_0_3 = {
	ICON_BORDER = 40,
	AWAKE_HIDE_ICON = 60,
	PLUS = 30,
	ICON_ITEM = 10,
	AWAKE_EFFECT = 70,
	AWAKE_HIDE_BG = 50
}

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0)

	arg_1_0.hero = arg_1_1.hero
	arg_1_0.idx = arg_1_1.idx
	arg_1_0.item = arg_1_0.hero:getEquipByIndexShow(arg_1_0.idx)
	arg_1_0.tableID = arg_1_0.item:getTableID()
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.task = xyd.ModelManager.get():loadModel(xyd.ModelType.TASK)
	arg_1_0.isAwakeItem = arg_1_0.item:getTableID() == 0 or var_0_2:isAwakenItem(arg_1_0.item:getTableID()) == 1

	arg_1_0:size(110, 110)
end

function var_0_0.layout(arg_2_0)
	if not arg_2_0.item:isCollected() or arg_2_0.tableID == 0 then
		if arg_2_0.isAwakeItem and arg_2_0:checkAwakeHide() then
			local var_2_0 = xyd.AssetLoader.get():loadSprite("windows/common/hero_common/bg_no_equip.png")

			var_2_0:addTo(arg_2_0, var_0_3.AWAKE_HIDE_BG)
			var_2_0:setAnchorPoint(0.5, 0.5)
			var_2_0:setPosition(arg_2_0:getWidth() / 2, arg_2_0:getHeight() / 2)

			local var_2_1 = xyd.AssetLoader.get():loadSprite("windows/common/hero_common/icon_question.png")

			var_2_1:addTo(arg_2_0, var_0_3.AWAKE_HIDE_ICON)
			var_2_1:setPosition(arg_2_0:getWidth() / 2, arg_2_0:getHeight() / 2)

			if arg_2_0:checkAwakeEffect() then
				arg_2_0:addAwakeEffect()
			end
		else
			arg_2_0:createItemIcon(true)

			if arg_2_0:checkYellowPlus() then
				arg_2_0:addPlus("yellow")
			elseif arg_2_0:checkBluePlus() then
				arg_2_0:addPlus("blue")
			end
		end
	else
		arg_2_0:createItemIcon()

		if arg_2_0.isAwakeItem and arg_2_0:checkAwakeTwiceEffect() then
			arg_2_0:addAwakeTwiceEffect()
		end
	end
end

function var_0_0.createItemIcon(arg_3_0, arg_3_1)
	if arg_3_0.tableID == 0 then
		return
	end

	local var_3_0 = xyd.SpriteLoader.new(var_0_2:icon(arg_3_0.tableID), nil, nil, xyd.DefaultImageType.ITEM_ICON, arg_3_0)

	if arg_3_1 then
		local var_3_1 = cc.FileUtils:getInstance():getStringFromFile("shaders/no_mvp.vsh")
		local var_3_2 = cc.FileUtils:getInstance():getStringFromFile("shaders/grayed_sprite.fsh")
		local var_3_3 = cc.GLProgram:createWithByteArrays(var_3_1, var_3_2)
		local var_3_4 = cc.GLProgramState:create(var_3_3)

		var_3_0:setGLProgramState(var_3_4)
	end

	var_3_0:addTo(arg_3_0, var_0_3.ICON_ITEM)
	var_3_0:setAnchorPoint(0.5, 0.5)
	var_3_0:setPosition(arg_3_0:getWidth() / 2, arg_3_0:getHeight() / 2)

	local var_3_5 = (arg_3_0:getWidth() - 10) / var_3_0:getWidth()

	var_3_0:setScale(var_3_5)

	local var_3_6 = xyd.AssetLoader.get():loadSprite(xyd.getItemBorder(var_0_2:quality(arg_3_0.tableID)), nil, extraParmas)

	var_3_6:addTo(arg_3_0, var_0_3.ICON_BORDER)
	var_3_6:setAnchorPoint(0.5, 0.5)
	var_3_6:setPosition(arg_3_0:getWidth() / 2, arg_3_0:getHeight() / 2)

	local var_3_7 = arg_3_0:getWidth() / var_3_6:getWidth()

	var_3_6:setScale(var_3_7)
end

function var_0_0.checkYellowPlus(arg_4_0)
	if arg_4_0.hero:isCollected() and (arg_4_0.hero:isHasItem(arg_4_0.idx) or arg_4_0.hero:canComposeItem(arg_4_0.idx)) and arg_4_0.hero:getLevel() < arg_4_0.item:getLevel() then
		return true
	end

	return false
end

function var_0_0.checkBluePlus(arg_5_0)
	if arg_5_0.hero:isCollected() and (arg_5_0.hero:isHasItem(arg_5_0.idx) or arg_5_0.hero:canComposeItem(arg_5_0.idx)) and arg_5_0.hero:getLevel() >= arg_5_0.item:getLevel() then
		return true
	end

	return false
end

function var_0_0.checkAwakeEffect(arg_6_0)
	if arg_6_0.item:getTableID() ~= 0 and arg_6_0.hero:isCanAwaken() and not arg_6_0.task:isHasAwakeOpen(xyd.AwakeType.HERO) and arg_6_0.hero:getLevel() > xyd.tables.misc.awakenOpenLev then
		return true
	end

	return false
end

function var_0_0.checkAwakeTwiceEffect(arg_7_0)
	if arg_7_0.hero:canOpenAwakeTwiceMission() and not arg_7_0.task:isHasAwakeOpen(xyd.AwakeType.HERO_TWICE) then
		return true
	end

	return false
end

function var_0_0.checkAwakeHide(arg_8_0)
	if arg_8_0.item:getTableID() == 0 or arg_8_0.hero:isCanAwaken() and not arg_8_0.task:isAwaking(arg_8_0.hero:getTableID(), xyd.AwakeType.HERO) and arg_8_0.selfPlayer.maxTeamLev >= 90 then
		return true
	end

	return false
end

function var_0_0.addPlus(arg_9_0, arg_9_1)
	local var_9_0

	if arg_9_1 == "blue" then
		var_9_0 = "windows/common/hero_common/icon_plus_blue.png"
	elseif arg_9_1 == "yellow" then
		var_9_0 = "windows/common/hero_common/icon_plus_yellow.png"
	else
		return
	end

	local var_9_1 = xyd.AssetLoader.get():loadSprite(var_9_0)

	var_9_1:addTo(arg_9_0, var_0_3.PLUS)
	var_9_1:setAnchorPoint(0.5, 0.5)
	var_9_1:setPosition(arg_9_0:getWidth() / 2, arg_9_0:getHeight() / 2)
end

function var_0_0.addAwakeEffect(arg_10_0)
	local var_10_0 = "skeletons/ui_effect/effect_awaken_item/effect_awaken_item_new"
	local var_10_1 = var_0_1.new(var_10_0 .. ".json", var_10_0 .. ".atlas", 1)

	var_10_1:addTo(arg_10_0, var_0_3.AWAKE_EFFECT)
	var_10_1:setAnchorPoint(cc.p(0.5, 0.5))
	var_10_1:setPosition(arg_10_0:getWidth() / 2, arg_10_0:getHeight() / 2)
	var_10_1:play(nil, true)
end

function var_0_0.addAwakeTwiceEffect(arg_11_0)
	local var_11_0 = "skeletons/ui_effect/awake_twice/awake_twice_effect2_new"
	local var_11_1 = var_0_1.new(var_11_0 .. ".json", var_11_0 .. ".atlas", 1)

	var_11_1:addTo(arg_11_0, var_0_3.AWAKE_EFFECT)
	var_11_1:setAnchorPoint(cc.p(0.5, 0.5))
	var_11_1:setPosition(arg_11_0:getWidth() / 2, arg_11_0:getHeight() / 2)
	var_11_1:play(nil, true)
end

return var_0_0
