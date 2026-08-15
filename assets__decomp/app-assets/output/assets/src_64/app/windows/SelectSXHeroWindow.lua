local var_0_0 = class("SelectSXHeroWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = import("app.model.Hero")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.attr
local var_0_5 = 28
local var_0_6 = 10
local var_0_7 = {
	10,
	30,
	80,
	180,
	330
}
local var_0_8 = 260
local var_0_9 = 392
local var_0_10 = 1

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.itemID = arg_1_2.itemID
	arg_1_0.isActivity = arg_1_2.isActivity
	arg_1_0.onlyShow = arg_1_2.onlyShow
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack_ = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.currentIdx = 0
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.heros = {}
	arg_1_0.heroCardBack = {}
	arg_1_0.items = {}

	for iter_1_0 = 1, #xyd.tables.item:gifts(arg_1_0.itemID) do
		arg_1_0.heroCardBack[iter_1_0] = 0
		arg_1_0.items[iter_1_0] = {}
	end

	arg_1_0.modelIsLoad = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("text_mid"):setString(var_0_3:translation("CLICK_HERO_CARD"))

	if arg_3_0.onlyShow then
		arg_3_0:nodeByName("text_mid"):setString(var_0_3:translation("ACTIVITY_HEROSELL__CARD"))
	end

	arg_3_0.itemList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_3_0:nodeByName("list"):getWidth(), arg_3_0:nodeByName("list"):getHeight()),
		direction = cc.ui.UIListView.DIRECTION_HORIZONTAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_3_0:nodeByName("list")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.itemList:setTouchSwallowEnabled(false)
	arg_3_0.itemList:setDelegate(handler(arg_3_0, arg_3_0.delegate))

	arg_3_0.scrollx = 0

	arg_3_0.itemList:reload()
	arg_3_0:nodeByName("select_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_3_0.currentIdx == 0 then
				return
			end

			if arg_3_0.isActivity then
				arg_3_0:activityTouch()
			else
				arg_3_0:backpackTouch()
			end
		end
	end)

	if arg_3_0.onlyShow then
		arg_3_0:nodeByName("select_btn"):setVisible(false)
		arg_3_0:nodeByName("img_select"):setVisible(false)
	end
end

function var_0_0.backpackTouch(arg_5_0)
	local var_5_0 = xyd.tables.item:gifts(arg_5_0.itemID)[arg_5_0.currentIdx]
	local var_5_1 = {
		item_id = arg_5_0.itemID,
		gift_id = var_5_0
	}

	var_5_1.num = 1

	xyd.Backend.get():request(xyd.mid.EXCHAGE_CODE_HERO, var_5_1, function(arg_6_0, arg_6_1)
		if arg_6_0 == xyd.error.OK then
			local var_6_0 = {
				itemNum = 1,
				itemID = var_5_1.item_id
			}

			arg_5_0.selfPlayer:getBackpack():removeItem(var_6_0)
			arg_5_0.selfPlayer:handleRewards(arg_6_1.awards)

			local var_6_1 = xyd.WindowManager.get():getWindow("backpack")

			if var_6_1 then
				var_6_1:updateItemDetail(var_5_1.item_id)
				var_6_1:refreshDisplayOption()
			end

			xyd.WindowManager.get():closeWindow(arg_5_0.name)
		end
	end)
end

function var_0_0.activityTouch(arg_7_0)
	local var_7_0 = xyd.tables.item:gifts(arg_7_0.itemID)[arg_7_0.currentIdx]

	xyd.Backend.get():request(xyd.mid.HERO_SELL_AWARD, {
		gift_id = var_7_0
	}, function(arg_8_0, arg_8_1)
		if arg_8_0 == xyd.error.OK then
			arg_7_0.selfPlayer:handleRewards(arg_8_1.awards)

			if arg_7_0.callback then
				arg_7_0.callback()
			end

			xyd.WindowManager.get():closeWindow(arg_7_0)
		end
	end)
end

