local var_0_0 = class("TuJianWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 11
local var_0_3 = 20001246
local var_0_4 = 12
local var_0_5 = 1
local var_0_6 = 2
local var_0_7 = 3
local var_0_8 = 4
local var_0_9 = 5
local var_0_10 = 6
local var_0_11 = 7
local var_0_12 = 8
local var_0_13 = 9
local var_0_14 = 10
local var_0_15 = 11
local var_0_16 = 12

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.playerLev = arg_1_0.selfPlayer.lev
	arg_1_0.item = {}

	for iter_1_0 = 1, 12 do
		arg_1_0["itemTotalNum_" .. iter_1_0] = {}

		table.insert(arg_1_0.item, arg_1_0["itemTotalNum_" .. iter_1_0])
	end
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:setTouchSwallowEnabled(true)
	arg_2_0:setFont()
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0.itemTotalNum = xyd.tables.item:getItemsByTypes(1)

	for iter_3_0, iter_3_1 in pairs(arg_3_0.itemTotalNum) do
		if not xyd.tables.item:isScreen(iter_3_1) then
			table.insert(arg_3_0.itemTotalNum_1, iter_3_1)
		end
	end

	arg_3_0:sortTables(arg_3_0.itemTotalNum_1)

	for iter_3_2 = 1, #arg_3_0.itemTotalNum_1 do
		arg_3_0.itemtemp = xyd.tables.item:attrs(arg_3_0.itemTotalNum_1[iter_3_2])

		local var_3_0 = false

		for iter_3_3, iter_3_4 in pairs(arg_3_0.itemtemp) do
			if iter_3_3 == var_0_5 then
				table.insert(arg_3_0.itemTotalNum_2, arg_3_0.itemTotalNum_1[iter_3_2])
			elseif iter_3_3 == var_0_6 then
				table.insert(arg_3_0.itemTotalNum_3, arg_3_0.itemTotalNum_1[iter_3_2])
			elseif iter_3_3 == var_0_7 then
				table.insert(arg_3_0.itemTotalNum_4, arg_3_0.itemTotalNum_1[iter_3_2])
			elseif iter_3_3 == var_0_8 then
				table.insert(arg_3_0.itemTotalNum_5, arg_3_0.itemTotalNum_1[iter_3_2])
			elseif iter_3_3 == var_0_9 then
				table.insert(arg_3_0.itemTotalNum_6, arg_3_0.itemTotalNum_1[iter_3_2])
			elseif iter_3_3 == var_0_10 then
				table.insert(arg_3_0.itemTotalNum_7, arg_3_0.itemTotalNum_1[iter_3_2])
			elseif iter_3_3 == var_0_11 then
				table.insert(arg_3_0.itemTotalNum_8, arg_3_0.itemTotalNum_1[iter_3_2])
			elseif iter_3_3 == var_0_12 then
				table.insert(arg_3_0.itemTotalNum_9, arg_3_0.itemTotalNum_1[iter_3_2])
			elseif iter_3_3 == var_0_13 or iter_3_3 == var_0_14 then
				if not var_3_0 then
					var_3_0 = true

					table.insert(arg_3_0.itemTotalNum_10, arg_3_0.itemTotalNum_1[iter_3_2])
				end
			elseif iter_3_3 == var_0_15 then
				table.insert(arg_3_0.itemTotalNum_11, arg_3_0.itemTotalNum_1[iter_3_2])
			elseif iter_3_3 == var_0_16 then
				table.insert(arg_3_0.itemTotalNum_12, arg_3_0.itemTotalNum_1[iter_3_2])
			end
		end
	end

	for iter_3_5 = 1, var_0_2 do
		arg_3_0:sortTables(arg_3_0.item[iter_3_5 + 1])
	end

	arg_3_0.itemNum = 1
	arg_3_0.pageIndex_ = 1
	arg_3_0.all = arg_3_0:nodeByName("all_btn")
	arg_3_0.left = arg_3_0:nodeByName("left_btn")
	arg_3_0.right = arg_3_0:nodeByName("right_btn")
	arg_3_0.close = arg_3_0:nodeByName("close")
	arg_3_0.lagePage = math.ceil(#arg_3_0.itemTotalNum_1 / var_0_4)
	arg_3_0.text_ = arg_3_0:nodeByName("page_text")

	arg_3_0.text_:enableShadow(cc.c4b(69, 46, 18, 20))
	arg_3_0.text_:setString(arg_3_0.pageIndex_ .. "/" .. arg_3_0.lagePage)

	arg_3_0.optionButtons_ = {}

	table.insert(arg_3_0.optionButtons_, arg_3_0:nodeByName("all_btn"))
	table.insert(arg_3_0.optionButtons_, arg_3_0:nodeByName("wuli_btn"))
	table.insert(arg_3_0.optionButtons_, arg_3_0:nodeByName("fashu_btn"))
	table.insert(arg_3_0.optionButtons_, arg_3_0:nodeByName("lingqiao_btn"))
	table.insert(arg_3_0.optionButtons_, arg_3_0:nodeByName("shengming_btn"))
	table.insert(arg_3_0.optionButtons_, arg_3_0:nodeByName("wugong_btn"))
	table.insert(arg_3_0.optionButtons_, arg_3_0:nodeByName("faqiang_btn"))
	table.insert(arg_3_0.optionButtons_, arg_3_0:nodeByName("hujia_btn"))
	table.insert(arg_3_0.optionButtons_, arg_3_0:nodeByName("fakang_btn"))
	table.insert(arg_3_0.optionButtons_, arg_3_0:nodeByName("baoji_btn"))
	table.insert(arg_3_0.optionButtons_, arg_3_0:nodeByName("huixue_btn"))
	table.insert(arg_3_0.optionButtons_, arg_3_0:nodeByName("nengliang_btn"))
	arg_3_0:nodeByName("text_0"):setColor(cc.c4b(255, 0, 0, 0))
	arg_3_0.all:setBrightStyle(ccui.BrightStyle.highlight)
	arg_3_0:loadItem(arg_3_0.itemTotalNum_1)
	arg_3_0:buttonListener()
end

function var_0_0.setFont(arg_4_0)
	for iter_4_0 = 1, var_0_2 + 1 do
		local var_4_0 = var_0_1:translation("BUTTON_TEXT_" .. iter_4_0)

		arg_4_0:nodeByName("text_" .. iter_4_0 - 1):setString(var_4_0)
	end

	arg_4_0:nodeByName("dian_text"):setColor(cc.c4b(114, 76, 30, 0))
	arg_4_0:nodeByName("page_text"):setColor(cc.c4b(114, 76, 30, 0))
	arg_4_0:nodeByName("dian2_text"):setColor(cc.c4b(114, 76, 30, 0))
end

function var_0_0.sortTables(arg_5_0, arg_5_1)
	for iter_5_0 = 1, #arg_5_1 do
		for iter_5_1 = 1, #arg_5_1 - iter_5_0 do
			if xyd.tables.item:level_visible(arg_5_1[iter_5_1]) > xyd.tables.item:level_visible(arg_5_1[iter_5_1 + 1]) then
				arg_5_1[iter_5_1], arg_5_1[iter_5_1 + 1] = arg_5_1[iter_5_1 + 1], arg_5_1[iter_5_1]
			end
		end
	end
end

function var_0_0.loadItem(arg_6_0, arg_6_1)
	if arg_6_0.itemNum <= 1 then
		arg_6_0:nodeByName("left_btn"):setTouchEnabled(false)
		arg_6_0:nodeByName("left_btn"):setVisible(false)
	else
		arg_6_0:nodeByName("left_btn"):setVisible(true)
		arg_6_0:nodeByName("left_btn"):setTouchEnabled(true)
	end

	if #arg_6_1 - arg_6_0.itemNum < var_0_4 then
		arg_6_0:nodeByName("right_btn"):setTouchEnabled(false)
		arg_6_0:nodeByName("right_btn"):setVisible(false)
	else
		arg_6_0:nodeByName("right_btn"):setTouchEnabled(true)
		arg_6_0:nodeByName("right_btn"):setVisible(true)
	end

	if #arg_6_1 - arg_6_0.itemNum >= var_0_4 then
		for iter_6_0 = 1, var_0_4 do
			local var_6_0 = arg_6_0:nodeByName("list_" .. iter_6_0)
			local var_6_1 = import("app.windows.TuJianCellItem").new()
			local var_6_2 = {
				itemID = arg_6_1[arg_6_0.itemNum]
			}

			if xyd.tables.item:level_visible(var_6_2.itemID) > arg_6_0.playerLev then
				var_6_2.isHide = true

				var_6_1:setTouchEnabled(true)
			else
				var_6_2.isHide = false

				var_6_1:setTouchEnabled(true)
			end

			var_6_1:setParams(var_6_2)
			var_6_1:setPosition(0, 13)
			var_6_1:setAnchorPoint(cc.p(0.5, 0.5))
			var_6_0:addChild(var_6_1)

			arg_6_0.itemNum = arg_6_0.itemNum + 1

			var_6_1:setTouchSwallowEnabled(true)
			var_6_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
				if arg_7_0.name == "began" then
					var_6_1.contentView_:nodeByName("container"):setScale(0.9)

					return true
				elseif arg_7_0.name == "ended" then
					var_6_1.contentView_:nodeByName("container"):setScale(1)
					xyd.playButtonSound()
					var_6_1:onClick(var_6_1.params.itemID, var_6_0)
				end
			end)
		end
	else
		local var_6_3 = #arg_6_1 - arg_6_0.itemNum + 1

		for iter_6_1 = 1, var_6_3 do
			local var_6_4 = arg_6_0:nodeByName("list_" .. iter_6_1)
			local var_6_5 = import("app.windows.TuJianCellItem").new()
			local var_6_6 = {
				itemID = arg_6_1[arg_6_0.itemNum]
			}

			if xyd.tables.item:level_visible(var_6_6.itemID) > arg_6_0.playerLev then
				var_6_6.isHide = true

				var_6_5:setTouchEnabled(true)
			else
				var_6_6.isHide = false

				var_6_5:setTouchEnabled(true)
			end

			var_6_5:setParams(var_6_6)
			var_6_5:setPosition(0, 13)
			var_6_5:setAnchorPoint(cc.p(0.5, 0.5))
			var_6_4:addChild(var_6_5)

			arg_6_0.itemNum = arg_6_0.itemNum + 1

			var_6_5:setTouchSwallowEnabled(true)
			var_6_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
				if arg_8_0.name == "began" then
					var_6_5.contentView_:nodeByName("container"):setScale(0.9)

					return true
				elseif arg_8_0.name == "ended" then
					var_6_5.contentView_:nodeByName("container"):setScale(1)
					xyd.playButtonSound()
					var_6_5:onClick(var_6_5.params.itemID, var_6_4)
				end
			end)
		end
	end

	if arg_6_0.itemNum > #arg_6_1 then
		if #arg_6_1 % var_0_4 == 0 then
			arg_6_0.itemNum = #arg_6_1 + 1
		else
			arg_6_0.itemNum = #arg_6_1 - #arg_6_1 % var_0_4 + var_0_4 + 1
		end
	end
