local var_0_0 = class("MapTaskWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 85

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.task = xyd.ModelManager.get():loadModel(xyd.ModelType.TASK)
	arg_1_0.campaignType = xyd.CampaignType.NORMAL
	arg_1_0.isInit = false

	arg_1_0:onMissionChange()
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_1_0):addEventListener(xyd.event.ON_MISSION_STATE_CHANGE, handler(arg_1_0, arg_1_0.onMissionChange))
end

function var_0_0.filterShowMissionIDs(arg_2_0, arg_2_1, arg_2_2)
	local var_2_0 = {}

	for iter_2_0, iter_2_1 in pairs(arg_2_1) do
		local var_2_1 = xyd.tables.mission:display(iter_2_1)
		local var_2_2 = arg_2_0:getCampaignType(iter_2_1)

		if var_2_1 == 1 and var_2_2 == arg_2_2 then
			table.insert(var_2_0, iter_2_1)
		end
	end

	return var_2_0
end

function var_0_0.onMissionChange(arg_3_0, arg_3_1)
	if not arg_3_0.isInit then
		arg_3_0:initCampaignType()

		arg_3_0.isInit = true
	end

	arg_3_0.missionIDs = arg_3_0:filterShowMissionIDs(arg_3_0.task:getTaskIDs(xyd.TaskType.STORY), arg_3_0.campaignType)

	if arg_3_0.scrollList then
		arg_3_0:updateRedPoint()

		if not arg_3_1 then
			arg_3_0.scrollList:refreshList()
		else
			arg_3_0.scrollList:reload()
		end
	end
end

function var_0_0.updateRedPoint(arg_4_0)
	local var_4_0, var_4_1 = arg_4_0:getRedPointInfo()

	arg_4_0:nodeByName("normal_btn"):getChildByName("red_point"):setVisible(var_4_0)
	arg_4_0:nodeByName("super_btn"):getChildByName("red_point"):setVisible(var_4_1)
end

function var_0_0.initCampaignType(arg_5_0)
	local var_5_0, var_5_1 = arg_5_0:getRedPointInfo()

	if not var_5_0 and var_5_1 then
		arg_5_0.campaignType = xyd.CampaignType.SUPER
	else
		arg_5_0.campaignType = xyd.CampaignType.NORMAL
	end
end

function var_0_0.getRedPointInfo(arg_6_0)
	local var_6_0 = arg_6_0.task:getTaskIDs(xyd.TaskType.STORY)
	local var_6_1 = false
	local var_6_2 = false

	for iter_6_0, iter_6_1 in pairs(var_6_0) do
		local var_6_3 = arg_6_0.task:getTaskByID(iter_6_1, xyd.TaskType.STORY)
		local var_6_4 = xyd.tables.mission:display(iter_6_1)
		local var_6_5 = arg_6_0:getCampaignType(iter_6_1)

		if var_6_3 and var_6_4 == 1 and var_6_3.is_complete == 1 and not var_6_3.is_reward == 0 then
			if var_6_5 == xyd.CampaignType.NORMAL then
				var_6_1 = true
			else
				var_6_2 = true
			end
		end
	end

	return var_6_1, var_6_2
end

function var_0_0.willOpen(arg_7_0, arg_7_1)
	var_0_0.super.willOpen(arg_7_0, arg_7_1)
	arg_7_0:layout()
end

function var_0_0.didOpen(arg_8_0, arg_8_1)
	var_0_0.super.didOpen(arg_8_0, arg_8_1)
	arg_8_0:addBlockLayer()
	arg_8_0:playGuide()
end

function var_0_0.layout(arg_9_0)
	arg_9_0.scroll = arg_9_0:nodeByName("scroll")

	local var_9_0 = arg_9_0.scroll:getContentSize()

	arg_9_0.scrollList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_9_0.width, var_9_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_9_0.scroll):onScroll(handler(arg_9_0, arg_9_0.scrollListener))

	arg_9_0.scrollList:setDelegate(handler(arg_9_0, arg_9_0.scrollListDelegate))
	arg_9_0.scrollList:reload()
	arg_9_0:updateRedPoint()
	arg_9_0:setButtonClick()
	arg_9_0:nodeByName("normal_text"):setString(var_0_1:translation("NORMAL_TEXT"))
	arg_9_0:nodeByName("super_text"):setString(var_0_1:translation("SUPER"))
	arg_9_0:nodeByName("empty_tip_text"):setString(var_0_1:translation("MISSION_EMPTY_TIP"))
	arg_9_0:nodeByName("title"):setString(var_0_1:translation("MISSION"))
