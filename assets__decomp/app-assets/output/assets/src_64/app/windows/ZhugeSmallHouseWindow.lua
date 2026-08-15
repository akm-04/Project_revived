local var_0_0 = class("ZhugeSmallHouseWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpriteNodeButton")
local var_0_2 = xyd.tables.translation
local var_0_3 = require("framework.scheduler")
local var_0_4 = xyd.tables.zhugeShopItem
local var_0_5 = xyd.tables.misc
local var_0_6 = 4
local var_0_7 = {
	NOTEBOOK_WND = 4,
	BOX_CHECK_WND = 3,
	FOREST_WND = 5,
	TRANSFER_WND = 6,
	EXCHANGE_SKILL = 7,
	BOX_WND = 2,
	MAIN_WND = 1
}
local var_0_8 = {
	[1] = 26,
	[2] = 32
}
local var_0_9 = {
	[26] = 1,
	[32] = 2
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.zhugeModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ZHUGE_FESTIVAL)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.houseType = var_0_7.MAIN_WND
	arg_1_0.isMoving = false

	local var_1_0 = arg_1_0.zhugeModel:getBaseInfo()

	if var_1_0.summon_type ~= 26 and var_1_0.summon_type ~= 32 then
		var_1_0.summon_type = 26
	end
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("txt_title"):setString(var_0_2:translation("ZHUGEJI"))
	arg_3_0:nodeByName("detail_container"):setVisible(false)
	arg_3_0:nodeByName("bottom"):setLocalZOrder(10)
	arg_3_0:nodeByName("text_cv"):setString("CV:" .. xyd.tables.hero:getCV(10001144))
	arg_3_0:updateCoin()
	arg_3_0:showDialog(true)
	arg_3_0:initDialogClick()
	arg_3_0:nodeByName("btn_rule"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			local var_4_0 = {}

			var_4_0.pageNum = 3

			xyd.WindowManager.get():openWindow("zhuge_graphic", var_4_0)
		end
	end)
	arg_3_0:nodeByName("btn_box"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			arg_3_0.houseType = var_0_7.BOX_WND

			arg_3_0:playEvent()
		end
	end)
	arg_3_0:nodeByName("btn_notebook"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			arg_3_0.houseType = var_0_7.NOTEBOOK_WND

			arg_3_0.zhugeModel:getNoteInfo(function(arg_7_0, arg_7_1)
				if arg_7_0 == xyd.error.OK then
					local var_7_0 = arg_3_0.zhugeModel:getLocalNoteInfo()

					if var_7_0 and next(var_7_0) and var_7_0.black_task ~= 0 and var_7_0.white_task ~= 0 then
						if var_7_0.cur_select ~= 0 then
							local var_7_1 = {
								battleID = xyd.tables.zhugeNote:battleID(1),
								noteID = var_7_0.cur_select
							}

							xyd.WindowManager.get():openWindow("zhuge_enemy_wnd", var_7_1)

							arg_3_0.houseType = var_0_7.MAIN_WND
						else
							arg_3_0:playEvent()
						end
					else
						arg_3_0.zhugeModel:ramdomTask(function(arg_8_0, arg_8_1)
							if arg_8_0 == xyd.error.OK then
								arg_3_0:playEvent()
							end
						end)
					end
				end
			end)
		end
	end)
	arg_3_0:nodeByName("btn_forest"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("zhuge_main_wnd")
		end
	end)

	if arg_3_0.zhugeModel:getLocalBossInfo().is_passed == 1 then
		arg_3_0:nodeByName("btn_word_transfer"):setVisible(false)
	else
		arg_3_0:nodeByName("btn_word_skill"):setVisible(false)
	end

	arg_3_0:nodeByName("btn_transfer"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			if arg_3_0.zhugeModel:getLocalBossInfo().is_passed == 1 then
				arg_3_0.houseType = var_0_7.EXCHANGE_SKILL
			else
				arg_3_0.houseType = var_0_7.TRANSFER_WND
			end

			arg_3_0:playEvent()
		end
	end)

	local var_3_0 = var_0_1.new({
		sprite = "windows/button/btn_return.png",
		isSound = 0,
		colorModes = xyd.tables.systemColor:btnColors(xyd.ColorMode.YELLOW)
	})

	var_3_0:addTo(arg_3_0:nodeByName("top"))
	var_3_0:setAnchorPoint(0.5, 0.5)
	var_3_0:setPosition(arg_3_0:nodeByName("pos_btn_return"):getPosition())
	var_3_0:setName("return_btn")

	arg_3_0.children_.return_btn = var_3_0

	arg_3_0:nodeByName("return_btn"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_11_0)
		if arg_11_0.name == "began" then
			return true
		elseif arg_11_0.name == "ended" then
			arg_3_0:playReturnHouse()
		end
	end)
end

function var_0_0.didOpen(arg_12_0, arg_12_1)
	var_0_0.super:didOpen(arg_12_1)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_12_0):addEventListener(xyd.event.ECONOMY, handler(arg_12_0, arg_12_0.updateCoin))

	if not arg_12_0.zhugeModel.hasShowTip then
		arg_12_0.zhugeModel.hasShowTip = true

		local var_12_0 = {}

		var_12_0.pageNum = 2

		xyd.WindowManager.get():openWindow("zhuge_graphic", var_12_0)
	end
end

function var_0_0.willClose(arg_13_0)
	if arg_13_0.dialogHandle then
		var_0_3.unscheduleGlobal(arg_13_0.dialogHandle)

		arg_13_0.dialogHandle = nil
	end
end