end

function var_0_0.refresh(arg_9_0, arg_9_1)
	arg_9_0.lagePage = math.ceil(#arg_9_1 / var_0_4)

	arg_9_0.text_:setString(arg_9_0.pageIndex_ .. "/" .. arg_9_0.lagePage)

	for iter_9_0 = 1, var_0_4 do
		arg_9_0:nodeByName("list_" .. iter_9_0):removeAllChildren()
	end
end

function var_0_0.updateItems(arg_10_0, arg_10_1)
	arg_10_0:refresh(arg_10_1)
	arg_10_0:loadItem(arg_10_1)
end

function var_0_0.didOpen(arg_11_0)
	arg_11_0.left:addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.began then
			arg_11_0:nodeByName("left_btn"):setScale(0.9)
		elseif arg_12_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_11_0:nodeByName("left_btn"):setScale(1)

			arg_11_0.pageIndex_ = arg_11_0.pageIndex_ - 1

			if #arg_11_0.itemTotalNum_1 - arg_11_0.itemNum ~= 0 then
				arg_11_0.itemNum = arg_11_0.itemNum - var_0_4 * 2

				if arg_11_0.itemNum == 0 then
					arg_11_0.itemNum = 1
				end

				arg_11_0:updateItems(arg_11_0.itemTotalNum_1)
			else
				if #arg_11_0.itemTotalNum_1 - arg_11_0.itemNum == 0 and (#arg_11_0.itemTotalNum_1 % var_0_4 == 0 or #arg_11_0.itemTotalNum_1 % var_0_4 == 1) then
					arg_11_0.itemNum = arg_11_0.itemNum - var_0_4 * 2

					arg_11_0:updateItems(arg_11_0.itemTotalNum_1)
				elseif #arg_11_0.itemTotalNum_1 - arg_11_0.itemNum == 0 and #arg_11_0.itemTotalNum_1 % var_0_4 ~= 0 then
					arg_11_0.itemNum = arg_11_0.itemNum - #arg_11_0.itemTotalNum_1 % var_0_4 - (var_0_4 - 1)

					arg_11_0:updateItems(arg_11_0.itemTotalNum_1)
				end

				arg_11_0.text_:setString(arg_11_0.pageIndex_ .. "/" .. arg_11_0.lagePage)
			end
		end
	end)
	arg_11_0.right:addTouchEventListener(function(arg_13_0, arg_13_1)
		if arg_13_1 == ccui.TouchEventType.began then
			arg_11_0:nodeByName("right_btn"):setScale(0.9)
		elseif arg_13_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_11_0:nodeByName("right_btn"):setScale(1)

			arg_11_0.pageIndex_ = arg_11_0.pageIndex_ + 1

			arg_11_0:updateItems(arg_11_0.itemTotalNum_1)
		end
	end)
