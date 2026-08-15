local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.ActivityPetGrowUpTable
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
	arg_1_0.buyTimes = 0
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	arg_2_0.isOnRotation = false

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	if not var_2_0 then
		return
	end

	arg_2_0.timeState = arg_2_0:calculateTimeState()
	arg_2_0.container = var_2_0:getChildByName("container")

	local var_2_1 = xyd.AssetLoader.get():loadSprite("windows/activities/1160/boundary.png")

	var_2_1:setAnchorPoint(cc.p(0, 0))
	var_2_1:setPosition(cc.p(-3, -2))
	var_2_1:addTo(arg_2_0.container:getChildByName("clipping_pos"))

	arg_2_0.clippingNode = display.newClippingRegionNode()

	arg_2_0.clippingNode:setClippingRegion(cc.rect(0, 0, 670, 236))
	arg_2_0.clippingNode:addTo(arg_2_0.container:getChildByName("clipping_pos"))
	var_2_0:addTo(arg_2_0.parent)
	var_2_0:setPosition(-13, -15)
	arg_2_0:setTouchBtn()

	arg_2_0.giftBagId = 1

	arg_2_0:initialGiftBagID()
	arg_2_0:setCurrentGiftBag()
	arg_2_0.container:getChildByName("end_time_text"):setString(var_0_2:translation("ACTIVITY_PETGROWUP_END_TIME"))
	arg_2_0.container:getChildByName("end_time_text"):enableOutline(cc.c4b(0, 0, 0, 255), 2)
	arg_2_0.container:getChildByName("decs"):setString(var_0_2:translation("ACTIVITY_PETGROWUP_DESC"))
	arg_2_0.container:getChildByName("diamond_num"):setVisible(false)

	arg_2_0.sky = xyd.AssetLoader.get():loadSprite("windows/activities/1160/sky.png")

	arg_2_0.sky:setScale(2.1)
	arg_2_0.sky:addTo(arg_2_0.clippingNode)
	arg_2_0.sky:setPosition(cc.p(335, -168))

	if arg_2_0.timeState == var_0_7.NIGHT then
		arg_2_0.sky:setRotation(180)
	end

	local var_2_2 = xyd.AssetLoader.get():loadSprite("windows/activities/1160/cloud.png")

	var_2_2:setPosition(cc.p(360, 152))
	var_2_2:addTo(arg_2_0.clippingNode)

	local var_2_3 = xyd.AssetLoader.get():loadSprite("windows/activities/1160/earth.png")

	var_2_3:setScale(1.4)
	var_2_3:addTo(arg_2_0.clippingNode)
	var_2_3:setPosition(cc.p(338, -166))
	var_2_3:runAction(cc.RepeatForever:create(cc.RotateBy:create(20, -360)))
	arg_2_0:setGiftContainer()
	arg_2_0:updateDownTimeScheduler()
end

function var_0_0.updateDownTimeScheduler(arg_3_0)
	if arg_3_0.handler then
		var_0_1.unscheduleGlobal(arg_3_0.handler)

		arg_3_0.handler = nil
	end

	arg_3_0.currentTime = xyd.ServerTime.get():getServerTime()
	arg_3_0.downTime = arg_3_0.activity.end_time - arg_3_0.currentTime

	if arg_3_0.downTime < 0 then
		arg_3_0.downTime = 0
	end

	arg_3_0:updateDownTime()

	arg_3_0.handler = var_0_1.scheduleGlobal(function()
		arg_3_0.currentTime = arg_3_0.currentTime + 1
		arg_3_0.downTime = arg_3_0.downTime - 1

		arg_3_0:updateDownTime()
		arg_3_0:updateSky()
	end, 1)
end

function var_0_0.updateDownTime(arg_5_0)
	if arg_5_0.downTime < 0 then
		arg_5_0.downTime = 0
	end

	local var_5_0 = xyd.timeFormatAsHMS(arg_5_0.downTime)

	if not tolua.isnull(arg_5_0.container) and not tolua.isnull(arg_5_0.container:getChildByName("down_time_txt")) then
		arg_5_0.container:getChildByName("down_time_txt"):setString(var_5_0)
		arg_5_0.container:getChildByName("down_time_txt"):enableOutline(cc.c4b(0, 0, 0, 255), 2)
	end
