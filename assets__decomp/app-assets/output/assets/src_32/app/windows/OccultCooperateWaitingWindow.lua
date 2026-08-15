local var_0_0 = class("OccultCooperateWaitingWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.occult = xyd.ModelManager.get():loadModel(xyd.ModelType.OCCULT)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.campaignId = arg_1_2.campaign_id
	arg_1_0.subId = arg_1_2.sub_id
	arg_1_0.playerIDs = arg_1_0:getShowPlayerIds()
end

function var_0_0.getShowPlayerIds(arg_2_0)
	local var_2_0 = clone(arg_2_0.occult.roomInfo.members)

	for iter_2_0 = 1, #var_2_0 do
		if var_2_0[iter_2_0] == arg_2_0.selfPlayer.playerID then
			table.remove(var_2_0, iter_2_0)

			return var_2_0
		end
	end

	return var_2_0
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super.willOpen(arg_3_0, arg_3_1)
	arg_3_0:layout()
	arg_3_0:addBlockLayerWithNoTouchEvent()
	arg_3_0.blockLayer_:setPosition(cc.p(-640, -360))
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("desc_txt"):setString(var_0_1:translation("OCCULT_WATING_DESC_TEXT"))

	arg_4_0.scroll = arg_4_0:nodeByName("scroll")

	local var_4_0 = arg_4_0.scroll:getContentSize()

	arg_4_0.scrollList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_0.width, var_4_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_4_0.scroll):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.scrollList:setBounceable(false)
	arg_4_0.scrollList:setDelegate(handler(arg_4_0, arg_4_0.scrollListDelegate))
	arg_4_0.scrollList:setTouchType(false)
	arg_4_0:refreshList()
	arg_4_0:setButtonClick()
end

function var_0_0.refreshList(arg_5_0)
	arg_5_0.subCampaignInfo = arg_5_0.occult.subCampaignInfo

	arg_5_0.scrollList:reload()
end

function var_0_0.setButtonClick(arg_6_0)
	arg_6_0:nodeByName("close"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("OCCULT_QUIT_COMPANION_TIP"), function()
				local var_8_0 = {
					campaign_id = arg_6_0.campaignId,
					sub_id = arg_6_0.subId
				}

				arg_6_0.occult:quitTeamFight(var_8_0, function(arg_9_0, arg_9_1)
					xyd.WindowManager.get():closeWindow(arg_6_0)
				end)
			end, nil, nil, arg_6_0.colorMode)
		end
	end)
end

function var_0_0.scrollListDelegate(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	if cc.ui.UIListView.COUNT_TAG == arg_10_2 then
		return #arg_10_0.playerIDs
	elseif cc.ui.UIListView.CELL_TAG == arg_10_2 then
		local var_10_0
		local var_10_1 = arg_10_0.scrollList:dequeueItem()

		if not var_10_1 then
			var_10_1 = arg_10_0.scrollList:newItem()
		else
			var_10_1:removeAllChildren(true)
		end

		local var_10_2 = arg_10_0:createListContent(arg_10_0.playerIDs[arg_10_3])
		local var_10_3 = var_10_2:getWidth()
		local var_10_4 = var_10_2:getHeight()

		var_10_1:setItemSize(var_10_3, var_10_4 + 10)
		var_10_2:setPositionY(5)
		var_10_1:addContent(var_10_2)

		return var_10_1
	end
end

function var_0_0.createListContent(arg_11_0, arg_11_1)
	local var_11_0 = display.newNode()
	local var_11_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/occult/companion_info/waiting_item.csb")
	local var_11_2 = var_11_1:getChildByName("container")
	local var_11_3 = arg_11_0.occult:getPlayerInfoByID(arg_11_1)

	xyd.setPlayerInfoContainer(var_11_2, var_11_3)

	if not xyd.isInTable(arg_11_0.subCampaignInfo.accept_players, arg_11_1) then
		var_11_2:getChildByName("all_inplace"):setVisible(false)
	end

	var_11_1:addTo(var_11_0)
	var_11_1:setAnchorPoint(cc.p(0, 0))
	var_11_0:setContentSize(var_11_2:getContentSize())
	var_11_1:setName("source")

	return var_11_0
end

function var_0_0.scrollListener(arg_12_0, arg_12_1)
	if arg_12_1.name == "began" then
		arg_12_0.scrollViewMoved_ = false
		arg_12_0.prevY_ = arg_12_1.y
	elseif arg_12_1.name == "moved" and 5 <= math.abs(arg_12_1.y - arg_12_0.prevY_) then
		arg_12_0.scrollViewMoved_ = true
	end
end

function var_0_0.toTeamFight(arg_13_0)
	local var_13_0 = {
		campaign_id = arg_13_0.campaignId,
		sub_id = arg_13_0.subId
	}

	xyd.WindowManager.get():openWindow("occult_show_team", var_13_0)
	xyd.WindowManager.get():closeWindow(arg_13_0)
end

return var_0_0