function var_0_0.updateCoin(arg_14_0)
	arg_14_0:nodeByName("text_mana"):setString(xyd.num2ThousandsStr(arg_14_0.selfPlayer.mana))
	arg_14_0:nodeByName("text_crystal"):setString(xyd.num2ThousandsStr(arg_14_0.selfPlayer.crystal))

	if arg_14_0.houseType == var_0_7.EXCHANGE_SKILL then
		arg_14_0:nodeByName("magic_box"):setTexture("windows/zhugeliang/small_house/skill_coin_icon.png")
		arg_14_0:nodeByName("magic_box"):setScale(1)

		local var_14_0 = arg_14_0.backpack:getItemNumByID(var_0_5.zhugeTeleportItem)

		arg_14_0:nodeByName("text_box_num"):setString(var_14_0)
	else
		arg_14_0:nodeByName("magic_box"):setTexture("windows/zhugeliang/small_house/magic_box.png")
		arg_14_0:nodeByName("magic_box"):setScale(0.6)

		local var_14_1 = arg_14_0.backpack:getItemNumByID(var_0_5.zhugeBoxPartItem)

		arg_14_0:nodeByName("text_box_num"):setString(var_14_1)
	end
end

function var_0_0.showDialog(arg_15_0, arg_15_1)
	if arg_15_0.dialogHandle then
		var_0_3.unscheduleGlobal(arg_15_0.dialogHandle)

		arg_15_0.dialogHandle = nil
	end

	if arg_15_0.speakHandler then
		var_0_3.unscheduleGlobal(arg_15_0.speakHandler)

		arg_15_0.speakHandler = nil
	end

	if not arg_15_1 then
		if arg_15_0 and not tolua.isnull(arg_15_0) then
			arg_15_0:nodeByName("bottom"):setVisible(false)
		end

		return
	end

	arg_15_0:nodeByName("bottom"):setVisible(true)

	local var_15_0 = var_0_5.dialogDefaultTime

	arg_15_0.dialogHandle = var_0_3.scheduleGlobal(function()
		var_15_0 = var_15_0 - 1

		if var_15_0 <= 0 then
			if arg_15_0.dialogHandle then
				var_0_3.unscheduleGlobal(arg_15_0.dialogHandle)

				arg_15_0.dialogHandle = nil
			end

			if arg_15_0 and not tolua.isnull(arg_15_0) then
				arg_15_0:showDialog(false)
			end
		end
	end, 1)

	local var_15_1 = arg_15_0:getDialog()
	local var_15_2 = xyd.tables.misc.dialogSpeed

	arg_15_0:nodeByName("text_dialog"):setString("")
	arg_15_0:speak(var_15_1, arg_15_0:nodeByName("text_dialog"), var_15_2)
end

function var_0_0.showBtn(arg_17_0, arg_17_1)
	arg_17_0:nodeByName("btn_container"):setVisible(arg_17_1)
end

function var_0_0.playEvent(arg_18_0)
	arg_18_0:showBtn(false)

	if arg_18_0.houseType == var_0_7.BOX_WND then
		arg_18_0:nodeByName("txt_title"):setString(var_0_2:translation("ZHUGEJI_JIESUOHEZI"))
		arg_18_0:initBoxWnd()
		arg_18_0:showDialog(true)
		arg_18_0.boxSelectItem:setVisible(true)
	elseif arg_18_0.houseType == var_0_7.EXCHANGE_SKILL then
		arg_18_0:updateCoin()
		arg_18_0:initExchangeWnd()
		arg_18_0.skillExchangeWnd:setVisible(false)
		arg_18_0:playMove(true, function()
			if arg_18_0.skillExchangeWnd and not tolua.isnull(arg_18_0.skillExchangeWnd) then
				arg_18_0.skillExchangeWnd:setVisible(true)
			end
		end)
	elseif arg_18_0.houseType == var_0_7.NOTEBOOK_WND then
		arg_18_0:initNotebookWnd()
		arg_18_0:playMove(true)
	elseif arg_18_0.houseType == var_0_7.TRANSFER_WND then
		arg_18_0:initTransferWnd()
		arg_18_0:playMove(true)
	else
		arg_18_0:playMove(true)
	end
end

function var_0_0.playMove(arg_20_0, arg_20_1, arg_20_2)
	local var_20_0 = arg_20_0:nodeByName("role")
	local var_20_1
	local var_20_2 = 0.5

	if arg_20_1 then
		if arg_20_0.houseType == var_0_7.EXCHANGE_SKILL then
			var_20_1 = cc.p(240.5, 307.5)
		else
			var_20_1 = cc.p(361.5, 307.5)
		end
	else
		var_20_1 = cc.p(598.5, 307.5)
	end

	local var_20_3 = cc.MoveTo:create(var_20_2, var_20_1)

	arg_20_0.isMoving = true

	var_20_0:runActionOnce(var_20_3, false, function()
		arg_20_0.isMoving = false

		if arg_20_1 then
			if arg_20_0.houseType ~= var_0_7.EXCHANGE_SKILL then
				arg_20_0:showDialog(true)
			end

			if arg_20_0.houseType ~= var_0_7.EXCHANGE_SKILL then
				arg_20_0:showDetail(true)
			end
		elseif arg_20_0.houseType ~= var_0_7.BOX_CHECK_WND then
			arg_20_0:showBtn(true)
		end

		if arg_20_2 then
			arg_20_2()
		end
	end)
end

