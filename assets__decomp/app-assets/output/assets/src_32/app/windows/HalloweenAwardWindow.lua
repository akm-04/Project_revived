local var_0_0 = class("HalloweenAwardWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = 110.8
local var_0_3 = 1
local var_0_4 = xyd.tables.translation
local var_0_5 = {
	AWARD = 1,
	RANK = 2
}
local var_0_6 = 6

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.activity = {}
	arg_1_0.activityModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.rightMenuType = nil
	arg_1_0.rankInfo = {}
	arg_1_0.rollContainer = {}
	arg_1_0.curRegionElement = nil
	arg_1_0.countRoll = 0
	arg_1_0.activity = arg_1_2
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0)
	arg_2_0:layout()
end

function var_0_0.loadSingleActivity(arg_3_0, arg_3_1)
	local var_3_0 = {
		activity_id = xyd.Activities.FUSION
	}

	arg_3_0.activityModel:loadSingleActivity(var_3_0, function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK and arg_3_1 then
			arg_3_1(arg_4_1)
		end
	end)
end

function var_0_0.didOpen(arg_5_0)
	var_0_0.super.didOpen(arg_5_0)
	arg_5_0:addBlockLayer()
end

function var_0_0.willClose(arg_6_0)
	var_0_0.super.willClose(arg_6_0)

	if arg_6_0.handler then
		var_0_1.unscheduleGlobal(arg_6_0.handler)

		arg_6_0.handler = nil
	end
end

function var_0_0.didClose(arg_7_0)
	var_0_0.super.didClose(arg_7_0)
end

function var_0_0.layout(arg_8_0)
	arg_8_0:nodeByName("txt_mid"):setString(var_0_4:translation("ACTIVITY_1076_TEXT_1"))
	arg_8_0:nodeByName("txt_mid"):enableOutline(cc.c4b(153, 72, 0, 255), 1)
	arg_8_0:nodeByName("text_all_award"):setString(var_0_4:translation("ACTIVITY_1076_TEXT_2"))
	arg_8_0:nodeByName("text_rank"):setString(var_0_4:translation("ACTIVITY_1076_TEXT_3"))
	arg_8_0:nodeByName("txt_progress"):setString(var_0_4:translation("ACTIVITY_FUSION_NOW_ELEMENT"))
	arg_8_0:nodeByName("text_award_tips"):setString(string.format(var_0_4:translation("ACTIVITY_FUSION_AWARD_TIPS"), xyd.tables.misc.activityFusionTargetRequire))
	arg_8_0:nodeByName("text_collect_num"):setString(xyd.tables.misc.activityFusionServerTarget)
	arg_8_0:nodeByName("img_punpkin_2"):setTouchEnabled(true)
	arg_8_0:nodeByName("img_punpkin_2"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
		if arg_9_0.name == "began" then
			arg_8_0:nodeByName("img_punpkin_2"):setScale(0.9)

			return true
		elseif arg_9_0.name == "ended" then
			arg_8_0:nodeByName("img_punpkin_2"):setScale(1)

			local var_9_0 = var_0_4:translation("ACTIVITY_FUSION_AWARD_TIPS_2")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_9_0
			})
		end
	end)

	local var_8_0 = arg_8_0:nodeByName("rank_container")
	local var_8_1 = var_8_0:getContentSize()

	arg_8_0.rankList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_8_1.width, var_8_1.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_8_0)

	arg_8_0.rankList:setDelegate(handler(arg_8_0, arg_8_0.delegate))
	arg_8_0:initLoadingBar()
	arg_8_0:initRightMenu()
	arg_8_0:initElementNum()
	arg_8_0:getActivityInfo()
end

function var_0_0.initLoadingBar(arg_10_0)
	local var_10_0 = 100 * arg_10_0.activity.details.region_element / xyd.tables.misc.activityFusionServerTarget

	arg_10_0:nodeByName("loading_bar"):setPercent(var_10_0)
end

