local var_0_0 = class("FifthAnniPartyMainWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.misc
local var_0_3 = xyd.tables.fifthAnniPartyAward
local var_0_4 = xyd.tables.gift
local var_0_5 = var_0_2:getValue("fifth_anni_party_point_per_level")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.model = xyd.ModelManager.get():loadModel(xyd.ModelType.FIFTH_ANNIVERSARY)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
end

function var_0_0.willOpen(arg_2_0)
	arg_2_0:addTopSidebar({
		show_rule = true
	})
	arg_2_0:layout()
	arg_2_0:setButtonClick()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("txt_rank"):setString(var_0_1:translation("FIFTH_ANNI_PARTY_TEXT_1"))
	arg_3_0:nodeByName("txt_log"):setString(var_0_1:translation("FIFTH_ANNI_PARTY_TEXT_2"))
	arg_3_0:nodeByName("txt_backpack"):setString(var_0_1:translation("FIFTH_ANNI_PARTY_TEXT_3"))
	arg_3_0:nodeByName("txt_gift"):setString(var_0_1:translation("FIFTH_ANNI_PARTY_TEXT_4"))
	arg_3_0:nodeByName("txt_get"):setString(var_0_1:translation("FIFTH_ANNI_PARTY_TEXT_5"))

	arg_3_0.list = cc.ui.UITableView.new({
		async = true,
		itemGap = 10,
		size = arg_3_0:nodeByName("list"):getContentSize(),
		direction = cc.ui.UITableView.DIRECTION_VERTICAL,
		itemSize = cc.size(630, 117)
	}):addTo(arg_3_0:nodeByName("list")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.list:setDelegate(handler(arg_3_0, arg_3_0.delegate))
	arg_3_0.list:reload()
	arg_3_0:updateNum()
end

function var_0_0.setButtonClick(arg_4_0)
	xyd.nodeEventSample(arg_4_0:nodeByName("btn_rank"), nil, function()
		arg_4_0.model:partyGetSendRankList(nil, function(arg_6_0, arg_6_1)
			if arg_6_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("fifth_anni_party_rank", arg_6_1)
			end
		end)
	end)
	xyd.nodeEventSample(arg_4_0:nodeByName("btn_log"), nil, function()
		arg_4_0.model:partyGetLogs(nil, function(arg_8_0, arg_8_1)
			if arg_8_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("fifth_anni_party_log", arg_8_1)
			end
		end)
	end)
	xyd.nodeEventSample(arg_4_0:nodeByName("btn_backpack"), nil, function()
		arg_4_0.model:partyGetCollectionInfo(nil, function(arg_10_0, arg_10_1)
			if arg_10_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("fifth_anni_party_backpack", arg_10_1)
			end
		end)
	end)
	xyd.nodeEventSample(arg_4_0:nodeByName("btn_gift"), nil, function()
		xyd.WindowManager.get():openWindow("fifth_anni_party_gift")
	end)
	arg_4_0:nodeByName("btn_get"):addTouchEventListener(function(arg_12_0, arg_12_1)
		xyd.buttonScaleAnim(arg_12_0, arg_12_1)

		if arg_12_1 == ccui.TouchEventType.ended then
			local var_12_0

			for iter_12_0 = 1, var_0_3:all() do
				if arg_4_0.model:getReceivePoint() >= var_0_3:receivePoint(iter_12_0) and arg_4_0.model:getSendPoint() >= var_0_3:sendPoint(iter_12_0) and arg_4_0.model:getPartyIsAward(iter_12_0) == 0 then
					var_12_0 = true

					break
				end
			end

			if not var_12_0 then
				local var_12_1 = var_0_1:translation("FIFTH_ANNI_PARTY_TEXT_9")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_12_1
				})

				return
			end

			arg_4_0.model:partyGetAllAwards(nil, function(arg_13_0, arg_13_1)
				if arg_13_0 == xyd.error.OK then
					arg_4_0.selfPlayer:handleRewards(arg_13_1.awards)
					arg_4_0.list:refreshList()
				end
			end)
		end
	end)
	xyd.nodeEventSample(arg_4_0:nodeByName("top_sidebar"):nodeByName("rule"), nil, function()
		local var_14_0 = {
			title_name = "FIFTH_ANNI_PARTY_RULE_TITLE",
			rule = "FIFTH_ANNI_PARTY_RULE_TEXT"
		}

		xyd.WindowManager.get():openWindow("fifth_anni_party_rule", var_14_0)
	end)
end

