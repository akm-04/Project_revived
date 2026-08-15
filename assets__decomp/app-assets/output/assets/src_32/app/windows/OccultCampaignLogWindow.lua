local var_0_0 = class("OccultCampaignLogWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.creatsDiary
local var_0_3 = xyd.tables.creatsCampaign

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.occult = xyd.ModelManager.get():loadModel(xyd.ModelType.OCCULT)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.logList = arg_1_2.log_list or {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
	arg_2_0.blockLayer_:setPosition(cc.p(-640, -360))
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("title_txt"):setString(var_0_1:translation("OCCULT_DIALOG_TEXT"))

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
		return #arg_4_0.logList
	elseif cc.ui.UIListView.CELL_TAG == arg_4_2 then
		local var_4_0
		local var_4_1 = arg_4_0.scrollList:dequeueItem()

		if not var_4_1 then
			var_4_1 = arg_4_0.scrollList:newItem()
		else
			var_4_1:removeAllChildren(true)
		end

		local var_4_2 = arg_4_0:createListContent(arg_4_0.logList[arg_4_3])
		local var_4_3 = var_4_2:getWidth()
		local var_4_4 = var_4_2:getHeight()

		var_4_1:setItemSize(var_4_3, var_4_4)
		var_4_1:addContent(var_4_2)

		return var_4_1
	end
end

function var_0_0.createListContent(arg_5_0, arg_5_1)
	local var_5_0 = display.newNode()
	local var_5_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/occult/sub_map/log_item.csb")
	local var_5_2 = var_5_1:getChildByName("container")
	local var_5_3 = import("app.common.ui.SplitLine")
	local var_5_4 = var_5_2:getChildByName("line")

	var_5_3.new({
		size = var_5_4:getWidth()
	}):addTo(var_5_4)

	local var_5_5 = os.date(" %H:%M", arg_5_1.time)

	if arg_5_0:isToday(arg_5_1) then
		var_5_2:getChildByName("time_txt"):setString(var_0_1:translation("TODAY") .. var_5_5)
	else
		var_5_2:getChildByName("time_txt"):setString(var_0_1:translation("YESTERDAY") .. var_5_5)
	end

	var_5_2:getChildByName("event_text"):setVisible(false)
	var_5_2:getChildByName("battle_img"):setVisible(false)

	if var_0_2:logType(arg_5_1.log_id) == 1 then
		var_5_2:getChildByName("battle_img"):setVisible(true)
		var_5_2:getChildByName("text_tag"):setString(var_0_1:translation("OCCLUT_TEXT_7"))
	elseif var_0_2:logType(arg_5_1.log_id) == 2 then
		var_5_2:getChildByName("event_text"):setVisible(true)
		var_5_2:getChildByName("text_tag"):setString(var_0_1:translation("OCCLUT_TEXT_8"))
	end

	local var_5_6 = {}

	if arg_5_1.log_id == 1 or arg_5_1.log_id == 3 then
		local var_5_7 = arg_5_0:getNamesString(arg_5_1)

		table.insert(var_5_6, var_5_7)

		local var_5_8 = var_0_3:campaignName(arg_5_1.campaign_id)

		table.insert(var_5_6, var_5_8)
	elseif arg_5_1.log_id == 2 then
		local var_5_9 = arg_5_0:getNamesString(arg_5_1)

		table.insert(var_5_6, var_5_9)

		local var_5_10 = var_0_3:campaignName(arg_5_1.campaign_id)

		table.insert(var_5_6, var_5_10)

		local var_5_11 = var_0_3:logDes(arg_5_1.campaign_id)

		table.insert(var_5_6, var_5_11)
	end

	local var_5_12 = var_5_2:getChildByName("details")

	arg_5_0:colorWords(var_5_12, arg_5_1, var_5_6)
	var_5_1:addTo(var_5_0)
	var_5_1:setAnchorPoint(cc.p(0, 0))

	local var_5_13 = var_5_2:getContentSize()

	var_5_0:setContentSize(var_5_13.width, var_5_13.height)
	var_5_1:setName("source")

	return var_5_0
end

function var_0_0.getNamesString(arg_6_0, arg_6_1)
	local var_6_0 = ""

	for iter_6_0 = 1, #arg_6_1.player_ids do
		var_6_0 = var_6_0 .. arg_6_1.player_ids[iter_6_0]

		if iter_6_0 ~= #arg_6_1.player_ids then
			var_6_0 = var_6_0 .. ","
		end
	end

	return var_6_0
end

function var_0_0.colorWords(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	local var_7_0 = display.newNode()
	local var_7_1 = var_0_2:content(arg_7_2.log_id)
	local var_7_2 = 0
	local var_7_3 = 1
	local var_7_4 = 1
	local var_7_5 = {}
	local var_7_6 = 0
	local var_7_7 = false

	while true do
		local function var_7_8(arg_8_0, arg_8_1)
			local var_8_0 = xyd.getTextLen(arg_8_0)
			local var_8_1 = var_7_6

			var_7_6 = var_7_6 + var_8_0

			while var_7_6 > 25 do
				var_7_4 = var_7_4 + 1

				local var_8_2

				if var_8_1 > 24 then
					var_8_1 = 23
				end

				local var_8_3

				var_8_3, arg_8_0 = xyd.getSplitByTextLen(arg_8_0, 24 - var_8_1)

				if arg_8_0 then
					var_7_6 = xyd.getTextLen(arg_8_0)
				else
					var_7_6 = 0
				end

				var_8_1 = 0

				local var_8_4 = display.newTTFLabel({
					font = "fonts/main_font.ttf",
					size = 22,
					text = var_8_3,
					color = arg_8_1,
					align = cc.TEXT_ALIGNMENT_LEFT
				})

				var_7_0:addChild(var_8_4)
				var_8_4:setPosition(var_7_2, 3)
				var_8_4:setAnchorPoint(cc.p(0, 0))

				var_7_2 = 0

				table.insert(var_7_5, var_8_4)

				for iter_8_0 = 1, #var_7_5 do
					var_7_5[iter_8_0]:setPositionY(var_7_5[iter_8_0]:getPositionY() + 36)
				end
			end

			if not arg_8_0 then
				return
			end

			local var_8_5 = display.newTTFLabel({
				font = "fonts/main_font.ttf",
				size = 22,
				text = arg_8_0,
				color = arg_8_1,
				align = cc.TEXT_ALIGNMENT_LEFT
			})

			var_7_0:addChild(var_8_5)
			var_8_5:setPosition(var_7_2, 3)
			var_8_5:setAnchorPoint(cc.p(0, 0))

			var_7_2 = var_7_2 + var_8_5:getContentSize().width

			table.insert(var_7_5, var_8_5)
		end

		var_7_1 = var_7_1 or ""

		local var_7_9 = string.find(var_7_1, "{")
		local var_7_10 = string.find(var_7_1, "}")

		if var_7_9 and var_7_10 then
			local var_7_11 = string.sub(var_7_1, 1, var_7_9 - 1)
			local var_7_12 = arg_7_3[var_7_3]

			var_7_3 = var_7_3 + 1
			var_7_1 = string.sub(var_7_1, var_7_10 + 1, #var_7_1)

			if var_7_9 < var_7_10 then
				if var_7_12 == nil then
					arg_7_0.is_wrong_item = true

					break
				else
					arg_7_0.is_wrong_item = false
				end

				var_7_8(var_7_11, cc.c3b(52, 54, 55))
				var_7_8("" .. var_7_12, cc.c3b(255, 120, 0))
			else
				print("wrong data.")

				break
			end
		elseif var_7_9 or var_7_10 then
			print("Wrong data.")

			break
		else
			var_7_8(var_7_1, cc.c3b(52, 54, 55))

			break
		end
	end

	arg_7_1:addChild(var_7_0)
	arg_7_1:setContentSize(arg_7_1:getContentSize().width, arg_7_1:getContentSize().height + 30 * (var_7_4 - 1))
end

function var_0_0.isToday(arg_9_0, arg_9_1)
	if os.date("%d", arg_9_1.time) == os.date("%d", xyd.ServerTime.get():getServerTime()) then
		return true
	else
		return false
	end
end

function var_0_0.scrollListener(arg_10_0, arg_10_1)
	if arg_10_1.name == "began" then
		arg_10_0.scrollViewMoved_ = false
		arg_10_0.prevY_ = arg_10_1.y
	elseif arg_10_1.name == "moved" and 5 <= math.abs(arg_10_1.y - arg_10_0.prevY_) then
		arg_10_0.scrollViewMoved_ = true
	end
end

return var_0_0
