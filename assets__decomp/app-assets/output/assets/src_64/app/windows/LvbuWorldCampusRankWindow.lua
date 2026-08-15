local var_0_0 = class("LvbuWorldCampusRankWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.lvbuFestival = xyd.ModelManager.get():loadModel(xyd.ModelType.LVBU_FESTIVAL)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.rankInfo = arg_1_0.lvbuFestival.campusRankInfo

	dump(arg_1_0.rankInfo)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
	arg_2_0.blockLayer_:setPosition(cc.p(-640, -360))
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("bg_hero"):setVisible(false)
	arg_3_0:nodeByName("message"):setString(var_0_1:translation("RANK_EMPTY_TEXT"))
	arg_3_0:nodeByName("rank_title"):setString(var_0_1:translation("LVBU_WORLD_CAMPUS_RANK"))
	arg_3_0:nodeByName("total_reward_txt"):setString(arg_3_0.rankInfo.self_score)
	arg_3_0:nodeByName("myrank_text"):setString(var_0_1:translation("MYRANK_TEXT"))
	arg_3_0:nodeByName("total_reward_text"):setString(var_0_1:translation("LV_TOTAL_REWARD"))

	local function var_3_0(arg_4_0)
		local var_4_0 = "windows/lvbu/world_campus/word_yellow" .. arg_4_0 .. ".png"

		return xyd.AssetLoader.get():loadSprite(var_4_0)
	end

	if arg_3_0.rankInfo.self_rank and arg_3_0.rankInfo.self_rank > 0 then
		local var_3_1 = display.newNode()
		local var_3_2 = arg_3_0.rankInfo.self_rank
		local var_3_3 = {}
		local var_3_4 = 1
		local var_3_5 = 0
		local var_3_6 = 0

		while var_3_2 ~= 0 do
			var_3_3[var_3_4] = var_3_2 % 10
			var_3_2 = math.floor(var_3_2 / 10)
			var_3_4 = var_3_4 + 1
		end

		for iter_3_0 = var_3_4 - 1, 1, -1 do
			local var_3_7 = var_3_0(var_3_3[iter_3_0])
			local var_3_8 = var_3_7:getWidth()

			var_3_6 = var_3_7:getHeight()

			var_3_7:addTo(var_3_1, 10)
			var_3_7:setPosition(var_3_5 + var_3_8 / 2, var_3_6 / 2)

			var_3_5 = var_3_5 + var_3_8
		end

		var_3_1:setContentSize(var_3_5, var_3_6)
		var_3_1:setAnchorPoint(0.5, 0.5)
		var_3_1:addTo(arg_3_0:nodeByName("rank_pos"))
	else
		arg_3_0:nodeByName("no_rank_tip"):setVisible(true)
		arg_3_0:nodeByName("no_rank_tip"):setString(var_0_1:translation("NO_RANK_TEXT"))
		arg_3_0:nodeByName("total_reward_txt"):setString(0)
	end

	arg_3_0.scroll = arg_3_0:nodeByName("scroll")

	local var_3_9 = arg_3_0.scroll:getContentSize()

	arg_3_0.scrollList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_9.width, var_3_9.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0.scroll):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.scrollList:setBounceable(true)
	arg_3_0.scrollList:setDelegate(handler(arg_3_0, arg_3_0.scrollListDelegate))
	arg_3_0.scrollList:setTouchType(false)
	arg_3_0.scrollList:reload()

	if arg_3_0.rankInfo.list == nil or #arg_3_0.rankInfo.list == 0 then
		arg_3_0:nodeByName("bg_hero"):setVisible(true)
	end
end

