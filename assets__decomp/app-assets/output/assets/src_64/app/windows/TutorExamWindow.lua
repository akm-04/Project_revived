local var_0_0 = class("TutorExamWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityTutorCampaign
local var_0_3 = import("app.model.Hero")
local var_0_4 = ngx.ctx.battle.getRequire("FighterModel")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.tutor = xyd.ModelManager.get():loadModel(xyd.ModelType.TUTOR)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.data = table.keys(arg_1_0.tutor.campaignInfos)

	if arg_1_0.tutor:getMode() == 0 then
		arg_1_0.mode_ = xyd.TutorMode.NORMAL
	else
		arg_1_0.mode_ = arg_1_0.tutor:getMode()
	end

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
	arg_4_0.scroll = arg_4_0:nodeByName("scroll")
	arg_4_0.btnHard = arg_4_0:nodeByName("btn_hard")
	arg_4_0.btnNormal = arg_4_0:nodeByName("btn_normal")

	local var_4_0 = arg_4_0.scroll:getContentSize()

	arg_4_0.scrollList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_0.width - 88, var_4_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(arg_4_0.scroll):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.scrollList:setPosition(55, 0)
	arg_4_0.scrollList:setDelegate(handler(arg_4_0, arg_4_0.scrollListDelegate))
	arg_4_0.scrollList:reload()
	arg_4_0:setMode(arg_4_0.mode_)
	xyd.nodeEventSample(arg_4_0.btnHard, nil, function(arg_5_0)
		arg_4_0.mode_ = xyd.TutorMode.NORMAL

		arg_4_0:setMode(arg_4_0.mode_)
	end)
	xyd.nodeEventSample(arg_4_0.btnNormal, nil, function(arg_6_0)
		arg_4_0.mode_ = xyd.TutorMode.HARD

		arg_4_0:setMode(arg_4_0.mode_)
	end)
	xyd.nodeEventSample(arg_4_0:nodeByName("btn_rank"), nil, function(arg_7_0)
		xyd.Backend.get():request(xyd.mid.LOAD_TUTOR_RANK, nil, function(arg_8_0, arg_8_1)
			if arg_8_0 == xyd.error.OK then
				local var_8_0 = {
					myRank = arg_8_1.my_rank,
					rankList = arg_8_1.rank_list
				}

				xyd.WindowManager.get():openWindow("tutor_rank_window", var_8_0)
			end
		end)
	end)
end

function var_0_0.scrollListDelegate(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	if cc.ui.UIListView.COUNT_TAG == arg_9_2 then
		return #arg_9_0.data
	elseif cc.ui.UIListView.CELL_TAG == arg_9_2 then
		local var_9_0
		local var_9_1 = arg_9_0.scrollList:dequeueItem()

		if not var_9_1 then
			var_9_1 = arg_9_0.scrollList:newItem()
		else
			var_9_1:removeAllChildren(true)
		end

		local var_9_2 = arg_9_0:createListContent(arg_9_0.data[arg_9_3])
		local var_9_3 = var_9_2:getWidth()
		local var_9_4 = var_9_2:getHeight()

		var_9_1:setItemSize(var_9_3, var_9_4)
		var_9_1:addContent(var_9_2)

		return var_9_1
	end
end

function var_0_0.createListContent(arg_10_0, arg_10_1)
	local var_10_0 = arg_10_0.tutor.campaignInfos[arg_10_1]

	var_10_0.campaign_id = tonumber(arg_10_1)
	arg_10_1 = tonumber(arg_10_1)

	local var_10_1 = display.newNode()
	local var_10_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/tutor/exam_item.csb")
	local var_10_3 = var_10_2:getChildByName("container")
	local var_10_4 = var_0_2:challengeTimes(arg_10_1)
	local var_10_5 = var_0_2:campaignDisplay(arg_10_1)
	local var_10_6 = var_0_2:campaignBackground(arg_10_1)

	background = xyd.AssetLoader.get():loadSprite(var_10_6)

	background:addTo(var_10_3:getChildByName("card_pos"))

	local var_10_7 = var_10_4 - var_10_0.challenge_times

	var_10_3:getChildByName("name_txt"):setString(var_0_2:campaignName(arg_10_1))
	var_10_3:getChildByName("time_txt"):setString(var_10_7)
	var_10_3:getChildByName("time_text"):setString(var_0_1:translation("LEFT_TIMES"))

	for iter_10_0 = 1, 3 do
		if iter_10_0 <= var_10_0.star then
			var_10_3:getChildByName("star" .. iter_10_0):setVisible(true)
			var_10_3:getChildByName("star_gray" .. iter_10_0):setVisible(false)
		else
			var_10_3:getChildByName("star" .. iter_10_0):setVisible(false)
			var_10_3:getChildByName("star_gray" .. iter_10_0):setVisible(true)
		end
	end

	local var_10_8 = var_0_3.new()

	var_10_8:populateWithTableID(var_10_5)

	local var_10_9 = xyd.tables.hero:modelID(var_10_5)
	local var_10_10 = xyd.tables.model:creatsUiScale(var_10_9) * 1.5
	local var_10_11 = var_0_4.new(var_10_8, var_10_10)

	var_10_11:addTo(var_10_3:getChildByName("model_pos"))
	var_10_11:getHeroAnimation():idle(true)
	var_10_2:setTouchEnabled(true)
	var_10_2:setTouchSwallowEnabled(false)
	var_10_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_11_0)
		if arg_11_0.name == "began" then
			return true
		elseif arg_11_0.name == "moved" then
			return true
		elseif arg_11_0.name == "ended" and not arg_10_0.scrollViewMoved_ then
			if var_10_7 <= 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("TUTOR_EXAM_TIME_LIMIT_TEXT")
				})

				return
			end

			params = {
				data = arg_10_0.tutor.campaignInfos[tostring(arg_10_1)],
				mode = arg_10_0.mode_
			}

			xyd.WindowManager.get():openWindow("tutor_exam_detail", params)
		end
	end)
	var_10_2:addTo(var_10_1)
	var_10_2:setAnchorPoint(cc.p(0, 0))
	var_10_1:setContentSize(var_10_3:getContentSize())
	var_10_2:setName("source")

	return var_10_1
end

function var_0_0.setMode(arg_12_0, arg_12_1)
	arg_12_0.tutor:setMode(arg_12_1)

	if xyd.TutorMode.HARD == arg_12_1 then
		arg_12_0.btnNormal:setVisible(false)
		arg_12_0.btnHard:setVisible(true)

		local var_12_0 = display.newColorLayer(cc.c4b(255, 0, 0, 120))

		var_12_0:addTo(arg_12_0:background(), arg_12_0.BG_ZORDER + 10)
		var_12_0:setName("red_layer")
	elseif xyd.TutorMode.NORMAL == arg_12_1 then
		arg_12_0.btnNormal:setVisible(true)
		arg_12_0.btnHard:setVisible(false)

		local var_12_1 = arg_12_0:background():getChildByName("red_layer")

		if var_12_1 then
			arg_12_0:background():removeChild(var_12_1)
		end
	end
end

function var_0_0.scrollListener(arg_13_0, arg_13_1)
	if arg_13_1.name == "began" then
		arg_13_0.scrollViewMoved_ = false
		arg_13_0.prevX_ = arg_13_1.x
	elseif arg_13_1.name == "moved" and 5 <= math.abs(arg_13_1.x - arg_13_0.prevX_) then
		arg_13_0.scrollViewMoved_ = true
	end
end

return var_0_0
