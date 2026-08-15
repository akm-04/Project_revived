local var_0_0 = class("OccultConfirmInvitedWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.creatsCampaign
local var_0_3 = xyd.tables.battle
local var_0_4 = import("app.model.Hero")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.occult = xyd.ModelManager.get():loadModel(xyd.ModelType.OCCULT)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.campaignId = arg_1_2.campaign_id
	arg_1_0.subId = arg_1_2.sub_id
	arg_1_0.playerName = arg_1_2.start_player_name
	arg_1_0.battleId = var_0_2:getFightId(arg_1_0.campaignId, arg_1_0.subId)
	arg_1_0.monsterIds = xyd.tables.battle:monsters(arg_1_0.battleId, 1)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayerWithNoTouchEvent()
	arg_2_0.blockLayer_:setPosition(cc.p(-640, -360))
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = import("app.common.ui.SplitLine")
	local var_3_1 = arg_3_0:nodeByName("line")

	var_3_0.new({
		size = var_3_1:getWidth()
	}):addTo(var_3_1)

	local var_3_2 = var_0_2:campaignName(arg_3_0.campaignId)
	local var_3_3 = string.format(var_0_1:translation("OCCULT_INVITE_TIP_TEXT"), arg_3_0.playerName, var_3_2)

	arg_3_0:nodeByName("invited_txt"):setString(var_3_3)
	arg_3_0:nodeByName("monster_info_text"):setString(var_0_1:translation("OCCULT_MONSTER_INFO_TEXT"))
	arg_3_0:nodeByName("text_go"):setString(var_0_1:translation("GOTO"))
	arg_3_0:nodeByName("text_refuse"):setString(var_0_1:translation("REFUSE"))

	arg_3_0.scroll = arg_3_0:nodeByName("scroll")

	local var_3_4 = arg_3_0.scroll:getContentSize()

	arg_3_0.scrollList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_4.width, var_3_4.height + 10),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(arg_3_0.scroll):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.scrollList:setBounceable(false)
	arg_3_0.scrollList:setDelegate(handler(arg_3_0, arg_3_0.scrollListDelegate))
	arg_3_0.scrollList:setTouchType(false)
	arg_3_0.scrollList:reload()
	arg_3_0:setButtonClick()
end

function var_0_0.setButtonClick(arg_4_0)
	arg_4_0:nodeByName("close"):addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_5_0, arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_5_0 = {
				campaign_id = arg_4_0.campaignId,
				sub_id = arg_4_0.subId
			}

			var_5_0.is_accept = 0

			arg_4_0.occult:acceptTeamInvite(var_5_0, function(arg_6_0, arg_6_1)
				if arg_6_0 == xyd.error.OK then
					xyd.WindowManager.get():closeWindow(arg_4_0)
				end
			end)
		end
	end)
	arg_4_0:nodeByName("refuse_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(arg_7_0, arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_7_0 = {
				campaign_id = arg_4_0.campaignId,
				sub_id = arg_4_0.subId
			}

			var_7_0.is_accept = 0

			arg_4_0.occult:acceptTeamInvite(var_7_0, function(arg_8_0, arg_8_1)
				if arg_8_0 == xyd.error.OK then
					xyd.WindowManager.get():closeWindow(arg_4_0)
				end
			end)
		end
	end)
	arg_4_0:nodeByName("go_btn"):addTouchEventListener(function(arg_9_0, arg_9_1)
		xyd.buttonScaleAnim(arg_9_0, arg_9_1)

		if arg_9_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if not xyd.WindowManager.get():isWindowOpen("occult_sub_map") then
				local var_9_0 = {}

				arg_4_0.occult:getInfo(var_9_0, function(arg_10_0, arg_10_1)
					if arg_10_0 == xyd.error.OK then
						if arg_4_0.occult:isDirectedToMap() then
							xyd.WindowManager.get():openWindow("occult_sub_map")
						else
							xyd.WindowManager.get():openWindow("occult")
						end

						arg_4_0:confirmInvite()
					end
				end)
			else
				arg_4_0:confirmInvite()
			end
		end
	end)
end

function var_0_0.confirmInvite(arg_11_0)
	local var_11_0 = {
		campaign_id = arg_11_0.campaignId,
		sub_id = arg_11_0.subId
	}

	var_11_0.is_accept = 1

	arg_11_0.occult:acceptTeamInvite(var_11_0, function(arg_12_0, arg_12_1)
		if arg_12_0 == xyd.error.OK then
			xyd.WindowManager.get():openWindow("occult_cooperate_waiting", var_11_0)
			xyd.WindowManager.get():closeWindow(arg_11_0)
		end
	end)
end

function var_0_0.scrollListDelegate(arg_13_0, arg_13_1, arg_13_2, arg_13_3)
	if cc.ui.UIListView.COUNT_TAG == arg_13_2 then
		return #arg_13_0.monsterIds
	elseif cc.ui.UIListView.CELL_TAG == arg_13_2 then
		local var_13_0
		local var_13_1 = arg_13_0.scrollList:dequeueItem()

		if not var_13_1 then
			var_13_1 = arg_13_0.scrollList:newItem()
		else
			var_13_1:removeAllChildren(true)
		end

		local var_13_2 = arg_13_0:createListContent(arg_13_0.monsterIds[arg_13_3])
		local var_13_3 = var_13_2:getWidth()
		local var_13_4 = var_13_2:getHeight()

		var_13_1:setItemSize(var_13_3 + 10, var_13_4 + 15)
		var_13_1:addContent(var_13_2)

		return var_13_1
	end
end

function var_0_0.createListContent(arg_14_0, arg_14_1)
	local var_14_0 = display.newNode()

	var_14_0:setContentSize(95, 95)

	local var_14_1 = var_0_4.new()

	var_14_1:populateWithTableID(arg_14_1)
	xyd.setAvatarBorderNewUI(var_14_1, var_14_0)

	return var_14_0
end

function var_0_0.scrollListener(arg_15_0, arg_15_1)
	if arg_15_1.name == "began" then
		arg_15_0.scrollViewMoved_ = false
		arg_15_0.prevY_ = arg_15_1.y
	elseif arg_15_1.name == "moved" and 5 <= math.abs(arg_15_1.y - arg_15_0.prevY_) then
		arg_15_0.scrollViewMoved_ = true
	end
end

return var_0_0