function var_0_0.playReturnHouse(arg_22_0)
	if not arg_22_0.houseType or arg_22_0.houseType == var_0_7.MAIN_WND then
		xyd.WindowManager.get():closeWindow(arg_22_0)

		return
	end

	if arg_22_0.isMoving then
		return
	end

	arg_22_0:showDialog(false)

	if arg_22_0.houseType == var_0_7.BOX_WND then
		if arg_22_0.boxSelectItem and not tolua.isnull(arg_22_0.boxSelectItem) then
			arg_22_0.boxSelectItem:setVisible(false)
		end

		arg_22_0:showBtn(true)
		arg_22_0:nodeByName("txt_title"):setString(var_0_2:translation("ZHUGEJI"))

		arg_22_0.houseType = var_0_7.MAIN_WND
	elseif arg_22_0.houseType == var_0_7.EXCHANGE_SKILL then
		if arg_22_0.skillExchangeWnd and not tolua.isnull(arg_22_0.skillExchangeWnd) then
			arg_22_0.skillExchangeWnd:setVisible(false)
		end

		arg_22_0:playMove(false, function()
			arg_22_0:nodeByName("txt_title"):setString(var_0_2:translation("ZHUGEJI"))

			arg_22_0.houseType = var_0_7.MAIN_WND

			arg_22_0:updateCoin()
			arg_22_0:showBtn(true)
		end)
	elseif arg_22_0.houseType == var_0_7.BOX_CHECK_WND then
		arg_22_0:showDetail(false)
		arg_22_0:playMove(false, function()
			if arg_22_0.boxSelectItem and not tolua.isnull(arg_22_0.boxSelectItem) then
				arg_22_0.boxSelectItem:setVisible(true)
			end

			arg_22_0.houseType = var_0_7.BOX_WND
		end)
	else
		arg_22_0:nodeByName("txt_title"):setString(var_0_2:translation("ZHUGEJI"))
		arg_22_0:showDetail(false)
		arg_22_0:playMove(false)

		arg_22_0.houseType = var_0_7.MAIN_WND
	end
end

function var_0_0.openSelectBox(arg_25_0, arg_25_1, arg_25_2, arg_25_3)
	local var_25_0 = {
		awards = arg_25_1,
		boxType = arg_25_2,
		summonType = arg_25_3
	}

	arg_25_0.backpack = arg_25_0.selfPlayer:getBackpack()

	for iter_25_0 = 1, #arg_25_1 do
		local var_25_1 = arg_25_1[iter_25_0]

		arg_25_0.backpack:addItemsByID(var_25_1.table_id, var_25_1.item_num)
	end

	arg_25_0:updateCoin()

	if #arg_25_1 == 1 then
		xyd.WindowManager.get():openWindow("zhuge_open_box", var_25_0)
	else
		xyd.WindowManager.get():openWindow("zhuge_open_ten_box", var_25_0)
	end
end

function var_0_0.switchSummonType(arg_26_0)
	local var_26_0 = arg_26_0.zhugeModel:getBaseInfo()
	local var_26_1 = var_0_9[var_26_0.summon_type]
	local var_26_2 = xyd.tables.misc.zhugeBoxSwitchAvatar
	local var_26_3 = xyd.tables.model:avatar2(var_26_2[var_26_1])
	local var_26_4 = xyd.AssetLoader.get():loadSprite(var_26_3)

	arg_26_0.tipBg:getChildByName("avatar_pos"):removeAllChildren()
	var_26_4:addTo(arg_26_0.tipBg:getChildByName("avatar_pos"))
	var_26_4:setName("avatar")
	var_26_4:setPosition(cc.p(0, 0))
end

