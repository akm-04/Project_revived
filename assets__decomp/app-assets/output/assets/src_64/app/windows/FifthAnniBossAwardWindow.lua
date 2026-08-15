local var_0_0 = class("FifthAnniBossAwardWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.fifthAnniBossPersonAward
local var_0_3 = {
	target = var_0_1:translation("ACTIVITY_1232_BOSS_14"),
	tips = var_0_1:translation("ACTIVITY_1232_BOSS_15"),
	num = var_0_1:translation("ACTIVITY_1232_BOSS_16"),
	get = var_0_1:translation("ACTIVITY_1232_BOSS_17"),
	not_get = var_0_1:translation("ACTIVITY_1232_BOSS_18"),
	has_get = var_0_1:translation("ACTIVITY_1232_BOSS_19")
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.fifthAnniModel = xyd.ModelManager.get():loadModel(xyd.ModelType.FIFTH_ANNIVERSARY)
	arg_1_0.awardList = arg_1_2
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0.btnGet = arg_4_0:nodeByName("btn_all_get")

	arg_4_0.btnGet:setBright(false)
	arg_4_0.btnGet:addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.began then
			arg_4_0.btnGet:setScale(0.9)
		elseif arg_5_1 == ccui.TouchEventType.ended then
			arg_4_0.btnGet:setScale(1)
			arg_4_0.fifthAnniModel:getAllAward(nil, function(arg_6_0, arg_6_1)
				if arg_6_0 == xyd.error.OK then
					arg_4_0.selfPlayer:handleRewards(arg_6_1.awards)

					arg_4_0.awardList = arg_6_1.info.is_award

					arg_4_0.list:reload()
				else
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("ACTIVITY_1232_BOSS_11")
					})
					arg_4_0.list:reload()
				end
			end)
		end
	end)
	arg_4_0:setTexts()
	arg_4_0:initList()
end

function var_0_0.setTexts(arg_7_0)
	arg_7_0:nodeByName("txt_title"):setString(var_0_1:translation("ACTIVITY_1232_BOSS_12"))
	arg_7_0:nodeByName("txt_all_get"):setString(var_0_1:translation("ACTIVITY_1232_BOSS_13"))
end

function var_0_0.initList(arg_8_0)
	arg_8_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_8_0:nodeByName("list"):getWidth(), arg_8_0:nodeByName("list"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_8_0:nodeByName("list")):onScroll(handler(arg_8_0, arg_8_0.scrollListener))

	arg_8_0.list:setBounceable(true)
	arg_8_0.list:setDelegate(handler(arg_8_0, arg_8_0.delegate))
	arg_8_0.list:reload()
end

function var_0_0.delegate(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	local var_9_0 = #arg_9_0.awardList

	if cc.ui.UIListView.COUNT_TAG == arg_9_2 then
		return var_9_0
	elseif cc.ui.UIListView.CELL_TAG == arg_9_2 then
		if var_9_0 < arg_9_3 then
			return nil
		end

		local var_9_1 = arg_9_0.list:dequeueItem()

		if not var_9_1 then
			var_9_1 = arg_9_0.list:newItem()
		else
			var_9_1:removeAllChildren(true)
		end

		local var_9_2 = display.newNode()

		arg_9_0:initCell(var_9_2, arg_9_3)

		local var_9_3 = display.newNode()

		var_9_3:addChild(var_9_2)
		var_9_3:setContentSize(var_9_2:getContentSize())
		var_9_1:setItemSize(var_9_2:getContentSize().width, var_9_2:getContentSize().height)
		var_9_1:addContent(var_9_3)

		return var_9_1
	end
end

function var_0_0.initCell(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0
	local var_10_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1232/boss/award_item.csb")
	local var_10_2 = var_10_1:getChildByName("container")
	local var_10_3 = arg_10_0.awardList[arg_10_2]
	local var_10_4 = arg_10_0.fifthAnniModel.bossPoint or 0
	local var_10_5 = var_0_2:req(arg_10_2)
	local var_10_6 = var_0_2:giftId(arg_10_2)

	var_10_2:getChildByName("txt_title"):setString(var_0_3.target .. arg_10_2)
	var_10_2:getChildByName("txt_tips"):setString(string.format(var_0_3.tips, var_10_5))
	var_10_2:getChildByName("txt_num"):setString(string.format(var_0_3.num, var_10_4, var_10_5))

	local var_10_7 = var_10_2:getChildByName("btn_get")

	if var_10_5 <= var_10_4 then
		var_10_2:getChildByName("bg_item_1"):setVisible(false)
		var_10_2:getChildByName("bg_item_2"):setVisible(true)

		if var_10_3 == 0 then
			var_10_7:setBright(true)
			var_10_7:setTouchEnabled(true)
			var_10_7:getChildByName("txt_get"):setVisible(true)
			var_10_7:getChildByName("txt_get"):setString(var_0_3.get)
			var_10_7:getChildByName("txt_notget"):setVisible(false)
			arg_10_0.btnGet:setBright(true)
		else
			var_10_7:setBright(false)
			var_10_7:setTouchEnabled(false)
			var_10_7:getChildByName("txt_get"):setVisible(false)
			var_10_7:getChildByName("txt_notget"):setString(var_0_3.has_get)
			var_10_7:getChildByName("txt_notget"):setVisible(true)
		end
	else
		var_10_2:getChildByName("bg_item_1"):setVisible(true)
		var_10_2:getChildByName("bg_item_2"):setVisible(false)
		var_10_7:setBright(false)
		var_10_7:setTouchEnabled(false)
		var_10_7:getChildByName("txt_get"):setVisible(false)
		var_10_7:getChildByName("txt_notget"):setString(var_0_3.not_get)
		var_10_7:getChildByName("txt_notget"):setVisible(true)
	end

	local var_10_8 = xyd.tables.gift:items(var_10_6)[1]
	local var_10_9 = xyd.tables.gift:itemNum(var_10_6)[1]
	local var_10_10 = var_10_2:getChildByName("item")

	xyd.setItemAndAddTips(var_10_10, var_10_8, var_10_9)
	var_10_7:addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.began then
			var_10_7:setScale(0.9)
		elseif arg_11_1 == ccui.TouchEventType.ended then
			var_10_7:setScale(1)

			local var_11_0 = {
				award_id = arg_10_2
			}

			arg_10_0.fifthAnniModel:getAward(var_11_0, function(arg_12_0, arg_12_1)
				if arg_12_0 == xyd.error.OK then
					arg_10_0.awardList[arg_10_2] = 1
					arg_10_0.fifthAnniModel.bossAwardInfo[arg_10_2] = 1

					arg_10_0.selfPlayer:handleRewards(arg_12_1.awards)
					var_10_7:setBright(false)
					var_10_7:setTouchEnabled(false)
					var_10_7:getChildByName("txt_get"):setVisible(false)
					var_10_7:getChildByName("txt_notget"):setString(var_0_3.has_get)
					var_10_7:getChildByName("txt_notget"):setVisible(true)
				end
			end)
		end
	end)

	local var_10_11 = var_10_2:getContentSize()

	var_10_1:addTo(arg_10_1)
	arg_10_1:setContentSize(arg_10_0:nodeByName("list"):getWidth(), var_10_11.height + 5)
end

function var_0_0.scrollListener(arg_13_0, arg_13_1)
	if arg_13_1.name == "began" then
		arg_13_0.startClick_ = true
		arg_13_0.prevX_ = arg_13_1.x
	elseif arg_13_1.name == "moved" and 20 <= math.abs(arg_13_1.x - arg_13_0.prevX_) then
		arg_13_0.startClick_ = false
	end
end

return var_0_0
