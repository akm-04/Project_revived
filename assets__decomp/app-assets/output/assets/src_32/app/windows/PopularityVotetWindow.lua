local var_0_0 = class("PopularityVotetWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityVoteTimeline
local var_0_3 = xyd.tables.activityVoteTicket
local var_0_4 = require("framework.scheduler")
local var_0_5 = 100
local var_0_6 = 10

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.popularContest = xyd.ModelManager.get():loadModel(xyd.ModelType.POPULARITY_CONTEST)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.data = arg_1_2.data
	arg_1_0.tableID = arg_1_0.data.table_id
	arg_1_0.stage = arg_1_0.popularContest:getStage()
	arg_1_0.selectVoteType = xyd.PopularityHeroPollType.NORMAL
	arg_1_0.addTicketNum = 1
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	arg_2_0.isShowSuper = var_0_2:isShowSuper(arg_2_0.stage)

	arg_2_0:initData()
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.initData(arg_4_0)
	local var_4_0 = var_0_3:itemID(xyd.PopularityHeroPollType.NORMAL)
	local var_4_1 = var_0_3:itemID(xyd.PopularityHeroPollType.SUPER)

	arg_4_0.normalTicketNum = arg_4_0.backpack:getItemNumByID(var_4_0)
	arg_4_0.superTicketNum = arg_4_0.backpack:getItemNumByID(var_4_1)
end

function var_0_0.layout(arg_5_0)
	arg_5_0:setupButton()
	arg_5_0:nodeByName("text_vote_tips"):setString(var_0_1:translation("VOTE_HERO_TIPS_4"))
	arg_5_0:nodeByName("text_vote_tips"):enableOutline(cc.c4b(85, 137, 243, 255), 2)
	arg_5_0:nodeByName("normal_name"):setString(var_0_1:translation("VOTE_HERO_TIPS_14"))
	arg_5_0:nodeByName("special_name"):setString(var_0_1:translation("VOTE_HERO_TIPS_13"))
	arg_5_0:updateView()
	arg_5_0:updateCurrentVoteNum()
end

function var_0_0.updateView(arg_6_0)
	local var_6_0 = arg_6_0.popularContest:getBaseInfo()[tostring(arg_6_0.tableID)] or {
		0,
		0
	}
	local var_6_1 = xyd.tables.hero:name(arg_6_0.tableID)
	local var_6_2 = var_6_0[xyd.PopularityHeroPollType.SUPER] * var_0_3:weight(xyd.PopularityHeroPollType.SUPER)

	if arg_6_0.isShowSuper == 1 then
		local var_6_3 = var_6_0[xyd.PopularityHeroPollType.NORMAL] + var_6_2

		arg_6_0:nodeByName("text_tips_1"):setString(string.format(var_0_1:translation("VOTE_HERO_TIPS_2"), var_6_1, var_6_3))
	else
		local var_6_4 = var_6_0[xyd.PopularityHeroPollType.NORMAL]
		local var_6_5 = string.format(var_0_1:translation("VOTE_HERO_TIPS_2"), var_6_1, var_6_4)
		local var_6_6 = string.format(var_0_1:translation("VOTE_HERO_TIPS_3"), var_6_2)

		arg_6_0:nodeByName("text_tips_1"):setString(var_6_5 .. var_6_6)
	end

	if arg_6_0.normalTicketNum > 0 then
		arg_6_0:nodeByName("normal_num"):setString(string.format(var_0_1:translation("VOTE_HERO_TIPS_15"), arg_6_0.normalTicketNum))
	else
		arg_6_0:nodeByName("normal_num"):setString(var_0_1:translation("VOTE_HERO_TIPS_16"))
	end

	if arg_6_0.superTicketNum > 0 then
		arg_6_0:nodeByName("special_num"):setString(string.format(var_0_1:translation("VOTE_HERO_TIPS_15"), arg_6_0.superTicketNum))
	else
		arg_6_0:nodeByName("special_num"):setString(var_0_1:translation("VOTE_HERO_TIPS_16"))
	end
end

function var_0_0.updateCurrentVoteNum(arg_7_0)
	arg_7_0:nodeByName("text_vote_num"):setString(arg_7_0.addTicketNum)
end

function var_0_0.changeTicketNum(arg_8_0, arg_8_1, arg_8_2)
	if arg_8_2 then
		if arg_8_0.addTicketNum - arg_8_1 < 1 then
			if arg_8_0.longTouchHandler and arg_8_0.longTouchHandler then
				var_0_4.unscheduleGlobal(arg_8_0.longTouchHandler)
			end

			arg_8_0.addTicketNum = 1

			arg_8_0:updateCurrentVoteNum()
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_1:translation("VOTE_HERO_TIPS_5")
			})

			return
		else
			arg_8_0.addTicketNum = arg_8_0.addTicketNum - arg_8_1

			arg_8_0:updateCurrentVoteNum()
		end
	elseif arg_8_0.addTicketNum + arg_8_1 > var_0_5 then
		if arg_8_0.longTouchHandler and arg_8_0.longTouchHandler then
			var_0_4.unscheduleGlobal(arg_8_0.longTouchHandler)
		end

		arg_8_0.addTicketNum = var_0_5

		arg_8_0:updateCurrentVoteNum()
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_1:translation("VOTE_HERO_TIPS_6")
		})

		return
	else
		arg_8_0.addTicketNum = arg_8_0.addTicketNum + arg_8_1

		arg_8_0:updateCurrentVoteNum()
	end