function var_0_0.initBoxWnd(arg_27_0)
	if arg_27_0.boxSelectItem and not tolua.isnull(arg_27_0.boxSelectItem) then
		arg_27_0.boxSelectItem:setVisible(false)

		return
	end

	arg_27_0.boxSelectItem = xyd.AssetLoader.get():loadNodeFromJson("windows/zhugeliang/small_house/box_wnd/box_wnd.csb")

	arg_27_0.boxSelectItem:addTo(arg_27_0:nodeByName("container"))
	arg_27_0.boxSelectItem:setPosition(cc.p(0, 0))
	arg_27_0.boxSelectItem:setName("box_select_item")

	local var_27_0 = arg_27_0.boxSelectItem:getChildByName("container")
	local var_27_1 = var_27_0:getChildByName("white")
	local var_27_2 = var_27_0:getChildByName("black")

	xyd.setItemBorder(var_27_1:getChildByName("item_1"), var_0_5.zhugeBox1Item)
	xyd.setItemBorder(var_27_2:getChildByName("item_2"), var_0_5.zhugeBox2Item)

	arg_27_0.tipBg = var_27_1:getChildByName("tip_bg")

	arg_27_0:switchSummonType()

	local var_27_3 = arg_27_0.selfPlayer:getHeroIgnoreAwaken(10001144)

	if not var_27_3 or var_27_3:getStar() < 3 then
		arg_27_0.tipBg:setVisible(false)
	end

	arg_27_0.tipBg:setTouchEnabled(true)
	arg_27_0.tipBg:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_28_0)
		if arg_28_0.name == "began" then
			-- block empty
		elseif arg_28_0.name == "ended" then
			local var_28_0 = arg_27_0.zhugeModel:getBaseInfo()
			local var_28_1 = {}

			if var_28_0.summon_type == 26 then
				var_28_1.summon_type = 32
			else
				var_28_1.summon_type = 26
			end

			arg_27_0.zhugeModel:changeSummonType(var_28_1, function(arg_29_0, arg_29_1)
				if arg_29_0 == xyd.error.OK then
					var_28_0.summon_type = var_28_1.summon_type

					arg_27_0:switchSummonType()
				end
			end)
		end

		return true
	end)
	var_27_1:getChildByName("btn_white_1"):addTouchEventListener(function(arg_30_0, arg_30_1)
		if arg_30_1 == ccui.TouchEventType.ended then
			local var_30_0 = arg_27_0.zhugeModel:getBaseInfo()

			if arg_27_0.backpack:getItemNumByID(var_0_5.zhugeBoxPartItem) <= 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("ZHUGE_HOUSE_TIPS_20")
				})

				return
			end

			arg_27_0.zhugeModel:summon(var_30_0.summon_type, 1, function(arg_31_0, arg_31_1)
				if arg_31_0 == xyd.error.OK then
					local var_31_0 = {
						itemNum = 1,
						itemID = var_0_5.zhugeBoxPartItem
					}

					arg_27_0.backpack:removeItem(var_31_0)
					arg_27_0:openSelectBox(arg_31_1.awards, "box01", var_30_0.summon_type)
				end
			end)
		end
	end)
	var_27_1:getChildByName("btn_white_10"):addTouchEventListener(function(arg_32_0, arg_32_1)
		if arg_32_1 == ccui.TouchEventType.ended then
			if arg_27_0.backpack:getItemNumByID(var_0_5.zhugeBoxPartItem) < 10 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("ZHUGE_HOUSE_TIPS_20")
				})

				return
			end

			local var_32_0 = arg_27_0.zhugeModel:getBaseInfo()

			arg_27_0.zhugeModel:summon(var_32_0.summon_type, 2, function(arg_33_0, arg_33_1)
				if arg_33_0 == xyd.error.OK then
					local var_33_0 = {
						itemNum = 10,
						itemID = var_0_5.zhugeBoxPartItem
					}

					arg_27_0.backpack:removeItem(var_33_0)
					arg_27_0:openSelectBox(arg_33_1.awards, "box01", var_32_0.summon_type)
				end
			end)
		end
	end)
	var_27_1:getChildByName("btn_white_check"):addTouchEventListener(function(arg_34_0, arg_34_1)
		if arg_34_1 == ccui.TouchEventType.ended then
			arg_27_0.houseType = var_0_7.BOX_CHECK_WND

			arg_27_0.boxSelectItem:setVisible(false)
			arg_27_0:initBoxCheckWnd(xyd.ZhugeBoxType.WHITE)
			arg_27_0:playMove(true, function()
				arg_27_0:showDetail(true, function()
					arg_27_0:nodeByName("detail_container"):getChildByName("box_check_wnd"):updateList()
				end)
			end)
		end
	end)
	var_27_2:getChildByName("btn_black_1"):addTouchEventListener(function(arg_37_0, arg_37_1)
		if arg_37_1 == ccui.TouchEventType.ended then
			if arg_27_0.backpack:getItemNumByID(var_0_5.zhugeBoxPartItem) <= 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("ZHUGE_HOUSE_TIPS_20")
				})

				return
			end

			arg_27_0.zhugeModel:summon(xyd.SummonType.ZhugeBlackBox, 1, function(arg_38_0, arg_38_1)
				if arg_38_0 == xyd.error.OK then
					local var_38_0 = {
						itemNum = 1,
						itemID = var_0_5.zhugeBoxPartItem
					}

					arg_27_0.backpack:removeItem(var_38_0)
					arg_27_0:openSelectBox(arg_38_1.awards, "box02", xyd.SummonType.ZhugeBlackBox)
				end
			end)
		end
	end)
	var_27_2:getChildByName("btn_black_10"):addTouchEventListener(function(arg_39_0, arg_39_1)
		if arg_39_1 == ccui.TouchEventType.ended then
			if arg_27_0.backpack:getItemNumByID(var_0_5.zhugeBoxPartItem) < 10 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("ZHUGE_HOUSE_TIPS_20")
				})

				return
			end

			arg_27_0.zhugeModel:summon(xyd.SummonType.ZhugeBlackBox, 2, function(arg_40_0, arg_40_1)
				if arg_40_0 == xyd.error.OK then
					local var_40_0 = {
						itemNum = 10,
						itemID = var_0_5.zhugeBoxPartItem
					}

					arg_27_0.backpack:removeItem(var_40_0)
					arg_27_0:openSelectBox(arg_40_1.awards, "box02", xyd.SummonType.ZhugeBlackBox)
				end
			end)
		end
	end)
	var_27_2:getChildByName("btn_black_check"):addTouchEventListener(function(arg_41_0, arg_41_1)
		if arg_41_1 == ccui.TouchEventType.ended then
			arg_27_0.houseType = var_0_7.BOX_CHECK_WND

			arg_27_0.boxSelectItem:setVisible(false)
			arg_27_0:initBoxCheckWnd(xyd.ZhugeBoxType.BLACK)
			arg_27_0:playMove(true, function()
				arg_27_0:showDetail(true, function()
					arg_27_0:nodeByName("detail_container"):getChildByName("box_check_wnd"):updateList()
				end)
			end)
		end
	end)
	arg_27_0.boxSelectItem:setVisible(false)
end

function var_0_0.initBoxCheckWnd(arg_44_0, arg_44_1)
	local var_44_0 = arg_44_0.zhugeModel:getBaseInfo()
	local var_44_1 = arg_44_0:nodeByName("detail_container")

	var_44_1:removeAllChildren()

	local var_44_2 = import("app.windows.ZhugeBoxCheckItem").new()
	local var_44_3 = {
		boxType = arg_44_1,
		idx = var_0_9[var_44_0.summon_type]
	}

	var_44_2:setParams(var_44_3)
	var_44_2:addTo(var_44_1)
	var_44_2:setPosition(cc.p(0, 0))
	var_44_2:setName("box_check_wnd")
	var_44_1:setVisible(false)
