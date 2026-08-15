local var_0_0 = class("SakuraFruitFactoryWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = "skeletons/ui_effect/vip_box_draw/box_draw_open3"
local var_0_2 = import("framework.scheduler")
local var_0_3 = import("app.common.ui.SpineEffect")
local var_0_4 = xyd.tables.translation
local var_0_5 = 3

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.sakura = xyd.ModelManager.get():loadModel(xyd.ModelType.SAKURA)
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
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.createMakeEffect(arg_3_0)
	if arg_3_0.makeEffect and not tolua.isnull(arg_3_0.makeEffect) then
		arg_3_0.makeEffect:removeFromParent(true)

		arg_3_0.makeEffect = nil
	end

	arg_3_0.makeEffect = arg_3_0:createEffect(var_0_1)

	arg_3_0.makeEffect:addTo(arg_3_0:nodeByName("make_result_pos"))
	arg_3_0.makeEffect:setPosition(cc.p(-2, -6))
	arg_3_0.makeEffect:setName("make_effect")
	arg_3_0.makeEffect:setLocalZOrder(20)
	arg_3_0.makeEffect:play(nil, false)
	arg_3_0.makeEffect:setScale(0.7)
end

function var_0_0.createEffect(arg_4_0, arg_4_1)
	local var_4_0 = arg_4_1 .. ".json"
	local var_4_1 = arg_4_1 .. ".atlas"
	local var_4_2 = var_0_3.new(var_4_0, var_4_1, 1)

	var_4_2:setAnchorPoint(cc.p(0.5, 0.5))

	return var_4_2
end

function var_0_0.layout(arg_5_0)
	arg_5_0:nodeByName("make_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended and arg_5_0.composeItemID then
			local var_6_0 = {
				item_id = arg_5_0.composeItemID
			}

			arg_5_0.sakura:composeItem(var_6_0, function(arg_7_0, arg_7_1)
				if arg_7_0 == xyd.error.OK then
					arg_5_0:playCompose()
					arg_5_0:updateMakeBtnState()
					arg_5_0:updateOwnMaterials()
				end
			end)
		end
	end)
	arg_5_0:nodeByName("close"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended and not arg_5_0.isPlayCompose then
			xyd.WindowManager.get():closeWindow(arg_5_0)
		end
	end)
	arg_5_0:addDialog()
	arg_5_0:updateOwnMaterials()
	arg_5_0:updateMakeContainer()
	arg_5_0:addInnerBg()
end

function var_0_0.addInnerBg(arg_9_0)
	local var_9_0 = math.random(1, 10)

	arg_9_0.dialogBaseCount = 0

	local var_9_1 = xyd.AssetLoader:get():loadSprite("windows/sakura/fruit_factory/inner_bg1.png")

	if var_9_0 == 10 then
		var_9_1 = xyd.AssetLoader:get():loadSprite("windows/sakura/fruit_factory/inner_bg2.png")
		arg_9_0.dialogBaseCount = 4
	end

	var_9_1:setTouchEnabled(true)
	var_9_1:addTo(arg_9_0:nodeByName("inner_bg_pos"))
	var_9_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_10_0)
		if arg_10_0.name == "began" then
			return true
		elseif arg_10_0.name == "ended" then
			local var_10_0 = {
				var_0_4:translation("SAKURA_COOK_DIALOG" .. arg_9_0.dialogBaseCount + 4)
			}

			arg_9_0:speakMsgs(var_10_0)
		end
	end)
end

function var_0_0.addDialog(arg_11_0)
	local var_11_0 = {
		msgs = {
			var_0_4:translation("SAKURA_COOK_DIALOG4")
		},
		times = {
			xyd.tables.misc.dialogDefaultTime
		}
	}

	arg_11_0.speakCellContent = import("app.windows.SpeakCell").new(var_11_0)

	arg_11_0.speakCellContent:addTo(arg_11_0:nodeByName("inner_bg_pos"))
	arg_11_0.speakCellContent:setAnchorPoint(cc.p(0.5, 0.5))
	arg_11_0.speakCellContent:setPosition(-130, -70)
	arg_11_0.speakCellContent:setLocalZOrder(20)
end

