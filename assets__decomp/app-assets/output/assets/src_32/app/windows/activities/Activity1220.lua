local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityGirlsTreasure
local var_0_3 = xyd.tables.dropbox
local var_0_4 = xyd.tables.misc
local var_0_5 = {
	TEN = 10,
	ONE = 1
}
local var_0_6 = {
	CRYSTAL = 1,
	CARD = 2
}
local var_0_7 = {
	NORMAL = 2,
	SX = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)
	var_2_0:setAnchorPoint(cc.p(0, 0))
	var_2_0:setPosition(0, 0)

	arg_2_0.container = var_2_0:getChildByName("background")

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:refreshLayout()
	arg_3_0.container:getChildByName("desc_1"):setString(var_0_1:translation("ACTIVITY_GIRLS_TREASURE_TEXT_7"))
	arg_3_0.container:getChildByName("desc_2"):setString(var_0_1:translation("ACTIVITY_GIRLS_TREASURE_TEXT_8"))
	arg_3_0.container:getChildByName("node_desc_2"):getChildByName("desc_3"):setString(var_0_1:translation("ACTIVITY_GIRLS_TREASURE_TEXT_14"))
	arg_3_0.container:getChildByName("text_left"):setString(var_0_1:translation("ACTIVITY_GIRLS_TREASURE_TEXT_5"))
	arg_3_0.container:getChildByName("node_cost_1_1"):getChildByName("text_cost"):setString(var_0_4:getValue("activity_girls_treasure_once_price"))
	arg_3_0.container:getChildByName("node_cost_1_2"):getChildByName("text_cost"):setString(var_0_4:getValue("activity_girls_treasure_ten_times_price"))
	arg_3_0.container:getChildByName("btn_rule"):addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_4_0, arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			local var_4_0 = {}

			var_4_0.title_name = "ACTIVITY_GIRLS_TREASURE_TEXT_9"
			var_4_0.rule = "ACTIVITY_GIRLS_TREASURE_TEXT_10"

			xyd.WindowManager.get():openWindow("activity_girls_treasure_text_rule", var_4_0)
		end
	end)
	arg_3_0.container:getChildByName("btn_record"):getChildByName("text_record"):setString(var_0_1:translation("ACTIVITY_GIRLS_TREASURE_TEXT_1"))
	arg_3_0.container:getChildByName("btn_record"):addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_5_0, arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("activity_girls_treasure_record", arg_3_0.activity.details.record)
		end
	end)
	arg_3_0.container:getChildByName("btn_browse"):getChildByName("text_browse"):setString(var_0_1:translation("ACTIVITY_GIRLS_TREASURE_TEXT_2"))
	arg_3_0.container:getChildByName("btn_browse"):addTouchEventListener(function(arg_6_0, arg_6_1)
		xyd.buttonScaleAnim(arg_6_0, arg_6_1)

		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("activity_girls_treasure_browse")
		end
	end)
	arg_3_0.container:getChildByName("btn_one"):getChildByName("text_one"):setString(var_0_1:translation("ACTIVITY_GIRLS_TREASURE_TEXT_3"))
	arg_3_0.container:getChildByName("btn_one"):addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(arg_7_0, arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			local var_7_0 = {
				times = var_0_5.ONE
			}

			if arg_3_0:isCostCard(var_0_5.ONE) then
				var_7_0.sub_type = var_0_6.CARD
			else
				var_7_0.sub_type = var_0_6.CRYSTAL

				if var_0_4:getValue("activity_girls_treasure_once_price") > arg_3_0.selfPlayer.crystal then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
						local var_8_0 = {}

						var_8_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_8_0)
					end, nil, nil, arg_3_0.colorMode)

					return
				end
			end

			xyd.Backend.get():request(xyd.mid.ACTIVITY_1220_SUMMON, var_7_0, function(arg_9_0, arg_9_1)
				if arg_9_0 == xyd.error.OK and arg_9_1 and arg_9_1.awards then
					arg_3_0.activity.details = arg_9_1

					if var_7_0.sub_type == var_0_6.CARD then
						local var_9_0 = var_0_4:getValue("activity_girls_treasure_item")

						arg_3_0.selfPlayer:getBackpack():removeItem({
							itemID = var_9_0,
							itemNum = var_0_5.ONE
						})
					end

					local var_9_1 = {}

					arg_3_0.selfPlayer:handleRewardsWithoutShow(arg_9_1.awards)

					for iter_9_0, iter_9_1 in pairs(arg_9_1.awards) do
						if tonumber(iter_9_0) then
							table.insert(var_9_1, iter_9_1)
						end
					end

					local var_9_2 = {
						items = var_9_1,
						times = var_0_5.ONE,
						extraAward = arg_9_1.items
					}

					for iter_9_2, iter_9_3 in pairs(var_9_1) do
						arg_3_0.selfPlayer:heroUpdateEvent_({
							name = xyd.event.HERO_UPDATE,
							params = iter_9_3
						}, true)
					end

					xyd.WindowManager.get():openWindow("activity_girls_treasure_award_show", var_9_2)
					arg_3_0:refreshLayout()
				end
			end)
		end
	end)
	arg_3_0.container:getChildByName("btn_ten"):getChildByName("text_ten"):setString(var_0_1:translation("ACTIVITY_GIRLS_TREASURE_TEXT_4"))
	arg_3_0.container:getChildByName("btn_ten"):addTouchEventListener(function(arg_10_0, arg_10_1)
		xyd.buttonScaleAnim(arg_10_0, arg_10_1)

		if arg_10_1 == ccui.TouchEventType.ended then
			local var_10_0 = {
				times = var_0_5.TEN
			}

			if arg_3_0:isCostCard(var_0_5.TEN) then
				var_10_0.sub_type = var_0_6.CARD
			else
				var_10_0.sub_type = var_0_6.CRYSTAL

				if var_0_4:getValue("activity_girls_treasure_ten_times_price") > arg_3_0.selfPlayer.crystal then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
						local var_11_0 = {}

						var_11_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_11_0)
					end, nil, nil, arg_3_0.colorMode)

					return
				end
			end

			xyd.Backend.get():request(xyd.mid.ACTIVITY_1220_SUMMON, var_10_0, function(arg_12_0, arg_12_1)
				if arg_12_0 == xyd.error.OK and arg_12_1 and arg_12_1.awards then
					arg_3_0.activity.details = arg_12_1

					if var_10_0.sub_type == var_0_6.CARD then
						local var_12_0 = var_0_4:getValue("activity_girls_treasure_item")

						arg_3_0.selfPlayer:getBackpack():removeItem({
							itemID = var_12_0,
							itemNum = var_0_5.TEN
						})
					end

					local var_12_1 = {}

					arg_3_0.selfPlayer:handleRewardsWithoutShow(arg_12_1.awards)

					for iter_12_0, iter_12_1 in pairs(arg_12_1.awards) do
						if tonumber(iter_12_0) then
							table.insert(var_12_1, iter_12_1)
						end
					end

					local var_12_2 = {
						items = var_12_1,
						times = var_0_5.TEN,
						extraAward = arg_12_1.items
					}

					for iter_12_2, iter_12_3 in pairs(var_12_1) do
						arg_3_0.selfPlayer:heroUpdateEvent_({
							name = xyd.event.HERO_UPDATE,
							params = iter_12_3
						}, true)
					end

					xyd.WindowManager.get():openWindow("activity_girls_treasure_award_show", var_12_2)
					arg_3_0:refreshLayout()
				end
			end)
		end
	end)