end

function var_0_0.setButtonClick(arg_10_0)
	arg_10_0:nodeByName("super_btn"):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_10_0.campaignType ~= xyd.CampaignType.SUPER then
				arg_10_0.campaignType = xyd.CampaignType.SUPER

				arg_10_0:updateBtnState()
				arg_10_0:onMissionChange(true)
			end
		end
	end)
	arg_10_0:nodeByName("normal_btn"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_10_0.campaignType ~= xyd.CampaignType.NORMAL then
				arg_10_0.campaignType = xyd.CampaignType.NORMAL

				arg_10_0:updateBtnState()
				arg_10_0:onMissionChange(true)
			end
		end
	end)
	arg_10_0:updateBtnState()
end

function var_0_0.updateBtnState(arg_13_0)
	if arg_13_0.campaignType == xyd.CampaignType.NORMAL then
		arg_13_0:nodeByName("super_btn"):setTouchEnabled(true)
		arg_13_0:nodeByName("super_btn"):setBright(true)
		arg_13_0:nodeByName("normal_btn"):setTouchEnabled(false)
		arg_13_0:nodeByName("normal_btn"):setBright(false)
	else
		arg_13_0:nodeByName("super_btn"):setTouchEnabled(false)
		arg_13_0:nodeByName("super_btn"):setBright(false)
		arg_13_0:nodeByName("normal_btn"):setTouchEnabled(true)
		arg_13_0:nodeByName("normal_btn"):setBright(true)
	end
end

function var_0_0.scrollListDelegate(arg_14_0, arg_14_1, arg_14_2, arg_14_3)
	if #arg_14_0.missionIDs <= 0 then
		arg_14_0:nodeByName("empty_tip_text"):setVisible(true)
	else
		arg_14_0:nodeByName("empty_tip_text"):setVisible(false)
	end

	if cc.ui.UIListView.COUNT_TAG == arg_14_2 then
		return #arg_14_0.missionIDs
	elseif cc.ui.UIListView.CELL_TAG == arg_14_2 then
		local var_14_0
		local var_14_1 = arg_14_0.scrollList:dequeueItem()

		if not var_14_1 then
			var_14_1 = arg_14_0.scrollList:newItem()
		else
			var_14_1:removeAllChildren(true)
		end

		local var_14_2 = arg_14_0:createListContent(arg_14_0.missionIDs[arg_14_3])
		local var_14_3 = var_14_2:getWidth()
		local var_14_4 = var_14_2:getHeight()

		var_14_1:setItemSize(var_14_3, var_14_4)
		var_14_1:addContent(var_14_2)

		return var_14_1
	end
end

