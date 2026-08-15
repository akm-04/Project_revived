local var_0_0 = class("SakuraBattleWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.sakura = xyd.ModelManager.get():loadModel(xyd.ModelType.SAKURA)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.battles = arg_1_0:getBattles()
end

function var_0_0.getBattles(arg_2_0)
	local var_2_0 = {}
	local var_2_1 = xyd.tables.activitySakura2Campaign:ids()

	for iter_2_0 = 1, #var_2_1 do
		if var_2_1[iter_2_0] <= arg_2_0.sakura.details.now_campaign_id or var_2_1[iter_2_0] <= arg_2_0.sakura.details.passed_campaign_id then
			table.insert(var_2_0, var_2_1[iter_2_0])
		end
	end

	return var_2_0
end

function var_0_0.getCompletePercentage(arg_3_0)
	local var_3_0 = #arg_3_0.battles

	if arg_3_0.sakura.details.now_campaign_id > 0 then
		var_3_0 = var_3_0 - 1
	end

	return var_3_0 * 100 / #xyd.tables.activitySakura2Campaign:ids()
end

function var_0_0.willOpen(arg_4_0, arg_4_1)
	var_0_0.super.willOpen(arg_4_0, arg_4_1)
	arg_4_0:layout()
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	var_0_0.super.didOpen(arg_5_0, arg_5_1)

	if arg_5_0.sakura.battleAwards then
		arg_5_0.selfPlayer:handleRewards(arg_5_0.sakura.battleAwards)

		arg_5_0.sakura.battleAwards = nil
	end
end

function var_0_0.layout(arg_6_0)
	arg_6_0.scroll = arg_6_0:nodeByName("scroll")
	arg_6_0.scrollContent = arg_6_0.scroll:getContentSize()
	arg_6_0.battleList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_6_0.scrollContent.width, arg_6_0.scrollContent.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_6_0.scroll):onScroll(handler(arg_6_0, arg_6_0.scrollListener))

	arg_6_0.battleList:setDelegate(handler(arg_6_0, arg_6_0.battleListDelegate))
	arg_6_0.battleList:setBounceable(true)
	arg_6_0.battleList:reload()
	arg_6_0:nodeByName("sakura_girl"):setPercent(arg_6_0:getCompletePercentage())
end