function var_0_0.speakMsgs(arg_12_0, arg_12_1)
	arg_12_0.speakCellContent:setMsgsParams(arg_12_1)
	arg_12_0.speakCellContent:onclick()
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

				local var_14_0 = {
					var_0_4:translation("SAKURA_COOK_DIALOG" .. arg_13_0.dialogBaseCount + iter_13_1)
				}

				arg_13_0:speakMsgs(var_14_0)
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

	arg_15_0.composeItemID = xyd.tables.activitySakura2Cook:canCompose(var_15_0)

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
		else
			xyd.setSpriteBorder(var_16_0, "windows/sakura/fruit_factory/unknow_bg.png", xyd.tables.item:quality(arg_16_0.composeItemID))
		end

		local var_16_3 = arg_16_0:createItemNameLabel(arg_16_0.composeItemID)

		var_16_3:setAnchorPoint(cc.p(0.5, 0))
		var_16_3:addTo(arg_16_0:nodeByName("make_result_pos"))
		var_16_3:setPosition(0, -90)
		var_16_3:enableOutline(arg_16_0.sakura.outlineColor, arg_16_0.sakura.outlineSize)
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

function var_0_0.playCompose(arg_18_0)
	arg_18_0.isPlayCompose = true

	arg_18_0:nodeByName("make_btn"):setBright(false)
	arg_18_0:nodeByName("make_btn"):setTouchEnabled(false)

	local var_18_0 = 1

	for iter_18_0 = 1, #arg_18_0.materials do
		if arg_18_0.isSelected[iter_18_0] then
			local var_18_1 = display.newNode()

			var_18_1:setContentSize(100, 100)
			xyd.setItemBorder(var_18_1, arg_18_0.materials[iter_18_0])
			var_18_1:setAnchorPoint(cc.p(0.5, 0.5))
			var_18_1:addTo(arg_18_0:nodeByName("make_container"))
			var_18_1:setPosition(arg_18_0:nodeByName("item_pos" .. iter_18_0):getPosition())
			var_18_1:setOpacity(0)
			var_18_1:runAction(cc.MoveTo:create(var_18_0, cc.p(arg_18_0:nodeByName("make_result_pos"):getPosition())))
			table.insert(arg_18_0.tmpItems, var_18_1)
		end
	end

	var_0_2.performWithDelayGlobal(function()
		arg_18_0:clearTmpItems()
		arg_18_0:nodeByName("make_result_pos"):removeAllChildren(true)

		local var_19_0 = display.newNode()

		var_19_0:setContentSize(100, 100)
		xyd.setItemBorder(var_19_0, arg_18_0.composeItemID)
		var_19_0:setAnchorPoint(cc.p(0.5, 0.5))
		var_19_0:addTo(arg_18_0:nodeByName("make_result_pos"))
		xyd.setCascadeOpacityEnabled(var_19_0, true)
		var_19_0:setOpacity(0)

		local var_19_1 = arg_18_0:createItemNameLabel(arg_18_0.composeItemID)

		var_19_1:setAnchorPoint(cc.p(0.5, 0))
		var_19_1:addTo(arg_18_0:nodeByName("make_result_pos"))
		var_19_1:setPosition(0, -90)
		var_19_0:runActionOnce(cc.Sequence:create({
			cc.FadeIn:create(var_18_0),
			cc.CallFunc:create(function()
				arg_18_0.isPlayCompose = false

				local var_20_0 = {
					item_num = 1,
					table_id = arg_18_0.composeItemID
				}

				arg_18_0.selfPlayer:handleRewards({
					var_20_0
				})
				arg_18_0:updateMakeContainer()
			end)
		}))
		arg_18_0:createMakeEffect()
	end, 1.2)
end

function var_0_0.updateMakeBtnState(arg_21_0)
	if arg_21_0.composeItemID and not arg_21_0.isPlayCompose then
		arg_21_0:nodeByName("make_btn"):setBright(true)
		arg_21_0:nodeByName("make_btn"):setTouchEnabled(true)
		arg_21_0:nodeByName("make_text"):setVisible(true)
		arg_21_0:nodeByName("make_gray_text"):setVisible(false)
	else
		arg_21_0:nodeByName("make_btn"):setBright(false)
		arg_21_0:nodeByName("make_btn"):setTouchEnabled(false)
		arg_21_0:nodeByName("make_text"):setVisible(false)
		arg_21_0:nodeByName("make_gray_text"):setVisible(true)
	end
end

function var_0_0.clearTmpItems(arg_22_0)
	for iter_22_0, iter_22_1 in pairs(arg_22_0.tmpItems) do
		iter_22_1:removeFromParent(true)
	end

	arg_22_0.tmpItems = {}
end

return var_0_0
