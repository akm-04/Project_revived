local var_0_0 = class("ActivitySelectHeroWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.attr
local var_0_4 = 28
local var_0_5 = 5
local var_0_6 = {
	10,
	30,
	80,
	180,
	330
}
local var_0_7 = 287
local var_0_8 = 425
local var_0_9 = 1

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.itemID = arg_1_2.itemID
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
	arg_3_0:nodeByName("text_mid"):setString(var_0_2:translation("CLICK_HERO_CARD"))

	if arg_3_0.onlyShow then
		arg_3_0:nodeByName("text_mid"):setString(var_0_2:translation("ACTIVITY_HEROSELL__CARD"))
	end

	arg_3_0:nodeByName("txt_select"):setString(var_0_2:translation("ACTIVITY_HEROSELL_TIP2"))
	arg_3_0:nodeByName("txt_title"):setString(var_0_2:translation("ACTIVITY_HEROSELL_TIP1"))
	arg_3_0:nodeByName("txt_title"):enableOutline(cc.c4b(104, 67, 37, 255), 2)

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
		xyd.buttonScaleAnim(arg_4_0, arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_3_0.currentIdx == 0 then
				return
			end

			arg_3_0:activityTouch()
		end
	end)

	if arg_3_0.onlyShow then
		arg_3_0:nodeByName("select_btn"):setVisible(false)
		arg_3_0:nodeByName("line"):setVisible(false)
	end
end

function var_0_0.activityTouch(arg_5_0)
	local var_5_0 = xyd.tables.item:gifts(arg_5_0.itemID)[arg_5_0.currentIdx]

	xyd.Backend.get():request(xyd.mid.HERO_SELL_AWARD, {
		gift_id = var_5_0
	}, function(arg_6_0, arg_6_1)
		if arg_6_0 == xyd.error.OK then
			arg_5_0.selfPlayer:handleRewards(arg_6_1.awards)

			if arg_5_0.callback then
				arg_5_0.callback()
			end

			xyd.WindowManager.get():closeWindow(arg_5_0)
		end
	end)
end

function var_0_0.scrollListener(arg_7_0, arg_7_1)
	if arg_7_1.name == "began" then
		arg_7_0.scrollViewMoved_ = false
		arg_7_0.prevX_ = arg_7_1.x
	elseif arg_7_1.name == "moved" then
		arg_7_0.scrollx = arg_7_0.itemList:getScrollNode():getPositionX()

		if 20 <= math.abs(arg_7_1.x - arg_7_0.prevX_) then
			arg_7_0.scrollViewMoved_ = true
		end
	elseif arg_7_1.name == "scrollEnd" then
		arg_7_0.scrollx = arg_7_0.itemList:getScrollNode():getPositionX()
	end
end

function var_0_0.didOpen(arg_8_0, arg_8_1)
	var_0_0.super:didOpen(arg_8_1)
	arg_8_0:addBlockLayer()
end

function var_0_0.delegate(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	local var_9_0 = #xyd.tables.item:gifts(arg_9_0.itemID)

	if cc.ui.UIListView.COUNT_TAG == arg_9_2 then
		return var_9_0
	elseif cc.ui.UIListView.CELL_TAG == arg_9_2 then
		local var_9_1
		local var_9_2
		local var_9_3
		local var_9_4 = arg_9_0.itemList:dequeueItem()

		if not var_9_4 then
			var_9_4 = arg_9_0.itemList:newItem()
		else
			var_9_4:removeAllChildren()
		end

		local var_9_5 = display.newNode()
		local var_9_6 = xyd.tables.gift:items(xyd.tables.item:gifts(arg_9_0.itemID)[arg_9_3])[1]
		local var_9_7 = xyd.tables.item:petID(var_9_6)

		if var_9_7 ~= 0 then
			var_9_6 = var_9_7
		end

		local var_9_8 = xyd.tables.item:gifts(arg_9_0.itemID)[arg_9_3]
		local var_9_9 = display.newNode()

		arg_9_0:initCell(var_9_9, var_9_6, var_9_8, arg_9_3)
		var_9_9:setAnchorPoint(cc.p(0, 0))
		var_9_9:pos(0, 0)
		var_9_5:addChild(var_9_9)
		var_9_9:setName("cell")
		var_9_5:size(var_9_9:getWidth(), var_9_9:getHeight())
		var_9_4:setItemSize(var_9_5:getWidth() + var_0_5, var_9_9:getHeight())
		var_9_5:align(display.CENTER, var_9_4:getWidth() / 2, var_9_4:getHeight() / 2)
		var_9_4:addContent(var_9_5)

		return var_9_4
	end
end

function var_0_0.initCell(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4)
	local var_10_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1040/hero_item.csb")
	local var_10_1 = var_10_0:getChildByName("container")
	local var_10_2 = var_10_0:getChildByName("card_container")
	local var_10_3 = var_10_1:getContentSize()

	arg_10_1:setContentSize(var_10_3.width, var_10_3.height)
	var_10_0:setPosition(cc.p(0, 0))
	arg_10_1:addChild(var_10_0)
	var_10_0:setName("layout")

	if arg_10_0.heros[arg_10_4] == nil then
		local var_10_4 = arg_10_2
		local var_10_5 = xyd.tables.gift:itemNum(arg_10_3)[1]
		local var_10_6 = xyd.tables.item:name(var_10_4)
		local var_10_7 = var_0_1.new()

		var_10_7:initUnCollected(var_10_4)

		arg_10_0.heros[arg_10_4] = var_10_7
	end

	arg_10_0.items[arg_10_4].card = {}
	arg_10_0.items[arg_10_4].card = var_10_2

	local var_10_8 = xyd.getHeroCard(arg_10_0.heros[arg_10_4])
	local var_10_9 = var_10_8:getContentSize()

	var_10_8:setScale(var_0_8 / var_10_9.height)
	var_10_8:setPosition(var_0_7 / 2, var_0_8 / 2)
	var_10_8:setAnchorPoint(cc.p(0.5, 0.5))
	var_10_8:setTouchEnabled(true)
	var_10_8:setTouchSwallowEnabled(false)
	var_10_8:addTo(var_10_2)
	var_10_8:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_11_0)
		if arg_11_0.name == "began" then
			return true
		elseif arg_11_0.name == "ended" and not arg_10_0.scrollViewMoved_ then
			local var_11_0 = arg_10_0.currentIdx

			if arg_10_0.heroCardBack[arg_10_4] == 1 then
				arg_10_0.heroCardBack[arg_10_4] = 0
			else
				arg_10_0.heroCardBack[arg_10_4] = 1
			end

			arg_10_0.currentIdx = arg_10_4

			arg_10_0:initAnimation(arg_10_4, var_11_0)
			arg_10_0:initHeroModel(var_10_1, arg_10_4)
		end
	end)

	arg_10_0.heroCardBack[arg_10_4] = 0
	arg_10_0.modelIsLoad[arg_10_4] = nil

	arg_10_0.items[arg_10_4].card:setVisible(true)

	if arg_10_0.items[arg_10_4].model and not tolua.isnull(arg_10_0.items[arg_10_4].model) then
		arg_10_0.items[arg_10_4].model:setVisible(false)
	end

	var_10_1:setVisible(false)

	arg_10_0.items[arg_10_4].effect = var_10_0:getChildByName("effect")

	if arg_10_0.items[arg_10_4].effect then
		if arg_10_4 == arg_10_0.currentIdx then
			arg_10_0.items[arg_10_4].effect:setVisible(true)
		else
			arg_10_0.items[arg_10_4].effect:setVisible(false)
		end
	end
