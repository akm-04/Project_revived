local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityMonthLimit
local var_0_3 = import("framework.scheduler")
local var_0_4 = xyd.tables.activityDecodeReward
local var_0_5 = "skeletons/ui_effect/activity_decode/biggift"
local var_0_6 = "skeletons/ui_effect/activity_decode/num"
local var_0_7 = "skeletons/ui_effect/activity_decode/smallgift"
local var_0_8 = {
	NotReach = 1,
	Awarded = 3,
	CanAward = 2
}
local var_0_9 = {
	7,
	8,
	9,
	10,
	11,
	12,
	13,
	6,
	5,
	4,
	3,
	2,
	1,
	14
}

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.details = arg_1_0.activity.details
	arg_1_0.days = arg_1_0.activity.days
	arg_1_0.mission_list = arg_1_0.details.mission_list
end

function var_0_0.decodePickNum(arg_2_0, arg_2_1, arg_2_2)
	local var_2_0 = arg_2_1 or {}

	xyd.Backend.get():request(xyd.mid.DECODE_PICK_NUM, var_2_0, function(arg_3_0, arg_3_1)
		if arg_3_0 == xyd.error.OK then
			arg_2_0:handleRespone(arg_3_1)
		end

		if arg_2_2 then
			arg_2_2(arg_3_0, arg_3_1)
		end
	end)
end

