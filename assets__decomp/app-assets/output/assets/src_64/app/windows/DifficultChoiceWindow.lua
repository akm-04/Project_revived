local var_0_0 = class("DifficultItem", function()
	return cc.Node:create()
end)

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()
end

function var_0_0.contentView(arg_3_0)
	if arg_3_0.contentView_ == nil then
		arg_3_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_3_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/trial_window/trial_item.csb"))
		arg_3_0.contentView_:addTo(arg_3_0):setAnchorPoint(0.5, 0.5)
		arg_3_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_3_0.contentView_
end

function var_0_0.setParams(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	local var_4_0 = xyd.tables.campaign:trialLv(arg_4_1)

	for iter_4_0 = 1, 12 do
		if arg_4_3 <= iter_4_0 then
			arg_4_0.contentView_:nodeByName("button" .. iter_4_0):setVisible(false)
		end

		if var_4_0 == iter_4_0 then
			arg_4_0.contentView_:nodeByName("button" .. iter_4_0):setVisible(true)
		else
			arg_4_0.contentView_:nodeByName("button" .. iter_4_0):setVisible(false)
		end

		if arg_4_2 >= 0 and arg_4_2 <= 3 then
			for iter_4_1 = 1, 3 do
				if arg_4_2 < iter_4_1 then
					arg_4_0.contentView_:nodeByName("light_star_" .. iter_4_1):setVisible(false)
				else
					arg_4_0.contentView_:nodeByName("light_star_" .. iter_4_1):setVisible(true)
				end
			end
		end
	end
end

local var_0_1 = class("DifficultChoiceWindow", import("app.common.ui.BaseWindow"))
local var_0_2 = xyd.tables.translation

function var_0_1.ctor(arg_5_0, arg_5_1, arg_5_2)
	var_0_1.super.ctor(arg_5_0, arg_5_1, arg_5_2)

	arg_5_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_1.scrollListener(arg_6_0, arg_6_1)
	if arg_6_1.name == "began" then
		arg_6_0.scrollViewMoved_ = false
		arg_6_0.prevX_ = arg_6_1.x
	elseif arg_6_1.name == "moved" and 20 <= math.abs(arg_6_1.x - arg_6_0.prevX_) then
		arg_6_0.scrollViewMoved_ = true
	end
end

function var_0_1.willOpen(arg_7_0, arg_7_1)
	arg_7_0:nodeByName("btn_buy"):setVisible(false)

	arg_7_0.listView_ = cc.ui.UIListView.new({
		touchOnContent = true,
		viewRect = cc.rect(0, 0, 850, 250),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(arg_7_0:nodeByName("campaign_list")):onScroll(handler(arg_7_0, arg_7_0.scrollListener))

	arg_7_0.listView_:setTouchSwallowEnabled(false)

	arg_7_0.initScrollNodeX = nil

	arg_7_0:nodeByName("txt_name"):setString(var_0_2:translation("DIFFICULT_CHOICE_TITLE"))

	arg_7_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	local var_7_0 = xyd.tables.sound:getSound("ui_button_click")
	local var_7_1

	audio.playSound(var_7_0, false)
	arg_7_0.selfPlayer:loadTrialInfos(function()
		if arg_7_0.selfPlayer and arg_7_0.updateItems then
			arg_7_0.challenges = arg_7_0.selfPlayer.challengeInfos_

			for iter_8_0, iter_8_1 in pairs(arg_7_0.challenges) do
				arg_7_0.lastchallengeid = iter_8_1.lastID
				arg_7_0.leftTimes = iter_8_1.leftTimes
				var_7_1 = xyd.tables.challenge:energyCost(iter_8_1.id)
				arg_7_0.challengeid = iter_8_1.id
			end

			arg_7_0.campaigns = arg_7_0.selfPlayer.worldMaps_

			arg_7_0:updateItems(arg_7_0.challengeid)
		end
	end)
	arg_7_0:nodeByName("txt_energy"):setString(var_0_2:translation("DIFFICULT_CHOICE_ENERGY_COST") .. tostring(var_7_1))
	arg_7_0:nodeByName("txt_left_times"):setString(var_0_2:translation("MAP_LEFT_TIMES") .. tostring(arg_7_0.leftTimes))
end

function var_0_1.updateItems(arg_9_0, arg_9_1)
	arg_9_0.listView_:removeAllItems()

	local var_9_0 = xyd.tables.challenge:challenges(arg_9_1)
	local var_9_1 = arg_9_0.lastchallengeid
	local var_9_2 = 0

	for iter_9_0 = 1, #var_9_0 do
		local var_9_3 = xyd.tables.campaign:campaignType(var_9_0[iter_9_0])
		local var_9_4 = tonumber(var_9_0[iter_9_0])

		if var_9_4 <= var_9_1 then
			local var_9_5 = arg_9_0.listView_:newItem()
			local var_9_6 = display.newNode()
			local var_9_7 = var_0_0.new()
			local var_9_8 = xyd.tables.campaign:openLv(var_9_0[iter_9_0])
			local var_9_9 = 0

			if arg_9_0.campaigns[var_9_4] ~= nil then
				var_9_9 = arg_9_0.campaigns[var_9_4].star
			end

			if var_9_8 <= arg_9_0.player.lev then
				var_9_2 = var_9_2 + 1
			end

			var_9_7:setParams(var_9_0[iter_9_0], var_9_9, #var_9_0)
			var_9_7:setTouchEnabled(true)
			var_9_7:setTouchSwallowEnabled(false)
			var_9_7:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_10_0)
				if arg_10_0.name == "began" then
					local var_10_0 = xyd.tables.sound:getSound("ui_button_click")

					audio.playSound(var_10_0, false)
					var_9_7.contentView_:nodeByName("container"):setScale(0.9)

					return true
				elseif arg_10_0.name == "ended" then
					var_9_7.contentView_:nodeByName("container"):setScale(1)

					if not arg_9_0.scrollViewMoved_ then
						if arg_9_0.player.lev >= var_9_8 then
							if arg_9_0.leftTimes > 0 then
								local var_10_1 = {
									campaignID = var_9_0[iter_9_0],
									campaignType = var_9_3,
									star = var_9_9,
									dailyLimit = arg_9_0.leftTimes,
									levelNumber = iter_9_0
								}

								xyd.WindowManager.get():openWindow("preperation_battle_prepare", var_10_1)
							else
								xyd.WindowManager.get():openWindow("toast", {
									message = var_0_2:translation("TRIAL_NO_TIMES_LEFT")
								})

								return
							end
						else
							local var_10_2 = string.format(var_0_2:translation("LEV_OPEN_TIPS"), var_9_8)

							xyd.WindowManager.get():openWindow("toast", {
								message = var_10_2
							})
						end
					end
				end
			end)
			var_9_6:addChild(var_9_7)
			var_9_5:addContent(var_9_6)
			var_9_6:setContentSize(220, 234)
			var_9_5:setItemSize(250, 234)
			arg_9_0.listView_:addItem(var_9_5)
		end
	end

	arg_9_0.listView_:reload()

	local var_9_10 = arg_9_0.listView_:getScrollNode()

	if not arg_9_0.initScrollNodeX then
		arg_9_0.initScrollNodeX = var_9_10:getPositionX()
	end

	if var_9_2 - 3 > 0 then
		var_9_10:setPositionX(arg_9_0.initScrollNodeX - var_9_2 * 250 + 850)
	end
end

function var_0_1.didOpen(arg_11_0)
	arg_11_0:addBlockLayer(nil)
end

return var_0_1