end

function var_0_0.refreshLayout(arg_13_0)
	arg_13_0:calculateRate()

	local var_13_0 = arg_13_0:isCostCard(var_0_5.ONE)

	arg_13_0.container:getChildByName("node_cost_1_1"):setVisible(not var_13_0)
	arg_13_0.container:getChildByName("node_cost_2_1"):setVisible(var_13_0)

	local var_13_1 = arg_13_0:isCostCard(var_0_5.TEN)

	arg_13_0.container:getChildByName("node_cost_1_2"):setVisible(not var_13_1)
	arg_13_0.container:getChildByName("node_cost_2_2"):setVisible(var_13_1)
	arg_13_0.container:getChildByName("text_left_count"):setString(var_0_2:time(var_0_7.SX) - arg_13_0.activity.details.sx_count)
end

function var_0_0.calculateRate(arg_14_0)
	local var_14_0 = 0
	local var_14_1 = 0
	local var_14_2 = var_0_2:dropboxID(var_0_7.SX)
	local var_14_3 = var_0_3:itemIDs(var_14_2)

	for iter_14_0 = 1, #var_14_3 do
		var_14_0 = var_14_0 + 1

		if not arg_14_0.selfPlayer:getHeroIgnoreAwaken(var_14_3[iter_14_0]) then
			var_14_1 = var_14_1 + 1
		end
	end

	local var_14_4 = var_0_2:dropboxID(var_0_7.NORMAL)
	local var_14_5 = var_0_3:itemIDs(var_14_4)

	for iter_14_1 = 1, #var_14_5 do
		var_14_0 = var_14_0 + 1

		if not arg_14_0.selfPlayer:getHeroIgnoreAwaken(var_14_5[iter_14_1]) then
			var_14_1 = var_14_1 + 1
		end
	end

	if var_14_1 > 0 then
		arg_14_0.container:getChildByName("node_desc_1"):setVisible(true)
		arg_14_0.container:getChildByName("node_desc_2"):setVisible(false)
	else
		arg_14_0.container:getChildByName("node_desc_1"):setVisible(false)
		arg_14_0.container:getChildByName("node_desc_2"):setVisible(true)
	end

	local var_14_6 = math.floor((var_14_1 + var_14_0) / (var_14_0 * 2) * 100)

	arg_14_0.container:getChildByName("node_desc_1"):getChildByName("fnt"):setString(var_14_6 .. "%")
end

function var_0_0.isCostCard(arg_15_0, arg_15_1)
	return arg_15_1 <= arg_15_0.selfPlayer:getBackpack():getItemNumByID(var_0_4:getValue("activity_girls_treasure_item"))
end

return var_0_0