end

function var_0_0.calculateTimeState(arg_6_0)
	local var_6_0
	local var_6_1 = xyd.ServerTime.get():getSecondsOfDay()

	if var_6_1 == 25200 or var_6_1 == 68400 or not arg_6_0.timeState then
		if var_6_1 >= 25200 and var_6_1 < 68400 then
			var_6_0 = var_0_7.DAY
		else
			var_6_0 = var_0_7.NIGHT
		end

		return var_6_0
	else
		return arg_6_0.timeState
	end
end

function var_0_0.update(arg_7_0)
	arg_7_0:setCurrentGiftBag()
	arg_7_0:setGiftContainer()
end

function var_0_0.updateSky(arg_8_0)
	local var_8_0 = arg_8_0:calculateTimeState()

	if var_8_0 ~= arg_8_0.timeState and not tolua.isnull(arg_8_0.sky) then
		arg_8_0.isOnRotation = true

		arg_8_0.sky:runAction(cc.Sequence:create({
			cc.RotateBy:create(0.5, -180),
			cc.CallFunc:create(function()
				if arg_8_0 and arg_8_0.isOnRotation then
					arg_8_0.isOnRotation = false
				end
			end)
		}))

		arg_8_0.timeState = var_8_0
	end
end

function var_0_0.changeSky(arg_10_0, arg_10_1)
	if arg_10_0.timeState == var_0_7.DAY then
		arg_10_0.timeState = var_0_7.NIGHT
	else
		arg_10_0.timeState = var_0_7.DAY
	end

	arg_10_0.isOnRotation = true

	if not tolua.isnull(arg_10_0.sky) then
		arg_10_0.sky:runAction(cc.Sequence:create({
			cc.RotateBy:create(0.5, 180 * arg_10_1),
			cc.CallFunc:create(function()
				if arg_10_0 and arg_10_0.isOnRotation then
					arg_10_0.isOnRotation = false
				end
			end)
		}))
	end
end

function var_0_0.setCurrentGiftBag(arg_12_0)
	arg_12_0:setChageBtnState()
	arg_12_0.container:getChildByName("gift_pos"):removeAllChildren()

	local var_12_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1160/activity_item.csb")
	local var_12_1 = var_12_0:getChildByName("container")

	arg_12_0:rewardItemLayout(arg_12_0.activity, var_12_1, arg_12_0.idx, arg_12_0.giftBagId, arg_12_0.giftBagId)
	var_12_0:addTo(arg_12_0.container:getChildByName("gift_pos"))
	var_12_0:setPosition(cc.p(-var_12_1:getContentSize().width / 2, -var_12_1:getContentSize().height / 2))
end

function var_0_0.initialGiftBagID(arg_13_0)
	local var_13_0 = 0

	if arg_13_0.details.base_info.is_awards then
		for iter_13_0 = 1, #arg_13_0.details.base_info.is_awards do
			if arg_13_0.details.base_info.is_awards[iter_13_0] ~= 1 then
				var_13_0 = iter_13_0

				break
			end
		end
	end

	if var_13_0 == 0 then
		var_13_0 = #arg_13_0.details.base_info.is_awards or 0
	end

	arg_13_0.giftBagId = var_13_0
end