function var_0_0.createListContent(arg_15_0, arg_15_1)
	local var_15_0 = arg_15_0.task:getTaskByID(arg_15_1, xyd.TaskType.STORY)
	local var_15_1 = display.newNode()
	local var_15_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/map_window/task/campaign_task_item.csb")
	local var_15_3 = var_15_2:getChildByName("container")

	if var_15_0.is_complete == 1 and var_15_0.is_reward == 0 then
		var_15_3:getChildByName("item_bg1"):setVisible(false)
		var_15_3:getChildByName("item_bg2"):setVisible(true)
		var_15_3:getChildByName("progress_txt"):setVisible(false)
		var_15_3:getChildByName("btn"):setVisible(false)
		var_15_3:getChildByName("icon_available"):setVisible(true)
		var_15_2:setTouchEnabled(true)
		var_15_2:setTouchSwallowEnabled(false)
		var_15_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_16_0)
			if arg_16_0.name == "began" then
				return true
			elseif arg_16_0.name == "ended" and not arg_15_0.scrollViewMoved_ then
				audio.playSound("sound/button.ogg", false)

				if var_15_0.is_reward == 1 then
					return
				elseif var_15_0.is_complete == 1 then
					arg_15_0.task:getTaskReward(arg_15_1, xyd.TaskType.STORY, function(arg_17_0, arg_17_1)
						if arg_17_0 == xyd.error.OK then
							xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):handleRewardsWithoutShow(arg_17_1.awards)

							local var_17_0 = string.format("%s %s", var_0_1:translation("FINISH"), xyd.tables.mission:name(var_15_0.table_id))

							xyd.WindowManager.get():openWindow("alert_award", {
								awards = arg_17_1.awards,
								name = var_17_0
							})
						end
					end)
				else
					local var_16_0 = xyd.tables.mission:goto_value(arg_15_1)
					local var_16_1 = {
						isStoneCampaign = true,
						chapter = xyd.tables.campaign:chapter(var_16_0),
						campaignID = var_16_0,
						campaignType = arg_15_0:getCampaignType(arg_15_1)
					}

					arg_15_0.guild:loadGuildMap(function(arg_18_0)
						xyd.WindowManager.get():closeWindow("map_window")
						xyd.WindowManager.get():openWindow("map_window", var_16_1)
						xyd.WindowManager.get():closeWindow(arg_15_0)
					end)
				end
			end
		end)
	else
		var_15_3:getChildByName("item_bg1"):setVisible(true)
		var_15_3:getChildByName("item_bg2"):setVisible(false)
		var_15_3:getChildByName("progress_txt"):setVisible(true)
		var_15_3:getChildByName("btn"):setVisible(true)
		var_15_3:getChildByName("icon_available"):setVisible(false)
		var_15_3:getChildByName("btn"):getChildByName("txt_btn"):setString(var_0_1:translation("BUTTON_NAME_GO"))
		var_15_3:getChildByName("btn"):addTouchEventListener(function(arg_19_0, arg_19_1)
			xyd.buttonScaleAnim(arg_19_0, arg_19_1)

			if arg_19_1 == ccui.TouchEventType.ended then
				audio.playSound("sound/button.ogg", false)

				if var_15_0.is_reward == 1 then
					return
				elseif var_15_0.is_complete == 1 then
					arg_15_0.task:getTaskReward(arg_15_1, xyd.TaskType.STORY, function(arg_20_0, arg_20_1)
						if arg_20_0 == xyd.error.OK then
							xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):handleRewardsWithoutShow(arg_20_1.awards)

							local var_20_0 = string.format("%s %s", var_0_1:translation("FINISH"), xyd.tables.mission:name(var_15_0.table_id))

							xyd.WindowManager.get():openWindow("alert_award", {
								awards = arg_20_1.awards,
								name = var_20_0
							})
						end
					end)
				else
					local var_19_0 = xyd.tables.mission:goto_value(arg_15_1)
					local var_19_1 = {
						isStoneCampaign = true,
						chapter = xyd.tables.campaign:chapter(var_19_0),
						campaignID = var_19_0,
						campaignType = arg_15_0:getCampaignType(arg_15_1)
					}

					arg_15_0.guild:loadGuildMap(function(arg_21_0)
						xyd.WindowManager.get():closeWindow("map_window")
						xyd.WindowManager.get():openWindow("map_window", var_19_1)
						xyd.WindowManager.get():closeWindow(arg_15_0)
					end)
				end
			end
		end)
	end

	var_15_3:getChildByName("task_name_txt"):setString(xyd.tables.mission:name(arg_15_1))

	local var_15_4 = xyd.tables.mission:des(arg_15_1)
	local var_15_5, var_15_6, var_15_7 = string.match(var_15_4, "(.*[^%d]+)(%d+)|(%d+)$")

	if var_15_5 and var_15_6 and var_15_7 then
		var_15_3:getChildByName("task_desc_txt"):setString(string.format(xyd.tables.translation:translation("MISSION_DESC"), var_15_5, "《" .. xyd.tables.campaign:campaignName(tonumber(var_15_6)) .. "》", tonumber(var_15_7) or 1))
	else
		var_15_3:getChildByName("task_desc_txt"):setString(var_15_4)
	end

	var_15_3:getChildByName("award_text"):setString(var_0_1:translation("MISSION_TEXT"))
	var_15_3:getChildByName("progress_txt"):setString(string.format("%d/%d", var_15_0.count, xyd.tables.mission:task_num(arg_15_1)))

	local var_15_8 = import("app.common.ui.SplitLine")
	local var_15_9 = var_15_3:getChildByName("line")

	var_15_8.new({
		size = var_15_9:getWidth()
	}):addTo(var_15_9)

	local var_15_10 = xyd.getFormatItemsByMissionId(arg_15_1)

	for iter_15_0, iter_15_1 in ipairs(var_15_10) do
		local var_15_11 = display.newNode()

		var_15_11:setContentSize(var_0_2, var_0_2)
		xyd.setItemAndAddTips(var_15_11, iter_15_1.item_id, iter_15_1.item_num)
		var_15_11:addTo(var_15_3:getChildByName("award_pos"))
		var_15_11:setPositionX((iter_15_0 - 1) * (var_0_2 + 15))
	end

	var_15_2:addTo(var_15_1)
	var_15_2:setAnchorPoint(cc.p(0, 0))
	var_15_1:setContentSize(var_15_3:getContentSize())
	var_15_2:setName("source")

	return var_15_1
