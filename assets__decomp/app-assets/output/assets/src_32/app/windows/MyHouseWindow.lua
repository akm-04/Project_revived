local var_0_0 = class("MyHouseWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.item
local var_0_5 = import("app.model.Hero")
local var_0_6 = xyd.tables.dormHouse
local var_0_7 = 2
local var_0_8 = {
	ALL = 1,
	FOREIGN = 3,
	NORMAL = 2,
	VILLA = 4
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.dorm = xyd.ModelManager.get():loadModel(xyd.ModelType.DORM)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.btnState = var_0_8.ALL
	arg_1_0.checkEmpty = true
	arg_1_0.checkHasPeople = true
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addBlockLayer()
	arg_2_0:setButtonClick()
	arg_2_0:layout()
end

function var_0_0.didClose(arg_3_0, arg_3_1)
	var_0_0.super:didClose(arg_3_1)

	if arg_3_0.handle then
		var_0_1.unscheduleGlobal(arg_3_0.handle)

		arg_3_0.handle = nil
	end
end

function var_0_0.setButtonClick(arg_4_0, arg_4_1)
	arg_4_0:nodeByName("btn_all"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			arg_4_0.btnState = var_0_8.ALL

			arg_4_0:changeButtonState()
			arg_4_0:updateListInfo()
			arg_4_0.list:reload()
		end
	end)
	arg_4_0:nodeByName("btn_normal"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			arg_4_0.btnState = var_0_8.NORMAL

			arg_4_0:changeButtonState()
			arg_4_0:updateListInfo()
			arg_4_0.list:reload()
		end
	end)
	arg_4_0:nodeByName("btn_foreign"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			arg_4_0.btnState = var_0_8.FOREIGN

			arg_4_0:changeButtonState()
			arg_4_0:updateListInfo()
			arg_4_0.list:reload()
		end
	end)
	arg_4_0:nodeByName("btn_villa"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			arg_4_0.btnState = var_0_8.VILLA

			arg_4_0:changeButtonState()
			arg_4_0:updateListInfo()
			arg_4_0.list:reload()
		end
	end)
	arg_4_0:nodeByName("btn_check"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("my_house_check")
		end
	end)
	arg_4_0:nodeByName("check_empty"):addEventListener(function(arg_10_0, arg_10_1)
		arg_4_0.checkEmpty = arg_4_0:nodeByName("check_empty"):isSelected()

		arg_4_0:updateListInfo()
		arg_4_0.list:reload()
	end)
	arg_4_0:nodeByName("check_haspeople"):addEventListener(function(arg_11_0, arg_11_1)
		arg_4_0.checkHasPeople = arg_4_0:nodeByName("check_haspeople"):isSelected()

		arg_4_0:updateListInfo()
		arg_4_0.list:reload()
	end)
end

function var_0_0.layout(arg_12_0)
	arg_12_0:nodeByName("check_haspeople"):setSelected(arg_12_0.checkHasPeople)
	arg_12_0:nodeByName("check_empty"):setSelected(arg_12_0.checkEmpty)
	arg_12_0:nodeByName("Text_1"):setString(var_0_3:translation("DORM_MY_HOUSE_TEXT1"))
	arg_12_0:nodeByName("Text_1_Copy"):setString(var_0_3:translation("DORM_MY_HOUSE_TEXT2"))

	local var_12_0 = arg_12_0:nodeByName("house_container")
	local var_12_1 = var_12_0:getContentSize()

	arg_12_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_12_1.width, var_12_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_12_0):onScroll(handler(arg_12_0, arg_12_0.scrollListener))

	arg_12_0.list:setDelegate(handler(arg_12_0, arg_12_0.delegate))
	arg_12_0:changeButtonState()
	arg_12_0:updateListInfo()
	arg_12_0.list:reload()
	arg_12_0:createScheduler()
end

function var_0_0.createScheduler(arg_13_0)
	if arg_13_0.handle then
		var_0_1.unscheduleGlobal(arg_13_0.handle)

		arg_13_0.handle = nil
	end

	arg_13_0:updateLoungeDownTime()

	arg_13_0.handle = var_0_1.scheduleGlobal(function()
		if arg_13_0 and not tolua.isnull(arg_13_0) then
			arg_13_0:updateLoungeDownTime()
		end
	end, 1)
end

function var_0_0.updateLoungeDownTime(arg_15_0)
	local var_15_0 = arg_15_0.list.items_[1]
	local var_15_1 = arg_15_0.listInfo[1]

	if not var_15_0 or not var_15_1 then
		return
	end

	local var_15_2

	for iter_15_0, iter_15_1 in pairs(var_15_1.partner_infos or {}) do
		if not var_15_2 then
			var_15_2 = iter_15_1.house_enter_time
		elseif var_15_2 < iter_15_1.house_enter_time then
			var_15_2 = iter_15_1.house_enter_time
		end
	end

	if var_15_0 and not tolua.isnull(var_15_0) then
		local var_15_3 = var_15_0:getContent():getChildByName("house1")
		local var_15_4

		if var_15_2 then
			var_15_4 = xyd.tables.misc.dormExpLimit * 3600 + var_15_2 - xyd.ServerTime.get():getServerTime()
		end

		if var_15_4 and var_15_4 > 0 and var_15_1.house_type == xyd.DormType.LOUNGE then
			var_15_3:getChildByName("down_time_txt"):setString(xyd.timeFormatAsHMS(var_15_4))
			var_15_3:getChildByName("down_time_txt"):setVisible(true)
			var_15_3:getChildByName("down_time_bg"):setVisible(true)
			var_15_3:getChildByName("down_time_txt"):enableOutline(cc.c4b(0, 0, 0, 255), 1)
		else
			var_15_3:getChildByName("down_time_txt"):setVisible(false)
			var_15_3:getChildByName("down_time_bg"):setVisible(false)
		end
	end
end

function var_0_0.updateListInfo(arg_16_0)
	arg_16_0.listInfo = {}

	if arg_16_0.btnState == var_0_8.ALL then
		for iter_16_0, iter_16_1 in pairs(arg_16_0.dorm.dormBaseInfo) do
			for iter_16_2, iter_16_3 in pairs(iter_16_1) do
				if (arg_16_0.checkHasPeople and iter_16_3.partner_infos and next(iter_16_3.partner_infos) or arg_16_0.checkEmpty and (not iter_16_3.partner_infos or not next(iter_16_3.partner_infos))) and (arg_16_0.dorm:isSelfDorm() or not iter_16_3.is_hide or iter_16_3.is_hide == 0) then
					table.insert(arg_16_0.listInfo, iter_16_3)
				end
			end
		end
	else
		for iter_16_4, iter_16_5 in pairs(arg_16_0.dorm.dormBaseInfo) do
			if iter_16_4 == arg_16_0.btnState then
				for iter_16_6, iter_16_7 in pairs(iter_16_5) do
					if (arg_16_0.checkHasPeople and iter_16_7.partner_infos and next(iter_16_7.partner_infos) or arg_16_0.checkEmpty and (not iter_16_7.partner_infos or not next(iter_16_7.partner_infos))) and (arg_16_0.dorm:isSelfDorm() or not iter_16_7.is_hide or iter_16_7.is_hide == 0) then
						table.insert(arg_16_0.listInfo, iter_16_7)
					end
				end
			end
		end
	end

	table.sort(arg_16_0.listInfo, function(arg_17_0, arg_17_1)
		if arg_17_0 == nil or arg_17_1 == nil then
			return false
		end

		if arg_17_0.house_type == xyd.DormType.LOUNGE then
			return true
		end

		if arg_17_1.house_type == xyd.DormType.LOUNGE then
			return false
		end

		return arg_17_0.comfort > arg_17_1.comfort
	end)
end

function var_0_0.scrollListener(arg_18_0, arg_18_1)
	if arg_18_1.name == "began" then
		arg_18_0.scrollViewMoved_ = false
		arg_18_0.prevX_ = arg_18_1.x
		arg_18_0.prevY_ = arg_18_1.y
	elseif arg_18_1.name == "moved" then
		local var_18_0 = 3

		if var_18_0 <= math.abs(arg_18_1.y - arg_18_0.prevY_) or var_18_0 <= math.abs(arg_18_1.x - arg_18_0.prevX_) then
			arg_18_0.scrollViewMoved_ = true
		end
	end
end

function var_0_0.delegate(arg_19_0, arg_19_1, arg_19_2, arg_19_3)
	if cc.ui.UIListView.COUNT_TAG == arg_19_2 then
		return (math.ceil(#arg_19_0.listInfo / var_0_7))
	elseif cc.ui.UIListView.CELL_TAG == arg_19_2 then
		local var_19_0 = arg_19_0.list:dequeueItem()

		if not var_19_0 then
			var_19_0 = arg_19_0.list:newItem()
		else
			var_19_0:removeAllChildren(true)
		end

		local var_19_1 = 930
		local var_19_2 = 220

		var_19_0:setItemSize(var_19_1, var_19_2)

		local var_19_3 = display.newNode()

		var_19_3:setContentSize(var_19_1, var_19_2)
		arg_19_0:initCell(var_19_3, arg_19_3)
		var_19_0:addContent(var_19_3)

		return var_19_0
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_19_2 then
		-- block empty
	end
end

function var_0_0.initCell(arg_20_0, arg_20_1, arg_20_2)
	for iter_20_0 = 1, var_0_7 do
		local var_20_0 = (arg_20_2 - 1) * var_0_7 + iter_20_0

		if var_20_0 > #arg_20_0.listInfo then
			break
		end

		local var_20_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/dorm/my_house/house_item.csb")

		var_20_1:setPosition((var_20_1:getChildByName("bg"):getContentSize().width + 15) * (iter_20_0 - 1), 0)
		arg_20_1:addChild(var_20_1)
		var_20_1:setName("house" .. tostring(iter_20_0))
		var_20_1:setTouchEnabled(true)
		var_20_1:setTouchSwallowEnabled(false)

		local var_20_2 = var_20_1:getChildByName("bg")
		local var_20_3 = arg_20_0.listInfo[var_20_0].house_type
		local var_20_4 = arg_20_0.listInfo[var_20_0].house_name
		local var_20_5 = arg_20_0.listInfo[var_20_0].table_id
		local var_20_6 = arg_20_0.listInfo[var_20_0].comfort
		local var_20_7 = arg_20_0.listInfo[var_20_0].expand_lev
		local var_20_8 = xyd.tables.dormHouse:comfort(var_20_5)
		local var_20_9 = 1
		local var_20_10
		local var_20_11

		if var_20_7 and var_20_7 > 0 then
			var_20_10 = xyd.AssetLoader.get():loadSprite("windows/dorm/my_house/orange.png")
		elseif var_20_3 == xyd.DormType.LOUNGE then
			var_20_10 = xyd.AssetLoader.get():loadSprite("windows/dorm/my_house/brown.png")
		elseif var_20_3 == xyd.DormType.NORMAL then
			var_20_10 = xyd.AssetLoader.get():loadSprite("windows/dorm/my_house/green.png")
		elseif var_20_3 == xyd.DormType.FOREIGN then
			var_20_10 = xyd.AssetLoader.get():loadSprite("windows/dorm/my_house/blue.png")
		elseif var_20_3 == xyd.DormType.VILLA then
			var_20_10 = xyd.AssetLoader.get():loadSprite("windows/dorm/my_house/purple.png")
		end

		local var_20_12 = xyd.AssetLoader.get():loadSprite(xyd.tables.dormHouse:bg(var_20_5))

		var_20_10:setAnchorPoint(0, 0)
		var_20_12:setAnchorPoint(0, 0)
		var_20_2:getChildByName("bg_img"):addChild(var_20_10)
		var_20_2:getChildByName("bg_img"):getChildByName("bgimg"):addChild(var_20_12)

		if var_20_3 == xyd.DormType.LOUNGE then
			-- block empty
		end

		if not var_20_4 or #var_20_4 == 0 then
			var_20_2:getChildByName("text_name"):setString(xyd.tables.dormHouse:name(var_20_5))
		else
			var_20_2:getChildByName("text_name"):setString(var_20_4)
		end

		var_20_2:getChildByName("text_name"):enableOutline(cc.c4b(255, 182, 27, 255), 2)

		for iter_20_1, iter_20_2 in pairs(var_20_8) do
			if iter_20_2 <= var_20_6 then
				var_20_9 = iter_20_1
			end
		end

		local var_20_13 = xyd.AssetLoader.get():loadSprite("windows/dorm/my_house/face_" .. var_20_9 .. ".png")

		var_20_13:setAnchorPoint(0, 0)

		if var_20_3 ~= xyd.DormType.LOUNGE then
			var_20_2:getChildByName("comfort"):addChild(var_20_13)
		end

		if arg_20_0.listInfo[var_20_0].partner_infos and next(arg_20_0.listInfo[var_20_0].partner_infos) then
			if var_20_3 ~= xyd.DormType.LOUNGE then
				if arg_20_0.dorm:isSelfDorm() then
					local var_20_14 = arg_20_0.selfPlayer:getHeroByID(arg_20_0.listInfo[var_20_0].partner_infos[1].partner_id)

					arg_20_0:rewardLayer(var_20_2:getChildByName("equip_container"), var_20_14.houseEquips, var_20_14)
					xyd.setAvatarBorder(var_20_14, var_20_2:getChildByName("hero_avatar"))
				else
					local var_20_15 = var_0_5.new()

					var_20_15:populate(arg_20_0.listInfo[var_20_0].partner_infos[1])
					xyd.setAvatarBorder(var_20_15, var_20_2:getChildByName("hero_avatar"))
					arg_20_0:rewardLayer(var_20_2:getChildByName("equip_container"), arg_20_0.listInfo[var_20_0].partner_infos[1].house_equips, var_20_15)
				end
			else
				var_20_2:getChildByName("equip_container"):setVisible(false)
				var_20_2:getChildByName("hero_avatar"):setVisible(false)

				for iter_20_3, iter_20_4 in pairs(arg_20_0.listInfo[var_20_0].partner_infos) do
					local var_20_16 = var_20_2:getChildByName("hero_container"):getContentSize().height
					local var_20_17 = 5
					local var_20_18 = display.newNode()
					local var_20_19 = iter_20_4.table_id
					local var_20_20 = iter_20_4.color
					local var_20_21 = iter_20_4.star
					local var_20_22 = iter_20_4.twice_awake_stage == xyd.AwakeTwiceStage.COMPLETE
					local var_20_23 = iter_20_4.current_skin_id

					var_20_18:setContentSize(var_20_16, var_20_16)
					xyd.setAvatarBorder(var_20_19, var_20_18, var_20_20, var_20_21, var_20_22, nil, var_20_23)
					var_20_18:addTo(var_20_2:getChildByName("hero_container"))
					var_20_18:setAnchorPoint(cc.p(0, 0))
					var_20_18:setPosition((iter_20_3 - 1) * (var_20_16 + var_20_17), 0)
				end
			end
		elseif var_20_3 ~= xyd.DormType.LOUNGE then
			var_20_2:getChildByName("attr"):setPositionY(var_20_2:getChildByName("attr"):getPositionY() - 60)
		end

		local var_20_24 = var_0_6:getHouseLevByComfort(var_20_5, var_20_6)
		local var_20_25 = xyd.getHouseCurrentAttrs(var_20_5, var_20_6, var_20_7)

		if var_20_3 == xyd.DormType.LOUNGE then
			var_20_2:getChildByName("attr"):setVisible(false)
		end

		for iter_20_5 = 1, #var_20_25 do
			local var_20_26 = "+" .. tostring(var_20_25[iter_20_5]) .. tostring("%")

			if iter_20_5 == xyd.AttributeType.STRENGTH then
				var_20_2:getChildByName("attr"):getChildByName("strength_increase_txt"):setString(var_20_26)
				var_20_2:getChildByName("attr"):getChildByName("strength_increase_txt"):enableOutline(cc.c4b(0, 0, 0, 255), 1)
			elseif iter_20_5 == xyd.AttributeType.WISE then
				var_20_2:getChildByName("attr"):getChildByName("wise_increase_txt"):setString(var_20_26)
				var_20_2:getChildByName("attr"):getChildByName("wise_increase_txt"):enableOutline(cc.c4b(0, 0, 0, 255), 1)
			elseif iter_20_5 == xyd.AttributeType.AGILE then
				var_20_2:getChildByName("attr"):getChildByName("agile_increase_txt"):setString(var_20_26)
				var_20_2:getChildByName("attr"):getChildByName("agile_increase_txt"):enableOutline(cc.c4b(0, 0, 0, 255), 1)
			end
		end

		var_20_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_21_0)
			if arg_21_0.name == "ended" and not arg_20_0.scrollViewMoved_ then
				arg_20_0.dorm:toHouse(arg_20_0.listInfo[var_20_0])
			end

			return true
		end)
	end
end

function var_0_0.changeButtonState(arg_22_0)
	if arg_22_0.btnState == var_0_8.ALL then
		arg_22_0:nodeByName("btn_all"):setTouchEnabled(false)
		arg_22_0:nodeByName("btn_normal"):setTouchEnabled(true)
		arg_22_0:nodeByName("btn_foreign"):setTouchEnabled(true)
		arg_22_0:nodeByName("btn_villa"):setTouchEnabled(true)
		arg_22_0:nodeByName("btn_all"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_22_0:nodeByName("btn_normal"):setBrightStyle(ccui.BrightStyle.normal)
		arg_22_0:nodeByName("btn_foreign"):setBrightStyle(ccui.BrightStyle.normal)
		arg_22_0:nodeByName("btn_villa"):setBrightStyle(ccui.BrightStyle.normal)
	elseif arg_22_0.btnState == var_0_8.NORMAL then
		arg_22_0:nodeByName("btn_all"):setTouchEnabled(true)
		arg_22_0:nodeByName("btn_normal"):setTouchEnabled(false)
		arg_22_0:nodeByName("btn_foreign"):setTouchEnabled(true)
		arg_22_0:nodeByName("btn_villa"):setTouchEnabled(true)
		arg_22_0:nodeByName("btn_all"):setBrightStyle(ccui.BrightStyle.normal)
		arg_22_0:nodeByName("btn_normal"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_22_0:nodeByName("btn_foreign"):setBrightStyle(ccui.BrightStyle.normal)
		arg_22_0:nodeByName("btn_villa"):setBrightStyle(ccui.BrightStyle.normal)
	elseif arg_22_0.btnState == var_0_8.FOREIGN then
		arg_22_0:nodeByName("btn_all"):setTouchEnabled(true)
		arg_22_0:nodeByName("btn_normal"):setTouchEnabled(true)
		arg_22_0:nodeByName("btn_foreign"):setTouchEnabled(false)
		arg_22_0:nodeByName("btn_villa"):setTouchEnabled(true)
		arg_22_0:nodeByName("btn_all"):setBrightStyle(ccui.BrightStyle.normal)
		arg_22_0:nodeByName("btn_normal"):setBrightStyle(ccui.BrightStyle.normal)
		arg_22_0:nodeByName("btn_foreign"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_22_0:nodeByName("btn_villa"):setBrightStyle(ccui.BrightStyle.normal)
	elseif arg_22_0.btnState == var_0_8.VILLA then
		arg_22_0:nodeByName("btn_all"):setTouchEnabled(true)
		arg_22_0:nodeByName("btn_normal"):setTouchEnabled(true)
		arg_22_0:nodeByName("btn_foreign"):setTouchEnabled(true)
		arg_22_0:nodeByName("btn_villa"):setTouchEnabled(false)
		arg_22_0:nodeByName("btn_all"):setBrightStyle(ccui.BrightStyle.normal)
		arg_22_0:nodeByName("btn_normal"):setBrightStyle(ccui.BrightStyle.normal)
		arg_22_0:nodeByName("btn_foreign"):setBrightStyle(ccui.BrightStyle.normal)
		arg_22_0:nodeByName("btn_villa"):setBrightStyle(ccui.BrightStyle.highlight)
	end
end

function var_0_0.rewardLayer(arg_23_0, arg_23_1, arg_23_2, arg_23_3)
	local var_23_0 = arg_23_3:getDormItemList()
	local var_23_1 = arg_23_2

	if #var_23_1 == 1 and var_23_1[1] == 0 then
		var_23_1 = {}
	end

	local var_23_2 = arg_23_1:getContentSize().height
	local var_23_3 = 2
	local var_23_4 = #var_23_1

	for iter_23_0 = 1, 5 do
		if var_23_1[iter_23_0] ~= 0 then
			local var_23_5 = display.newNode()

			var_23_5:setContentSize(var_23_2, var_23_2)

			local var_23_6 = xyd.tables.item:type(var_23_1[iter_23_0])

			xyd.setItemBorder(var_23_5, var_23_1[iter_23_0], false, false)
			var_23_5:addTo(arg_23_1)
			var_23_5:setAnchorPoint(cc.p(0, 0))
			var_23_5:setPosition((iter_23_0 - 1) * (var_23_2 + var_23_3), 0)
		else
			local var_23_7 = var_23_0[iter_23_0]
			local var_23_8 = xyd.AssetLoader.get():loadSprite("windows/dorm/my_house/equip_bg.png")

			var_23_8:addTo(arg_23_1)
			var_23_8:setAnchorPoint(cc.p(0, 0))
			var_23_8:setPosition((iter_23_0 - 1) * (var_23_2 + var_23_3), -3)

			if arg_23_0.backpack:getItemNumByID(var_23_7) > 0 and iter_23_0 <= arg_23_3:getStar() then
				local var_23_9 = xyd.AssetLoader.get():loadSprite("windows/dorm/room_equip/green_plus.png")

				var_23_9:addTo(arg_23_1)
				var_23_9:setPosition((iter_23_0 - 1) * (var_23_2 + var_23_3) + var_23_2 / 2 + 3, var_23_2 / 2)
			elseif arg_23_0.backpack:getItemNumByID(var_23_7) > 0 then
				local var_23_10 = xyd.AssetLoader.get():loadSprite("windows/dorm/room_equip/white_plus.png")

				var_23_10:addTo(arg_23_1)
				var_23_10:setPosition((iter_23_0 - 1) * (var_23_2 + var_23_3) + var_23_2 / 2 + 3, var_23_2 / 2)
			end
		end
	end

	return arg_23_1
end

return var_0_0