function var_0_0.setTouchBtn(arg_14_0)
	local var_14_0 = arg_14_0.activity
	local var_14_1 = "open"
	local var_14_2 = xyd.ServerTime.get():getServerTime()

	if var_14_2 < var_14_0.start_time and var_14_0.is_open == 0 then
		local var_14_3 = "not_open"
	elseif var_14_2 > var_14_0.end_time and var_14_0.is_open == 0 then
		local var_14_4 = "expired"
	end

	arg_14_0.container:getChildByName("last_btn"):addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_15_1 == ccui.TouchEventType.ended then
			if arg_14_0.isOnRotation == true then
				return
			end

			arg_14_0.giftBagId = arg_14_0.giftBagId - 1

			if arg_14_0.giftBagId < 1 then
				arg_14_0.giftBagId = 1
			end

			arg_14_0:changeSky(var_0_5)
			arg_14_0:update()
		end
	end)
	arg_14_0.container:getChildByName("next_btn"):addTouchEventListener(function(arg_16_0, arg_16_1)
		if arg_16_1 == ccui.TouchEventType.ended then
			if arg_14_0.isOnRotation == true then
				return
			end

			arg_14_0.giftBagId = arg_14_0.giftBagId + 1

			if arg_14_0.giftBagId > var_0_3:allCounts() then
				arg_14_0.giftBagId = var_0_3:allCounts()
			end

			arg_14_0:changeSky(var_0_6)
			arg_14_0:update()
		end
	end)
	arg_14_0.container:getChildByName("rule_btn"):addTouchEventListener(function(arg_17_0, arg_17_1)
		if arg_17_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("activity_gacha_rule", {
				rule = "ACTIVITY_PETGROWUP_RULE",
				title = "ACTIVITY_PETGROWUP_TITLE"
			})
		end
	end)
end

function var_0_0.setChageBtnState(arg_18_0)
	arg_18_0.container:getChildByName("last_btn"):setVisible(true)
	arg_18_0.container:getChildByName("next_btn"):setVisible(true)

	if arg_18_0.giftBagId == 1 then
		arg_18_0.container:getChildByName("last_btn"):setVisible(false)
	end

	if arg_18_0.giftBagId == var_0_3:allCounts() then
		arg_18_0.container:getChildByName("next_btn"):setVisible(false)
	end
end

function var_0_0.setGiftContainer(arg_19_0)
	arg_19_0.giftIDs = var_0_3:gift(arg_19_0.giftBagId)
	arg_19_0.modelIDs = var_0_3:modelID(arg_19_0.giftBagId)
	arg_19_0.models = {}

	for iter_19_0 = 1, var_0_4 do
		arg_19_0.container:getChildByName("pet_container" .. iter_19_0):removeAllChildren()
		arg_19_0.container:getChildByName("pet_container" .. iter_19_0):setTouchEnabled(false)
		arg_19_0.container:getChildByName("pet_container" .. iter_19_0):setTouchSwallowEnabled(false)

		arg_19_0.models[iter_19_0] = xyd.HeroAnimation.new(nil, arg_19_0.modelIDs[iter_19_0], 1, {})

		arg_19_0.models[iter_19_0]:setTouchSwallowEnabled(false)
		arg_19_0.models[iter_19_0]:setTouchEnabled(true)
		arg_19_0.models[iter_19_0]:addTo(arg_19_0.container:getChildByName("pet_container" .. iter_19_0))
		arg_19_0.models[iter_19_0]:setPositionX(arg_19_0.container:getChildByName("pet_container" .. iter_19_0):getContentSize().width / 2)
		arg_19_0.models[iter_19_0]:walk(true)
	end

	arg_19_0.models[1]:setScale(0.8)
	arg_19_0.models[1]:setRotation(-15)
	arg_19_0.models[2]:setPositionY(arg_19_0.models[2]:getPositionY() + 20)
	arg_19_0.models[3]:setRotation(15)
end

