local var_0_0 = class("AwakeCompleteWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = import("app.model.Pet")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.skill
local var_0_5 = 5

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.oldHeroID = arg_1_2.oldHeroID
	arg_1_0.newHeroID = arg_1_2.newHeroID
	arg_1_0.isPet = arg_1_2.isPet
	arg_1_0.oldHeroForce = arg_1_2.oldHeroForce
	arg_1_0.hero = arg_1_2.hero
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer(nil, nil, true)
end

function var_0_0.playEffect(arg_3_0)
	local var_3_0 = arg_3_0:nodeByName("background")
	local var_3_1 = var_3_0:getContentSize()
	local var_3_2
	local var_3_3 = arg_3_0.isPet and "skeletons/ui_effect/awake/pet_awaken" or "skeletons/ui_effect/awake/character_awaken"
	local var_3_4 = var_0_1.new(var_3_3 .. ".json", var_3_3 .. ".atlas", 1)

	var_3_4:setAnchorPoint(0.5, 0.5)
	var_3_4:setPosition(var_3_1.width / 2, var_3_1.height - 20)
	var_3_0:addChild(var_3_4, 0)
	var_3_4:play(function()
		var_3_4:play(nil, true, nil, "texiao02")
	end, false, nil, "texiao01")
end

function var_0_0.layout(arg_5_0)
	arg_5_0:nodeByName("new_skill_words"):setString(var_0_3:translation("ALREADY_UNLOCK_AWAKE_SKILL"))
	arg_5_0:nodeByName("power_words"):setString(var_0_3:translation("HERO_MAIN_TEXT_11"))

	local var_5_0 = arg_5_0:nodeByName("from_icon_container")
	local var_5_1 = arg_5_0:nodeByName("to_icon_container")
	local var_5_2 = arg_5_0.hero

	if not arg_5_0.isPet then
		var_5_2 = var_5_2 or arg_5_0.player:getHeroByTableID(arg_5_0.newHeroID)

		xyd.setAvatarBorderNewUI(arg_5_0.oldHeroID, var_5_0, var_5_2:getColor(), var_5_2:getStar())
		xyd.setAvatarBorderNewUI(arg_5_0.newHeroID, var_5_1, var_5_2:getColor(), var_5_2:getStar())
	else
		var_5_2 = var_5_2 or arg_5_0.player:getPetByTableID(arg_5_0.newHeroID)

		xyd.setPetAvatarNewUI(var_5_0, var_5_2, nil, true, true)
		xyd.setPetAvatarNewUI(var_5_1, var_5_2, nil, true)
	end

	arg_5_0:nodeByName("power_num_from_text"):setString(arg_5_0.oldHeroForce)
	arg_5_0:nodeByName("power_num_to_text"):setString(var_5_2:getZhandouli())
	arg_5_0:fillFooter(var_0_5)
	arg_5_0:playEffect()
end

function var_0_0.fillFooter(arg_6_0, arg_6_1)
	local var_6_0 = arg_6_0:nodeByName("skill_container")
	local var_6_1 = arg_6_0:nodeByName("skill_text")
	local var_6_2 = xyd.tables.hero:getSkill(arg_6_0.newHeroID, 5)

	arg_6_0:nodeByName("skill_des_text"):setString(var_0_4:desc(var_6_2))
	xyd.setSkillBorder(var_6_0, var_6_2, arg_6_1)
	var_6_1:setString(var_0_3:translation("NEW_SKILL") .. var_0_4:name(var_6_2))
	var_6_1:enableOutline(cc.c4b(71, 78, 84, 255), 2)
end

return var_0_0