end

function var_0_0.initHeroModel(arg_12_0, arg_12_1, arg_12_2)
	if arg_12_0.modelIsLoad[arg_12_2] then
		return
	else
		arg_12_0.modelIsLoad[arg_12_2] = true
	end

	local var_12_0 = arg_12_0.heros[arg_12_2]:getName()
	local var_12_1 = arg_12_0.heros[arg_12_2]:getDes()
	local var_12_2 = cc.p(arg_12_1:getChildByName("text_pos"):getPosition())
	local var_12_3 = {
		size = 22,
		color = cc.c3b(0, 0, 0),
		text = var_12_1,
		dimensions = cc.size(215, 0),
		x = var_12_2.x,
		y = var_12_2.y,
		align = cc.ui.TEXT_ALIGN_CENTER
	}
	local var_12_4 = xyd.AssetLoader.get():loadLabel(var_12_3)

	var_12_4:addTo(arg_12_1)
	var_12_4:setAnchorPoint(cc.p(0.5, 0.5))
	arg_12_1:getChildByName("text_name"):setString(var_12_0)

	local var_12_5 = arg_12_1:getChildByName("hero_container")
	local var_12_6 = arg_12_0.heros[arg_12_2]:getHeroModel()

	var_12_6:setScale(0.8)
	var_12_5:addChild(var_12_6)
	var_12_6:setPositionX(var_12_5:getContentSize().width / 2)

	arg_12_0.items[arg_12_2].model = {}
	arg_12_0.items[arg_12_2].model = arg_12_1

	local var_12_7 = display.newNode()

	var_12_7:setContentSize(var_0_7, var_0_8)
	var_12_7:setAnchorPoint(cc.p(0, 0))
	var_12_7:setPosition(2, arg_12_1:getContentSize().height - var_0_8 - 20)
	var_12_7:setTouchEnabled(true)
	var_12_7:setTouchSwallowEnabled(false)
	var_12_7:addTo(arg_12_1)
	var_12_7:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_13_0)
		if arg_13_0.name == "began" then
			return true
		elseif arg_13_0.name == "ended" and not arg_12_0.scrollViewMoved_ then
			local var_13_0 = arg_12_0.currentIdx

			arg_12_0.currentIdx = arg_12_2

			if arg_12_0.heroCardBack[arg_12_2] == 1 then
				arg_12_0.heroCardBack[arg_12_2] = 0
			else
				arg_12_0.heroCardBack[arg_12_2] = 1
			end

			arg_12_0:initAnimation(arg_12_2, var_13_0)
		end
	end)