end

function var_0_0.setBtnColor(arg_14_0, arg_14_1)
	for iter_14_0 = 0, var_0_2 do
		arg_14_0.text = arg_14_0:nodeByName("text_" .. iter_14_0)

		if arg_14_1 == iter_14_0 then
			arg_14_0.text:setColor(cc.c4b(255, 0, 0, 0))
			arg_14_0.optionButtons_[iter_14_0 + 1]:setBrightStyle(ccui.BrightStyle.highlight)
		else
			arg_14_0.text:setColor(cc.c4b(255, 255, 255, 0))
			arg_14_0.optionButtons_[iter_14_0 + 1]:setBrightStyle(ccui.BrightStyle.normal)
		end
	end
end

function var_0_0.turnButtonListener(arg_15_0, arg_15_1)
	arg_15_0.left:addTouchEventListener(function(arg_16_0, arg_16_1)
		if arg_16_1 == ccui.TouchEventType.began then
			arg_15_0:nodeByName("left_btn"):setScale(0.9)
		elseif arg_16_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_15_0:nodeByName("left_btn"):setScale(1)

			arg_15_0.pageIndex_ = arg_15_0.pageIndex_ - 1

			if #arg_15_1 - arg_15_0.itemNum ~= 0 then
				arg_15_0.itemNum = arg_15_0.itemNum - var_0_4 * 2

				if arg_15_0.itemNum == 0 then
					arg_15_0.itemNum = 1
				end

				arg_15_0:updateItems(arg_15_1)
			else
				if #arg_15_1 - arg_15_0.itemNum == 0 and (#arg_15_1 % var_0_4 == 0 or #arg_15_1 % var_0_4 == 1) then
					arg_15_0.itemNum = arg_15_0.itemNum - var_0_4 * 2

					arg_15_0:updateItems(arg_15_1)
				elseif #arg_15_1 - arg_15_0.itemNum == 0 and #arg_15_1 % var_0_4 ~= 0 then
					arg_15_0.itemNum = arg_15_0.itemNum - #arg_15_1 % var_0_4 - (var_0_4 - 1)

					arg_15_0:updateItems(arg_15_1)
				end

				arg_15_0.text_:setString(arg_15_0.pageIndex_ .. "/" .. arg_15_0.lagePage)
			end
		end
	end)
	arg_15_0.right:addTouchEventListener(function(arg_17_0, arg_17_1)
		if arg_17_1 == ccui.TouchEventType.began then
			arg_15_0:nodeByName("right_btn"):setScale(0.9)
		elseif arg_17_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_15_0:nodeByName("right_btn"):setScale(1)

			arg_15_0.pageIndex_ = arg_15_0.pageIndex_ + 1

			arg_15_0:updateItems(arg_15_1)
		end
	end)
