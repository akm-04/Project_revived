local var_0_0 = class("SakuraFruitFactoryWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = "skeletons/ui_effect/vip_box_draw/box_draw_open3"
local var_0_2 = import("framework.scheduler")
local var_0_3 = import("app.common.ui.SpineEffect")
local var_0_4 = xyd.tables.translation
local var_0_5 = 3

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.sakura = xyd.ModelManager.get():loadModel(xyd.ModelType.SAKURA2018)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.materials = xyd.tables.misc.activitySakura2CookMaterial
	arg_1_0.isSelected = {
		false,
		false,
		false
	}
	arg_1_0.composeItemID = nil
	arg_1_0.tmpItems = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.createMakeEffect(arg_4_0)
	if arg_4_0.makeEffect and not tolua.isnull(arg_4_0.makeEffect) then
		arg_4_0.makeEffect:removeFromParent(true)

		arg_4_0.makeEffect = nil
	end

	arg_4_0.makeEffect = arg_4_0:createEffect(var_0_1)

	arg_4_0.makeEffect:addTo(arg_4_0:nodeByName("make_result_pos"))
	arg_4_0.makeEffect:setPosition(cc.p(-2, -6))
	arg_4_0.makeEffect:setName("make_effect")
	arg_4_0.makeEffect:setLocalZOrder(20)
	arg_4_0.makeEffect:play(nil, false)
	arg_4_0.makeEffect:setScale(0.7)
end

function var_0_0.createEffect(arg_5_0, arg_5_1)
	local var_5_0 = arg_5_1 .. ".json"
	local var_5_1 = arg_5_1 .. ".atlas"
	local var_5_2 = var_0_3.new(var_5_0, var_5_1, 1)

	var_5_2:setAnchorPoint(cc.p(0.5, 0.5))

	return var_5_2
end

function var_0_0.layout(arg_6_0)
	local var_6_0 = arg_6_0:nodeByName("close_btn")

	var_6_0:addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(var_6_0, arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():closeWindow(arg_6_0)
		end
	end)

	local var_6_1 = arg_6_0:nodeByName("make_btn")

	var_6_1:getChildByName("txt"):setString(var_0_4:translation("MAKE"))
	var_6_1:addTouchEventListener(function(arg_8_0, arg_8_1)
		xyd.buttonScaleAnim(var_6_1, arg_8_1)

		if arg_8_1 == ccui.TouchEventType.ended and arg_6_0.composeItemID and arg_6_0.composeItemID then
			local var_8_0 = {
				item_id = arg_6_0.composeItemID
			}

			arg_6_0.sakura:composeItem(var_8_0, function(arg_9_0, arg_9_1)
				if arg_9_0 == xyd.error.OK then
					arg_6_0:playCompose()
					arg_6_0:updateMakeBtnState()
					arg_6_0:updateOwnMaterials()
				end
			end)
		end
	end)

	local var_6_2 = arg_6_0:nodeByName("exchange_btn")

	var_6_2:getChildByName("txt"):setString(var_0_4:translation("EXCHANGE_AWARD"))
	var_6_2:addTouchEventListener(function(arg_10_0, arg_10_1)
		xyd.buttonScaleAnim(var_6_2, arg_10_1)

		if arg_10_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("sakura2018_exchange")
		end
	end)
	arg_6_0:nodeByName("satisfaction_txt"):enableOutline(cc.c4b(127, 96, 204, 255), 2)
	arg_6_0:updateOwnMaterials()
	arg_6_0:updateMakeContainer()
	arg_6_0:updatePoints()
end

function var_0_0.addModel(arg_11_0)
	local var_11_0 = xyd.tables.misc.activitySakura2SitModel[2]

	arg_11_0.heroModel = xyd.HeroAnimation.new(nil, var_11_0, 0.7, {})

	arg_11_0.heroModel:addTo(arg_11_0:nodeByName("inner_bg_pos"))
	arg_11_0.heroModel:setPosition(cc.p(-100, -50))
	arg_11_0.heroModel:playAnimation_("idle", true)
end

function var_0_0.updatePoints(arg_12_0)
	arg_12_0:nodeByName("satisfaction_txt"):setString(string.format(var_0_4:translation("SAKURA2018_OWN_POINT_TXT1"), arg_12_0.sakura.details.base_info.satisfy))
end

function var_0_0.updateOwnMaterials(arg_13_0)
	for iter_13_0 = 1, var_0_5 do
		arg_13_0:nodeByName("item_pos" .. iter_13_0):removeAllChildren(true)
	end

	for iter_13_1 = 1, #arg_13_0.materials do
		local var_13_0 = arg_13_0.sakura:createMaterialsItemContent(arg_13_0.materials[iter_13_1])

		var_13_0:setAnchorPoint(cc.p(0.5, 0.7))
		var_13_0:addTo(arg_13_0:nodeByName("item_pos" .. iter_13_1))
		var_13_0:setName("material")
		var_13_0:getChildByName("source"):getChildByName("container"):getChildByName("select"):setVisible(false)
		var_13_0:setTouchEnabled(true)
		var_13_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_14_0)
			if arg_14_0.name == "began" then
				return true
			elseif arg_14_0.name == "ended" and not arg_13_0.isPlayCompose then
				arg_13_0.isSelected[iter_13_1] = not arg_13_0.isSelected[iter_13_1]

				arg_13_0:updateMakeContainer()
			end
		end)
	end
