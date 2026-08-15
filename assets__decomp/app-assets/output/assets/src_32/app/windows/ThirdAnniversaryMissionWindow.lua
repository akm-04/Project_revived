local var_0_0 = class("ThirdAnniversaryMissionWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.ThirdAnniversaryMission

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.thirdAnniModel = xyd.ModelManager.get():loadModel(xyd.ModelType.THIRD_ANNIVERSARY)
	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.scroll = arg_2_0:nodeByName("scroll")

	local var_2_0 = arg_2_0.scroll:getContentSize()

	arg_2_0.scrollList = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_2_0.width, var_2_0.height),
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_2_0.scroll)

	arg_2_0.scrollList:setBounceable(true)
	arg_2_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_3_0, arg_3_1)
		if arg_3_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("third_anni_rule", {
				rule = "ACTIVITY_MISSION_RULE_TEXT",
				title = "ACTIVITY_MISSION_RULE_TITLE"
			})
		end
	end)
	arg_2_0:nodeByName("rule_btn"):setVisible(false)
	arg_2_0:updateMissions()
end

function var_0_0.updateMissions(arg_4_0)
	local var_4_0 = var_0_2:ids()
	local var_4_1 = arg_4_0.thirdAnniModel.missionInfo.counts
	local var_4_2 = arg_4_0.thirdAnniModel.missionInfo.is_awards

	for iter_4_0 = 1, #var_4_0 do
		local var_4_3 = var_4_0[iter_4_0]
		local var_4_4 = var_0_2:itemIds(var_4_3)
		local var_4_5 = var_0_2:itemNums(var_4_3)
		local var_4_6 = arg_4_0.scrollList:newItem()
		local var_4_7 = xyd.AssetLoader.get():loadNodeFromJson("windows/anniversary3rd/mission/mission_item.csb")
		local var_4_8 = var_4_7:getChildByName("container")

		var_4_8:getChildByName("mission"):setString(var_0_2:name(var_4_3))
		var_4_8:getChildByName("discraption"):setString(var_0_2:mesc(var_4_3))
		var_4_8:getChildByName("num"):setString(var_4_1[var_4_3] .. "/" .. var_0_2:condition(var_4_3))

		local var_4_9 = var_4_8:getChildByName("get_btn")

		var_4_9:getChildByName("get_txt"):setString(var_0_1:translation("OBTAIN"))
		var_4_9:getChildByName("got_txt"):setString(var_0_1:translation("ACTIVITY_COMMON_TEXT2"))
		var_4_9:getChildByName("unreach_txt"):setString(var_0_1:translation("NOT_REACHED_TEXT"))
		var_4_9:getChildByName("get_txt"):setVisible(false)
		var_4_9:getChildByName("got_txt"):setVisible(false)
		var_4_8:getChildByName("have_got"):setVisible(false)
		var_4_9:getChildByName("unreach_txt"):setVisible(false)

		if var_4_1[var_4_3] < var_0_2:condition(var_4_3) then
			var_4_9:getChildByName("unreach_txt"):setVisible(true)
			var_4_9:setBright(false)
		elseif var_4_2[var_4_3] == 0 then
			var_4_9:getChildByName("get_txt"):setVisible(true)
			var_4_9:setBright(true)
			var_4_9:addTouchEventListener(function(arg_5_0, arg_5_1)
				if arg_5_1 == ccui.TouchEventType.ended then
					xyd.playButtonSound()
					arg_4_0.thirdAnniModel:getMissionReward(var_4_3, function(arg_6_0, arg_6_1)
						if arg_6_0 == xyd.error.OK then
							arg_4_0.player:handleRewards(arg_6_1.awards)
							var_4_9:setBright(false)
							var_4_9:getChildByName("get_txt"):setVisible(false)
							var_4_9:getChildByName("got_txt"):setVisible(true)
							var_4_8:getChildByName("have_got"):setVisible(true)
						end
					end)
				end
			end)
		else
			var_4_9:getChildByName("got_txt"):setVisible(true)
			var_4_8:getChildByName("have_got"):setVisible(true)
			var_4_9:setBright(false)
		end

		for iter_4_1 = 1, #var_4_4 do
			local var_4_10 = display.newNode()

			var_4_10:setContentSize(85, 85)
			xyd.setItemAndAddTips(var_4_10, var_4_4[iter_4_1], var_4_5[iter_4_1])
			var_4_10:addTo(var_4_8:getChildByName("item_pos"))
			var_4_10:setAnchorPoint(cc.p(0.5, 0.5))
			var_4_10:setPosition(iter_4_1 * 100 - 110, 0)
		end

		local var_4_11 = var_4_8:getContentSize()

		var_4_7:setAnchorPoint(cc.p(0, 0))
		var_4_7:setContentSize(var_4_11.width, var_4_11.height)
		var_4_6:setItemSize(var_4_11.width, var_4_11.height)
		var_4_6:addContent(var_4_7)
		arg_4_0.scrollList:addItem(var_4_6)
	end

	arg_4_0.scrollList:reload()
end

function var_0_0.didOpen(arg_7_0, arg_7_1)
	var_0_0.super:didOpen(arg_7_1)
	arg_7_0:addBlockLayer()
end

return var_0_0
