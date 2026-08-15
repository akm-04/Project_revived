local var_0_0 = class("TutorInstructorWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = xyd.tables.activityTutorCampaign

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.tutor = xyd.ModelManager.get():loadModel(xyd.ModelType.TUTOR)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.data = table.keys(arg_1_0.tutor.campaignInfos)

	table.sort(arg_1_0.data, function(arg_2_0, arg_2_1)
		return tonumber(arg_2_0) < tonumber(arg_2_1)
	end)
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super.willOpen(arg_3_0, arg_3_1)
	arg_3_0:addThemeBG()
	arg_3_0:addTopSidebar()
	arg_3_0:layout()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("time_text"):setString(var_0_1:translation("REFRESH_TIME_TEXT"))
	arg_4_0:nodeByName("time_txt"):setString(var_0_1:translation("TUTOR_INSTRUCTOR_FRESH_TEXT"))
	arg_4_0:nodeByName("dialog_text"):setString(var_0_1:translation("TUTOR_INSTRUCTOR_DIALOG_TEXT"))

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

	arg_4_0.scrollList:setDelegate(handler(arg_4_0, arg_4_0.scrollListDelegate))
	arg_4_0.scrollList:reload()
	arg_4_0:nodeByName("book"):setTouchEnabled(true)
	arg_4_0:nodeByName("book"):setTouchSwallowEnabled(false)
	arg_4_0:nodeByName("book"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
		if arg_5_0.name == "began" then
			arg_4_0:nodeByName("book"):setScale(0.9)

			return true
		elseif arg_5_0.name == "moved" then
			return true
		elseif arg_5_0.name == "ended" then
			arg_4_0:nodeByName("book"):setScale(1)

			if arg_4_0.backpack:getItemNumByID(xyd.tables.misc:getValue("activity_tutor_senior_book_item")) > 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("TUTOR_SENIOR_BOOK_ITEM_TIP")
				})

				return
			end

			local var_5_0 = {
				chargeState = xyd.ChargeState.giftbag
			}

			xyd.WindowManager.get():openWindow("vip_recharge", var_5_0)
		end
	end)
	arg_4_0.tutor:updateIcon(arg_4_0:nodeByName("book"))
	arg_4_0:playActivityGuide()
end

function var_0_0.playActivityGuide(arg_6_0, ...)
	local var_6_0 = 1184001
	local var_6_1 = xyd.ServerTime.get():getServerTime()
	local var_6_2 = {
		playerID = arg_6_0.selfPlayer.playerID,
		name = "activity_guide" .. tostring(var_6_0),
		state = tostring(var_6_1)
	}

	if (tonumber(xyd.db.stateVariable:getState(var_6_2.playerID, var_6_2.name)) or 0) >= arg_6_0.activitiesModel:getActivityInfo(xyd.Activities.Tutor).start_time then
		return
	end

	xyd.db.stateVariable:setState(var_6_2)

	local var_6_3 = arg_6_0:nodeByName("book")

	xyd.WindowManager.get():openWindow("guide_activity")

	local var_6_4 = {
		400,
		520
	}
	local var_6_5 = true
	local var_6_6 = xyd.WindowManager.get():getWindow("guide_activity")

	var_6_6:addNode()

	local var_6_7 = xyd.tables.guideActivity:desc(1184001)
	local var_6_8 = cc.p(103, 585)

	var_6_6:setStencil(var_6_7, 100, 50, var_6_8.x, var_6_8.y, 1, {
		position = var_6_4,
		right = var_6_5
	})
end

