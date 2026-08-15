local var_0_0 = class("KiteAwardWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityKiteKing

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.activities = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.playerLev = arg_1_0.selfPlayer.lev
	arg_1_0.playerId = arg_1_0.selfPlayer.playerID
	arg_1_0.playerName = arg_1_0.selfPlayer.playerName
	arg_1_0.activityId = xyd.RedEnvelope.KITE_ID
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	arg_2_0.awardList = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, 500, 420),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_2_0:nodeByName("scroll")):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0, var_3_1 = arg_3_0.activities:getActivityTimeInterVal(arg_3_0.activityId)
	local var_3_2 = os.date("%m", var_3_0)
	local var_3_3 = os.date("%d", var_3_0)
	local var_3_4 = os.date("%m", var_3_1)
	local var_3_5 = os.date("%d", var_3_1)

	arg_3_0:nodeByName("timeinterval_txt"):setString(string.format(var_0_1:translation("KITE_KING_TIME"), var_3_2, var_3_3, var_3_4, var_3_5))
	arg_3_0:nodeByName("session_time"):setString(var_0_1:translation("SESSION_TIME"))
	arg_3_0:nodeByName("close"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			local var_4_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_4_0, false)
			xyd.WindowManager.get():closeWindow(arg_3_0)
		end
	end)
	arg_3_0:updateAwardList()
end

function var_0_0.updateAwardList(arg_5_0)
	local var_5_0 = var_0_2:allcount()
	local var_5_1 = xyd.AssetLoader.get():loadSprite("images/icon/black_bg.png")

	for iter_5_0 = 1, var_5_0 do
		local var_5_2 = var_0_2:gift(iter_5_0)
		local var_5_3 = var_0_2:scroll(iter_5_0)
		local var_5_4 = xyd.tables.gift:items(var_5_2)
		local var_5_5 = xyd.tables.gift:itemNum(var_5_2)
		local var_5_6 = display.newNode()
		local var_5_7 = arg_5_0.awardList:newItem()
		local var_5_8 = xyd.AssetLoader.get():loadNodeFromJson("windows/kite_king/award/reward_item.csb")
		local var_5_9 = var_5_8:getChildByName("container")

		var_5_9:setTouchEnabled(true)
		var_5_9:getChildByName("revard_name_txt"):setString(var_0_2:name(iter_5_0))
		var_5_6:setAnchorPoint(cc.p(0, 0))
		var_5_6:setPosition(0, 0)
		arg_5_0:addTipsNew(var_5_9:getChildByName("avtar_container1"), var_5_4[1], var_5_5[1])
		arg_5_0:addTipsNew(var_5_9:getChildByName("avtar_container2"), -1, xyd.tables.gift:crystal(var_5_2))
		arg_5_0:addTipsNew(var_5_9:getChildByName("avtar_container3"), -2, xyd.tables.gift:mana(var_5_2))

		if var_5_3 > 0 then
			local var_5_10 = var_5_9:getChildByName("avtar_container4"):getContentSize().height
			local var_5_11 = display.newNode()

			var_5_11:addTo(var_5_9:getChildByName("avtar_container4"))
			var_5_11:setAnchorPoint(cc.p(0, 0))
			var_5_11:setContentSize(var_5_10, var_5_10)

			local var_5_12 = xyd.AssetLoader.get():loadSprite("images/icon/black_bg.png")

			if var_5_12 then
				local var_5_13 = var_5_11:getWidth()
				local var_5_14 = var_5_11:getHeight()
				local var_5_15 = var_5_13 / var_5_12:getWidth()

				var_5_12:setScale(var_5_15)
				var_5_12:addTo(var_5_11)
				var_5_12:setAnchorPoint(cc.p(0.5, 0.5))
				var_5_12:setPosition(var_5_13 / 2, var_5_14 / 2)

				local var_5_16 = xyd.getBorder(0, false)

				xyd.displaySpriteOnContainer(var_5_16, var_5_11, true)

				local var_5_17 = xyd.AssetLoader:get():loadSprite("images/digit_bg.png")

				var_5_17:addTo(var_5_11)
				var_5_17:setAnchorPoint(cc.p(0, 0))
				var_5_17:setPosition(var_5_12:getContentSize().width - var_5_17:getContentSize().width - 5, 5)

				local var_5_18 = {
					size = 20,
					y = 1,
					text = var_5_3,
					color = cc.c3b(255, 255, 255),
					align = cc.ui.TEXT_ALIGN_CENTER,
					valign = cc.ui.TEXT_VALIGN_TOP,
					x = var_5_10 / 10 * 9
				}
				local var_5_19 = xyd.AssetLoader.get():loadLabel(var_5_18)

				var_5_19:addTo(var_5_11)
				var_5_19:setAnchorPoint(1, 0)
			end

			local var_5_20 = {}

			var_5_20.id = -9
			var_5_20.tipsType = 1

			arg_5_0:addTips(var_5_11, var_5_20)
		end

		var_5_8:addTo(var_5_6)
		var_5_8:setAnchorPoint(cc.p(0, 0))
		var_5_6:setContentSize(var_5_9:getContentSize())
		var_5_7:addContent(var_5_6)
		var_5_7:setItemSize(var_5_9:getWidth(), var_5_9:getHeight() + 10)
		arg_5_0.awardList:addItem(var_5_7)
	end

	local var_5_21 = xyd.tables.activityKiteSet:allcount()

	for iter_5_1 = 1, var_5_21 do
		local var_5_22 = xyd.tables.activityKiteSet:gift(iter_5_1)
		local var_5_23 = xyd.tables.gift:items(var_5_22)
		local var_5_24 = xyd.tables.gift:itemNum(var_5_22)
		local var_5_25 = display.newNode()
		local var_5_26 = arg_5_0.awardList:newItem()
		local var_5_27 = xyd.AssetLoader.get():loadNodeFromJson("windows/kite_king/award/reward_item.csb")
		local var_5_28 = var_5_27:getChildByName("container")

		var_5_28:getChildByName("revard_name_txt"):setString(xyd.tables.activityKiteSet:name(iter_5_1))
		var_5_25:setAnchorPoint(cc.p(0, 0))
		var_5_25:setPosition(0, 0)

		for iter_5_2 = 1, #var_5_23 do
			arg_5_0:addTipsNew(var_5_28:getChildByName("avtar_container" .. iter_5_2), var_5_23[iter_5_2])
		end

		var_5_27:addTo(var_5_25)
		var_5_27:setAnchorPoint(cc.p(0, 0))
		var_5_25:setContentSize(var_5_28:getContentSize())
		var_5_26:addContent(var_5_25)
		var_5_26:setItemSize(var_5_28:getWidth(), var_5_28:getHeight() + 10)
		arg_5_0.awardList:addItem(var_5_26)
	end

	arg_5_0.awardList:reload()