function var_0_0.scrollListener(arg_9_0, arg_9_1)
	if arg_9_1.name == "began" then
		arg_9_0.scrollViewMoved_ = false
		arg_9_0.prevX_ = arg_9_1.x
	elseif arg_9_1.name == "moved" then
		arg_9_0.scrollx = arg_9_0.itemList:getScrollNode():getPositionX()

		if 20 <= math.abs(arg_9_1.x - arg_9_0.prevX_) then
			arg_9_0.scrollViewMoved_ = true
		end
	elseif arg_9_1.name == "scrollEnd" then
		arg_9_0.scrollx = arg_9_0.itemList:getScrollNode():getPositionX()
	end
end

function var_0_0.didOpen(arg_10_0, arg_10_1)
	var_0_0.super:didOpen(arg_10_1)
	arg_10_0:addBlockLayer()
end

function var_0_0.delegate(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	local var_11_0 = #xyd.tables.item:gifts(arg_11_0.itemID)

	if cc.ui.UIListView.COUNT_TAG == arg_11_2 then
		return var_11_0
	elseif cc.ui.UIListView.CELL_TAG == arg_11_2 then
		local var_11_1
		local var_11_2
		local var_11_3
		local var_11_4 = arg_11_0.itemList:dequeueItem()

		if not var_11_4 then
			var_11_4 = arg_11_0.itemList:newItem()
		else
			var_11_4:removeAllChildren()
		end

		local var_11_5 = display.newNode()
		local var_11_6 = xyd.tables.gift:items(xyd.tables.item:gifts(arg_11_0.itemID)[arg_11_3])[1]
		local var_11_7 = xyd.tables.item:petID(var_11_6)

		if var_11_7 ~= 0 then
			var_11_6 = var_11_7
		end

		local var_11_8 = xyd.tables.item:gifts(arg_11_0.itemID)[arg_11_3]
		local var_11_9 = display.newNode()

		arg_11_0:initCell(var_11_9, var_11_6, var_11_8, arg_11_3)
		var_11_9:setAnchorPoint(cc.p(0, 0))
		var_11_9:pos(0, 0)
		var_11_5:addChild(var_11_9)
		var_11_9:setName("cell")
		var_11_5:size(var_11_9:getWidth(), var_11_9:getHeight())
		var_11_4:setItemSize(var_11_5:getWidth() + var_0_6, var_11_9:getHeight())
		var_11_5:align(display.CENTER, var_11_4:getWidth() / 2, var_11_4:getHeight() / 2)
		var_11_4:addContent(var_11_5)

		return var_11_4
	end
end

function var_0_0.initCell(arg_12_0, arg_12_1, arg_12_2, arg_12_3, arg_12_4)
	local var_12_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/select_sx/hero_item.csb")
	local var_12_1 = var_12_0:getChildByName("container")
	local var_12_2 = var_12_0:getChildByName("card_container")
	local var_12_3 = var_12_1:getContentSize()

	arg_12_1:setContentSize(var_12_3.width, var_12_3.height)
	var_12_0:setPosition(cc.p(0, 0))
	arg_12_1:addChild(var_12_0)
	var_12_0:setName("layout")

	if arg_12_0.heros[arg_12_4] == nil then
		local var_12_4 = arg_12_2
		local var_12_5 = xyd.tables.gift:itemNum(arg_12_3)[1]
		local var_12_6 = xyd.tables.item:name(var_12_4)
		local var_12_7 = var_0_2.new()

		var_12_7:initUnCollected(var_12_4)

		arg_12_0.heros[arg_12_4] = var_12_7
	end

	arg_12_0.items[arg_12_4].card = {}
	arg_12_0.items[arg_12_4].card = var_12_2

	local var_12_8 = xyd.getHeroCard(arg_12_0.heros[arg_12_4])
	local var_12_9 = var_12_8:getContentSize()

	var_12_8:setScale(var_0_9 / var_12_9.height)
	var_12_8:setPosition(var_0_8 / 2, var_0_9 / 2)
	var_12_8:setAnchorPoint(cc.p(0.5, 0.5))
	var_12_8:setTouchEnabled(true)
	var_12_8:setTouchSwallowEnabled(false)
	var_12_8:addTo(var_12_2)
	var_12_8:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_13_0)
		if arg_13_0.name == "began" then
			return true
		elseif arg_13_0.name == "ended" and not arg_12_0.scrollViewMoved_ then
			local var_13_0 = arg_12_0.currentIdx

			if arg_12_0.heroCardBack[arg_12_4] == 1 then
				arg_12_0.heroCardBack[arg_12_4] = 0
			else
				arg_12_0.heroCardBack[arg_12_4] = 1
			end

			arg_12_0.currentIdx = arg_12_4

			arg_12_0:initAnimation(arg_12_4, var_13_0)
			arg_12_0:initHeroModel(var_12_1, arg_12_4)
		end
	end)

	arg_12_0.heroCardBack[arg_12_4] = 0
	arg_12_0.modelIsLoad[arg_12_4] = nil

	arg_12_0.items[arg_12_4].card:setVisible(true)

	if arg_12_0.items[arg_12_4].model and not tolua.isnull(arg_12_0.items[arg_12_4].model) then
		arg_12_0.items[arg_12_4].model:setVisible(false)
	end

	var_12_1:setVisible(false)

	if not var_12_0:getChildByName("effect") then
		local var_12_10 = "skeletons/ui_effect/summon_hero/common_effect_summon12_02" .. ".json"
		local var_12_11 = "skeletons/ui_effect/summon_hero/common_effect_summon12_02" .. ".atlas"
		local var_12_12 = var_0_1.new(var_12_10, var_12_11, 1)

		var_12_12:setAnchorPoint(cc.p(0, 0))
		var_12_12:setPosition(var_12_3.width / 2 + 1, var_12_3.height / 2 - 10)
		var_12_12:addTo(var_12_0)
		var_12_12:setName("effect")
		var_12_12:setScale(0.6, 0.6)
		var_12_12:play(nil, true)

		arg_12_0.items[arg_12_4].effect = {}
		arg_12_0.items[arg_12_4].effect = var_12_0:getChildByName("effect")
	end

	if arg_12_0.items[arg_12_4].effect then
		if arg_12_4 == arg_12_0.currentIdx then
			arg_12_0.items[arg_12_4].effect:setVisible(true)
		else
			arg_12_0.items[arg_12_4].effect:setVisible(false)
		end
	end