function var_0_0.battleListDelegate(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	if cc.ui.UIListView.COUNT_TAG == arg_7_2 then
		local var_7_0 = string.format(var_0_2:translation("SAKURA_BATTLE_PROGRESS"), arg_7_0:getCompletePercentage())

		arg_7_0:nodeByName("progress_txt"):setString(var_7_0 .. "%")

		return #arg_7_0.battles
	elseif cc.ui.UIListView.CELL_TAG == arg_7_2 then
		local var_7_1
		local var_7_2 = arg_7_0.battleList:dequeueItem()

		if not var_7_2 then
			var_7_2 = arg_7_0.battleList:newItem()
		else
			var_7_2:removeAllChildren(true)
		end

		local var_7_3 = arg_7_0:createListContent(arg_7_0.battles[arg_7_3])
		local var_7_4 = var_7_3:getWidth()
		local var_7_5 = var_7_3:getHeight()

		var_7_2:setItemSize(var_7_4, var_7_5)
		var_7_2:addContent(var_7_3)

		return var_7_2
	end
end

function var_0_0.createListContent(arg_8_0, arg_8_1)
	local var_8_0 = xyd.tables.activitySakura2Campaign
	local var_8_1 = display.newNode()
	local var_8_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/sakura/sakura_battle/battle_item.csb")
	local var_8_3 = var_8_2:getChildByName("container")

	var_8_3:getChildByName("desc_txt"):setString(var_8_0:campaignName(arg_8_1))
	var_8_3:getChildByName("title_txt"):setString(var_0_2:translation("STORY_TEXT") .. arg_8_1 - 1000)

	if arg_8_1 <= arg_8_0.sakura.details.passed_campaign_id then
		var_8_3:getChildByName("select"):setVisible(true)
		var_8_3:getChildByName("new"):setVisible(false)
	else
		var_8_3:getChildByName("select"):setVisible(false)
		var_8_3:getChildByName("new"):setVisible(true)
	end

	local var_8_4 = var_8_0:avatar(arg_8_1)
	local var_8_5 = xyd.AssetLoader.get():loadSprite(xyd.tables.model:avatar2(var_8_4))

	var_8_5:setAnchorPoint(cc.p(0, 0))
	var_8_5:addTo(var_8_3:getChildByName("icon_pos"))

	if arg_8_1 == arg_8_0.sakura.details.now_campaign_id then
		local var_8_6 = xyd.AssetLoader:get():loadSprite(xyd.tables.model:avatar2(var_8_4))
		local var_8_7 = var_8_6:getContentSize().height
		local var_8_8 = var_8_6:getContentSize().width

		var_8_6:setPosition(var_8_8 / 2, var_8_7 / 2)
		var_8_6:setAnchorPoint(cc.p(0.5, 0.5))

		local var_8_9 = cc.ClippingNode:create()

		var_8_9:setStencil(var_8_6)
		var_8_9:setAlphaThreshold(0)
		var_8_3:getChildByName("icon_pos"):addChild(var_8_9)
		var_8_9:setPosition(cc.p(0, 0))

		local var_8_10 = xyd.AssetLoader:get():loadSprite("windows/sakura/sakura_battle/cover.png")

		var_8_10:setPosition(var_8_8 / 2, var_8_7 / 2)
		var_8_10:setAnchorPoint(cc.p(0.5, 0.5))
		var_8_10:setScale(var_8_7 / var_8_10:getContentSize().height)
		var_8_9:addChild(var_8_10)
		xyd.setCascadeOpacityEnabled(var_8_9, true)
		var_8_9:setOpacity(230)
	end

	var_8_1:setTouchEnabled(true)
	var_8_1:setTouchSwallowEnabled(false)
	var_8_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
		if arg_9_0.name == "began" then
			var_8_1:setScale(0.9)

			return true
		elseif arg_9_0.name == "ended" then
			var_8_1:setScale(1)

			if arg_8_0.scrollViewMoved_ then
				return
			end

			if arg_8_1 ~= arg_8_0.sakura.details.now_campaign_id then
				arg_8_0:onlyPlayStory(arg_8_1)

				return
			end

			local var_9_0 = {
				star = 0,
				campaignID = arg_8_1,
				campaignType = xyd.CampaignType.SAKURA2_WAR
			}

			xyd.WindowManager.get():openWindow("sakura2_map_detail", var_9_0)
		end
	end)
	var_8_2:addTo(var_8_1)
	var_8_2:setAnchorPoint(cc.p(0, 0))
	var_8_1:setContentSize(var_8_3:getContentSize())
	var_8_2:setName("source")

	return var_8_1
end

function var_0_0.onlyPlayStory(arg_10_0, arg_10_1)
	local var_10_0 = xyd.tables.activitySakura2Campaign:preWarStory(arg_10_1)
	local var_10_1 = xyd.tables.activitySakura2Campaign:victoryStory(arg_10_1)

	local function var_10_2()
		xyd.WindowManager.get():openWindow("school_story_talk", {
			is_play_fadein = true,
			talk_id = var_10_1
		}):playFadeIn()
	end

	xyd.WindowManager.get():openWindow("school_story_talk", {
		is_play_fadeout = true,
		callback = var_10_2,
		talk_id = var_10_0
	})
end

function var_0_0.scrollListener(arg_12_0, arg_12_1)
	if arg_12_1.name == "began" then
		arg_12_0.scrollViewMoved_ = false
		arg_12_0.prevY_ = arg_12_1.y
	elseif arg_12_1.name == "moved" and 5 <= math.abs(arg_12_1.y - arg_12_0.prevY_) then
		arg_12_0.scrollViewMoved_ = true
	end
end

return var_0_0