function var_0_0.decodeRandomNum(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0 = arg_4_1 or {}

	xyd.Backend.get():request(xyd.mid.DECODE_RANDOM_NUM, var_4_0, function(arg_5_0, arg_5_1)
		if arg_5_0 == xyd.error.OK then
			if arg_5_1.num and arg_4_0.details.num_map[arg_5_1.num] == 1 then
				local var_5_0 = string.format(var_0_1:translation("ACTIVITY_DECODE_GET_NUM_EXIST"), arg_5_1.num, 1)

				xyd.WindowManager.get():openWindow("toast", {
					message = var_5_0
				})
			end

			arg_4_0:handleRespone(arg_5_1)
		end

		if arg_4_2 then
			arg_4_2(arg_5_0, arg_5_1)
		end
	end)
end

function var_0_0.decodeBuyScore(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = arg_6_1 or {}

	xyd.Backend.get():request(xyd.mid.DECODE_BUY_SCORE, var_6_0, function(arg_7_0, arg_7_1)
		if arg_7_0 == xyd.error.OK then
			arg_6_0:handleRespone(arg_7_1)
		end

		if arg_6_2 then
			arg_6_2(arg_7_0, arg_7_1)
		end
	end)
end

function var_0_0.handleRespone(arg_8_0, arg_8_1)
	arg_8_0.isCanUse = false

	if arg_8_1.score then
		arg_8_0.details.score = arg_8_1.score
	end

	if arg_8_1.energy then
		arg_8_0.details.energy = arg_8_1.energy
	end

	if arg_8_1.num_map then
		arg_8_0.details.num_map = arg_8_1.num_map
	end

	if arg_8_1.is_awarded then
		arg_8_0.details.is_awarded = arg_8_1.is_awarded
	end

	if arg_8_1.awards then
		arg_8_0.selfPlayer:handleRewards(arg_8_1.awards)
	end

	arg_8_0:updateInfo()
	arg_8_0:updateDecodeItems()
	arg_8_0:updateGiftBoxState()
end

function var_0_0.show(arg_9_0, arg_9_1)
	var_0_0.super.show(arg_9_0, arg_9_1)

	if not arg_9_0.res or arg_9_0.res == 0 then
		print("No res available.")

		return
	end

	local var_9_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_9_0.res)

	if var_9_0 then
		arg_9_0.container = var_9_0:getChildByName("container")

		var_9_0:addTo(arg_9_0.parent)
		arg_9_0.container:getChildByName("rule_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
			if arg_10_1 == ccui.TouchEventType.ended then
				local var_10_0 = {
					title_name = "ACTIVITY_DECODE_RULE_TITLE",
					rule = "ACTIVITY_DECODE_RULE_TEXT"
				}

				xyd.WindowManager.get():openWindow("new_text_rule", var_10_0)
			end
		end)
		arg_9_0.container:getChildByName("task_btn"):addTouchEventListener(function(arg_11_0, arg_11_1)
			if arg_11_1 == ccui.TouchEventType.ended then
				local var_11_0 = {
					title_name = "ACTIVITY_DECODE_RULE_TITLE",
					rule = "ACTIVITY_DECODE_RULE_TEXT",
					type = 1,
					activity = arg_9_0.activity
				}

				xyd.WindowManager.get():openWindow("decode_task", var_11_0)
			end
		end)

		local function var_9_1(...)
			if arg_9_0.selfPlayer.crystal < xyd.tables.misc.activityDecodeCreditsPrice then
				local var_12_0 = {
					rcallBefore = 0,
					title = var_0_1:translation("TIP"),
					txt = var_0_1:translation("ZUANSHI_ABSENCE"),
					rcallback = function()
						local var_13_0 = {}

						var_13_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_13_0)
					end,
					colorMode = xyd.ColorMode.ACTIVITY,
					align = xyd.ui_align.CENTER,
					valign = xyd.ui_valign.CENTER
				}

				xyd.WindowManager.get():openWindow("alert_green", var_12_0)

				return
			end

			local var_12_1 = string.format(var_0_1:translation("ACTIVITY_DECODE_BUY_CREDITS"), xyd.tables.misc.activityDecodeCreditsPrice)
			local var_12_2 = {
				rcallBefore = 0,
				title = var_0_1:translation("TIP"),
				txt = var_12_1,
				rcallback = function()
					local var_14_0 = {}

					arg_9_0:decodeBuyScore(var_14_0, function(arg_15_0, arg_15_1)
						if arg_15_0 == xyd.error.OK then
							-- block empty
						end
					end)
				end,
				colorMode = xyd.ColorMode.ACTIVITY,
				align = xyd.ui_align.CENTER,
				valign = xyd.ui_valign.CENTER
			}

			xyd.WindowManager.get():openWindow("alert_green", var_12_2)
		end

		arg_9_0.container:getChildByName("use_btn"):addTouchEventListener(function(arg_16_0, arg_16_1)
			if arg_16_1 == ccui.TouchEventType.ended then
				if arg_9_0.details.score < xyd.tables.misc.acitivityDecodeCreditsToNum then
					local var_16_0 = var_0_1:translation("ACTIVITY_DECODE_CREDITS_NOT_ENOUGH")

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_16_0, function()
						var_9_1()
					end, nil, nil, xyd.ColorMode.ACTIVITY)
				else
					arg_9_0.isCanUse = not arg_9_0.isCanUse

					arg_9_0:updateDecodeItems()
				end
			end
		end)
		arg_9_0.container:getChildByName("buy_btn"):addTouchEventListener(function(arg_18_0, arg_18_1)
			if arg_18_1 == ccui.TouchEventType.ended then
				var_9_1()
			end
		end)
		arg_9_0.container:getChildByName("decode_btn"):addTouchEventListener(function(arg_19_0, arg_19_1)
			if arg_19_1 == ccui.TouchEventType.ended then
				local var_19_0 = var_0_1:translation("ACTIVITY_DECODE_USE_ENERGY")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_19_0, function()
					local var_20_0 = {}

					arg_9_0:decodeRandomNum(var_20_0, function(arg_21_0, arg_21_1)
						if arg_21_0 == xyd.error.OK then
							-- block empty
						end
					end)
				end, nil, nil, xyd.ColorMode.ACTIVITY)
			end
		end)
		arg_9_0.container:getChildByName("award_container"):addTouchEventListener(function(arg_22_0, arg_22_1)
			local var_22_0 = 14
			local var_22_1 = arg_9_0.container:getChildByName("award_container")

			if arg_22_1 == ccui.TouchEventType.began then
				if arg_9_0:getAwardState(var_22_0) == var_0_8.NotReach then
					local var_22_2 = var_0_4:content(var_22_0)
					local var_22_3 = var_0_4:num(var_22_0)
					local var_22_4 = xyd.getFormatItemsByIdNums(var_22_2, var_22_3)

					xyd.WindowManager.get():openWindow("common_award", {
						awards = var_22_4
					})

					local var_22_5 = var_22_1:getParent():convertToWorldSpace(cc.p(0, 0))
					local var_22_6 = var_22_1:getParent():convertToWorldSpace(cc.p(var_22_1:getPositionX() - 250, var_22_1:getPositionY() + 40))

					var_22_6.x = math.max(var_22_6.x, 50)
					var_22_6.y = math.max(var_22_6.y, 140)

					xyd.WindowManager.get():getWindow("common_award"):setPosition(var_22_6)
				end
			elseif arg_22_1 == ccui.TouchEventType.canceled then
				if xyd.WindowManager:get():getWindow("common_award") then
					xyd.WindowManager:get():closeWindow("common_award")
				end
			elseif arg_22_1 == ccui.TouchEventType.ended then
				if xyd.WindowManager:get():getWindow("common_award") then
					xyd.WindowManager:get():closeWindow("common_award")
				end

				if arg_9_0:getAwardState(var_22_0) ~= var_0_8.CanAward then
					return
				end

				arg_9_0.activitiesModel:getActivityReward(arg_9_0.activity.table_id, var_22_0, function(arg_23_0, arg_23_1)
					if arg_23_0 == xyd.error.OK then
						arg_9_0:handleRespone(arg_23_1)
					end
				end)
			end
		end)
		arg_9_0:initDecodeItem()
		arg_9_0:initGiftBox()
		arg_9_0:updateInfo()
		arg_9_0:updateGiftBoxState()
		arg_9_0:updateDecodeItems()
	end