end

function var_0_0.initHeroModel(arg_14_0, arg_14_1, arg_14_2)
	if arg_14_0.modelIsLoad[arg_14_2] then
		return
	else
		arg_14_0.modelIsLoad[arg_14_2] = true
	end

	local var_14_0 = arg_14_0.heros[arg_14_2]:getName()
	local var_14_1 = arg_14_0.heros[arg_14_2]:getDes()
	local var_14_2 = cc.p(arg_14_1:getChildByName("text_pos"):getPosition())
	local var_14_3 = {
		size = 22,
		color = cc.c3b(0, 0, 0),
		text = var_14_1,
		dimensions = cc.size(215, 0),
		x = var_14_2.x,
		y = var_14_2.y,
		align = cc.ui.TEXT_ALIGN_CENTER
	}
	local var_14_4 = xyd.AssetLoader.get():loadLabel(var_14_3)

	var_14_4:addTo(arg_14_1)
	var_14_4:setAnchorPoint(cc.p(0.5, 0.5))
	arg_14_1:getChildByName("text_name"):setString(var_14_0)

	local var_14_5 = arg_14_1:getChildByName("hero_container")
	local var_14_6 = arg_14_0.heros[arg_14_2]:getHeroModel()

	var_14_6:setScale(0.8)
	var_14_5:addChild(var_14_6)
	var_14_6:setPositionX(var_14_5:getContentSize().width / 2)

	arg_14_0.items[arg_14_2].model = {}
	arg_14_0.items[arg_14_2].model = arg_14_1

	local var_14_7 = display.newNode()

	var_14_7:setContentSize(var_0_8, var_0_9)
	var_14_7:setAnchorPoint(cc.p(0, 0))
	var_14_7:setPosition(2, arg_14_1:getContentSize().height - var_0_9 - 20)
	var_14_7:setTouchEnabled(true)
	var_14_7:setTouchSwallowEnabled(false)
	var_14_7:addTo(arg_14_1)
	var_14_7:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_15_0)
		if arg_15_0.name == "began" then
			return true
		elseif arg_15_0.name == "ended" and not arg_14_0.scrollViewMoved_ then
			local var_15_0 = arg_14_0.currentIdx

			arg_14_0.currentIdx = arg_14_2

			if arg_14_0.heroCardBack[arg_14_2] == 1 then
				arg_14_0.heroCardBack[arg_14_2] = 0
			else
				arg_14_0.heroCardBack[arg_14_2] = 1
			end

			arg_14_0:initAnimation(arg_14_2, var_15_0)
		end
	end)
