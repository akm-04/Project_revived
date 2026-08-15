local var_0_0 = class("CourseRecommendWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.objectBook

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.course = xyd.ModelManager.get():loadModel(xyd.ModelType.COURSE)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.hero = arg_1_2.hero
	arg_1_0.data = arg_1_2.data
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
	arg_2_0.blockLayer_:setPosition(cc.p(-640, -360))
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("txt_title"):setString(var_0_1:translation("COURSE_TEXT_17"))

	arg_3_0.scroll = arg_3_0:nodeByName("scroll")

	local var_3_0 = arg_3_0.scroll:getContentSize()

	arg_3_0.scrollList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_0.width, var_3_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0.scroll):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.scrollList:setDelegate(handler(arg_3_0, arg_3_0.scrollListDelegate))
	arg_3_0.scrollList:reload()
end

function var_0_0.scrollListDelegate(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	if cc.ui.UIListView.COUNT_TAG == arg_4_2 then
		return #arg_4_0.data
	elseif cc.ui.UIListView.CELL_TAG == arg_4_2 then
		local var_4_0
		local var_4_1 = arg_4_0.scrollList:dequeueItem()

		if not var_4_1 then
			var_4_1 = arg_4_0.scrollList:newItem()
		else
			var_4_1:removeAllChildren(true)
		end

		local var_4_2 = arg_4_0:createListContent(arg_4_3)
		local var_4_3 = var_4_2:getWidth()
		local var_4_4 = var_4_2:getHeight()

		var_4_1:setItemSize(var_4_3, var_4_4 + 5)
		var_4_1:addContent(var_4_2)

		return var_4_1
	end
end

function var_0_0.createListContent(arg_5_0, arg_5_1)
	local var_5_0 = arg_5_0.data[arg_5_1]
	local var_5_1 = display.newNode()
	local var_5_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/course/recommend/recommend_item.csb")
	local var_5_3 = var_5_2:getChildByName("container")
	local var_5_4 = var_5_0.player_info
	local var_5_5 = {
		avatar_id = var_5_4.avatar_id,
		avatar_frame_id = var_5_4.avatar_frame_id,
		playerInfo = var_5_4
	}

	xyd.setPlayerAvatar(var_5_3:getChildByName("avtar_container"), var_5_5)

	local var_5_6 = {
		lev = var_5_4.lev,
		conquerLev = var_5_4.conquer_lev,
		loopID = var_5_4.conquer_loop_id,
		fontColor = cc.c3b(80, 12, 26)
	}

	xyd.setLev(var_5_3:getChildByName("lv"), var_5_6)
	var_5_3:getChildByName("name_txt"):setString(var_5_4.player_name)
	var_5_3:getChildByName("region_txt"):setString("S" .. tostring(var_5_4.region))
	var_5_3:getChildByName("zhandouli_txt"):setString(math.ceil(var_5_0.force))
	var_5_3:getChildByName("zhandouli_text"):setString(var_0_1:translation("HERO_INFO_ZHANDOULI"))

	local var_5_7 = var_5_3:getChildByName("scroll")
	local var_5_8 = var_5_0.partner_courses
	local var_5_9 = 0

	for iter_5_0, iter_5_1 in pairs(var_5_8) do
		var_5_9 = var_5_9 + 1

		local var_5_10 = arg_5_0:createBookItem(tonumber(iter_5_0), iter_5_1)
		local var_5_11 = var_5_10:getWidth()
		local var_5_12 = var_5_10:getHeight()

		var_5_10:addTo(var_5_7)
		var_5_10:setPositionX((var_5_9 - 1) * (var_5_11 + 10))
	end

	var_5_0.rank = arg_5_1

	if arg_5_1 <= 3 then
		local var_5_13 = xyd.AssetLoader.get():loadSprite("windows/course/recommend/rank_" .. arg_5_1 .. ".png")

		var_5_13:setAnchorPoint(cc.p(0.5, 0.5))
		var_5_3:getChildByName("rank_pos"):addChild(var_5_13)
	else
		var_5_3:getChildByName("txt_rank"):setString(arg_5_1)
	end

	var_5_2:addTo(var_5_1)
	var_5_2:setAnchorPoint(cc.p(0, 0))
	var_5_1:setContentSize(var_5_3:getContentSize())
	var_5_2:setName("source")

	return var_5_1
end

function var_0_0.createBookItem(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = 98
	local var_6_1 = display.newNode()

	var_6_1:setContentSize(var_6_0, var_6_0)

	local var_6_2 = var_0_2:icon(arg_6_1)

	var_6_1:setTouchEnabled(true)
	var_6_1:setTouchSwallowEnabled(false)
	xyd.setSpriteBorder(var_6_1, var_6_2, arg_6_2.quality, false)
	var_6_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
		if arg_7_0.name == "began" then
			if arg_6_0.scrollViewMoved_ then
				return false
			end

			var_6_1:setScale(0.9)

			return true
		elseif arg_7_0.name == "ended" then
			xyd.playButtonSound()
			var_6_1:setScale(1)

			if arg_6_0.scrollViewMoved_ then
				return
			end

			local var_7_0 = {
				hero = arg_6_0.hero,
				book_id = arg_6_1,
				info = arg_6_2
			}

			xyd.WindowManager.get():openWindow("course_recommend_apply", var_7_0)
		end
	end)

	return var_6_1
end

function var_0_0.scrollListener(arg_8_0, arg_8_1)
	if arg_8_1.name == "began" then
		arg_8_0.scrollViewMoved_ = false
		arg_8_0.prevY_ = arg_8_1.y
	elseif arg_8_1.name == "moved" and 5 <= math.abs(arg_8_1.y - arg_8_0.prevY_) then
		arg_8_0.scrollViewMoved_ = true
	end
end

function var_0_0.scrollListener2(arg_9_0, arg_9_1)
	if arg_9_1.name == "began" then
		arg_9_0.scrollViewMoved1_ = false
		arg_9_0.prevX_ = arg_9_1.x
	elseif arg_9_1.name == "moved" and 5 <= math.abs(arg_9_1.x - arg_9_0.prevX_) then
		arg_9_0.scrollViewMoved1_ = true
	end
end

return var_0_0
