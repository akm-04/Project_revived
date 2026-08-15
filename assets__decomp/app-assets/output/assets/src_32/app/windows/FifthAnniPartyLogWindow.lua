local var_0_0 = class("FifthAnniPartyLogWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 3

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.model = xyd.ModelManager.get():loadModel(xyd.ModelType.FIFTH_ANNIVERSARY)
	arg_1_0.data = arg_1_2
	arg_1_0.page = math.min(1, #arg_1_0.data)
	arg_1_0.logs = {}
	arg_1_0.maxPage = math.ceil(#arg_1_0.data / var_0_2)
end

function var_0_0.willOpen(arg_2_0)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("txt_title"):setString(var_0_1:translation("FIFTH_ANNI_PARTY_TEXT_16"))
	xyd.nodeEventSample(arg_4_0:nodeByName("btn_last"), nil, function()
		if arg_4_0.page <= 1 then
			return
		end

		arg_4_0.page = arg_4_0.page - 1

		arg_4_0:nodeByName("btn_next"):setVisible(true)

		if arg_4_0.page == 1 then
			arg_4_0:nodeByName("btn_last"):setVisible(false)
		end

		arg_4_0:updateListShow()
	end)
	xyd.nodeEventSample(arg_4_0:nodeByName("btn_next"), nil, function()
		if arg_4_0.page >= arg_4_0.maxPage then
			return
		end

		arg_4_0.page = arg_4_0.page + 1

		arg_4_0:nodeByName("btn_last"):setVisible(true)

		if arg_4_0.page == arg_4_0.maxPage then
			arg_4_0:nodeByName("btn_next"):setVisible(false)
		end

		arg_4_0:updateListShow()
	end)
	arg_4_0:nodeByName("btn_last"):setVisible(false)

	if arg_4_0.maxPage <= 1 then
		arg_4_0:nodeByName("btn_next"):setVisible(false)
	end

	for iter_4_0 = 1, var_0_2 do
		local var_4_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1232/party/log_item.csb")
		local var_4_1 = var_4_0:getChildByName("container")
		local var_4_2 = var_4_1:getContentSize()

		table.insert(arg_4_0.logs, var_4_1)
		cc.ui.UITableView.new({
			itemGap = 13,
			size = var_4_1:getChildByName("list"):getContentSize(),
			direction = cc.ui.UITableView.DIRECTION_HORIZONTAL
		}):addTo(var_4_1:getChildByName("list")):setName("list")
		var_4_1:getChildByName("txt_send_word"):setString(var_0_1:translation("FIFTH_ANNI_PARTY_TEXT_18"))
		var_4_1:getChildByName("txt_receive_word"):setString(var_0_1:translation("FIFTH_ANNI_PARTY_TEXT_19"))

		local var_4_3 = var_4_1:getChildByName("btn")

		var_4_3:getChildByName("txt"):setString(var_0_1:translation("FIFTH_ANNI_PARTY_TEXT_20"))
		var_4_3:addTouchEventListener(function(arg_7_0, arg_7_1)
			xyd.buttonScaleAnim(arg_7_0, arg_7_1)

			if arg_7_1 == ccui.TouchEventType.ended then
				local var_7_0 = (arg_4_0.page - 1) * var_0_2 + iter_4_0

				if not arg_4_0.data[var_7_0] then
					return
				end

				arg_4_0.model:partyGetPlayerInfo({
					player_id = arg_4_0.data[var_7_0].from_player
				}, function(arg_8_0, arg_8_1)
					if arg_8_0 == xyd.error.OK then
						local var_8_0 = {
							player_id = arg_8_1.player_info.player_id,
							player_name = arg_8_1.player_info.player_name,
							player_send_point = arg_8_1.point
						}

						xyd.WindowManager.get():openWindow("fifth_anni_party_gift_select", var_8_0)
					end
				end)
			end
		end)
		var_4_0:setPosition(0, (var_4_2.height + 10) * (var_0_2 - iter_4_0))
		arg_4_0:nodeByName("list"):addChild(var_4_0)
	end

	arg_4_0:updateListShow()
end

function var_0_0.updateListShow(arg_9_0)
	for iter_9_0 = 1, var_0_2 do
		local var_9_0 = arg_9_0.logs[iter_9_0]
		local var_9_1 = (arg_9_0.page - 1) * var_0_2 + iter_9_0
		local var_9_2 = arg_9_0.data[var_9_1]

		if not var_9_2 then
			var_9_0:setVisible(false)
		else
			var_9_0:setVisible(true)
			var_9_0:getChildByName("txt_time_word"):setString(var_0_1:translation("FIFTH_ANNI_PARTY_TEXT_17"))
			var_9_0:getChildByName("txt_name"):setString(var_9_1)

			local var_9_3 = var_9_0:getChildByName("list"):getChildByName("list")

			var_9_3:removeAllItems()

			for iter_9_1 = 1, #var_9_2.items do
				local var_9_4 = var_9_3:newItem()
				local var_9_5 = display.newNode()

				var_9_5:setContentSize(78, 78)
				var_9_5:setAnchorPoint(0.5, 0.5)
				xyd.setItemAndAddTips(var_9_5, var_9_2.items[iter_9_1], var_9_2.nums[iter_9_1])
				var_9_4:setItemSize(80, 80)
				var_9_4:addContent(var_9_5)
				var_9_3:addItem(var_9_4)
			end

			var_9_3:reload()
			var_9_0:getChildByName("txt_region"):setString("S" .. xyd.getPlayerRegion(var_9_2.player_info.player_id))
			var_9_0:getChildByName("txt_name"):setString(var_9_2.player_info.player_name)
			var_9_0:getChildByName("txt_send_point"):setString(var_9_2.send_point)
			var_9_0:getChildByName("txt_receive_point"):setString(var_9_2.receive_point)

			local var_9_6 = {
				is_new = true,
				avatar_frame_id = var_9_2.player_info.avatar_frame_id,
				avatar_id = var_9_2.player_info.avatar_id
			}

			xyd.setPlayerAvatar(var_9_0:getChildByName("avatar"), var_9_6)

			local var_9_7 = {
				lev = var_9_2.player_info.lev,
				conquerLev = var_9_2.player_info.conquer_lev,
				loopID = var_9_2.player_info.conquer_loop_id,
				fontColor = cc.c3b(80, 12, 26)
			}

			xyd.setLev(var_9_0:getChildByName("lv"), var_9_7)

			local var_9_8 = var_9_2.time

			var_9_0:getChildByName("txt_time"):setString(os.date("%Y/%m/%d %X", var_9_8))
		end
	end

	arg_9_0:nodeByName("txt_page"):setString(arg_9_0.page .. "/" .. arg_9_0.maxPage)
end

return var_0_0
