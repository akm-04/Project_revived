local var_0_0 = class("JunkChestSkillAlertWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.cabinetSkillTable
local var_0_4 = xyd.tables.item

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.lev = arg_1_2.lev
	arg_1_0.iconType = arg_1_2.iconType
	arg_1_0.redArr = arg_1_2.redArr
	arg_1_0.resType = arg_1_2.resType
	arg_1_0.resNum = arg_1_2.resNum
	arg_1_0.lastId = arg_1_2.lastId
	arg_1_0.skillPageId = arg_1_2.skillPageId
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = #arg_3_0.resType

	for iter_3_0 = 1, 5 do
		arg_3_0:nodeByName("container" .. iter_3_0):setVisible(false)

		local var_3_1, var_3_2 = arg_3_0:nodeByName("container" .. iter_3_0):getPosition()

		arg_3_0:nodeByName("container" .. iter_3_0):setPosition(var_3_1, var_3_2 - math.ceil((5 - var_3_0) / 2) * 70)
	end

	for iter_3_1 = 1, 3 do
		arg_3_0:nodeByName("need_words" .. iter_3_1):setString(var_0_2:translation("NEED"))

		local var_3_3, var_3_4 = arg_3_0:nodeByName("last_skill_container" .. iter_3_1):getPosition()

		arg_3_0:nodeByName("last_skill_container" .. iter_3_1):setPosition(var_3_3, var_3_4 - math.ceil((5 - var_3_0) / 2) * 70)

		if iter_3_1 > #arg_3_0.lastId then
			arg_3_0:nodeByName("last_skill_container" .. iter_3_1):setVisible(false)
		else
			arg_3_0:nodeByName("last_skill_container" .. iter_3_1):setVisible(true)

			if arg_3_0.iconType[iter_3_1] == 1 then
				arg_3_0:nodeByName("lev_text" .. iter_3_1):setColor(xyd.color.RED)
			end

			arg_3_0:nodeByName("lev_text" .. iter_3_1):setString("Lv." .. arg_3_0.lev + 1)

			local var_3_5 = xyd.SpriteLoader.new(var_0_3:icon(arg_3_0.lastId[iter_3_1]), nil, nil, xyd.DefaultImageType.ITEM_ICON)
			local var_3_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/event_centre/junk_chest/skill_item.csb")
			local var_3_7 = cc.p(80, 80)

			var_3_6:setContentSize(var_3_7)

			local var_3_8 = var_3_6:getChildByName("icon")

			stencil = xyd.AssetLoader:get():loadSprite("images/icon_mask2.png")

			stencil:setPosition(var_3_8:getWidth() / 2, var_3_8:getHeight() / 2)
			stencil:setAnchorPoint(cc.p(0.5, 0.5))
			stencil:scale(var_3_8:getWidth() / stencil:getWidth())

			local var_3_9 = cc.ClippingNode:create()

			var_3_9:setStencil(stencil)
			var_3_9:setInverted(true)
			var_3_9:setAlphaThreshold(0)
			var_3_8:addChild(var_3_9)
			var_3_9:addChild(var_3_5)
			var_3_5:align(display.LEFT_BOTTOM, 0, 0)
			var_3_5:scale((var_3_8:getWidth() - 3) / var_3_5:getWidth())
			var_3_6:scale(0.5, 0.5)
			var_3_6:addTo(arg_3_0:nodeByName("icon_node" .. iter_3_1))
			var_3_6:setPosition(arg_3_0:nodeByName("icon_node" .. iter_3_1):getWidth() / 2, arg_3_0:nodeByName("icon_node" .. iter_3_1):getHeight() / 2)
		end
	end

	for iter_3_2, iter_3_3 in pairs(arg_3_0.resType) do
		if iter_3_3 == xyd.currencyType.MAGIC_DUST then
			local var_3_10 = xyd.AssetLoader.get():loadSprite("images/icon/eco/magic_dust.png")

			arg_3_0:nodeByName("node" .. iter_3_2):addChild(var_3_10)
		elseif iter_3_3 == xyd.currencyType.MAGIC_LIQUID then
			local var_3_11 = xyd.AssetLoader.get():loadSprite("images/icon/eco/magic_liquid.png")

			arg_3_0:nodeByName("node" .. iter_3_2):addChild(var_3_11)
		elseif iter_3_3 == xyd.currencyType.MAGIC_ENERGY then
			local var_3_12 = xyd.AssetLoader.get():loadSprite("images/icon/eco/magic_energy.png")

			arg_3_0:nodeByName("node" .. iter_3_2):addChild(var_3_12)
		elseif iter_3_3 == xyd.currencyType.MANA then
			local var_3_13 = xyd.AssetLoader.get():loadSprite("images/icon/eco/jinbi.png")

			arg_3_0:nodeByName("node" .. iter_3_2):addChild(var_3_13)
		elseif iter_3_3 == -1 then
			local var_3_14 = xyd.SpriteLoader.new(var_0_4:icon(arg_3_0.skillPageId), nil, nil, xyd.DefaultImageType.ITEM_ICON)

			var_3_14:setScale(0.6, 0.6)
			arg_3_0:nodeByName("node" .. iter_3_2):addChild(var_3_14)
		end

		arg_3_0:nodeByName("container" .. iter_3_2):setVisible(true)
		arg_3_0:nodeByName("need_num" .. iter_3_2):setString(arg_3_0.resNum[iter_3_2])

		if arg_3_0.redArr[iter_3_2] == 0 then
			arg_3_0:nodeByName("need_num" .. iter_3_2):setColor(xyd.color.RED)
		end
	end

	arg_3_0:nodeByName("container"):height(arg_3_0:nodeByName("container"):getHeight() + 60 * (#arg_3_0.lastId - 3) - math.ceil((5 - var_3_0) / 2) * 70)
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super:didOpen(arg_4_1)
end

return var_0_0