end

function var_0_0.updateInfo(arg_24_0, ...)
	if arg_24_0.container and not tolua.isnull(arg_24_0.container) then
		arg_24_0.container:getChildByName("score_txt"):setString(arg_24_0.details.score)
		arg_24_0.container:getChildByName("decode_num_txt"):setString(arg_24_0.details.energy)

		local var_24_0 = arg_24_0.container:getChildByName("decode_btn")

		if arg_24_0.details.energy > 0 then
			var_24_0:setBright(true)
			var_24_0:setTouchEnabled(true)
		else
			var_24_0:setBright(false)
			var_24_0:setTouchEnabled(false)
		end
	end
end

function var_0_0.initDecodeItem(arg_25_0)
	arg_25_0.decodeItems = {}

	local var_25_0 = 91
	local var_25_1 = 59

	for iter_25_0 = 1, 6 do
		for iter_25_1 = 1, 6 do
			local var_25_2 = (iter_25_0 - 1) * 6 + iter_25_1
			local var_25_3 = arg_25_0:createListContent(var_25_2)

			var_25_3:addTo(arg_25_0.container:getChildByName("decode_pos"))
			var_25_3:setPosition(cc.p((iter_25_1 - 1) * var_25_0, (6 - iter_25_0) * var_25_1))
			table.insert(arg_25_0.decodeItems, var_25_3:getChildByName("source"):getChildByName("container"))
		end
	end
end

function var_0_0.updateDecodeItems(arg_26_0, ...)
	for iter_26_0 = 1, #arg_26_0.decodeItems do
		local var_26_0 = arg_26_0.decodeItems[iter_26_0]

		var_26_0:getChildByName("effect"):setVisible(false)

		if arg_26_0.details.num_map[iter_26_0] > 0 then
			var_26_0:getChildByName("grid_light"):setVisible(true)
		elseif arg_26_0.isCanUse and iter_26_0 ~= 1 and iter_26_0 ~= 36 then
			var_26_0:getChildByName("effect"):setVisible(true)
		else
			var_26_0:getChildByName("grid_light"):setVisible(false)
		end
	end
end