end

function var_0_0.setupButton(arg_9_0)
	local var_9_0 = false

	arg_9_0:nodeByName("btn_delete"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.began then
			arg_10_0:setScale(0.9)

			local var_10_0 = 0

			local function var_10_1()
				var_10_0 = var_10_0 + 0.1

				if var_10_0 > 0.5 then
					var_9_0 = true

					arg_9_0:changeTicketNum(var_0_6, true)
				else
					var_9_0 = false
				end
			end

			var_9_0 = false
			arg_9_0.longTouchHandler = var_0_4.scheduleGlobal(var_10_1, 0.1)
		elseif arg_10_1 == ccui.TouchEventType.ended or arg_10_1 == ccui.TouchEventType.canceled then
			arg_10_0:setScale(1)

			if arg_9_0.longTouchHandler and arg_9_0.longTouchHandler then
				var_0_4.unscheduleGlobal(arg_9_0.longTouchHandler)
			end

			if not var_9_0 then
				arg_9_0:changeTicketNum(1, true)
			end
		end
	end)
	arg_9_0:nodeByName("btn_add"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.began then
			arg_12_0:setScale(0.9)

			local var_12_0 = 0

			local function var_12_1()
				var_12_0 = var_12_0 + 0.1

				if var_12_0 > 0.5 then
					var_9_0 = true

					arg_9_0:changeTicketNum(var_0_6, false)
				else
					var_9_0 = false
				end
			end

			var_9_0 = false
			arg_9_0.longTouchHandler = var_0_4.scheduleGlobal(var_12_1, 0.1)
		elseif arg_12_1 == ccui.TouchEventType.ended or arg_12_1 == ccui.TouchEventType.canceled then
			arg_12_0:setScale(1)

			if arg_9_0.longTouchHandler and arg_9_0.longTouchHandler then
				var_0_4.unscheduleGlobal(arg_9_0.longTouchHandler)
			end

			if not var_9_0 then
				arg_9_0:changeTicketNum(1, false)
			end
		end
	end)
	arg_9_0:nodeByName("btn_ok"):addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.ended then
			local var_14_0 = ""
			local var_14_1 = false
			local var_14_2 = 0

			if arg_9_0.selectVoteType == xyd.PopularityHeroPollType.NORMAL then
				if arg_9_0.addTicketNum > arg_9_0.normalTicketNum then
					local var_14_3 = arg_9_0.addTicketNum - arg_9_0.normalTicketNum

					var_14_2 = var_14_3 * xyd.tables.misc.voteTicketCost
					var_14_0 = string.format(var_0_1:translation("VOTE_HERO_TIPS_7"), var_14_2, var_14_3)
					var_14_1 = true
				else
					local var_14_4 = xyd.tables.hero:name(arg_9_0.tableID)

					var_14_0 = string.format(var_0_1:translation("VOTE_HERO_TIPS_9"), var_14_4, arg_9_0.addTicketNum)
				end
			elseif arg_9_0.addTicketNum < 1 or arg_9_0.addTicketNum > arg_9_0.superTicketNum then
				var_14_0 = var_0_1:translation("VOTE_HERO_TIPS_8")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_14_0
				})

				return
			else
				local var_14_5 = xyd.tables.hero:name(arg_9_0.tableID)

				var_14_0 = string.format(var_0_1:translation("VOTE_HERO_TIPS_10"), var_14_5, arg_9_0.addTicketNum)
			end

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_14_0, function()
				if var_14_1 and var_14_2 > 0 then
					if arg_9_0.selfPlayer.crystal < var_14_2 then
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
							xyd.WindowManager.get():openWindow(xyd.WindowName.vipRecharge)
						end, nil, nil, arg_9_0.colorMode)
					else
						arg_9_0:openVoteSpecial()
					end
				else
					arg_9_0:openVoteSpecial()
				end
			end, nil, 0, arg_9_0.colorMode)
		end
	end)
	arg_9_0:nodeByName("btn_add_all"):addTouchEventListener(function(arg_17_0, arg_17_1)
		if arg_17_1 == ccui.TouchEventType.began then
			arg_17_0:setScale(0.9)
		elseif arg_17_1 == ccui.TouchEventType.moved then
			arg_17_0:setScale(1)
		elseif arg_17_1 == ccui.TouchEventType.ended then
			arg_17_0:setScale(1)

			if arg_9_0.selectVoteType == xyd.PopularityHeroPollType.NORMAL then
				arg_9_0.addTicketNum = arg_9_0.normalTicketNum > 0 and arg_9_0.normalTicketNum or 1
			else
				arg_9_0.addTicketNum = arg_9_0.superTicketNum and arg_9_0.superTicketNum or 1
			end

			arg_9_0:updateCurrentVoteNum()
		end
	end)
	arg_9_0:nodeByName("normal_ticket"):setTouchEnabled(true)
	arg_9_0:nodeByName("normal_ticket"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_18_0)
		if arg_18_0.name == "began" then
			return true
		elseif arg_18_0.name == "ended" then
			arg_9_0:nodeByName("normal_select"):setVisible(true)
			arg_9_0:nodeByName("special_select"):setVisible(false)

			arg_9_0.selectVoteType = xyd.PopularityHeroPollType.NORMAL
		end
	end)
	arg_9_0:nodeByName("super_ticket"):setTouchEnabled(true)
	arg_9_0:nodeByName("super_ticket"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_19_0)
		if arg_19_0.name == "began" then
			return true
		elseif arg_19_0.name == "ended" then
			arg_9_0:nodeByName("normal_select"):setVisible(false)
			arg_9_0:nodeByName("special_select"):setVisible(true)

			arg_9_0.selectVoteType = xyd.PopularityHeroPollType.SUPER
		end
	end)
	arg_9_0:nodeByName("normal_select"):setVisible(true)
	arg_9_0:nodeByName("special_select"):setVisible(false)
