local var_0_0 = class("LotteryNumberConsumeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.activityLotteryConsume
local var_0_4 = 10
local var_0_5 = 100
local var_0_6 = var_0_3:getDays()

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.activityModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.details = arg_1_2
	arg_1_0.pageNum_ = 1
	arg_1_0.stageCount = arg_1_0.details.base_info.day_count % var_0_6

	if arg_1_0.stageCount == 0 then
		arg_1_0.stageCount = var_0_6
	end

	arg_1_0.maxPageNum = math.ceil(var_0_3:ticketNum(arg_1_0.stageCount) / var_0_5)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	if arg_2_0.details.base_info.can_select_times - #arg_2_0.details.base_info.selected_nums > 0 and #arg_2_0.details.total_info.total_selected_nums < var_0_3:ticketNum(arg_2_0.stageCount) then
		arg_2_0.canChoose = true
	else
		arg_2_0.canChoose = false
	end

	arg_2_0:initTable()
	arg_2_0:layout()
end

function var_0_0.initTable(arg_3_0)
	arg_3_0.numberTable = {}

	for iter_3_0, iter_3_1 in pairs(arg_3_0.details.total_info.total_selected_nums) do
		arg_3_0.numberTable[iter_3_1] = 2
	end

	for iter_3_2, iter_3_3 in pairs(arg_3_0.details.base_info.selected_nums) do
		arg_3_0.numberTable[iter_3_3] = 1
	end
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("text1"):setString(var_0_2:translation("ACTIVITY_LOTTERY_TIP6"))
	arg_4_0:nodeByName("text2"):setString(var_0_2:translation("ACTIVITY_LOTTERY_TIP7"))

	local var_4_0 = arg_4_0:nodeByName("number_list")
	local var_4_1 = var_4_0:getContentSize()

	arg_4_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_1.width, var_4_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_4_0):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.list:setDelegate(handler(arg_4_0, arg_4_0.delegate))
	arg_4_0.list:reload()
	arg_4_0:updateList()
	arg_4_0:nodeByName("text_last"):setString(var_0_3:ticketNum(arg_4_0.stageCount) - #arg_4_0.details.total_info.total_selected_nums .. "/" .. var_0_3:ticketNum(arg_4_0.stageCount))
	arg_4_0:nodeByName("text_chose"):setString(#arg_4_0.details.base_info.selected_nums .. "/" .. arg_4_0.details.base_info.can_select_times)
	arg_4_0:initEditBox()
	arg_4_0:listChange()
end

function var_0_0.delegate(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	if cc.ui.UIListView.COUNT_TAG == arg_5_2 then
		return (math.ceil(var_0_5 / var_0_4))
	elseif cc.ui.UIListView.CELL_TAG == arg_5_2 then
		local var_5_0 = arg_5_0.list:dequeueItem()

		if not var_5_0 then
			var_5_0 = arg_5_0.list:newItem()
		else
			var_5_0:removeAllChildren(true)
		end

		local var_5_1 = 970
		local var_5_2 = 80

		var_5_0:setItemSize(var_5_1, 80)

		local var_5_3 = display.newNode()

		var_5_3:setContentSize(var_5_1, 80)
		arg_5_0:initNumberCell(var_5_3, arg_5_3)
		var_5_0:addContent(var_5_3)

		return var_5_0
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_5_2 then
		-- block empty
	end
end

function var_0_0.scrollListener(arg_6_0, arg_6_1)
	if arg_6_1.name == "began" then
		arg_6_0.scrollViewMoved_ = false
		arg_6_0.prevX_ = arg_6_1.x
		arg_6_0.prevY_ = arg_6_1.y
	elseif arg_6_1.name == "moved" then
		local var_6_0 = 3

		if var_6_0 <= math.abs(arg_6_1.y - arg_6_0.prevY_) or var_6_0 <= math.abs(arg_6_1.x - arg_6_0.prevX_) then
			arg_6_0.scrollViewMoved_ = true
		end
	end
end

function var_0_0.makeString(arg_7_0, arg_7_1)
	local var_7_0 = tostring(arg_7_1)

	if math.floor(arg_7_1 / 10) == 0 then
		var_7_0 = "00" .. var_7_0
	elseif math.floor(arg_7_1 / 100) == 0 then
		var_7_0 = "0" .. var_7_0
	end

	return var_7_0
end

function var_0_0.initNumberCell(arg_8_0, arg_8_1, arg_8_2)
	for iter_8_0 = 1, var_0_4 do
		local var_8_0 = (arg_8_2 - 1) * var_0_4 + iter_8_0 + (arg_8_0.pageNum_ - 1) * var_0_5

		if var_8_0 > var_0_3:ticketNum(arg_8_0.stageCount) then
			break
		end

		local var_8_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1148/lottery_number_item.csb")

		var_8_1:setPosition(97 * iter_8_0 - 97, 0)
		arg_8_1:addChild(var_8_1)
		var_8_1:setTouchEnabled(true)
		var_8_1:setTouchSwallowEnabled(false)

		local var_8_2 = var_8_1:getChildByName("container")

		var_8_2:getChildByName("item_bg1"):setVisible(false)
		var_8_2:getChildByName("item_bg2"):setVisible(false)
		var_8_2:getChildByName("item_bg_grey"):setVisible(false)
		var_8_2:getChildByName("item_chose"):setVisible(false)

		if arg_8_0.numberTable[var_8_0] == 1 then
			var_8_2:getChildByName("item_chose"):setVisible(true)
		elseif arg_8_0.numberTable[var_8_0] == 2 then
			var_8_2:getChildByName("item_bg_grey"):setVisible(true)
			var_8_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
				if arg_9_0.name == "began" then
					var_8_2:setScale(0.9)

					return true
				elseif arg_9_0.name == "moved" then
					var_8_2:setScale(1)

					return true
				elseif arg_9_0.name == "ended" and not arg_8_0.scrollViewMoved_ then
					var_8_2:setScale(1)

					local var_9_0 = {
						num = var_8_0
					}

					xyd.Backend.get():request(xyd.mid.LOTTERY_CONSUME_GET_PLAYER_INFO_BY_NUM, var_9_0, function(arg_10_0, arg_10_1)
						if arg_10_0 == xyd.error.OK then
							xyd.WindowManager.get():openWindow("lottery_tips_consume", arg_10_1)
						end
					end, nil, nil, false)
				end
			end)
		elseif arg_8_0.numberTable[var_8_0] == nil and arg_8_0.canChoose then
			var_8_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_11_0)
				if arg_11_0.name == "began" then
					var_8_2:setScale(0.9)

					return true
				elseif arg_11_0.name == "moved" then
					var_8_2:setScale(1)

					return true
				elseif arg_11_0.name == "ended" and arg_8_0.scrollViewMoved_ == false then
					var_8_2:setScale(1)

					local var_11_0 = {
						num = var_8_0
					}

					xyd.Backend.get():request(xyd.mid.LOTTERY_CONSUME_SELECT_NUM, var_11_0, function(arg_12_0, arg_12_1)
						if arg_12_0 == xyd.error.OK then
							arg_8_0.numberTable[var_8_0] = 1

							var_8_2:getChildByName("item_chose"):setVisible(true)
							var_8_1:setTouchEnabled(false)
							table.insert(arg_8_0.details.base_info.selected_nums, var_8_0)
							table.insert(arg_8_0.details.total_info.total_selected_nums, var_8_0)
							arg_8_0:nodeByName("text_last"):setString(var_0_3:ticketNum(arg_8_0.stageCount) - #arg_8_0.details.total_info.total_selected_nums .. "/" .. var_0_3:ticketNum(arg_8_0.stageCount))
							arg_8_0:nodeByName("text_chose"):setString(#arg_8_0.details.base_info.selected_nums .. "/" .. arg_8_0.details.base_info.can_select_times)

							if var_0_3:ticketNum(arg_8_0.stageCount) <= #arg_8_0.details.total_info.total_selected_nums then
								local var_12_0 = {
									activity_id = xyd.Activities.LotteryConsume
								}

								arg_8_0.activityModel:loadSingleActivity(var_12_0, function(arg_13_0, arg_13_1)
									if arg_13_0 == xyd.error.OK then
										arg_8_0.details = arg_13_1.details

										arg_8_0:nodeByName("text_last"):setString(var_0_3:ticketNum(arg_8_0.stageCount) - #arg_8_0.details.total_info.total_selected_nums .. "/" .. var_0_3:ticketNum(arg_8_0.stageCount))
										arg_8_0:nodeByName("text_chose"):setString(#arg_8_0.details.base_info.selected_nums .. "/" .. arg_8_0.details.base_info.can_select_times)

										local var_13_0 = xyd.WindowManager.get():getWindow("activities")

										if var_13_0 and var_13_0.openedActivities[xyd.Activities.LotteryConsume] then
											var_13_0.openedActivities[xyd.Activities.LotteryConsume].details = arg_13_1.details

											var_13_0.openedActivities[xyd.Activities.LotteryConsume]:updateWnd()
										end

										arg_8_0:initTable()
										arg_8_0.list:refreshList()
									end
								end)
							else
								local var_12_1 = xyd.WindowManager.get():getWindow("activities")

								if var_12_1 and var_12_1.openedActivities[xyd.Activities.LotteryConsume] then
									var_12_1.openedActivities[xyd.Activities.LotteryConsume].details.base_info.selected_nums = arg_8_0.details.base_info.selected_nums
									var_12_1.openedActivities[xyd.Activities.LotteryConsume].details.total_info.total_selected_nums = arg_8_0.details.total_info.total_selected_nums

									var_12_1.openedActivities[xyd.Activities.LotteryConsume]:updateWnd()
								end
							end
						elseif #arg_8_0.details.base_info.selected_nums == arg_8_0.details.base_info.can_select_times then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_2:translation("LOTTERY_NUMBER_NONE")
							})
						else
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_2:translation("LOTTERY_NUMBER_CONFLICT")
							})

							local var_12_2 = {
								activity_id = xyd.Activities.LotteryConsume
							}

							arg_8_0.activityModel:loadSingleActivity(var_12_2, function(arg_14_0, arg_14_1)
								if arg_14_0 == xyd.error.OK then
									arg_8_0.details = arg_14_1.details

									arg_8_0:nodeByName("text_last"):setString(var_0_3:ticketNum(arg_8_0.stageCount) - #arg_8_0.details.total_info.total_selected_nums .. "/" .. var_0_3:ticketNum(arg_8_0.stageCount))
									arg_8_0:nodeByName("text_chose"):setString(#arg_8_0.details.base_info.selected_nums .. "/" .. arg_8_0.details.base_info.can_select_times)

									local var_14_0 = xyd.WindowManager.get():getWindow("activities")

									if var_14_0 and var_14_0.openedActivities[xyd.Activities.LotteryConsume] then
										var_14_0.openedActivities[xyd.Activities.LotteryConsume].details = arg_14_1.details

										var_14_0.openedActivities[xyd.Activities.LotteryConsume]:updateWnd()
									end

									arg_8_0:initTable()
									arg_8_0.list:refreshList()
								end
							end)
						end
					end)
				end
			end)
		end

		if (arg_8_2 + iter_8_0) % 2 == 1 then
			var_8_2:getChildByName("item_bg1"):setVisible(true)
		else
			var_8_2:getChildByName("item_bg2"):setVisible(true)
		end

		var_8_2:getChildByName("text_num"):setString(arg_8_0:makeString(var_8_0))
	end
end

function var_0_0.listChange(arg_15_0)
	arg_15_0:nodeByName("text_input_max"):setString("/" .. arg_15_0.maxPageNum)
	arg_15_0:nodeByName("left"):setTouchEnabled(true)
	arg_15_0:nodeByName("left"):addTouchEventListener(function(arg_16_0, arg_16_1)
		if arg_16_1 == ccui.TouchEventType.began then
			arg_15_0:nodeByName("left"):setScale(0.9, 0.9)
		end

		if arg_16_1 == ccui.TouchEventType.moved then
			arg_15_0:nodeByName("left"):setScale(1, 1)
		end

		if arg_16_1 == ccui.TouchEventType.ended then
			arg_15_0:nodeByName("left"):setScale(1, 1)

			if arg_15_0.pageNum_ > 1 then
				arg_15_0.pageNum_ = arg_15_0.pageNum_ - 1

				arg_15_0.textInput:setString(arg_15_0.pageNum_)
				arg_15_0:updateList()
			end
		end
	end)
	arg_15_0:nodeByName("right"):setTouchEnabled(true)
	arg_15_0:nodeByName("right"):addTouchEventListener(function(arg_17_0, arg_17_1)
		if arg_17_1 == ccui.TouchEventType.began then
			arg_15_0:nodeByName("right"):setScale(0.9, 0.9)
		end

		if arg_17_1 == ccui.TouchEventType.moved then
			arg_15_0:nodeByName("right"):setScale(1, 1)
		end

		if arg_17_1 == ccui.TouchEventType.ended then
			arg_15_0:nodeByName("right"):setScale(1, 1)

			if arg_15_0.pageNum_ < arg_15_0.maxPageNum then
				arg_15_0.pageNum_ = arg_15_0.pageNum_ + 1

				arg_15_0:updateList()
			end
		end
	end)
end

function var_0_0.updateList(arg_18_0)
	arg_18_0:nodeByName("text_input"):setString(arg_18_0.pageNum_)

	if arg_18_0.pageNum_ <= 1 then
		arg_18_0:nodeByName("left"):setVisible(false)
	else
		arg_18_0:nodeByName("left"):setVisible(true)
	end

	if arg_18_0.pageNum_ >= arg_18_0.maxPageNum then
		arg_18_0:nodeByName("right"):setVisible(false)
	else
		arg_18_0:nodeByName("right"):setVisible(true)
	end

	arg_18_0.list:reload()
end

function var_0_0.initEditBox(arg_19_0)
	arg_19_0.textInput = arg_19_0:nodeByName("text_input")

	arg_19_0.textInput:setString(arg_19_0.pageNum_)

	local var_19_0 = arg_19_0:nodeByName("edit_box"):getContentSize()
	local var_19_1 = "windows/login/transparent.png"

	arg_19_0.editBox = ccui.EditBox:create(var_19_0, var_19_1)

	arg_19_0:nodeByName("edit_box"):addChild(arg_19_0.editBox)
	arg_19_0.editBox:setAnchorPoint(cc.p(0, 0))
	arg_19_0.editBox:setPosition(0, 0)
	arg_19_0.editBox:registerScriptEditBoxHandler(handler(arg_19_0, arg_19_0.inputContentbox))
	arg_19_0.editBox:setInputFlag(3)
	arg_19_0.editBox:setInputMode(cc.EDITBOX_INPUT_MODE_ANY)
	arg_19_0.editBox:setMaxLength(40)
end

function var_0_0.inputContentbox(arg_20_0, arg_20_1)
	if arg_20_1 == "began" then
		arg_20_0:nodeByName("text_input"):setVisible(false)

		if not arg_20_0.pageNum_ or arg_20_0.pageNum_ == "" then
			arg_20_0.textInput:setString("")
		else
			arg_20_0.editBox:setText(arg_20_0.textInput:getString())
		end
	elseif arg_20_1 == "return" then
		local var_20_0 = arg_20_0.editBox:getText()

		if var_20_0 == "" then
			arg_20_0.textInput:setString(arg_20_0.pageNum_)
		elseif arg_20_0:checkStrInvalid(var_20_0) then
			arg_20_0.pageNum_ = math.ceil(tonumber(var_20_0))

			arg_20_0:updateList()
		else
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_2:translation("LOTTERY_NUMBER_PAGE_INVALID")
			})
			arg_20_0.textInput:setString(arg_20_0.pageNum_)
		end

		arg_20_0.editBox:setText("")
		arg_20_0.editBox:setVisible(true)
		arg_20_0:nodeByName("text_input"):setVisible(true)
	end
end

function var_0_0.checkStrInvalid(arg_21_0, arg_21_1)
	local var_21_0 = tonumber(arg_21_1)

	if var_21_0 and var_21_0 <= arg_21_0.maxPageNum and var_21_0 >= 1 and math.ceil(var_21_0) == var_21_0 then
		return true
	end

	return false
end

function var_0_0.didOpen(arg_22_0, arg_22_1)
	arg_22_0:addBlockLayer()
end

function var_0_0.willClose(arg_23_0, arg_23_1)
	if xyd.WindowManager.get():getWindow("lottery_tips_consume") then
		xyd.WindowManager.get():closeWindow("lottery_tips_consume")
	end
end

return var_0_0