function var_0_0.initGiftBox(arg_27_0)
	arg_27_0.giftItems = {}

	local var_27_0 = 7

	for iter_27_0 = 1, 13 do
		local var_27_1 = arg_27_0:createGiftContent(var_0_9[iter_27_0])

		var_27_1:addTo(arg_27_0.container:getChildByName("box_pos"))
		table.insert(arg_27_0.giftItems, var_27_1:getChildByName("source"):getChildByName("container"))

		if iter_27_0 < var_27_0 then
			var_27_1:setPositionX(-(7 - iter_27_0) * 89 + 20)
		elseif var_27_0 < iter_27_0 then
			var_27_1:setPositionY((iter_27_0 - 7) * 60 - 2)
		end

		local var_27_2 = xyd.createEffect(var_0_7)

		var_27_2:addTo(arg_27_0.giftItems[iter_27_0])
		var_27_2:play(nil, true)
		var_27_2:setPosition(arg_27_0.giftItems[iter_27_0]:getChildByName("box_close"):getPosition())
		var_27_2:setName("effect")
	end

	table.insert(arg_27_0.giftItems, arg_27_0.container:getChildByName("award_container"))

	local var_27_3 = xyd.createEffect(var_0_5)

	var_27_3:addTo(arg_27_0.container:getChildByName("award_container"))
	var_27_3:play(nil, true)
	var_27_3:setPosition(arg_27_0.container:getChildByName("award_container"):getChildByName("box_close"):getPosition())
	var_27_3:setName("effect")
end

function var_0_0.updateGiftBoxState(arg_28_0)
	for iter_28_0 = 1, #arg_28_0.details.is_awarded do
		local var_28_0 = var_0_9[iter_28_0]
		local var_28_1 = arg_28_0.giftItems[iter_28_0]

		var_28_1:getChildByName("box_close"):setVisible(false)
		var_28_1:getChildByName("box_gray"):setVisible(false)
		var_28_1:getChildByName("box_open"):setVisible(false)
		var_28_1:getChildByName("effect"):setVisible(false)

		local var_28_2 = arg_28_0:getAwardState(var_28_0)

		if var_28_2 == var_0_8.NotReach then
			var_28_1:getChildByName("box_gray"):setVisible(true)
		elseif var_28_2 == var_0_8.CanAward then
			var_28_1:getChildByName("effect"):setVisible(true)
		else
			var_28_1:getChildByName("box_open"):setVisible(true)
		end
	end
end

function var_0_0.createGiftContent(arg_29_0, arg_29_1)
	local var_29_0 = display.newNode()
	local var_29_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1171/main/box_item.csb")
	local var_29_2 = var_29_1:getChildByName("container")

	var_29_1:setTouchEnabled(true)
	var_29_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_30_0)
		if arg_30_0.name == "began" then
			var_29_0:setScale(0.9)

			if arg_29_0:getAwardState(arg_29_1) == var_0_8.NotReach then
				local var_30_0 = var_0_4:content(arg_29_1)
				local var_30_1 = var_0_4:num(arg_29_1)
				local var_30_2 = xyd.getFormatItemsByIdNums(var_30_0, var_30_1)

				xyd.WindowManager.get():openWindow("common_award", {
					awards = var_30_2
				})

				local var_30_3 = var_29_0:getParent():convertToWorldSpace(cc.p(0, 0))
				local var_30_4 = var_29_0:getParent():convertToWorldSpace(cc.p(var_29_0:getPositionX() - 380, var_29_0:getPositionY() - 80))

				var_30_4.x = math.min(var_30_4.x, 800)
				var_30_4.y = math.min(var_30_4.y, 450)

				xyd.WindowManager.get():getWindow("common_award"):setPosition(var_30_4)
			end

			return true
		elseif arg_30_0.name == "ended" then
			xyd.playButtonSound()
			var_29_0:setScale(1)

			if xyd.WindowManager:get():getWindow("common_award") then
				xyd.WindowManager:get():closeWindow("common_award")
			end

			if arg_29_0:getAwardState(arg_29_1) ~= var_0_8.CanAward then
				return
			end

			arg_29_0.activitiesModel:getActivityReward(arg_29_0.activity.table_id, arg_29_1, function(arg_31_0, arg_31_1)
				if arg_31_0 == xyd.error.OK then
					arg_29_0:handleRespone(arg_31_1)
				end
			end)
		end
	end)
	var_29_1:addTo(var_29_0)
	var_29_1:setAnchorPoint(cc.p(0, 0))
	var_29_0:setContentSize(var_29_2:getContentSize())
	var_29_1:setName("source")
	var_29_0:setAnchorPoint(cc.p(0.5, 0.5))

	return var_29_0
end

