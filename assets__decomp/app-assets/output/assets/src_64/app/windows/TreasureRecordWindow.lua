local var_0_0 = class("TreasureRecordWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.records = arg_1_2.records
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.treasure = xyd.ModelManager.get():loadModel(xyd.ModelType.TREASURE)
	arg_1_0.reports = arg_1_2.reports or {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)

	local var_2_0 = xyd.AssetLoader.get():loadSprite("windows/treasure/treasure_report_title.png")

	var_2_0:addTo(arg_2_0:nodeByName("title"))
	var_2_0:setAnchorPoint(cc.p(0, 0))
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0.container = arg_4_0:nodeByName("inner")

	local var_4_0 = arg_4_0.container:getContentSize()

	arg_4_0.recordList_ = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_4_0.width, var_4_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_4_0.container):onScroll(handler(arg_4_0, arg_4_0.scrollListener)):setTouchType(true):pos(0, 0)

	arg_4_0:updateRecordList()
end

function var_0_0.updateRecordList(arg_5_0)
	if not arg_5_0.records or not next(arg_5_0.records) then
		return
	end

	arg_5_0.recordList_:removeAllItems()

	local var_5_0 = {}

	for iter_5_0, iter_5_1 in pairs(arg_5_0.records) do
		if iter_5_1.attack_name then
			local var_5_1 = display.newNode()
			local var_5_2 = arg_5_0.recordList_:newItem()
			local var_5_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/arena/record/record_item.csb")
			local var_5_4 = var_5_3:getChildByName("container")

			if tonumber(iter_5_1.is_attack) == 0 and tonumber(iter_5_1.attack_avatar) ~= 0 then
				var_5_0 = {
					avatar_id = tonumber(iter_5_1.attack_avatar),
					avatar_frame_id = iter_5_1.attack_avatar_frame
				}
			end

			xyd.setPlayerAvatar(var_5_4:getChildByName("avatar"), var_5_0)
			var_5_4:getChildByName("text_level"):setString(iter_5_1.attack_lev)
			var_5_4:getChildByName("text_player_name"):setString(iter_5_1.attack_name)

			if tonumber(iter_5_1.win) == 1 then
				var_5_4:getChildByName("win"):setVisible(true)
				var_5_4:getChildByName("win_text"):setVisible(true)
				var_5_4:getChildByName("lose"):setVisible(false)
				var_5_4:getChildByName("lose_text"):setVisible(false)
			else
				var_5_4:getChildByName("win"):setVisible(false)
				var_5_4:getChildByName("win_text"):setVisible(false)
				var_5_4:getChildByName("lose"):setVisible(true)
				var_5_4:getChildByName("lose_text"):setVisible(true)
			end

			if iter_5_1.time then
				local var_5_5 = xyd.ServerTime.get():getServerTime() - iter_5_1.time

				var_5_4:getChildByName("text_time"):setString(xyd.secondsToString(var_5_5, {
					short = true,
					toText = true
				}) .. xyd.tables.translation:translation("BEFORE"))
			end

			local var_5_6 = var_5_4:getContentSize()

			var_5_3:setPosition(cc.p(15, 0))
			var_5_3:setContentSize(var_5_6.width + 15, var_5_6.height)
			var_5_1:addChild(var_5_3)
			var_5_1:setContentSize(cc.size(arg_5_0.recordList_.viewRect_.width, var_5_3:getContentSize().height + 5))
			var_5_2:addContent(var_5_1)
			var_5_2:setItemSize(arg_5_0.recordList_.viewRect_.width, var_5_1:getContentSize().height)

			local var_5_7 = var_5_4:getChildByName("share_btn")
			local var_5_8 = var_5_4:getChildByName("share")

			var_5_4:getChildByName("data_icon"):setVisible(false)
			var_5_4:getChildByName("data_btn"):setVisible(false)
			var_5_7:setVisible(false)
			var_5_8:setVisible(false)
			var_5_4:getChildByName("replay_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
				if arg_6_1 == ccui.TouchEventType.ended then
					local var_6_0 = var_0_1:translation("FUNCTION_NOT_OPEN")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_6_0
					})
				end
			end)
			arg_5_0.recordList_:addItem(var_5_2)
		end
	end

	arg_5_0.recordList_:reload()
end

function var_0_0.replayRecord(arg_7_0, arg_7_1)
	local var_7_0 = {
		campaignType = xyd.CampaignType.ARENA,
		campaignID = arg_7_0.campaignID,
		jsonData = arg_7_1[1].content
	}

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
		params = {
			window = xyd.WindowName.treasureRecordWnd,
			status = {
				reports = arg_7_0.reports
			}
		}
	})
	xyd.WindowManager.get():retainHistory()
	cc.Director:getInstance():pushScene(xyd.ReportScene.new(var_7_0))
end

function var_0_0.scrollListener(arg_8_0, arg_8_1)
	if arg_8_1.name == "began" then
		arg_8_0.scrollViewMoved_ = false
		arg_8_0.prevX_ = arg_8_1.x
	elseif arg_8_1.name == "moved" and 1 <= math.abs(arg_8_1.x - arg_8_0.prevX_) then
		arg_8_0.scrollViewMoved_ = true
	end
end

function var_0_0.willClose(arg_9_0)
	return
end

function var_0_0.didClose(arg_10_0)
	return
end

return var_0_0