function var_0_0.scrollListDelegate(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	if cc.ui.UIListView.COUNT_TAG == arg_7_2 then
		return #arg_7_0.data
	elseif cc.ui.UIListView.CELL_TAG == arg_7_2 then
		local var_7_0
		local var_7_1 = arg_7_0.scrollList:dequeueItem()

		if not var_7_1 then
			var_7_1 = arg_7_0.scrollList:newItem()
		else
			var_7_1:removeAllChildren(true)
		end

		local var_7_2 = arg_7_0:createListContent(arg_7_0.data[arg_7_3])
		local var_7_3 = var_7_2:getWidth()
		local var_7_4 = var_7_2:getHeight()

		var_7_1:setItemSize(var_7_3, var_7_4)
		var_7_1:addContent(var_7_2)

		return var_7_1
	end
end

function var_0_0.createListContent(arg_8_0, arg_8_1)
	local var_8_0 = arg_8_0.tutor.campaignInfos[arg_8_1]

	var_8_0.campaign_id = tonumber(arg_8_1)
	arg_8_1 = tonumber(arg_8_1)

	local var_8_1 = display.newNode()
	local var_8_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/tutor/instructor_item.csb")
	local var_8_3 = var_8_2:getChildByName("container")
	local var_8_4 = table.keys(var_8_0.rent_heroes)
	local var_8_5 = arg_8_0.tutor:getHeros(arg_8_1, arg_8_0.selfPlayer.lev)

	var_8_3:getChildByName("name_txt"):setString(var_0_3:campaignName(var_8_0.campaign_id))

	local var_8_6 = var_0_3:campaignText(var_8_0.campaign_id)
	local var_8_7 = xyd.createMultiColorTxt(var_8_6, cc.c4b(91, 102, 111, 255), 22, false)

	var_8_7:setAnchorPoint(cc.p(1, 0.5))
	var_8_7:addTo(var_8_3:getChildByName("desc_pos"))
	var_8_7:setPositionY(-5)

	local var_8_8 = 90
	local var_8_9 = 20

	line_num = 7

	for iter_8_0 = 1, #var_8_5 do
		local var_8_10 = display.newNode()

		var_8_10:setContentSize(var_8_8, var_8_8)

		local var_8_11 = var_8_5[iter_8_0]

		xyd.setAvatarBorderNewUI(var_8_11, var_8_10)

		if var_8_0.star < 3 then
			xyd.GrayNode(var_8_10)
		end

		var_8_10:setAnchorPoint(cc.p(0, 1))
		var_8_10:addTo(var_8_3:getChildByName("hero_pos"))

		local var_8_12 = math.ceil(iter_8_0 / 7)
		local var_8_13 = iter_8_0 - (var_8_12 - 1) * 7

		var_8_10:setPosition(cc.p((var_8_13 - 1) * (var_8_8 + var_8_9), -(var_8_12 - 1) * (var_8_8 + 10)))
		var_8_10:setTouchEnabled(true)
		var_8_10:setTouchSwallowEnabled(false)
		var_8_10:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
			if arg_9_0.name == "began" then
				return true
			elseif arg_9_0.name == "moved" then
				return true
			elseif arg_9_0.name == "ended" and not arg_8_0.scrollViewMoved_ then
				local var_9_0 = {
					heros = {
						var_8_11
					}
				}

				var_9_0.current = 1
				var_9_0.showType = 2

				xyd.WindowManager.get():openWindow("tujian_herodetail", var_9_0)
			end
		end)
	end

	var_8_2:addTo(var_8_1)
	var_8_2:setAnchorPoint(cc.p(0, 0))
	var_8_1:setContentSize(var_8_3:getContentSize())
	var_8_2:setName("source")

	return var_8_1
end

function var_0_0.scrollListener(arg_10_0, arg_10_1)
	if arg_10_1.name == "began" then
		arg_10_0.scrollViewMoved_ = false
		arg_10_0.prevY_ = arg_10_1.y
		arg_10_0.prevX_ = arg_10_1.x
	elseif arg_10_1.name == "moved" then
		local var_10_0 = 5

		if var_10_0 <= math.abs(arg_10_1.y - arg_10_0.prevY_) or var_10_0 < math.abs(arg_10_1.x - arg_10_0.prevX_) then
			arg_10_0.scrollViewMoved_ = true
		end
	end
end

function var_0_0.scrollListener2(arg_11_0, arg_11_1)
	if arg_11_1.name == "began" then
		arg_11_0.scrollViewMoved2_ = false
		arg_11_0.prevX2_ = arg_11_1.x
	elseif arg_11_1.name == "moved" and 5 < math.abs(arg_11_1.x - arg_11_0.prevX2_) then
		arg_11_0.scrollViewMoved2_ = true
	end
end

return var_0_0