end

function var_0_0.initAnimation(arg_14_0, arg_14_1, arg_14_2)
	local function var_14_0()
		if not arg_14_0.items[arg_14_1].model or tolua.isnull(arg_14_0.items[arg_14_1].model) then
			if arg_14_0.items[arg_14_1].card and not tolua.isnull(arg_14_0.items[arg_14_1].card) then
				arg_14_0.items[arg_14_1].card:setVisible(true)
				arg_14_0.items[arg_14_1].card:runAction(cc.Sequence:create(cc.ScaleTo:create(0.5, 1, 1), cc.CallFunc:create(function()
					return
				end)))
			end
		else
			arg_14_0.items[arg_14_1].model:runAction(cc.Sequence:create(cc.ScaleTo:create(0.5, 0, 1), cc.CallFunc:create(function()
				arg_14_0.items[arg_14_1].model:setVisible(false)

				if arg_14_0.items[arg_14_1].card and not tolua.isnull(arg_14_0.items[arg_14_1].card) then
					arg_14_0.items[arg_14_1].card:setVisible(true)
					arg_14_0.items[arg_14_1].card:runAction(cc.Sequence:create(cc.ScaleTo:create(0.5, 1, 1), cc.CallFunc:create(function()
						return
					end)))
				end
			end)))
		end
	end

	local function var_14_1()
		if arg_14_0.items[arg_14_1].card and not tolua.isnull(arg_14_0.items[arg_14_1].card) then
			arg_14_0.items[arg_14_1].card:runAction(cc.Sequence:create(cc.ScaleTo:create(0.5, 0, 1), cc.CallFunc:create(function()
				arg_14_0.items[arg_14_1].card:setVisible(false)

				if arg_14_0.items[arg_14_1].model and not tolua.isnull(arg_14_0.items[arg_14_1].model) then
					arg_14_0.items[arg_14_1].model:setVisible(true)
					arg_14_0.items[arg_14_1].model:setScale(0, 1)
					arg_14_0.items[arg_14_1].model:runAction(cc.Sequence:create(cc.ScaleTo:create(0.5, 1, 1), cc.CallFunc:create(function()
						return
					end)))
				end
			end)))
		elseif arg_14_0.items[arg_14_1].model and not tolua.isnull(arg_14_0.items[arg_14_1].model) then
			arg_14_0.items[arg_14_1].model:setVisible(true)
			arg_14_0.items[arg_14_1].model:setScale(0, 1)
			arg_14_0.items[arg_14_1].model:runAction(cc.Sequence:create(cc.ScaleTo:create(0.5, 1, 1), cc.CallFunc:create(function()
				return
			end)))
		end
	end

	local var_14_2

	if arg_14_2 ~= arg_14_1 and arg_14_2 ~= 0 and arg_14_0.items[arg_14_2].effect and not tolua.isnull(arg_14_0.items[arg_14_2].effect) then
		arg_14_0.items[arg_14_2].effect:setVisible(false)
	end

	if arg_14_0.items[arg_14_1].effect and not tolua.isnull(arg_14_0.items[arg_14_1].effect) then
		arg_14_0.items[arg_14_1].effect:setVisible(true)
	end

	if arg_14_0.heroCardBack[arg_14_1] == 0 then
		var_14_2 = cc.Spawn:create({
			cc.CallFunc:create(var_14_0)
		})
	else
		var_14_2 = cc.Spawn:create({
			cc.CallFunc:create(var_14_1)
		})
	end

	arg_14_0:runAction(var_14_2)
end

return var_0_0