function var_0_0.scrollListDelegate(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	if cc.ui.UIListView.COUNT_TAG == arg_5_2 then
		return #(arg_5_0.rankInfo.list or {})
	elseif cc.ui.UIListView.CELL_TAG == arg_5_2 then
		local var_5_0
		local var_5_1 = arg_5_0.scrollList:dequeueItem()

		if not var_5_1 then
			var_5_1 = arg_5_0.scrollList:newItem()
		else
			var_5_1:removeAllChildren(true)
		end

		local var_5_2 = arg_5_0:createListContent(arg_5_3)
		local var_5_3 = var_5_2:getWidth()
		local var_5_4 = var_5_2:getHeight()

		var_5_1:setItemSize(var_5_3, var_5_4)
		var_5_1:addContent(var_5_2)

		return var_5_1
	end
end

function var_0_0.createListContent(arg_6_0, arg_6_1)
	local var_6_0 = arg_6_0.rankInfo.list[arg_6_1]
	local var_6_1 = display.newNode()
	local var_6_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/lvbu/world_campus/rank_item.csb")
	local var_6_3 = var_6_2:getChildByName("container")

	xyd.setPlayerAvatar(var_6_3:getChildByName("icon_container"), var_6_0)

	if var_6_0.conquer_lev and var_6_0.conquer_lev > 0 then
		var_6_3:getChildByName("lev_txt"):setString(var_6_0.conquer_lev)
		var_6_3:getChildByName("lv_bg"):setVisible(false)

		local var_6_4 = xyd.getLoopBy(var_6_0.conquer_lev, var_6_0.conquer_loop_id)

		if var_6_4 < 2 then
			var_6_4 = ""
		end

		var_6_3:getChildByName("conquer_lev_bg"):setTexture("images/conquer_lev" .. var_6_4 .. ".png")
	else
		var_6_3:getChildByName("lev_txt"):setString(var_6_0.lev)
		var_6_3:getChildByName("conquer_lev_bg"):setVisible(false)
	end

	var_6_3:getChildByName("region_txt"):setString("S" .. tostring(xyd.getPlayerRegion(var_6_0.player_id)))
	var_6_3:getChildByName("name_txt"):setString(var_6_0.player_name)
	var_6_3:getChildByName("total_reward_txt"):setString(var_6_0.score)
	var_6_3:getChildByName("total_reward_text"):setString(var_0_1:translation("LV_TOTAL_REWARD"))

	local var_6_5

	var_6_3:getChildByName("bg1"):setVisible(false)
	var_6_3:getChildByName("bg2"):setVisible(false)
	var_6_3:getChildByName("bg3"):setVisible(false)
	var_6_3:getChildByName("bg4"):setVisible(false)

	if arg_6_1 <= 3 then
		var_6_3:getChildByName("bg" .. arg_6_1):setVisible(true)

		var_6_5 = xyd.AssetLoader.get():loadSprite("windows/lvbu/world_campus/bg_rank" .. arg_6_1 .. ".png")
	else
		var_6_3:getChildByName("bg4"):setVisible(true)

		local var_6_6 = {
			size = 48,
			text = arg_6_1,
			color = cc.c3b(222, 243, 253)
		}

		var_6_5 = xyd.AssetLoader.get():loadLabel(var_6_6)

		var_6_5:setString(arg_6_1)
		var_6_5:enableOutline(cc.c4b(89, 138, 174, 255), 3)
	end

	var_6_5:setAnchorPoint(cc.p(0.5, 0.5))
	var_6_5:addTo(var_6_3:getChildByName("rank_pos"))
	var_6_2:addTo(var_6_1)
	var_6_2:setAnchorPoint(cc.p(0, 0))
	var_6_1:setContentSize(var_6_3:getContentSize())
	var_6_2:setName("source")

	return var_6_1
end

function var_0_0.scrollListener(arg_7_0, arg_7_1)
	if arg_7_1.name == "began" then
		arg_7_0.scrollViewMoved_ = false
		arg_7_0.prevY_ = arg_7_1.y
	elseif arg_7_1.name == "moved" and 5 <= math.abs(arg_7_1.y - arg_7_0.prevY_) then
		arg_7_0.scrollViewMoved_ = true
	end
end

return var_0_0