function var_0_0.getAwardState(arg_32_0, arg_32_1)
	local var_32_0 = var_0_4:numRequired(arg_32_1)
	local var_32_1 = arg_32_0.details.is_awarded
	local var_32_2 = arg_32_0.details.num_map

	if var_32_1[arg_32_1] ~= 0 then
		return var_0_8.Awarded
	end

	for iter_32_0, iter_32_1 in pairs(var_32_0) do
		if var_32_2[iter_32_1] == 0 then
			return var_0_8.NotReach
		end
	end

	return var_0_8.CanAward
end

function var_0_0.createListContent(arg_33_0, arg_33_1)
	local var_33_0 = display.newNode()
	local var_33_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1171/main/decode_item.csb")
	local var_33_2 = var_33_1:getChildByName("container")

	var_33_1:setTouchEnabled(true)
	var_33_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_34_0)
		if arg_34_0.name == "began" then
			if arg_33_0.details.num_map[arg_33_1] == 1 then
				return false
			end

			if arg_33_0.isCanUse then
				var_33_2:getChildByName("effect"):setVisible(true)
			end

			var_33_0:setScale(0.9)

			return true
		elseif arg_34_0.name == "ended" then
			xyd.playButtonSound()
			var_33_0:setScale(1)

			if arg_33_1 == 1 or arg_33_1 == 36 then
				local var_34_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
				local var_34_1 = {
					activity_id = xyd.Activities.Decode
				}

				var_34_0:loadSingleActivity(var_34_1, function(arg_35_0, arg_35_1)
					if arg_35_0 == xyd.error.OK then
						arg_33_0.activity = arg_35_1
						arg_33_0.details = arg_33_0.activity.details

						local var_35_0 = {
							collect_items = arg_33_0.details.collect_items
						}

						if arg_33_1 == 1 then
							var_35_0.need_num = xyd.tables.misc.acitvityDecodeNum1
						else
							var_35_0.need_num = xyd.tables.misc.activityDecodeNum36
						end

						xyd.WindowManager.get():openWindow("activity_decode_collection_tip", var_35_0)
						var_33_2:getChildByName("effect"):setVisible(false)
						arg_33_0:updateInfo()
						arg_33_0:updateDecodeItems()
						arg_33_0:updateGiftBoxState()
					end
				end)

				return
			end

			if arg_33_0.isCanUse then
				local var_34_2 = string.format(var_0_1:translation("ACTIVITY_DECODE_USE_CREDITS"), xyd.tables.misc.acitivityDecodeCreditsToNum)

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_34_2, function()
					local var_36_0 = {
						num = arg_33_1
					}

					arg_33_0:decodePickNum(var_36_0, function(arg_37_0, arg_37_1)
						if arg_37_0 == xyd.error.OK then
							-- block empty
						end

						var_33_2:getChildByName("effect"):setVisible(false)
					end)
				end, nil, nil, xyd.ColorMode.ACTIVITY)
			end
		end
	end)

	local var_33_3

	if arg_33_1 == 1 or arg_33_1 == 36 then
		local var_33_4 = {
			UILabelType = cc.ui.UILabel.LABEL_TYPE_BM
		}

		var_33_4.font = "windows/activities/1171/main/decode_r.fnt"
		var_33_3 = cc.ui.UILabel.new(var_33_4)
	else
		local var_33_5 = {
			UILabelType = cc.ui.UILabel.LABEL_TYPE_BM
		}

		var_33_5.font = "windows/activities/1171/main/decode_b.fnt"
		var_33_3 = cc.ui.UILabel.new(var_33_5)
	end

	var_33_3:setAnchorPoint(cc.p(0.5, 0.5))
	var_33_3:addTo(var_33_2:getChildByName("num_pos"))
	var_33_3:setString(arg_33_1)

	local var_33_6 = xyd.createEffect(var_0_6)

	var_33_6:addTo(var_33_2)
	var_33_6:setPosition(cc.p(var_33_2:getContentSize().width / 2, var_33_2:getContentSize().height / 2 + 1))
	var_33_6:setName("effect")
	var_33_6:setVisible(false)
	var_33_6:play(nil, true)
	var_33_1:addTo(var_33_0)
	var_33_1:setAnchorPoint(cc.p(0, 0))
	var_33_0:setContentSize(var_33_2:getContentSize())
	var_33_1:setName("source")
	var_33_0:setAnchorPoint(cc.p(0.5, 0.5))

	return var_33_0
end

return var_0_0