end

function var_0_0.updateMakeContainer(arg_15_0)
	local var_15_0 = {}

	for iter_15_0 = 1, #arg_15_0.materials do
		local var_15_1 = arg_15_0:nodeByName("item_pos" .. iter_15_0):getChildByName("material"):getChildByName("source"):getChildByName("container"):getChildByName("select")

		if arg_15_0.backpack:getItemNumByID(arg_15_0.materials[iter_15_0]) <= 0 then
			arg_15_0.isSelected[iter_15_0] = false
		end

		if arg_15_0.isSelected[iter_15_0] then
			var_15_1:setVisible(true)
			table.insert(var_15_0, arg_15_0.materials[iter_15_0])
		else
			var_15_1:setVisible(false)
		end
	end

	arg_15_0.composeItemID = xyd.tables.activitySakura3Cook:canCompose(var_15_0)

	arg_15_0:updateComposeResult()
	arg_15_0:updateMakeBtnState()
end

function var_0_0.updateComposeResult(arg_16_0)
	arg_16_0:nodeByName("make_result_pos"):removeAllChildren(true)

	local var_16_0 = display.newNode()

	var_16_0:setContentSize(100, 100)
	var_16_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_16_0:addTo(arg_16_0:nodeByName("make_result_pos"))

	if not arg_16_0.composeItemID then
		xyd.setSpriteBorder(var_16_0, "windows/sakura/fruit_factory/no_item_bg.png", 1)

		local var_16_1 = {
			font = "fonts/main_font.ttf",
			size = 24,
			color = cc.c3b(255, 255, 255)
		}
		local var_16_2 = xyd.AssetLoader.get():loadLabel(var_16_1)

		var_16_2:setString(var_0_4:translation("SAKURA_MAKE_TIP"))
		var_16_2:setAnchorPoint(cc.p(0.5, 0))
		var_16_2:addTo(arg_16_0:nodeByName("make_result_pos"))
		var_16_2:setPosition(0, -90)
		var_16_2:enableOutline(arg_16_0.sakura.outlineColor, arg_16_0.sakura.outlineSize)
	else
		if arg_16_0.sakura:isItemMaked(arg_16_0.composeItemID) then
			xyd.setItemAndAddTips(var_16_0, arg_16_0.composeItemID)

			local var_16_3 = {
				font = "fonts/main_font.ttf",
				size = 24,
				color = cc.c3b(255, 255, 255)
			}
			local var_16_4 = xyd.tables.activitySakura3Cook:satisfaction(arg_16_0.composeItemID)
			local var_16_5 = xyd.AssetLoader.get():loadLabel(var_16_3)

			var_16_5:setString(string.format(var_0_4:translation("SAKURA2018_GET_POINT_TXT"), var_16_4))
			var_16_5:setAnchorPoint(cc.p(0.5, 0))
			var_16_5:addTo(arg_16_0:nodeByName("make_result_pos"))
			var_16_5:setPosition(0, -120)
			var_16_5:enableOutline(arg_16_0.sakura.outlineColor, arg_16_0.sakura.outlineSize)
		else
			xyd.setSpriteBorder(var_16_0, "windows/sakura/fruit_factory/unknow_bg.png", xyd.tables.item:quality(arg_16_0.composeItemID))
		end

		local var_16_6 = arg_16_0:createItemNameLabel(arg_16_0.composeItemID)

		var_16_6:setAnchorPoint(cc.p(0.5, 0))
		var_16_6:addTo(arg_16_0:nodeByName("make_result_pos"))
		var_16_6:setPosition(0, -90)
		var_16_6:enableOutline(arg_16_0.sakura.outlineColor, arg_16_0.sakura.outlineSize)
	end