end

function var_0_0.temp(arg_18_0, arg_18_1, arg_18_2)
	arg_18_0.itemNum = 1

	arg_18_0:refresh(arg_18_2)
	arg_18_0:loadItem(arg_18_2)
	arg_18_0:setBtnColor(arg_18_1)
end

function var_0_0.buttonHander(arg_19_0, arg_19_1, arg_19_2, arg_19_3)
	if arg_19_0.pageIndex_ == 0 and #arg_19_1 == 0 then
		arg_19_0.pageIndex_ = 0
	else
		arg_19_0.pageIndex_ = 1
	end

	for iter_19_0 = 0, var_0_2 do
		if arg_19_3 == iter_19_0 and arg_19_2 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_19_0:temp(iter_19_0, arg_19_1)
		end
	end
end

function var_0_0.buttonListener(arg_20_0)
	arg_20_0.close:addTouchEventListener(function(arg_21_0, arg_21_1)
		if arg_21_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():closeWindow("tujian_itemdetail")
			xyd.WindowManager.get():closeWindow("moreItemDetail")
			xyd.WindowManager.get():closeWindow(arg_20_0)
		end
	end)

	for iter_20_0 = 0, var_0_2 do
		arg_20_0.optionButtons_[iter_20_0 + 1]:addTouchEventListener(function(arg_22_0, arg_22_1)
			local var_22_0 = arg_20_0.item[iter_20_0 + 1]

			if #var_22_0 == 0 then
				arg_20_0.pageIndex_ = 0
				arg_20_0.lagePage = 0
			end

			arg_20_0:buttonHander(var_22_0, arg_22_1, iter_20_0)
			arg_20_0:turnButtonListener(var_22_0)
		end)
	end
end

return var_0_0