end

function var_0_0.showDetail(arg_45_0, arg_45_1, arg_45_2)
	local var_45_0 = arg_45_0:nodeByName("detail_container")
	local var_45_1
	local var_45_2 = 0.2

	if arg_45_1 then
		var_45_0:setVisible(true)
		var_45_0:setScale(0)

		var_45_1 = cc.EaseBackOut:create(cc.ScaleTo:create(var_45_2, 1))
	else
		var_45_1 = cc.EaseBackIn:create(cc.ScaleTo:create(var_45_2, 0))
	end

	var_45_0:runActionOnce(var_45_1, false, arg_45_2)
end

function var_0_0.initNotebookWnd(arg_46_0)
	local var_46_0 = arg_46_0.zhugeModel:getBaseInfo()
	local var_46_1 = var_46_0.missions
	local var_46_2 = var_46_0.is_awarded
	local var_46_3 = var_46_0.day_count

	if not var_46_1 or not next(var_46_1) then
		return
	end

	local var_46_4 = arg_46_0:nodeByName("detail_container")

	var_46_4:removeAllChildren()

	local var_46_5 = xyd.AssetLoader.get():loadNodeFromJson("windows/zhugeliang/small_house/notebook_item.csb")

	var_46_5:addTo(var_46_4)
	arg_46_0:nodeByName("txt_title"):setString(var_0_2:translation("ZHUGEJI_SHENMIBIJI"))

	local var_46_6 = var_46_5:getChildByName("container")

	var_46_6:getChildByName("text_left_count"):setString(var_0_2:translation("ZHUGE_ADVENTURE_TIPS_26"))

	local var_46_7 = var_46_6:getChildByName("btn_get")

	var_46_7:addTouchEventListener(function(arg_47_0, arg_47_1)
		if arg_47_1 == ccui.TouchEventType.ended then
			xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):getActivityReward(xyd.Activities.ZhugeFestival, nil, function(arg_48_0, arg_48_1)
				if arg_48_0 == xyd.error.OK then
					if arg_48_1 and arg_48_1.awards then
						arg_46_0.selfPlayer:handleRewards(arg_48_1.awards)
					end

					var_46_6:getChildByName("lingqu"):setVisible(false)
					var_46_6:getChildByName("already_get_gray"):setVisible(true)
					var_46_6:getChildByName("get_gray"):setVisible(false)
					var_46_7:setTouchEnabled(false)
					var_46_7:setBright(false)
					arg_46_0:updateCoin()
				end
			end)
		end
	end)

	local var_46_8 = var_46_6:getChildByName("list"):getContentSize().height - 80
	local var_46_9 = xyd.tables.zhugeNoteMission:ids()
	local var_46_10 = 1
	local var_46_11 = true

	for iter_46_0 = 1, #var_46_9 do
		local var_46_12 = var_46_9[iter_46_0]
		local var_46_13 = xyd.tables.zhugeNoteMission:desc(var_46_12)
		local var_46_14 = xyd.tables.zhugeNoteMission:req(var_46_12)[var_46_3] or 0
		local var_46_15 = var_46_1[iter_46_0]

		if var_46_14 > 0 and var_46_15 < var_46_14 then
			var_46_11 = false
		end

		if var_46_14 > 0 then
			local var_46_16 = xyd.AssetLoader.get():loadNodeFromJson("windows/zhugeliang/small_house/mission_item.csb")

			var_46_16:addTo(var_46_6:getChildByName("list"))
			var_46_16:setPosition(cc.p(0, var_46_8))

			var_46_8 = var_46_8 - 75

			var_46_16:getChildByName("text_desc"):setString(var_46_10 .. ". " .. string.format(var_46_13, var_46_14))

			local var_46_17 = var_46_16:getChildByName("text_desc"):getContentSize().width

			var_46_16:getChildByName("select"):setVisible(var_46_14 <= var_46_15)
			var_46_16:getChildByName("select"):setPositionX(var_46_17 + 40)

			local var_46_18 = string.format(var_0_2:translation("ZHUGE_ADVENTURE_TIPS_25"), var_46_15, var_46_14)

			var_46_16:getChildByName("text_tips"):setString(var_46_18)

			var_46_10 = var_46_10 + 1
		end
	end

	if var_46_2 == 1 then
		var_46_6:getChildByName("lingqu"):setVisible(false)
		var_46_6:getChildByName("already_get_gray"):setVisible(true)
		var_46_6:getChildByName("get_gray"):setVisible(false)
		var_46_7:setTouchEnabled(false)
		var_46_7:setBright(false)
	else
		var_46_6:getChildByName("already_get_gray"):setVisible(false)

		if var_46_11 then
			var_46_6:getChildByName("lingqu"):setVisible(true)
			var_46_6:getChildByName("get_gray"):setVisible(false)
		else
			var_46_6:getChildByName("lingqu"):setVisible(false)
			var_46_6:getChildByName("get_gray"):setVisible(true)
			var_46_7:setTouchEnabled(false)
			var_46_7:setBright(false)
		end
	end
end