function var_0_0.rewardItemLayout(arg_20_0, arg_20_1, arg_20_2, arg_20_3, arg_20_4, arg_20_5)
	local var_20_0 = arg_20_2:getChildByName("btn")
	local var_20_1 = arg_20_2:getChildByName("yilingqu")
	local var_20_2 = arg_20_2:getChildByName("lingqu")
	local var_20_3 = arg_20_2:getChildByName("get_gray")
	local var_20_4 = arg_20_2:getChildByName("expired")
	local var_20_5 = arg_20_2:getChildByName("not_begin")
	local var_20_6 = {
		btn = var_20_0,
		alreadyObtain = var_20_1,
		obtain_bright = var_20_2,
		obtain_gray = var_20_3,
		expired = var_20_4,
		notBegin = var_20_5
	}
	local var_20_7 = arg_20_2:getChildByName("reward_container")
	local var_20_8 = arg_20_2:getChildByName("item_title_container")
	local var_20_9 = {
		color = cc.c3b(255, 255, 255)
	}

	var_20_9.size = 20

	local var_20_10 = xyd.AssetLoader.get():loadLabel(var_20_9)

	var_20_10:setMaxLineWidth(280)
	var_20_10:addTo(var_20_8)
	var_20_10:setAnchorPoint(cc.p(0, 0))
	var_20_10:setPosition(10, 3)
	var_20_10:enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)

	local var_20_11 = var_0_3:name(arg_20_4)

	var_20_10:setString(var_20_11)

	local var_20_12 = xyd.ServerTime.get():getServerTime()

	arg_20_0.buyTimes = 0

	if arg_20_0.details.base_info.is_awards[1] == 1 then
		for iter_20_0 = 1, #arg_20_0.details.base_info.is_awards do
			if arg_20_0.details.base_info.is_awards[iter_20_0] == 1 then
				arg_20_0.buyTimes = iter_20_0
			else
				break
			end
		end
	end

	arg_20_0:rewardFormat(var_20_7, arg_20_4)

	if var_20_12 < arg_20_1.start_time then
		arg_20_0:setBtnGetState(-2, var_20_6)

		return
	elseif var_20_12 > arg_20_1.end_time then
		arg_20_0:setBtnGetState(2, var_20_6)

		return
	end

	if not arg_20_1.details.base_info.is_awards then
		arg_20_0:setBtnGetState(-1, var_20_6)

		return
	end

	if arg_20_5 < arg_20_0.buyTimes + 1 then
		arg_20_0:setBtnGetState(0, var_20_6)
	elseif arg_20_5 == arg_20_0.buyTimes + 1 then
		arg_20_0:setBtnGetState(1, var_20_6)
	else
		arg_20_0:setBtnGetState(-1, var_20_6)
	end

	var_20_0:addTouchEventListener(function(arg_21_0, arg_21_1)
		if arg_21_1 == ccui.TouchEventType.ended then
			if arg_20_0.player.crystal >= var_0_3:price(arg_20_4) then
				local var_21_0 = {
					id = arg_20_0.giftBagId,
					activityID = arg_20_1.table_id,
					giftIDs = var_0_3:gift(arg_20_0.giftBagId),
					modelIDs = var_0_3:modelID(arg_20_0.giftBagId)
				}

				function var_21_0.callback()
					if arg_20_0 and not tolua.isnull(arg_20_0.container) then
						arg_20_0.details.base_info.is_awards[var_21_0.id] = 1

						arg_20_0:initialGiftBagID()
						arg_20_0:setCurrentGiftBag()
						arg_20_0:setGiftContainer()
					end
				end

				xyd.WindowManager.get():openWindow("select_giftbag", var_21_0)
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = xyd.tables.translation:translation("LIBRARY_YUANBAO_ABSENCE")
				})
			end
		end
	end)
end

