local var_0_0 = class("JunkChestSkillUpOkWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.cabinetSkillTable

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.eventCentre = xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.skillId = arg_1_0.eventCentre.recentCompleteSkill
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	local var_4_0 = xyd.AssetLoader.get():loadSprite(var_0_3:icon(arg_4_0.skillId))
	local var_4_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/event_centre/junk_chest/skill_item.csb")
	local var_4_2 = cc.p(80, 80)

	var_4_1:setContentSize(var_4_2)

	local var_4_3 = var_4_1:getChildByName("icon")

	stencil = xyd.AssetLoader:get():loadSprite("images/icon_mask2.png")

	stencil:setPosition(var_4_3:getWidth() / 2, var_4_3:getHeight() / 2)
	stencil:setAnchorPoint(cc.p(0.5, 0.5))
	stencil:scale(var_4_3:getWidth() / stencil:getWidth())

	local var_4_4 = cc.ClippingNode:create()

	var_4_4:setStencil(stencil)
	var_4_4:setInverted(true)
	var_4_4:setAlphaThreshold(0)
	var_4_3:addChild(var_4_4)
	var_4_4:addChild(var_4_0)
	var_4_0:align(display.LEFT_BOTTOM, 0, 0)
	var_4_0:scale((var_4_3:getWidth() - 3) / var_4_0:getWidth())
	var_4_1:scale(arg_4_0:nodeByName("avatar_icon"):getWidth() / var_4_3:getWidth())
	arg_4_0:nodeByName("avatar_icon"):removeAllChildren()
	var_4_1:addTo(arg_4_0:nodeByName("avatar_icon"))
	var_4_1:setPosition(arg_4_0:nodeByName("avatar_icon"):getWidth() / 2, arg_4_0:nodeByName("avatar_icon"):getHeight() / 2)
	arg_4_0:nodeByName("skill_name_text"):setString(var_0_3:name(arg_4_0.skillId))

	local var_4_5 = var_0_3:skillbook(arg_4_0.skillId)
	local var_4_6 = arg_4_0.eventCentre.allBooks[var_4_5].skills[arg_4_0.skillId].lev
	local var_4_7 = math.max(var_4_6, 1)

	arg_4_0:nodeByName("skill_lev_text"):setString("Lv. " .. var_4_7)
	arg_4_0:nodeByName("ability_text"):setString(string.format(var_0_3:desc2(arg_4_0.skillId), var_0_3:attrValues(arg_4_0.skillId) * var_4_7))
	arg_4_0:nodeByName("knowlage_text"):setString(string.format(var_0_2:translation("GET_KNOWLEDGE_EXP"), xyd.tables.misc.eventCentreSkillExp[var_4_7]))
end

return var_0_0