end

function var_0_0.initAnimation(arg_16_0, arg_16_1, arg_16_2)
	local function var_16_0()
		if not arg_16_0.items[arg_16_1].model or tolua.isnull(arg_16_0.items[arg_16_1].model) then
			if arg_16_0.items[arg_16_1].card and not tolua.isnull(arg_16_0.items[arg_16_1].card) then
				arg_16_0.items[arg_16_1].card:setVisible(true)
				arg_16_0.items[arg_16_1].card:runAction(cc.Sequence:create(cc.ScaleTo:create(0.5, 1, 1), cc.CallFunc:create(function()
					return
				end)))
			end
		else
			arg_16_0.items[arg_16_1].model:runAction(cc.Sequence:create(cc.ScaleTo:create(0.5, 0, 1), cc.CallFunc:create(function()
				arg_16_0.items[arg_16_1].model:setVisible(false)

				if arg_16_0.items[arg_16_1].card and not tolua.isnull(arg_16_0.items[arg_16_1].card) then
					arg_16_0.items[arg_16_1].card:setVisible(true)
					arg_16_0.items[arg_16_1].card:runAction(cc.Sequence:create(cc.ScaleTo:create(0.5, 1, 1), cc.CallFunc:create(function()
						return
					end)))
				end
			end)))
		end
	end

	local function var_16_1()
		if arg_16_0.items[arg_16_1].card and not tolua.isnull(arg_16_0.items[arg_16_1].card) then
			arg_16_0.items[arg_16_1].card:runAction(cc.Sequence:create(cc.ScaleTo:create(0.5, 0, 1), cc.CallFunc:create(function()
				arg_16_0.items[arg_16_1].card:setVisible(false)

				if arg_16_0.items[arg_16_1].model and not tolua.isnull(arg_16_0.items[arg_16_1].model) then
					arg_16_0.items[arg_16_1].model:setVisible(true)
					arg_16_0.items[arg_16_1].model:setScale(0, 1)
					arg_16_0.items[arg_16_1].model:runAction(cc.Sequence:create(cc.ScaleTo:create(0.5, 1, 1), cc.CallFunc:create(function()
						return
					end)))
				end
			end)))
		elseif arg_16_0.items[arg_16_1].model and not tolua.isnull(arg_16_0.items[arg_16_1].model) then
			arg_16_0.items[arg_16_1].model:setVisible(true)
			arg_16_0.items[arg_16_1].model:setScale(0, 1)
			arg_16_0.items[arg_16_1].model:runAction(cc.Sequence:create(cc.ScaleTo:create(0.5, 1, 1), cc.CallFunc:create(function()
				return
			end)))
		end
	end

	local var_16_2

	if arg_16_2 ~= arg_16_1 and arg_16_2 ~= 0 and arg_16_0.items[arg_16_2].effect and not tolua.isnull(arg_16_0.items[arg_16_2].effect) then
		arg_16_0.items[arg_16_2].effect:setVisible(false)
	end

	if arg_16_0.items[arg_16_1].effect and not tolua.isnull(arg_16_0.items[arg_16_1].effect) then
		arg_16_0.items[arg_16_1].effect:setVisible(true)
	end

	if arg_16_0.heroCardBack[arg_16_1] == 0 then
		var_16_2 = cc.Spawn:create({
			cc.CallFunc:create(var_16_0)
		})
	else
		var_16_2 = cc.Spawn:create({
			cc.CallFunc:create(var_16_1)
		})
	end

	arg_16_0:runAction(var_16_2)
end

return var_0_0