function var_0_0.initRightMenu(arg_11_0)
	arg_11_0:nodeByName("btn_all_award"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.ended and arg_11_0.rightMenuType ~= var_0_5.AWARD then
			xyd.playTabButtonSound()

			arg_11_0.rightMenuType = var_0_5.AWARD

			arg_11_0:initBtnState()
		end
	end)
	arg_11_0:nodeByName("btn_all_rank"):addTouchEventListener(function(arg_13_0, arg_13_1)
		if arg_13_1 == ccui.TouchEventType.ended and arg_11_0.rightMenuType ~= var_0_5.RANK then
			xyd.playTabButtonSound()

			arg_11_0.rightMenuType = var_0_5.RANK

			arg_11_0:initBtnState()
			arg_11_0:getRankList()
		end
	end)

	arg_11_0.rightMenuType = var_0_5.AWARD

	arg_11_0:initBtnState()
end

function var_0_0.initBtnState(arg_14_0)
	if arg_14_0.rightMenuType == var_0_5.AWARD then
		arg_14_0:nodeByName("btn_all_award"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_14_0:nodeByName("btn_all_rank"):setBrightStyle(ccui.BrightStyle.normal)
		arg_14_0:nodeByName("btn_all_award"):setTouchEnabled(false)
		arg_14_0:nodeByName("btn_all_rank"):setTouchEnabled(true)
		arg_14_0:nodeByName("award_container"):setVisible(true)
		arg_14_0:nodeByName("rank_container"):setVisible(false)
	elseif arg_14_0.rightMenuType == var_0_5.RANK then
		arg_14_0:nodeByName("btn_all_award"):setBrightStyle(ccui.BrightStyle.normal)
		arg_14_0:nodeByName("btn_all_rank"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_14_0:nodeByName("award_container"):setVisible(false)
		arg_14_0:nodeByName("rank_container"):setVisible(true)
		arg_14_0:nodeByName("btn_all_award"):setTouchEnabled(true)
		arg_14_0:nodeByName("btn_all_rank"):setTouchEnabled(false)
	end
end

function var_0_0.getRegionElement(arg_15_0)
	local var_15_0 = tostring(arg_15_0.activity.details.region_element)
	local var_15_1 = var_0_6

	if var_15_1 > #var_15_0 then
		for iter_15_0 = 1, var_15_1 - #var_15_0 do
			var_15_0 = "0" .. var_15_0
		end
	elseif var_15_1 < #var_15_0 then
		var_15_0 = ""

		for iter_15_1 = 1, var_15_1 do
			var_15_0 = "9" .. var_15_0
		end
	end

	return var_15_0
end

function var_0_0.initElementNum(arg_16_0)
	local var_16_0 = arg_16_0:nodeByName("progress_container")
	local var_16_1 = arg_16_0:getRegionElement()
	local var_16_2 = 20

	for iter_16_0 = 1, #var_16_1 do
		local var_16_3 = arg_16_0:clipRollContainer(var_16_0, var_16_2, -66):getChildByName("container")
		local var_16_4 = cc.p(var_16_3:getChildByName("node_mid"):getPosition())
		local var_16_5 = string.sub(var_16_1, iter_16_0, iter_16_0)
		local var_16_6 = xyd.AssetLoader.get():loadSprite("windows/activities/1076/num/" .. var_16_5 .. ".png")

		var_16_6:addTo(var_16_3)
		var_16_6:setPosition(cc.p(var_16_4))
		var_16_6:setName("num_mid")

		var_16_2 = var_16_2 + var_0_2

		table.insert(arg_16_0.rollContainer, var_16_3)
	end

	arg_16_0.curRegionElement = var_16_1
end

function var_0_0.getActivityInfo(arg_17_0)
	if arg_17_0.handler then
		var_0_1.unscheduleGlobal(arg_17_0.handler)

		arg_17_0.handler = nil
	end

	local var_17_0 = 3

	arg_17_0.handler = var_0_1.scheduleGlobal(function()
		var_17_0 = var_17_0 - 1

		if var_17_0 <= 0 then
			if arg_17_0.handler then
				var_0_1.unscheduleGlobal(arg_17_0.handler)

				arg_17_0.handler = nil
			end

			if arg_17_0 and not tolua.isnull(arg_17_0) then
				arg_17_0:loadSingleActivity(function(arg_19_0)
					if arg_17_0 and not tolua.isnull(arg_17_0) then
						arg_17_0.activity = arg_19_0

						arg_17_0:initLoadingBar()
						arg_17_0:changeElementNum()
					end
				end)
			end
		end
	end, 1)
end

function var_0_0.clipRollContainer(arg_20_0, arg_20_1, arg_20_2, arg_20_3)
	local var_20_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1076/roll_num.csb")

	var_20_0:setAnchorPoint(cc.p(0, 0))
	var_20_0:setPosition(cc.p(0, 0))

	local var_20_1 = xyd.AssetLoader:get():loadSprite("windows/activities/1076/clip_rect.png")

	var_20_1:setPosition(cc.p(0, 0))
	var_20_1:setAnchorPoint(cc.p(0, 0))

	local var_20_2 = cc.ClippingNode:create()

	var_20_2:setStencil(var_20_1)
	var_20_2:setInverted(true)
	var_20_2:setAlphaThreshold(0)
	arg_20_1:addChild(var_20_2)
	var_20_2:setPosition(cc.p(arg_20_2, arg_20_3))
	var_20_2:addChild(var_20_0)

	return var_20_0
end

function var_0_0.changeElementNum(arg_21_0)
	local var_21_0 = arg_21_0:getRegionElement()

	if not arg_21_0.rollContainer or not next(arg_21_0.rollContainer) then
		return
	elseif arg_21_0.curRegionElement == var_21_0 then
		arg_21_0:getActivityInfo()

		return
	end

	local var_21_1 = 0

	for iter_21_0 = 1, #var_21_0 do
		if string.sub(arg_21_0.curRegionElement, iter_21_0, iter_21_0) ~= string.sub(var_21_0, iter_21_0, iter_21_0) then
			var_21_1 = var_21_1 + 1
		end
	end

	for iter_21_1 = 1, #var_21_0 do
		local var_21_2 = string.sub(arg_21_0.curRegionElement, iter_21_1, iter_21_1)

		if var_21_2 ~= string.sub(var_21_0, iter_21_1, iter_21_1) then
			local var_21_3 = arg_21_0.rollContainer[iter_21_1]
			local var_21_4 = cc.p(var_21_3:getChildByName("node_top"):getPosition())
			local var_21_5 = cc.p(var_21_3:getChildByName("node_mid"):getPosition())
			local var_21_6 = cc.p(var_21_3:getChildByName("node_bottom"):getPosition())
			local var_21_7 = var_21_2 + 1

			if var_21_7 > 9 then
				var_21_7 = 0
			end

			local var_21_8 = var_21_3:getChildByName("num_bottom")

			if var_21_8 and not tolua.isnull(var_21_8) then
				var_21_8:removeSelf()
			end

			local var_21_9 = var_21_3:getChildByName("num_mid")

			if var_21_9 and not tolua.isnull(var_21_9) then
				var_21_9:setName("num_bottom")
			end

			local var_21_10 = xyd.AssetLoader.get():loadSprite("windows/activities/1076/num/" .. var_21_7 .. ".png")

			var_21_10:addTo(var_21_3)
			var_21_10:setPosition(cc.p(var_21_4))
			var_21_10:setName("num_mid")

			arg_21_0.curRegionElement = string.sub(arg_21_0.curRegionElement, 1, iter_21_1 - 1) .. var_21_7 .. string.sub(arg_21_0.curRegionElement, iter_21_1 + 1, -1)

			local var_21_11 = cc.MoveTo:create(var_0_3, cc.p(var_21_6))
			local var_21_12 = cc.MoveTo:create(var_0_3, cc.p(var_21_5))
			local var_21_13 = cc.CallFunc:create(function()
				arg_21_0.countRoll = arg_21_0.countRoll + 1

				if arg_21_0.countRoll == 2 * var_21_1 then
					arg_21_0:changeElementNum()

					arg_21_0.countRoll = 0
				end
			end)

			var_21_9:runAction(transition.sequence({
				var_21_11,
				var_21_13
			}))
			var_21_10:runAction(transition.sequence({
				var_21_12,
				var_21_13
			}))
		end
	end
end

function var_0_0.scrollListener(arg_23_0, arg_23_1)
	if arg_23_1.name == "began" then
		arg_23_0.scrollViewMoved_ = false
		arg_23_0.prevX_ = arg_23_1.x
	elseif arg_23_1.name == "moved" and 20 <= math.abs(arg_23_1.x - arg_23_0.prevX_) then
		arg_23_0.scrollViewMoved_ = true
	end
end

function var_0_0.getRankList(arg_24_0, arg_24_1)
	local var_24_0 = arg_24_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_HALLOWEEN_AWARD_RANK, var_24_0, function(arg_25_0, arg_25_1)
		if arg_25_0 == xyd.error.OK then
			arg_24_0.rankInfo = arg_25_1.infos

			arg_24_0.rankList:reload()
		end
	end)
end

function var_0_0.delegate(arg_26_0, arg_26_1, arg_26_2, arg_26_3)
	local var_26_0 = #arg_26_0.rankInfo

	if cc.ui.UIListView.COUNT_TAG == arg_26_2 then
		return var_26_0
	elseif cc.ui.UIListView.CELL_TAG == arg_26_2 then
		local var_26_1
		local var_26_2
		local var_26_3
		local var_26_4 = arg_26_0.rankList:dequeueItem()

		if not var_26_4 then
			var_26_4 = arg_26_0.rankList:newItem()
		else
			var_26_4:removeAllChildren()
		end

		local var_26_5 = display.newNode()

		var_26_5:setTouchSwallowEnabled(false)

		local var_26_6 = arg_26_3
		local var_26_7 = display.newNode()

		arg_26_0:initRankCell(var_26_7, var_26_6)

		local var_26_8 = var_26_7:getContentSize().width
		local var_26_9 = var_26_7:getContentSize().height

		var_26_5:addChild(var_26_7)
		var_26_5:setContentSize(cc.size(arg_26_0.rankList.viewRect_.width, var_26_7:getContentSize().height + 10))
		var_26_4:setItemSize(arg_26_0.rankList.viewRect_.width, var_26_7:getContentSize().height + 10)
		var_26_4:addContent(var_26_5)

		return var_26_4
	end
end

function var_0_0.initRankCell(arg_27_0, arg_27_1, arg_27_2)
	local var_27_0 = arg_27_0.rankInfo[arg_27_2]
	local var_27_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1076/rank_item.csb")

	var_27_1:addTo(arg_27_1)

	local var_27_2 = var_27_1:getChildByName("container")

	arg_27_1:setContentSize(var_27_2:getContentSize().width, var_27_2:getContentSize().height)
	var_27_2:getChildByName("text_name"):setString(var_27_0.player_name)
	var_27_2:getChildByName("text_lev"):setString(var_27_0.level)
	var_27_2:getChildByName("text_element_num"):setString(string.format(var_0_4:translation("ACTIVITY_FUSION_ELEMENT_NUM"), var_27_0.element_num))
	xyd.setAvatarClip(var_27_2:getChildByName("avatar"), var_27_0.avatar_id, 1)

	local var_27_3 = "images/avatar_frames/" .. xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarFrameId] .. ".png"

	if var_27_0.avatar_frame_id and var_27_0.avatar_frame_id ~= 0 then
		var_27_3 = "images/avatar_frames/" .. xyd.tables.avatar.icon_[var_27_0.avatar_frame_id] .. ".png"
	end

	local var_27_4 = xyd.SpriteLoader.new(var_27_3, nil, nil, xyd.DefaultImageType.AVATAR_FRAME)
	local var_27_5 = var_27_2:getChildByName("avatar_frame"):getContentSize()

	var_27_4:addTo(var_27_2:getChildByName("avatar_frame"))
	var_27_4:setAnchorPoint(cc.p(0.5, 0.5))
	var_27_4:setPosition(var_27_5.width / 2 - 1, var_27_5.height / 2 - 3)

	local var_27_6 = cc.p(var_27_2:getChildByName("rank_pos"):getPosition())
	local var_27_7

	if arg_27_2 <= 3 then
		var_27_7 = xyd.AssetLoader.get():loadSprite("windows/activities/1076/rank_" .. arg_27_2 .. ".png")
	else
		var_27_7 = xyd.AssetLoader.get():loadLabel(nil, "rankFonts")

		var_27_7:setString(arg_27_2)
	end

	var_27_7:setAnchorPoint(cc.p(0.5, 0.5))
	var_27_7:setPosition(cc.p(var_27_6))
	var_27_7:addTo(var_27_2)
end

return var_0_0