function var_0_0.delegate(arg_15_0, arg_15_1, arg_15_2, arg_15_3)
	if arg_15_2 == cc.ui.UITableView.COUNT_TAG then
		return var_0_3:all()
	elseif arg_15_2 == cc.ui.UITableView.CELL_TAG then
		local var_15_0 = arg_15_0.list:getItem()
		local var_15_1 = arg_15_0:createContent(arg_15_3)

		var_15_0:addContent(var_15_1)

		return var_15_0
	end
end

function var_0_0.createContent(arg_16_0, arg_16_1)
	local var_16_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1232/party/reward_item.csb")
	local var_16_1 = var_0_3:sendPoint(arg_16_1)
	local var_16_2 = 1 + math.floor(var_0_3:receivePoint(arg_16_1) / var_0_5)
	local var_16_3 = var_0_3:giftId(arg_16_1)
	local var_16_4 = var_0_4:items(var_16_3)
	local var_16_5 = var_0_4:itemNum(var_16_3)

	var_16_0:getChildByName("btn_get"):getChildByName("txt_get"):setString(var_0_1:translation("FIFTH_ANNI_PARTY_TEXT_10"))
	var_16_0:getChildByName("btn_gray"):getChildByName("txt_gray"):setString(var_0_1:translation("FIFTH_ANNI_PARTY_TEXT_11"))
	var_16_0:getChildByName("txt_name"):setString(string.format(var_0_1:translation("FIFTH_ANNI_PARTY_TEXT_38"), arg_16_1))
	var_16_0:getChildByName("txt_count"):setString(string.format(var_0_1:translation("FIFTH_ANNI_PARTY_TEXT_7"), var_16_1))

	for iter_16_0, iter_16_1 in ipairs(var_16_4) do
		xyd.setItemAndAddTips(var_16_0:getChildByName("item_" .. iter_16_0), iter_16_1, var_16_5[iter_16_0])
	end

	if arg_16_0.model:getPartyIsAward(arg_16_1) ~= 0 then
		local var_16_6 = var_16_0:getChildByName("btn_get"):getChildByName("txt_get")

		var_16_0:getChildByName("btn_get"):setBright(false)
		var_16_6:setString(var_0_1:translation("FIFTH_ANNI_PARTY_TEXT_39"))
		var_16_6:setColor(cc.c3b(52, 54, 55))
	elseif var_16_2 > arg_16_0.model:getCelebrationLev() then
		var_16_0:getChildByName("btn_get"):setVisible(false)
		var_16_0:getChildByName("txt_lock"):setVisible(true)
		var_16_0:getChildByName("mask"):setVisible(true)
		var_16_0:getChildByName("txt_lock"):setString(string.format(var_0_1:translation("FIFTH_ANNI_PARTY_TEXT_8"), var_16_2))
	elseif var_16_1 > arg_16_0.model:getSendPoint() then
		var_16_0:getChildByName("btn_get"):setVisible(false)
		var_16_0:getChildByName("btn_gray"):setVisible(true)
	else
		var_16_0:getChildByName("btn_get"):addTouchEventListener(function(arg_17_0, arg_17_1)
			xyd.buttonScaleAnim(arg_17_0, arg_17_1)

			if arg_17_1 == ccui.TouchEventType.ended then
				if arg_16_0.scrollViewMoved_ then
					return
				end

				arg_16_0.model:partyGetAward({
					award_id = arg_16_1
				}, function(arg_18_0, arg_18_1)
					if arg_18_0 == xyd.error.OK then
						arg_16_0.selfPlayer:handleRewards(arg_18_1.awards)
						arg_16_0.list:refreshList()
					end
				end)
			end
		end)
	end

	return var_16_0
end

function var_0_0.updateNum(arg_19_0, arg_19_1)
	arg_19_0:nodeByName("txt_celebration"):setString("LV." .. arg_19_0.model:getCelebrationLev())
	arg_19_0:nodeByName("txt_exp"):setString(arg_19_0.model:getCelebrationExp() .. "/" .. var_0_5)
	arg_19_0:nodeByName("txt_friendship"):setString(string.format(var_0_1:translation("FIFTH_ANNI_PARTY_TEXT_6"), arg_19_0.model:getSendPoint()))

	if arg_19_1 then
		arg_19_0.list:refreshList()
	end
end

function var_0_0.scrollListener(arg_20_0, arg_20_1)
	if arg_20_1.name == "began" then
		arg_20_0.scrollViewMoved_ = false
		arg_20_0.prevY_ = arg_20_1.y
	elseif arg_20_1.name == "moved" and 10 <= math.abs(arg_20_1.y - arg_20_0.prevY_) then
		arg_20_0.scrollViewMoved_ = true
	end
end

return var_0_0