function var_0_0.initTransferWnd(arg_49_0)
	local var_49_0 = arg_49_0:nodeByName("detail_container")

	var_49_0:removeAllChildren()

	local var_49_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/zhugeliang/small_house/transfer_item.csb")

	var_49_1:addTo(var_49_0)
	arg_49_0:nodeByName("txt_title"):setString(var_0_2:translation("ZHUGEJI_CHUANSONGZHUANGZHI"))

	local var_49_2 = var_49_1:getChildByName("container")

	var_49_2:getChildByName("text_title"):setString(var_0_2:translation("ZHUGE_HOUSE_TIPS_10"))

	local var_49_3 = var_0_5.zhugeTeleportBattle

	var_49_2:getChildByName("btn_go"):addTouchEventListener(function(arg_50_0, arg_50_1)
		if arg_50_1 == ccui.TouchEventType.ended then
			local var_50_0 = arg_49_0.zhugeModel:getLocalBossInfo()
			local var_50_1 = arg_49_0.backpack:getItemNumByID(var_0_5.zhugeTeleportItem)

			if var_50_0.free_times <= 0 and var_50_1 <= 0 then
				local var_50_2 = var_0_2:translation("ZHUGE_FOREST_TIPS_32")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_50_2
				})

				return
			end

			if var_50_0.free_times <= 0 then
				arg_49_0.zhugeModel:setDeleteBossItem(true)
			else
				arg_49_0.zhugeModel:setDeleteBossItem(false)
			end

			if var_50_0.cur_damage == 0 then
				arg_49_0:playStory(function()
					local var_51_0 = {
						enemyType = xyd.ZhugeHouseEnemy.ZHUGE_BOSS,
						battleID = var_49_3
					}

					xyd.WindowManager.get():openWindow("zhuge_enemy_wnd", var_51_0)
				end)
			else
				local var_50_3 = {
					enemyType = xyd.ZhugeHouseEnemy.ZHUGE_BOSS,
					battleID = var_49_3
				}

				xyd.WindowManager.get():openWindow("zhuge_enemy_wnd", var_50_3)
			end
		end
	end)

	local var_49_4 = arg_49_0.zhugeModel:getLocalBossInfo()
	local var_49_5 = var_49_4.cur_damage
	local var_49_6 = var_49_4.free_times
	local var_49_7 = var_49_4.is_passed
	local var_49_8 = var_49_4.total_hp
	local var_49_9 = math.floor(var_49_5 / var_49_8 * 100)

	if var_49_9 > 100 then
		var_49_9 = 100
	end

	var_49_2:getChildByName("bar"):setPercent(var_49_9)
	var_49_2:getChildByName("text_progress"):setString(var_49_9 .. "%")

	if var_49_6 ~= 0 then
		var_49_2:getChildByName("text_item_num"):setString(var_0_2:translation("ZHUGE_HOUSE_TIPS_11") .. var_49_6)
	else
		local var_49_10 = arg_49_0.backpack:getItemNumByID(var_0_5.zhugeTeleportItem)

		var_49_2:getChildByName("text_item_num"):setString(var_0_2:translation("ZHUGE_HOUSE_TIPS_12") .. var_49_10)
	end

	if var_49_7 == 1 then
		var_49_2:getChildByName("btn_go"):setTouchEnabled(false)
		var_49_2:getChildByName("btn_go"):setBright(false)
	end

	if xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):isZhugeActivityShow() == 1 then
		var_49_2:getChildByName("btn_go"):setTouchEnabled(false)
		var_49_2:getChildByName("btn_go"):setBright(false)
	end
end

function var_0_0.getDialog(arg_52_0)
	local var_52_0 = ""

	if arg_52_0.houseType == var_0_7.BOX_WND then
		local var_52_1 = arg_52_0.backpack:getItemNumByID(var_0_5.zhugeBoxPartItem)

		var_52_0 = string.format(var_0_2:translation("ZHUGE_HOUSE_DIALOG_2"), var_52_1)
	elseif arg_52_0.houseType == var_0_7.BOX_CHECK_WND then
		var_52_0 = var_0_2:translation("ZHUGE_HOUSE_DIALOG_3")
	elseif arg_52_0.houseType == var_0_7.NOTEBOOK_WND then
		var_52_0 = var_0_2:translation("ZHUGE_HOUSE_DIALOG_4")
	elseif arg_52_0.houseType == var_0_7.TRANSFER_WND then
		local var_52_2 = arg_52_0.zhugeModel:getLocalBossInfo()

		if var_52_2.cur_damage == var_52_2.total_hp then
			var_52_0 = var_0_2:translation("ZHUGE_HOUSE_DIALOG_6")
		else
			var_52_0 = var_0_2:translation("ZHUGE_HOUSE_DIALOG_5")
		end
	elseif arg_52_0.houseType == var_0_7.EXCHANGE_SKILL then
		var_52_0 = var_0_2:translation("ZHUGE_HOUSE_DIALOG_7")
	else
		var_52_0 = var_0_2:translation("ZHUGE_HOUSE_DIALOG_1")
	end

	return var_52_0
end

function var_0_0.speak(arg_53_0, arg_53_1, arg_53_2, arg_53_3, arg_53_4)
	local var_53_0 = xyd.utf8len(arg_53_1)

	arg_53_0.isOnSpeaking = true

	local var_53_1 = 0

	if arg_53_0.speakHandler then
		var_0_3.unscheduleGlobal(arg_53_0.speakHandler)

		arg_53_0.speakHandler = nil
	end

	arg_53_0.speakHandler = var_0_3.scheduleGlobal(function()
		var_53_1 = var_53_1 + 1

		if var_53_1 > var_53_0 and arg_53_0.speakHandler or arg_53_0.showInOneTime == true then
			if not tolua.isnull(arg_53_2) then
				arg_53_2:setString(arg_53_1)
			end

			var_0_3.unscheduleGlobal(arg_53_0.speakHandler)

			arg_53_0.isOnSpeaking = false

			if arg_53_4 then
				arg_53_4()
			end

			return
		end

		local var_54_0 = xyd.getSplitUtf8Str(arg_53_1, 0, var_53_1 * 3)

		if not tolua.isnull(arg_53_2) then
			arg_53_2:setString(var_54_0)
		end
	end, arg_53_3)