end

function var_0_0.scrollListener(arg_6_0, arg_6_1)
	if arg_6_1.name == "began" then
		arg_6_0.scrollViewMoved_ = false
		arg_6_0.prevY_ = arg_6_1.y
	elseif arg_6_1.name == "moved" and 10 <= math.abs(arg_6_1.y - arg_6_0.prevY_) then
		arg_6_0.scrollViewMoved_ = true
	end
end

function var_0_0.didOpen(arg_7_0, arg_7_1)
	arg_7_0:addBlockLayer(cc.c4b(0, 0, 0, 225), true)
end

function var_0_0.addTipsNew(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	local var_8_0 = arg_8_1:getContentSize().height
	local var_8_1 = display.newNode()

	var_8_1:setContentSize(var_8_0, var_8_0)

	local var_8_2 = xyd.tables.item:type(arg_8_2)

	xyd.setItemBorder(var_8_1, arg_8_2, false, false, arg_8_3)
	var_8_1:addTo(arg_8_1)
	var_8_1:setAnchorPoint(cc.p(0, 0))

	if arg_8_2 > 0 then
		local var_8_3 = {
			id = arg_8_2,
			lev = xyd.tables.item:level(arg_8_2)
		}

		if xyd.tables.item:type(arg_8_2) == -1 then
			var_8_3.tipsType = 0
			var_8_3.desc1 = xyd.tables.hero:getDes(arg_8_2)
		elseif specialItem then
			var_8_3.tipsType = 1
			var_8_3.id = -3
		else
			var_8_3.tipsType = 1
			var_8_3.desc1 = xyd.tables.item:desc1(arg_8_2)
			var_8_3.desc2 = xyd.tables.item:desc2(arg_8_2)
		end

		var_8_3.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(arg_8_2)
		var_8_3.name = xyd.tables.item:name(arg_8_2)

		arg_8_0:addTips(var_8_1, var_8_3)
	end
end

return var_0_0