end

function var_0_0.openVoteSpecial(arg_20_0)
	local var_20_0 = xyd.tables.activityVotePartner:models(arg_20_0.tableID)

	if #var_20_0 == 1 then
		local var_20_1 = {
			table_id = arg_20_0.tableID,
			model_id = var_20_0[1],
			poll_num = arg_20_0.addTicketNum,
			poll_type = arg_20_0.selectVoteType
		}

		arg_20_0.popularContest:poll(var_20_1, function(arg_21_0, arg_21_1)
			if arg_21_0 == xyd.error.OK then
				local var_21_0 = xyd.WindowManager.get():getWindow("popularity_race_wnd")

				if var_21_0 and not tolua.isnull(var_21_0) then
					var_21_0:updateSearchHero()
				end

				xyd.WindowManager.get():closeWindow(arg_20_0)
			end
		end)
	else
		local var_20_2 = {
			table_id = arg_20_0.tableID,
			poll_num = arg_20_0.addTicketNum,
			poll_type = arg_20_0.selectVoteType,
			data = arg_20_0.data
		}

		xyd.WindowManager.get():openWindow("popularity_vote_special", var_20_2)
		xyd.WindowManager.get():closeWindow(arg_20_0)
	end
end

function var_0_0.willClose(arg_22_0)
	if arg_22_0.longTouchHandler and arg_22_0.longTouchHandler then
		var_0_4.unscheduleGlobal(arg_22_0.longTouchHandler)

		arg_22_0.longTouchHandler = nil
	end
end

return var_0_0