end

function var_0_0.playStory(arg_55_0, arg_55_1)
	local var_55_0 = {
		talk_id = "zhuge03",
		callback = function()
			if arg_55_1 then
				arg_55_1()
			end
		end
	}

	xyd.WindowManager.get():openWindow("school_story_talk", var_55_0)
end

function var_0_0.initDialogClick(arg_57_0)
	if not arg_57_0.dialogClickNode then
		arg_57_0.dialogClickNode = display.newNode()

		arg_57_0.dialogClickNode:setContentSize(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT)
		arg_57_0.dialogClickNode:setTouchEnabled(true)
		arg_57_0.dialogClickNode:setTouchSwallowEnabled(false)
		arg_57_0.dialogClickNode:addTo(arg_57_0)
	end

	arg_57_0.dialogClickNode:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_58_0)
		if arg_58_0.name == "began" then
			-- block empty
		elseif arg_58_0.name == "ended" then
			arg_57_0:showDialog(false)
		end

		return true
	end)
end

function var_0_0.initExchangeWnd(arg_59_0)
	if arg_59_0.skillExchangeWnd and not tolua.isnull(arg_59_0.skillExchangeWnd) then
		arg_59_0.skillExchangeWnd:setVisible(false)

		return
	end

	arg_59_0.skillExchangeWnd = xyd.AssetLoader.get():loadNodeFromJson("windows/zhugeliang/small_house/skill_exchange.csb")

	arg_59_0.skillExchangeWnd:addTo(arg_59_0:nodeByName("container"))
	arg_59_0.skillExchangeWnd:setPosition(cc.p(351, 29))
	arg_59_0.skillExchangeWnd:setName("skill_exchange")
	arg_59_0:nodeByName("txt_title"):setString(var_0_2:translation("ZHUGEJI_DUIHUANJIANGLI"))

	arg_59_0.scroll = arg_59_0.skillExchangeWnd:getChildByName("container"):getChildByName("list")

	local var_59_0 = arg_59_0.scroll:getContentSize()

	arg_59_0.exchangeList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_59_0.width, var_59_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_59_0.scroll):onScroll(handler(arg_59_0, arg_59_0.scrollListener))

	arg_59_0.exchangeList:setDelegate(handler(arg_59_0, arg_59_0.exchangeListDelegate))
	arg_59_0.exchangeList:setTouchType(false)
	arg_59_0.exchangeList:reload()
end

