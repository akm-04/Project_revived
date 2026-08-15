local var_0_0 = class("AchievementAwardWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.achievement = xyd.ModelManager.get():loadModel(xyd.ModelType.ACHIEVEMENT)
	arg_1_0.awardStatus = arg_1_0.achievement.baseInfo.award_status or {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0.scrollContainer = arg_4_0:nodeByName("scroll")

	local var_4_0 = arg_4_0.scrollContainer:getContentSize()

	arg_4_0.scrollList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 5, var_4_0.width, var_4_0.height - 5),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_4_0.scrollContainer):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.scrollList:setDelegate(handler(arg_4_0, arg_4_0.achievementAwardsDelegate))
	arg_4_0.scrollList:reload()
end

function var_0_0.achievementAwardsDelegate(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	if cc.ui.UIListView.COUNT_TAG == arg_5_2 then
		return #arg_5_0.awardStatus - 1
	elseif cc.ui.UIListView.CELL_TAG == arg_5_2 then
		local var_5_0 = arg_5_0.scrollList:dequeueItem()

		if not var_5_0 then
			var_5_0 = arg_5_0.scrollList:newItem()
		else
			var_5_0:removeAllChildren(true)
		end

		local var_5_1 = arg_5_0:createAwardItem(arg_5_0:calculateIdByIdx(arg_5_3))
		local var_5_2 = var_5_1:getWidth()
		local var_5_3 = var_5_1:getHeight()

		var_5_0:setItemSize(var_5_2, var_5_3)
		var_5_0:addContent(var_5_1)

		return var_5_0
	end
end

function var_0_0.calculateIdByIdx(arg_6_0, arg_6_1)
	local var_6_0 = #arg_6_0.awardStatus - 1

	return (arg_6_1 + 1 - 2 + arg_6_0:getRotationBias()) % var_6_0 + 2
end

function var_0_0.getRotationBias(arg_7_0)
	local var_7_0 = 0

	for iter_7_0 = 2, #arg_7_0.awardStatus do
		if arg_7_0.awardStatus[iter_7_0] == -1 then
			var_7_0 = var_7_0 + 1
		else
			break
		end
	end

	return var_7_0
end

function var_0_0.createAwardItem(arg_8_0, arg_8_1)
	local var_8_0 = display.newNode()
	local var_8_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/achievement/achieve_awards/award_item.csb")
	local var_8_2 = var_8_1:getChildByName("container")

	var_8_2:getChildByName("name_txt"):setString(xyd.tables.achievementLevel:levelName(arg_8_1))
	var_8_2:getChildByName("not_get_text"):setString(var_0_1:translation("NOT_REACHED_TEXT"))

	local var_8_3 = xyd.tables.achievementLevel:pointCondition(arg_8_1)

	var_8_2:getChildByName("desc_txt"):setString(xyd.tables.achievementLevel:desc(arg_8_1))
	arg_8_0.achievement:setItemClip(var_8_2:getChildByName("icon"), xyd.tables.achievementLevel:icon(arg_8_1))

	if arg_8_0.awardStatus[arg_8_1] == 0 then
		var_8_2:getChildByName("achieved_text"):setVisible(false)
		var_8_2:getChildByName("not_get_text"):setVisible(true)
		var_8_2:getChildByName("have_gotten_text"):setVisible(false)
	elseif arg_8_0.awardStatus[arg_8_1] == 1 then
		var_8_2:getChildByName("achieved_text"):setVisible(true)
		var_8_2:getChildByName("not_get_text"):setVisible(false)
		var_8_2:getChildByName("have_gotten_text"):setVisible(false)
	elseif arg_8_0.awardStatus[arg_8_1] == -1 then
		var_8_2:getChildByName("achieved_text"):setVisible(false)
		var_8_2:getChildByName("not_get_text"):setVisible(false)
		var_8_2:getChildByName("have_gotten_text"):setVisible(true)
	end

	local var_8_4 = xyd.tables.achievementLevel:items(arg_8_1)
	local var_8_5 = xyd.tables.achievementLevel:itemNums(arg_8_1)

	var_8_2:getChildByName("not_open_text"):setString(var_0_1:translation("ACHIEVEMENT_LEV_AWARD_NOT_OPEN"))

	if #var_8_4 > 0 and var_8_4[1] > 0 then
		var_8_2:getChildByName("not_open_text"):setVisible(false)
		xyd.setItemAndAddTips(var_8_2:getChildByName("award_item"), var_8_4[1], var_8_5[1])
	else
		var_8_2:getChildByName("not_open_text"):setVisible(true)
	end

	var_8_1:addTo(var_8_0)
	var_8_1:setAnchorPoint(cc.p(0, 0))
	var_8_0:setContentSize(var_8_2:getContentSize())
	var_8_1:setName("source")

	return var_8_0
end

function var_0_0.getLatestTime(arg_9_0, arg_9_1)
	for iter_9_0 = #arg_9_1, 1, -1 do
		if arg_9_1[iter_9_0] ~= 0 then
			return arg_9_1[iter_9_0]
		end
	end

	return 0
end

function var_0_0.createItemNumLabel(arg_10_0, arg_10_1)
	local var_10_0 = {
		font = "fonts/main_font.ttf",
		size = 30,
		color = cc.c3b(255, 255, 255)
	}
	local var_10_1 = xyd.AssetLoader.get():loadLabel(var_10_0)

	var_10_1:setMaxLineWidth(250)
	var_10_1:setString("X" .. arg_10_1)

	return var_10_1
end

function var_0_0.scrollListener(arg_11_0, arg_11_1)
	if arg_11_1.name == "began" then
		arg_11_0.scrollViewMoved_ = false
		arg_11_0.prevY_ = arg_11_1.y
	elseif arg_11_1.name == "moved" and 10 <= math.abs(arg_11_1.y - arg_11_0.prevY_) then
		arg_11_0.scrollViewMoved_ = true
	end
end

return var_0_0
