local var_0_0 = class("WorldBossDesWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.des = arg_1_2.des
	arg_1_0.skills = arg_1_2.skills
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	arg_2_0.WorldBoss = xyd.ModelManager.get():loadModel(xyd.ModelType.WORLD_BOSS)

	arg_2_0:init()
end

function var_0_0.init(arg_3_0)
	arg_3_0:nodeByName("des_text"):setString(arg_3_0.des)
	arg_3_0:nodeByName("des_words"):setString(var_0_2:translation("WORLD_BOSS_DES_WORDS"))
	arg_3_0:nodeByName("skill_words"):setString(var_0_2:translation("WORLD_BOSS_SKILL_WORDS"))

	arg_3_0.skillContainer = arg_3_0:nodeByName("skills_container")

	arg_3_0:setSkillContainer(arg_3_0.skills)
end

function var_0_0.setSkillContainer(arg_4_0, arg_4_1)
	local var_4_0 = arg_4_1
	local var_4_1 = {}

	arg_4_0.skillItems = {}

	local var_4_2 = arg_4_0.skillContainer:getChildren()
	local var_4_3 = arg_4_0.skillContainer:getHeight()

	for iter_4_0, iter_4_1 in pairs(var_4_0) do
		local var_4_4 = display.newNode()

		var_4_4:setContentSize(var_4_3, var_4_3)

		local var_4_5 = xyd.tables.skill:icon(iter_4_1)

		if var_4_5 and var_4_5 ~= "" then
			local var_4_6 = xyd.AssetLoader.get():loadSprite(var_4_5)
			local var_4_7 = xyd.AssetLoader.get():loadSprite("windows/hero/skill_icon.png")

			var_4_7:setPosition(var_4_4:getWidth() / 2, var_4_4:getHeight() / 2)
			var_4_7:setAnchorPoint(cc.p(0.5, 0.5))
			var_4_7:scale(var_4_4:getWidth() / var_4_7:getWidth() / 20 * 19)

			stencil = xyd.AssetLoader:get():loadSprite("images/icon_mask2.png")

			stencil:setPosition(var_4_4:getWidth() / 2, var_4_4:getHeight() / 2)
			stencil:setAnchorPoint(cc.p(0.5, 0.5))
			stencil:scale(var_4_4:getWidth() / stencil:getWidth())

			local var_4_8 = cc.ClippingNode:create()

			var_4_8:setStencil(stencil)
			var_4_8:setInverted(true)
			var_4_8:setAlphaThreshold(0)
			var_4_4:addChild(var_4_8)
			var_4_8:addChild(var_4_6)
			var_4_6:align(display.LEFT_BOTTOM, 0, 0)
			var_4_6:scale((var_4_4:getWidth() - 3) / var_4_6:getWidth())
			var_4_4:addTo(arg_4_0.skillContainer)
			var_4_7:addTo(var_4_4)
			table.insert(arg_4_0.skillItems, var_4_4)
			var_4_4:x((iter_4_0 - 1) * (var_4_3 + 10) + 20)
			var_4_4:y(0)
			arg_4_0:createSkillTip(iter_4_0, iter_4_1)
		end
	end
end

function var_0_0.createSkillTip(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = {
		has_jiantou = false,
		id = arg_5_2
	}
	local var_5_1 = arg_5_0.skillItems[arg_5_1]
	local var_5_2, var_5_3 = var_5_1:getPosition()
	local var_5_4, var_5_5 = arg_5_0.skillContainer:getPosition()
	local var_5_6 = var_5_2 + var_5_4
	local var_5_7 = var_5_3 + var_5_5
	local var_5_8 = display.newNode()

	var_5_8:setPosition(0, 0)
	var_5_8:setAnchorPoint(cc.p(0, 0))
	var_5_8:setContentSize(var_5_1:getContentSize())
	var_5_8:setTouchEnabled(true)
	var_5_8:addTo(var_5_1)
	var_5_8:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		if arg_6_0.name == "began" then
			if not xyd.WindowManager.get():getWindow("skill_tips") then
				local var_6_0 = xyd.WindowManager.get():openWindow("skill_tips", var_5_0)

				xyd.adaptToWorldPosition(var_5_8, var_6_0)
			end

			return true
		elseif arg_6_0.name == "ended" then
			xyd.WindowManager.get():closeWindow("skill_tips")
		end
	end)
end

function var_0_0.didOpen(arg_7_0, arg_7_1)
	var_0_0.super:didOpen(arg_7_1)
	arg_7_0:addBlockLayer()
end

return var_0_0