end

function var_0_0.getCampaignType(arg_22_0, arg_22_1)
	local var_22_0 = xyd.tables.mission:goto_value(arg_22_1)
	local var_22_1 = 2
	local var_22_2 = 1

	if xyd.tables.campaign:campaignType(var_22_0) == var_22_1 or xyd.tables.campaign:campaignType(var_22_0) == var_22_2 then
		return xyd.CampaignType.NORMAL
	else
		return xyd.CampaignType.SUPER
	end
end

function var_0_0.scrollListener(arg_23_0, arg_23_1)
	if arg_23_1.name == "began" then
		arg_23_0.scrollViewMoved_ = false
		arg_23_0.prevY_ = arg_23_1.y
	elseif arg_23_1.name == "moved" and 5 <= math.abs(arg_23_1.y - arg_23_0.prevY_) then
		arg_23_0.scrollViewMoved_ = true
	end
end

function var_0_0.playGuide(arg_24_0)
	local var_24_0 = xyd.StoryData.get():getGuideID()

	if xyd.WindowManager.get():getWindow("guide") then
		xyd.WindowManager.get():closeWindow("guide")
	end

	if var_24_0 <= xyd.GuideStoryType.GUIDE_MISSION_TWO then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_MISSION_TWO)
		arg_24_0.scrollList:setViewCanNotScroll(true)

		if not arg_24_0.scrollList.items_[1] then
			return
		end

		xyd.WindowManager.get():openWindow("guide")

		local var_24_1 = xyd.WindowManager.get():getWindow("guide")

		var_24_1:addNode()
		var_24_1:setStencil(878, 148, 743, 535, 0, {
			rect = true,
			position = {
				700,
				220
			}
		})
		arg_24_0.selfPlayer:sendOperationLog(xyd.StatID.ID_MISSION_2)
	elseif var_24_0 <= xyd.GuideStoryType.GUIDE_MISSION_FOUR then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_MISSION_FOUR)
		xyd.WindowManager.get():openWindow("guide")

		local var_24_2 = xyd.WindowManager.get():getWindow("guide")

		var_24_2:addNode()
		var_24_2:setStencil(30, 30, 1168, 653, 1, {
			position = {
				700,
				350
			}
		})
	end
end

function var_0_0.didClose(arg_25_0)
	xyd.WindowManager.get():closeWindow("guide")

	local var_25_0 = xyd.WindowManager.get():getWindow("map_window")
	local var_25_1 = xyd.StoryData.get():getGuideID()

	if var_25_0 and var_25_1 == xyd.GuideStoryType.GUIDE_MISSION_FOUR then
		var_25_0:playGuide()
	end
end

return var_0_0