function var_0_0.rewardFormat(arg_23_0, arg_23_1, arg_23_2)
	local var_23_0 = arg_23_1:getContentSize().height
	local var_23_1 = var_23_0 / 4
	local var_23_2 = var_0_3:gift(arg_23_2)[1]
	local var_23_3 = xyd.tables.gift:items(var_23_2)

	if #var_23_3 == 1 and var_23_3[1] == 0 then
		var_23_3 = {}
	end

	local var_23_4 = xyd.tables.gift:itemNum(var_23_2)
	local var_23_5 = #var_23_3
	local var_23_6 = display.newNode()

	var_23_6:setContentSize(var_23_0, var_23_0)

	local var_23_7 = var_0_3:icon(arg_23_2)

	xyd.setSpriteBorder(var_23_6, var_23_7, 1)
	var_23_6:addTo(arg_23_1)
	var_23_6:setAnchorPoint(cc.p(0, 0))
	var_23_6:setPosition(0 * (var_23_0 + var_23_1), 0)

	local var_23_8 = {}

	var_23_8.id = -100000
	var_23_8.tipsType = 1
	var_23_8.desc1 = var_0_3:giftlist(arg_23_2)

	arg_23_0:addTips(var_23_6, var_23_8)

	for iter_23_0 = 2, #var_23_3 do
		local var_23_9 = display.newNode()

		var_23_9:setContentSize(var_23_0, var_23_0)

		if xyd.tables.item:type(var_23_3[iter_23_0]) == -1 then
			xyd.setAvatarBorder(var_23_3[iter_23_0], var_23_9, 1, xyd.tables.hero:initialStar(var_23_3[iter_23_0]))
		else
			xyd.setItemBorder(var_23_9, var_23_3[iter_23_0], false, false, var_23_4[iter_23_0])
		end

		var_23_9:addTo(arg_23_1)
		var_23_9:setAnchorPoint(cc.p(0, 0))
		var_23_9:setPosition((iter_23_0 - 1) * (var_23_0 + var_23_1), 0)

		local var_23_10 = {
			id = var_23_3[iter_23_0],
			lev = xyd.tables.item:level(var_23_3[iter_23_0])
		}

		if xyd.tables.item:type(var_23_3[iter_23_0]) == -1 then
			var_23_10.tipsType = 0
			var_23_10.desc1 = xyd.tables.hero:getDes(var_23_3[iter_23_0])
		elseif specialItem then
			var_23_10.tipsType = 1
			var_23_10.id = -3
		else
			var_23_10.tipsType = 1
			var_23_10.desc1 = xyd.tables.item:desc1(var_23_3[iter_23_0])
			var_23_10.desc2 = xyd.tables.item:desc2(var_23_3[iter_23_0])
		end

		var_23_10.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_23_3[iter_23_0])
		var_23_10.name = xyd.tables.item:name(var_23_3[iter_23_0])

		arg_23_0:addTips(var_23_9, var_23_10)
	end

	local var_23_11 = xyd.tables.gift:crystal(var_23_2)

	if var_23_11 and var_23_11 > 0 then
		local var_23_12 = display.newNode()

		var_23_12:setContentSize(var_23_0, var_23_0)
		xyd.setItemBorder(var_23_12, -1, false, false, var_23_11)
		var_23_12:addTo(arg_23_1)
		var_23_12:setAnchorPoint(cc.p(0, 0))
		var_23_12:setPosition(var_23_5 * (var_23_0 + var_23_1), 0)

		local var_23_13 = {}

		var_23_13.id = -1
		var_23_13.tipsType = 1

		arg_23_0:addTips(var_23_12, var_23_13)

		var_23_5 = var_23_5 + 1
	end

	local var_23_14 = xyd.tables.gift:mana(var_23_2)

	if var_23_14 and var_23_14 > 0 then
		local var_23_15 = display.newNode()

		var_23_15:setContentSize(var_23_0, var_23_0)
		xyd.setItemBorder(var_23_15, -2, false, false, var_23_14)
		var_23_15:addTo(arg_23_1)
		var_23_15:setAnchorPoint(cc.p(0, 0))
		var_23_15:setPosition(var_23_5 * (var_23_0 + var_23_1), 0)

		local var_23_16 = {}

		var_23_16.id = -2
		var_23_16.tipsType = 1

		arg_23_0:addTips(var_23_15, var_23_16)

		local var_23_17 = var_23_5 + 1
	end

	return arg_23_1
end

function var_0_0.release(arg_24_0, arg_24_1)
	var_0_0.super.release(arg_24_1)

	if arg_24_0.handler then
		var_0_1.unscheduleGlobal(arg_24_0.handler)

		arg_24_0.handler = nil
	end
end

return var_0_0