end

function var_0_0.createItemNameLabel(arg_17_0, arg_17_1)
	local var_17_0 = {
		font = "fonts/main_font.ttf",
		size = 24,
		color = cc.c3b(255, 255, 255)
	}
	local var_17_1 = xyd.AssetLoader.get():loadLabel(var_17_0)

	var_17_1:setString(xyd.tables.item:name(arg_17_1))

	return var_17_1
end

function var_0_0.createAwardPointLabel(arg_18_0, arg_18_1)
	local var_18_0 = {
		font = "fonts/main_font.ttf",
		size = 24,
		color = cc.c3b(255, 255, 255)
	}
	local var_18_1 = xyd.AssetLoader.get():loadLabel(var_18_0)

	var_18_1:setString(xyd.tables.item:name(arg_18_1))

	return var_18_1
end

function var_0_0.playCompose(arg_19_0)
	arg_19_0.isPlayCompose = true

	arg_19_0:nodeByName("make_btn"):setBright(false)
	arg_19_0:nodeByName("make_btn"):setTouchEnabled(false)

	local var_19_0 = 1

	for iter_19_0 = 1, #arg_19_0.materials do
		if arg_19_0.isSelected[iter_19_0] then
			local var_19_1 = display.newNode()

			var_19_1:setContentSize(100, 100)
			xyd.setItemBorder(var_19_1, arg_19_0.materials[iter_19_0])
			var_19_1:setAnchorPoint(cc.p(0.5, 0.5))
			var_19_1:addTo(arg_19_0:nodeByName("make_container"))
			var_19_1:setPosition(arg_19_0:nodeByName("item_pos" .. iter_19_0):getPosition())
			var_19_1:setOpacity(0)
			var_19_1:runAction(cc.MoveTo:create(var_19_0, cc.p(arg_19_0:nodeByName("make_result_pos"):getPosition())))
			table.insert(arg_19_0.tmpItems, var_19_1)
		end
	end

	var_0_2.performWithDelayGlobal(function()
		if not arg_19_0 or tolua.isnull(arg_19_0) then
			return
		end

		arg_19_0:clearTmpItems()
		arg_19_0:nodeByName("make_result_pos"):removeAllChildren(true)

		local var_20_0 = display.newNode()

		var_20_0:setContentSize(100, 100)
		xyd.setItemBorder(var_20_0, arg_19_0.composeItemID)
		var_20_0:setAnchorPoint(cc.p(0.5, 0.5))
		var_20_0:addTo(arg_19_0:nodeByName("make_result_pos"))
		xyd.setCascadeOpacityEnabled(var_20_0, true)
		var_20_0:setOpacity(0)

		local var_20_1 = arg_19_0:createItemNameLabel(arg_19_0.composeItemID)

		var_20_1:setAnchorPoint(cc.p(0.5, 0))
		var_20_1:addTo(arg_19_0:nodeByName("make_result_pos"))
		var_20_1:setPosition(0, -90)
		var_20_0:runActionOnce(cc.Sequence:create({
			cc.FadeIn:create(var_19_0),
			cc.CallFunc:create(function()
				arg_19_0.isPlayCompose = false

				arg_19_0:updateMakeContainer()
				arg_19_0:updatePoints()
			end)
		}))
		arg_19_0:createMakeEffect()
	end, 1.2)
end

function var_0_0.updateMakeBtnState(arg_22_0)
	if arg_22_0.composeItemID and not arg_22_0.isPlayCompose then
		arg_22_0:nodeByName("make_btn"):setBright(true)
		arg_22_0:nodeByName("make_btn"):setTouchEnabled(true)
	else
		arg_22_0:nodeByName("make_btn"):setBright(false)
		arg_22_0:nodeByName("make_btn"):setTouchEnabled(false)
	end
end

function var_0_0.clearTmpItems(arg_23_0)
	for iter_23_0, iter_23_1 in pairs(arg_23_0.tmpItems) do
		iter_23_1:removeFromParent(true)
	end

	arg_23_0.tmpItems = {}
end

return var_0_0
