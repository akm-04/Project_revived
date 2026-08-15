local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.ActivityPetSellTable
local var_0_4 = 3
local var_0_5 = 1
local var_0_6 = -1
local var_0_7 = {
	DAY = 0,
	NIGHT = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.details = arg_1_0.activity.details
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	arg_2_0.isOnRotation = false

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	if var_2_0 then
		arg_2_0.timeState = arg_2_0:calculateTimeState()
		arg_2_0.container = var_2_0:getChildByName("container")
		arg_2_0.clippingNode = display.newClippingRegionNode()

		arg_2_0.clippingNode:setClippingRegion(cc.rect(0, 0, 2000, 2000))
		arg_2_0.clippingNode:addTo(arg_2_0.container:getChildByName("clipping_pos"))
		var_2_0:addTo(arg_2_0.parent)
		var_2_0:setPosition(0, 0)
	end

	arg_2_0:setTouchBtn()

	arg_2_0.giftBagId = 1

	arg_2_0:initialGiftBagID()
	arg_2_0:setCurrentGiftBag()
	arg_2_0.container:getChildByName("end_time_text"):setString(var_0_2:translation("ACTIVITY_END_TIME"))
	arg_2_0.container:getChildByName("end_time_text"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_2_0.container:getChildByName("decs"):setString(var_0_2:translation("ACTIVITY_PETSELL_DESC"))
	arg_2_0.container:getChildByName("decs"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_2_0.container:getChildByName("diamond_num"):setString(string.format(var_0_2:translation("TODAY_CHARGE"), arg_2_0.details.charge_count))
	arg_2_0.container:getChildByName("diamond_num"):enableOutline(cc.c4b(255, 255, 255, 255), 2)

	arg_2_0.sky = xyd.AssetLoader.get():loadSprite("windows/activities/1063/sky.png")

	arg_2_0.sky:setScale(1)
	arg_2_0.sky:addTo(arg_2_0.clippingNode)
	arg_2_0.sky:setPosition(cc.p(800, -120))

	if arg_2_0.timeState == var_0_7.NIGHT then
		arg_2_0.sky:setRotation(180)
	end

	local var_2_1 = xyd.AssetLoader.get():loadSprite("windows/activities/1063/cloud.png")

	var_2_1:setPosition(cc.p(820, 400))
	var_2_1:addTo(arg_2_0.clippingNode)

	local var_2_2 = xyd.AssetLoader.get():loadSprite("windows/activities/1063/earth.png")

	var_2_2:setScale(1.4)
	var_2_2:addTo(arg_2_0.clippingNode)
	var_2_2:setPosition(cc.p(800, 100))
	var_2_2:runAction(cc.RepeatForever:create(cc.RotateBy:create(20, -360)))

	local var_2_3 = xyd.AssetLoader.get():loadSprite("windows/activities/1063/cloud.png")

	var_2_3:setPosition(cc.p(360, 152))
	var_2_3:addTo(arg_2_0.clippingNode)

	local var_2_4 = xyd.AssetLoader.get():loadSprite("windows/activities/1063/earth.png")

	var_2_4:setScale(1.4)
	var_2_4:addTo(arg_2_0.clippingNode)
	var_2_4:setPosition(cc.p(338, -166))
	var_2_4:runAction(cc.RepeatForever:create(cc.RotateBy:create(20, -360)))
	arg_2_0:setGiftContainer()
	arg_2_0:updateDownTimeScheduler()
end

function var_0_0.initAwardList(arg_3_0)
	local var_3_0 = arg_3_0.container:getChildByName("container_list")
	local var_3_1 = var_3_0:getContentSize()

	arg_3_0.awardList = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_3_1.width, var_3_1.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(var_3_0)

	local var_3_2 = var_0_3:getIDs()

	for iter_3_0 = 1, #var_3_2 do
		local var_3_3 = var_3_2[iter_3_0]
		local var_3_4 = arg_3_0.awardList:newItem()
		local var_3_5 = display.newNode()
		local var_3_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1058/activity_item.csb")
		local var_3_7 = var_3_6:getChildByName("container")

		arg_3_0:rewardItemLayout(arg_3_0.activity, var_3_7, var_3_3)
		var_3_6:addTo(var_3_5)
		var_3_6:setTouchEnabled(true)
		var_3_6:setAnchorPoint(cc.p(0, 0))
		var_3_6:setTouchSwallowEnabled(false)

		local var_3_8 = var_3_7:getContentSize()

		var_3_5:setContentSize(var_3_8.width, var_3_8.height)
		var_3_4:addContent(var_3_5)
		var_3_4:setItemSize(var_3_8.width, var_3_8.height)
		arg_3_0.awardList:addItem(var_3_4)
	end

	arg_3_0.awardList:reload()
end

function var_0_0.rewardItemLayout(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	local var_4_0 = arg_4_2:getChildByName("btn")
	local var_4_1 = arg_4_2:getChildByName("yilingqu")
	local var_4_2 = arg_4_2:getChildByName("lingqu")
	local var_4_3 = arg_4_2:getChildByName("get_gray")
	local var_4_4 = arg_4_2:getChildByName("expired")
	local var_4_5 = arg_4_2:getChildByName("not_begin")
	local var_4_6 = {
		btn = var_4_0,
		alreadyObtain = var_4_1,
		obtain_bright = var_4_2,
		obtain_gray = var_4_3,
		expired = var_4_4,
		notBegin = var_4_5
	}
	local var_4_7 = arg_4_2:getChildByName("reward_container")
	local var_4_8 = arg_4_2:getChildByName("item_title_container")
	local var_4_9 = {
		color = cc.c3b(255, 255, 255)
	}

	var_4_9.size = 20

	local var_4_10 = xyd.AssetLoader.get():loadLabel(var_4_9)

	var_4_10:setMaxLineWidth(280)
	var_4_10:addTo(var_4_8)
	var_4_10:setAnchorPoint(cc.p(0, 0))
	var_4_10:setPosition(10, 3)
	var_4_10:enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)

	local var_4_11 = var_0_3:name(arg_4_3)

	var_4_10:setString(var_4_11)

	local var_4_12 = xyd.ServerTime.get():getServerTime()
	local var_4_13 = arg_4_1.details.is_awards
	local var_4_14 = arg_4_1.details.can_award

	arg_4_0:rewardFormat(var_4_7, arg_4_3)

	if var_4_12 < arg_4_1.start_time then
		arg_4_0:setBtnGetState(-2, var_4_6)

		return
	elseif var_4_12 > arg_4_1.end_time then
		arg_4_0:setBtnGetState(2, var_4_6)

		return
	end

	if not var_4_13 or not var_4_14 then
		arg_4_0:setBtnGetState(-1, var_4_6)

		return
	end

	if var_4_13[arg_4_3] == 1 then
		arg_4_0:setBtnGetState(0, var_4_6)
	elseif var_4_14[arg_4_3] == 0 then
		arg_4_0:setBtnGetState(-1, var_4_6)
	else
		arg_4_0:setBtnGetState(1, var_4_6)
	end

	var_4_0:addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			local var_5_0 = {
				id = arg_4_3,
				activityID = arg_4_1.table_id,
				giftIDs = var_0_3:gift(arg_4_3),
				modelIDs = var_0_3:modelID(arg_4_3)
			}

			function var_5_0.callback()
				arg_4_0:setBtnGetState(0, var_4_6)

				if arg_4_0 and not tolua.isnull(arg_4_0.container) then
					arg_4_0.details.is_awards[var_5_0.id] = 1
					arg_4_0.details.can_award[var_5_0.id] = 0

					arg_4_0:initialGiftBagID()
					arg_4_0:setChageBtnState()
					arg_4_0:setGiftContainer()
				end
			end

			xyd.WindowManager.get():openWindow("select_giftbag", var_5_0)
		end
	end)
end

function var_0_0.updateDownTimeScheduler(arg_7_0)
	if arg_7_0.handler then
		var_0_1.unscheduleGlobal(arg_7_0.handler)

		arg_7_0.handler = nil
	end

	arg_7_0.currentTime = xyd.ServerTime.get():getServerTime()
	arg_7_0.downTime = arg_7_0.activity.end_time - arg_7_0.currentTime

	if arg_7_0.downTime < 0 then
		arg_7_0.downTime = 0
	end

	arg_7_0:updateDownTime()

	arg_7_0.handler = var_0_1.scheduleGlobal(function()
		arg_7_0.currentTime = arg_7_0.currentTime + 1
		arg_7_0.downTime = arg_7_0.downTime - 1

		arg_7_0:updateDownTime()
		arg_7_0:updateSky()
	end, 1)
end

function var_0_0.updateDownTime(arg_9_0)
	if arg_9_0.downTime < 0 then
		arg_9_0.downTime = 0
	end

	local var_9_0 = xyd.timeFormatAsHMS(arg_9_0.downTime)

	if not tolua.isnull(arg_9_0.container) and not tolua.isnull(arg_9_0.container:getChildByName("down_time_txt")) then
		arg_9_0.container:getChildByName("down_time_txt"):setString(var_9_0)
		arg_9_0.container:getChildByName("down_time_txt"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	end
end

function var_0_0.calculateTimeState(arg_10_0)
	local var_10_0
	local var_10_1 = xyd.ServerTime.get():getSecondsOfDay()

	if var_10_1 == 25200 or var_10_1 == 68400 or not arg_10_0.timeState then
		if var_10_1 >= 25200 and var_10_1 < 68400 then
			var_10_0 = var_0_7.DAY
		else
			var_10_0 = var_0_7.NIGHT
		end

		return var_10_0
	else
		return arg_10_0.timeState
	end
end

function var_0_0.update(arg_11_0)
	arg_11_0:setChageBtnState()
	arg_11_0:setGiftContainer()
end

function var_0_0.updateSky(arg_12_0)
	local var_12_0 = arg_12_0:calculateTimeState()

	if var_12_0 ~= arg_12_0.timeState and not tolua.isnull(arg_12_0.sky) then
		arg_12_0.isOnRotation = true

		arg_12_0.sky:runAction(cc.Sequence:create({
			cc.RotateBy:create(0.5, -180),
			cc.CallFunc:create(function()
				if arg_12_0 and arg_12_0.isOnRotation then
					arg_12_0.isOnRotation = false
				end
			end)
		}))

		arg_12_0.timeState = var_12_0
	end
end

function var_0_0.changeSky(arg_14_0, arg_14_1)
	if arg_14_0.timeState == var_0_7.DAY then
		arg_14_0.timeState = var_0_7.NIGHT
	else
		arg_14_0.timeState = var_0_7.DAY
	end

	arg_14_0.isOnRotation = true

	if not tolua.isnull(arg_14_0.sky) then
		arg_14_0.sky:runAction(cc.Sequence:create({
			cc.RotateBy:create(0.5, 180 * arg_14_1),
			cc.CallFunc:create(function()
				if arg_14_0 and arg_14_0.isOnRotation then
					arg_14_0.isOnRotation = false
				end
			end)
		}))
	end
end

function var_0_0.setCurrentGiftBag(arg_16_0)
	arg_16_0:setChageBtnState()
	arg_16_0.container:getChildByName("gift_pos"):removeAllChildren()

	local var_16_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1063/activity_item.csb")
	local var_16_1 = var_16_0:getChildByName("container")

	arg_16_0:rewardItemLayout(arg_16_0.activity, var_16_1, arg_16_0.idx, arg_16_0.giftBagId, arg_16_0.giftBagId)
	var_16_0:addTo(arg_16_0.container:getChildByName("gift_pos"))
	var_16_0:setPosition(cc.p(-var_16_1:getContentSize().width / 2, -var_16_1:getContentSize().height / 2))
end

function var_0_0.initialGiftBagID(arg_17_0)
	local var_17_0 = 0

	if arg_17_0.details.is_awards then
		for iter_17_0 = 1, #arg_17_0.details.is_awards do
			if arg_17_0.details.is_awards[iter_17_0] ~= 1 then
				var_17_0 = iter_17_0

				break
			end
		end
	end

	if var_17_0 == 0 then
		var_17_0 = #arg_17_0.details.is_awards
	end

	arg_17_0.giftBagId = var_17_0
end

function var_0_0.setTouchBtn(arg_18_0)
	local var_18_0 = arg_18_0.activity
	local var_18_1 = "open"
	local var_18_2 = xyd.ServerTime.get():getServerTime()

	if var_18_2 < var_18_0.start_time and var_18_0.is_open == 0 then
		local var_18_3 = "not_open"
	elseif var_18_2 > var_18_0.end_time and var_18_0.is_open == 0 then
		local var_18_4 = "expired"
	end

	arg_18_0.container:getChildByName("last_btn"):addTouchEventListener(function(arg_19_0, arg_19_1)
		if arg_19_1 == ccui.TouchEventType.ended then
			if arg_18_0.isOnRotation == true then
				return
			end

			arg_18_0.giftBagId = arg_18_0.giftBagId - 1

			if arg_18_0.giftBagId < 1 then
				arg_18_0.giftBagId = 1
			end

			arg_18_0:changeSky(var_0_5)
			arg_18_0:update()
		end
	end)
	arg_18_0.container:getChildByName("next_btn"):addTouchEventListener(function(arg_20_0, arg_20_1)
		if arg_20_1 == ccui.TouchEventType.ended then
			if arg_18_0.isOnRotation == true then
				return
			end

			arg_18_0.giftBagId = arg_18_0.giftBagId + 1

			if arg_18_0.giftBagId > var_0_3:allCounts() then
				arg_18_0.giftBagId = var_0_3:allCounts()
			end

			arg_18_0:changeSky(var_0_6)
			arg_18_0:update()
		end
	end)
	arg_18_0.container:getChildByName("rule_btn"):addTouchEventListener(function(arg_21_0, arg_21_1)
		if arg_21_1 == ccui.TouchEventType.ended then
			local var_21_0 = {
				title_name = "ACTIVITY_PETSELL_TITLE",
				rule = "ACTIVITY_PETSELL_RULE"
			}

			xyd.WindowManager.get():openWindow("new_text_rule", var_21_0)
		end
	end)
end

function var_0_0.setChageBtnState(arg_22_0)
	arg_22_0.container:getChildByName("last_btn"):setVisible(true)
	arg_22_0.container:getChildByName("next_btn"):setVisible(true)

	if arg_22_0.giftBagId == 1 then
		arg_22_0.container:getChildByName("last_btn"):setVisible(false)
	end

	if arg_22_0.giftBagId == var_0_3:allCounts() then
		arg_22_0.container:getChildByName("next_btn"):setVisible(false)
	end
end

function var_0_0.setGiftContainer(arg_23_0)
	arg_23_0.giftIDs = var_0_3:gift(arg_23_0.giftBagId)
	arg_23_0.modelIDs = var_0_3:modelID(arg_23_0.giftBagId)
	arg_23_0.models = {}

	for iter_23_0 = 1, var_0_4 do
		arg_23_0.container:getChildByName("pet_container" .. iter_23_0):removeAllChildren()
		arg_23_0.container:getChildByName("pet_container" .. iter_23_0):setTouchEnabled(false)
		arg_23_0.container:getChildByName("pet_container" .. iter_23_0):setTouchSwallowEnabled(false)

		arg_23_0.models[iter_23_0] = xyd.HeroAnimation.new(nil, arg_23_0.modelIDs[iter_23_0], 1, {})

		arg_23_0.models[iter_23_0]:setTouchSwallowEnabled(false)
		arg_23_0.models[iter_23_0]:setTouchEnabled(true)
		arg_23_0.models[iter_23_0]:addTo(arg_23_0.container:getChildByName("pet_container" .. iter_23_0))
		arg_23_0.models[iter_23_0]:setPositionX(arg_23_0.container:getChildByName("pet_container" .. iter_23_0):getContentSize().width / 2)
		arg_23_0.models[iter_23_0]:walk(true)
	end

	arg_23_0.models[1]:setScale(0.8)
	arg_23_0.models[1]:setRotation(-15)
	arg_23_0.models[2]:setPositionY(arg_23_0.models[2]:getPositionY() + 20)
	arg_23_0.models[3]:setRotation(15)
end

function var_0_0.rewardItemLayout(arg_24_0, arg_24_1, arg_24_2, arg_24_3, arg_24_4, arg_24_5)
	local var_24_0 = arg_24_2:getChildByName("btn")
	local var_24_1 = arg_24_2:getChildByName("yilingqu")
	local var_24_2 = arg_24_2:getChildByName("lingqu")
	local var_24_3 = arg_24_2:getChildByName("get_gray")
	local var_24_4 = arg_24_2:getChildByName("expired")
	local var_24_5 = arg_24_2:getChildByName("not_begin")
	local var_24_6 = {
		btn = var_24_0,
		alreadyObtain = var_24_1,
		obtain_bright = var_24_2,
		obtain_gray = var_24_3,
		expired = var_24_4,
		notBegin = var_24_5
	}
	local var_24_7 = arg_24_2:getChildByName("reward_container")
	local var_24_8 = arg_24_2:getChildByName("item_title_container")
	local var_24_9 = {
		color = cc.c3b(255, 255, 255)
	}

	var_24_9.size = 20

	local var_24_10 = xyd.AssetLoader.get():loadLabel(var_24_9)

	var_24_10:setMaxLineWidth(280)
	var_24_10:addTo(var_24_8)
	var_24_10:setAnchorPoint(cc.p(0, 0))
	var_24_10:setPosition(10, 3)
	var_24_10:enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)

	local var_24_11 = xyd.tables.ActivityPetSellTable:name(arg_24_4)

	var_24_10:setString(var_24_11)

	local var_24_12 = xyd.ServerTime.get():getServerTime()

	arg_24_0:rewardFormat(var_24_7, arg_24_4)

	if var_24_12 < arg_24_1.start_time then
		arg_24_0:setBtnGetState(-2, var_24_6)

		return
	elseif var_24_12 > arg_24_1.end_time then
		arg_24_0:setBtnGetState(2, var_24_6)

		return
	end

	if not arg_24_0.details.is_awards or not arg_24_0.details.can_award then
		arg_24_0:setBtnGetState(-1, var_24_6)

		return
	end

	if arg_24_0.details.is_awards[arg_24_5] == 1 then
		arg_24_0:setBtnGetState(0, var_24_6)
	elseif arg_24_0.details.can_award[arg_24_5] == 0 then
		arg_24_0:setBtnGetState(-1, var_24_6)
	else
		arg_24_0:setBtnGetState(1, var_24_6)
	end

	var_24_0:addTouchEventListener(function(arg_25_0, arg_25_1)
		if arg_25_1 == ccui.TouchEventType.ended then
			local var_25_0 = {
				id = arg_24_0.giftBagId,
				activityID = arg_24_1.table_id,
				giftIDs = xyd.tables.ActivityPetSellTable:gift(arg_24_0.giftBagId),
				modelIDs = xyd.tables.ActivityPetSellTable:modelID(arg_24_0.giftBagId)
			}

			function var_25_0.callback()
				if arg_24_0 and not tolua.isnull(arg_24_0.container) then
					arg_24_0.details.is_awards[var_25_0.id] = 1
					arg_24_0.details.can_award[var_25_0.id] = 0

					arg_24_0:initialGiftBagID()
					arg_24_0:setCurrentGiftBag()
					arg_24_0:setGiftContainer()
				end
			end

			xyd.WindowManager.get():openWindow("select_giftbag", var_25_0)
		end
	end)
end

function var_0_0.rewardFormat(arg_27_0, arg_27_1, arg_27_2)
	local var_27_0 = arg_27_1:getContentSize().height
	local var_27_1 = var_27_0 / 4
	local var_27_2 = var_0_3:gift(arg_27_2)[1]
	local var_27_3 = xyd.tables.gift:items(var_27_2)

	if #var_27_3 == 1 and var_27_3[1] == 0 then
		var_27_3 = {}
	end

	local var_27_4 = xyd.tables.gift:itemNum(var_27_2)
	local var_27_5 = #var_27_3
	local var_27_6 = display.newNode()

	var_27_6:setContentSize(var_27_0, var_27_0)

	local var_27_7 = var_0_3:icon(arg_27_2)

	xyd.setSpriteBorder(var_27_6, var_27_7, 1)
	var_27_6:addTo(arg_27_1)
	var_27_6:setAnchorPoint(cc.p(0, 0))
	var_27_6:setPosition(0 * (var_27_0 + var_27_1), 0)

	local var_27_8 = {}

	var_27_8.id = -100000
	var_27_8.tipsType = 1
	var_27_8.desc1 = var_0_3:giftlist(arg_27_2)

	arg_27_0:addTips(var_27_6, var_27_8)

	for iter_27_0 = 2, #var_27_3 do
		local var_27_9 = display.newNode()

		var_27_9:setContentSize(var_27_0, var_27_0)

		if xyd.tables.item:type(var_27_3[iter_27_0]) == -1 then
			xyd.setAvatarBorder(var_27_3[iter_27_0], var_27_9, 1, xyd.tables.hero:initialStar(var_27_3[iter_27_0]))
		else
			xyd.setItemBorder(var_27_9, var_27_3[iter_27_0], false, false, var_27_4[iter_27_0])
		end

		var_27_9:addTo(arg_27_1)
		var_27_9:setAnchorPoint(cc.p(0, 0))
		var_27_9:setPosition((iter_27_0 - 1) * (var_27_0 + var_27_1), 0)

		local var_27_10 = {
			id = var_27_3[iter_27_0],
			lev = xyd.tables.item:level(var_27_3[iter_27_0])
		}

		if xyd.tables.item:type(var_27_3[iter_27_0]) == -1 then
			var_27_10.tipsType = 0
			var_27_10.desc1 = xyd.tables.hero:getDes(var_27_3[iter_27_0])
		elseif specialItem then
			var_27_10.tipsType = 1
			var_27_10.id = -3
		else
			var_27_10.tipsType = 1
			var_27_10.desc1 = xyd.tables.item:desc1(var_27_3[iter_27_0])
			var_27_10.desc2 = xyd.tables.item:desc2(var_27_3[iter_27_0])
		end

		var_27_10.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_27_3[iter_27_0])
		var_27_10.name = xyd.tables.item:name(var_27_3[iter_27_0])

		arg_27_0:addTips(var_27_9, var_27_10)
	end

	local var_27_11 = xyd.tables.gift:crystal(var_27_2)

	if var_27_11 and var_27_11 > 0 then
		local var_27_12 = display.newNode()

		var_27_12:setContentSize(var_27_0, var_27_0)
		xyd.setItemBorder(var_27_12, -1, false, false, var_27_11)
		var_27_12:addTo(arg_27_1)
		var_27_12:setAnchorPoint(cc.p(0, 0))
		var_27_12:setPosition(var_27_5 * (var_27_0 + var_27_1), 0)

		local var_27_13 = {}

		var_27_13.id = -1
		var_27_13.tipsType = 1

		arg_27_0:addTips(var_27_12, var_27_13)

		var_27_5 = var_27_5 + 1
	end

	local var_27_14 = xyd.tables.gift:mana(var_27_2)

	if var_27_14 and var_27_14 > 0 then
		local var_27_15 = display.newNode()

		var_27_15:setContentSize(var_27_0, var_27_0)
		xyd.setItemBorder(var_27_15, -2, false, false, var_27_14)
		var_27_15:addTo(arg_27_1)
		var_27_15:setAnchorPoint(cc.p(0, 0))
		var_27_15:setPosition(var_27_5 * (var_27_0 + var_27_1), 0)

		local var_27_16 = {}

		var_27_16.id = -2
		var_27_16.tipsType = 1

		arg_27_0:addTips(var_27_15, var_27_16)

		local var_27_17 = var_27_5 + 1
	end

	return arg_27_1
end

function var_0_0.release(arg_28_0, arg_28_1)
	var_0_0.super.release(arg_28_1)

	if arg_28_0.handler then
		var_0_1.unscheduleGlobal(arg_28_0.handler)

		arg_28_0.handler = nil
	end
end

return var_0_0