function var_0_0.exchangeListDelegate(arg_60_0, arg_60_1, arg_60_2, arg_60_3)
	local var_60_0 = arg_60_0:filteredIds()

	if cc.ui.UIListView.COUNT_TAG == arg_60_2 then
		return math.ceil(#var_60_0 / var_0_6)
	elseif cc.ui.UIListView.CELL_TAG == arg_60_2 then
		local var_60_1
		local var_60_2 = arg_60_0.exchangeList:dequeueItem()

		if not var_60_2 then
			var_60_2 = arg_60_0.exchangeList:newItem()
		else
			var_60_2:removeAllChildren(true)
		end

		local var_60_3 = display.newNode()
		local var_60_4 = arg_60_0.exchangeList:getViewRect().width
		local var_60_5

		for iter_60_0 = 1, var_0_6 do
			local var_60_6 = (arg_60_3 - 1) * var_0_6 + iter_60_0

			if not var_60_0[var_60_6] then
				break
			end

			local var_60_7 = arg_60_0:createListContent(var_60_0[var_60_6])

			var_60_7:setPosition(215 * (iter_60_0 - 1), 0)

			var_60_5 = var_60_5 or var_60_7:getContentSize().height

			var_60_3:addChild(var_60_7)
		end

		var_60_3:setContentSize(var_60_4, var_60_5)
		var_60_2:setItemSize(var_60_4, var_60_5 + 10)
		var_60_2:addContent(var_60_3)

		return var_60_2
	end
end

function var_0_0.filteredIds(arg_61_0)
	local var_61_0 = arg_61_0.selfPlayer:getHeroIgnoreAwaken(10001144)
	local var_61_1 = arg_61_0.selfPlayer:getHeroIgnoreAwaken(10001242)
	local var_61_2 = arg_61_0.selfPlayer:getHeroIgnoreAwaken(10001200)
	local var_61_3 = {}

	if var_61_1 or not var_61_0 or var_61_0:getStar() < 3 then
		table.insert(var_61_3, 1)
	end

	local var_61_4 = {}

	for iter_61_0, iter_61_1 in pairs(var_0_4:ids()) do
		if not xyd.isInTable(var_61_3, iter_61_1) then
			table.insert(var_61_4, iter_61_1)
		end
	end

	return var_61_4
end

function var_0_0.createListContent(arg_62_0, arg_62_1)
	local var_62_0 = display.newNode()
	local var_62_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/zhugeliang/small_house/skill_exchange_item.csb")
	local var_62_2 = var_62_1:getChildByName("container")

	var_62_2:getChildByName("own_text"):setString(var_0_2:translation("MULTISKIN_OWN_TEXT"))

	local var_62_3 = var_0_4:giftID(arg_62_1)
	local var_62_4 = xyd.tables.gift:items(var_62_3)[1]
	local var_62_5 = xyd.tables.gift:itemNum(var_62_3)[1]
	local var_62_6 = arg_62_0.backpack:getItemNumByID(var_62_4)

	if var_0_4:buyLimit(arg_62_1) > 0 and var_62_6 > 0 then
		var_62_2:getChildByName("btn_exchange"):setVisible(false)
		var_62_2:getChildByName("text_exchange"):setVisible(false)
	end

	local var_62_7 = arg_62_0:checkIsLock(var_0_4:condition(arg_62_1))

	if var_62_7 then
		local var_62_8 = var_0_4:conditionDesc(arg_62_1)

		var_62_2:getChildByName("mask"):setVisible(true)
		var_62_2:getChildByName("mask"):getChildByName("txt_lock"):setString(var_62_8)
	end

	local var_62_9 = var_0_4:price(arg_62_1)

	var_62_2:getChildByName("text_cost"):setString(var_62_9)
	var_62_2:getChildByName("text_name"):setString(xyd.tables.item:name(var_62_4))

	if not var_62_7 then
		var_62_2:getChildByName("btn_exchange"):addTouchEventListener(function(arg_63_0, arg_63_1)
			if arg_63_1 == ccui.TouchEventType.ended then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, xyd.tables.translation:translation("ADVENTURE_GIFT_BUY_CHOOSE"), function()
					if arg_62_0.backpack:getItemNumByID(var_0_5.zhugeTeleportItem) < var_62_9 then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_2:translation("ZHUGE_ADVENTURE_TIPS_30")
						})

						return
					end

					arg_62_0.zhugeModel:exchangeSkillBook(arg_62_1, function(arg_65_0, arg_65_1)
						if arg_65_0 == xyd.error.OK then
							local var_65_0 = {
								itemID = var_0_5.zhugeTeleportItem,
								itemNum = var_62_9
							}

							arg_62_0.backpack:removeItem(var_65_0)

							if arg_65_1 and arg_65_1.awards then
								arg_62_0.selfPlayer:handleRewards(arg_65_1.awards)
							end

							arg_62_0:updateCoin()
							arg_62_0.exchangeList:refreshList(0)
						end
					end)
				end, nil, nil, arg_62_0.colorMode)
			end
		end)
	end

	if var_62_4 >= 50000001 and var_62_4 <= 50000025 then
		xyd.setItemBorder(var_62_2:getChildByName("item"), var_62_4, nil, nil, var_62_5)

		local var_62_10 = xyd.tables.item:skillId(var_62_4)

		if var_62_10 and var_62_10 > 0 then
			local var_62_11 = {
				has_jiantou = false,
				id = var_62_10
			}
			local var_62_12 = var_62_2:getChildByName("item")

			var_62_12:setTouchEnabled(true)
			var_62_12:addTouchEventListener(function(arg_66_0, arg_66_1)
				if arg_66_1 == ccui.TouchEventType.began then
					if not xyd.WindowManager.get():getWindow("skill_tips") then
						local var_66_0 = xyd.WindowManager.get():openWindow("skill_tips", var_62_11)

						xyd.adaptToWorldPosition(var_62_12, var_66_0)
					end

					return true
				elseif arg_66_1 == ccui.TouchEventType.ended then
					xyd.WindowManager.get():closeWindow("skill_tips")
				end
			end)
		end
	else
		xyd.setItemAndAddTips(var_62_2:getChildByName("item"), var_62_4, var_62_5)
	end

	var_62_1:addTo(var_62_0)
	var_62_1:setAnchorPoint(cc.p(0, 0))
	var_62_0:setContentSize(var_62_2:getContentSize())
	var_62_1:setName("source")

	return var_62_0
end

function var_0_0.checkIsLock(arg_67_0, arg_67_1)
	if arg_67_1 == 0 then
		return false
	elseif arg_67_1 == 1 then
		local var_67_0 = arg_67_0.selfPlayer:getHeroIgnoreAwaken(10001144)

		if var_67_0 and var_67_0:getStar() >= 3 then
			return false
		else
			return true
		end
	elseif arg_67_1 == 2 then
		if arg_67_0.selfPlayer:getHeroIgnoreAwaken(10001242) then
			return false
		else
			return true
		end
	elseif arg_67_1 == 3 then
		local var_67_1 = arg_67_0.selfPlayer:getHeroIgnoreAwaken(10001200)

		if var_67_1 and var_67_1:getStar() >= 3 then
			return false
		else
			return true
		end
	elseif arg_67_1 == 4 then
		local var_67_2 = arg_67_0.selfPlayer:getHeroIgnoreAwaken(10001200)

		if var_67_2 and var_67_2:isAwaken() then
			return false
		else
			return true
		end
	elseif arg_67_1 == 5 then
		local var_67_3 = arg_67_0.selfPlayer:getHeroIgnoreAwaken(10001144)

		if var_67_3 and var_67_3:getStar() >= 5 then
			return false
		else
			return true
		end
	elseif arg_67_1 == 6 then
		local var_67_4 = arg_67_0.backpack:getItemNumByID(230001006)

		if var_67_4 and var_67_4 > 0 then
			return false
		else
			return true
		end
	elseif arg_67_1 == 7 then
		local var_67_5 = arg_67_0.backpack:getItemNumByID(230001009)

		if var_67_5 and var_67_5 > 0 then
			return false
		else
			return true
		end
	end
end

function var_0_0.scrollListener(arg_68_0, arg_68_1)
	if arg_68_1.name == "began" then
		arg_68_0.scrollViewMoved_ = false
		arg_68_0.prevX_ = arg_68_1.x
	elseif arg_68_1.name == "moved" and 5 <= math.abs(arg_68_1.x - arg_68_0.prevX_) then
		arg_68_0.scrollViewMoved_ = true
	end
end

return var_0_0
