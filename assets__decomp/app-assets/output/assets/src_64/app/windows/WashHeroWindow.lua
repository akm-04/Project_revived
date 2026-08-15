local var_0_0 = class("WashHeroWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = import("app.windows.EquipItem")
local var_0_4 = require("framework.scheduler")
local var_0_5 = xyd.tables.attr
local var_0_6 = xyd.tables.hero

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)

	function returnback(...)
		xyd.WindowManager.get():closeWindow(arg_2_0)
	end

	arg_2_0:addTopSidebar({
		show_rule = 1,
		callback = function()
			if arg_2_0:alertCloseOrSwitch(returnback) then
				xyd.WindowManager.get():closeWindow(arg_2_0)
			end
		end
	})
	arg_2_0:initData()
	arg_2_0:initLayout()
	arg_2_0:initPracticeInfo()
	arg_2_0:addBtnListener()
	arg_2_0:randomDialog()
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	var_0_0.super.didOpen(arg_5_0, arg_5_1)
	arg_5_0:addBlockLayer()
	arg_5_0:addTopSidebar()
end

function var_0_0.initData(arg_6_0)
	arg_6_0.baseMana = 0
	arg_6_0.baseCrystal = 0
	arg_6_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_6_0.practiceType = xyd.WashWay.NORMAL
	arg_6_0.locks = {
		0,
		0,
		0
	}
end

function var_0_0.initLayout(arg_7_0)
	arg_7_0.attrIcons = {}
	arg_7_0.attrTxts = {}
	arg_7_0.arrows = {}
	arg_7_0.attrValues = {}
	arg_7_0.lockUnselecteds = {}
	arg_7_0.lockSelecteds = {}
	arg_7_0.fullTxts = {}
	arg_7_0.newValues = {}
	arg_7_0.changeValues = {}
	arg_7_0.awardTxts = {}
	arg_7_0.needTxts = {}
	arg_7_0.whitePoints = {}
	arg_7_0.greenPoints = {}
	arg_7_0.ishero = false
	arg_7_0.ispet = false

	for iter_7_0 = 1, 3 do
		local var_7_0 = arg_7_0:nodeByName("attr_icon" .. iter_7_0)

		var_7_0:setVisible(false)

		local var_7_1 = arg_7_0:nodeByName("attr_txt" .. iter_7_0)

		var_7_1:setString(var_0_5:name(iter_7_0))

		local var_7_2 = arg_7_0:nodeByName("arrow" .. iter_7_0)
		local var_7_3 = arg_7_0:nodeByName("attr_value" .. iter_7_0)

		var_7_3:setString("")

		local var_7_4 = arg_7_0:nodeByName("lock_unselected" .. iter_7_0)
		local var_7_5 = arg_7_0:nodeByName("lock_selected" .. iter_7_0)
		local var_7_6 = arg_7_0:nodeByName("full_txt" .. iter_7_0)

		var_7_6:setString(var_0_1:translation("WASH_FULL"))

		local var_7_7 = arg_7_0:nodeByName("new_value" .. iter_7_0)

		var_7_7:setString("")

		local var_7_8 = arg_7_0:nodeByName("change_value" .. iter_7_0)

		var_7_8:setString("")

		local var_7_9 = arg_7_0:nodeByName("award_txt" .. iter_7_0)
		local var_7_10 = arg_7_0:nodeByName("need_txt" .. iter_7_0)
		local var_7_11 = arg_7_0:nodeByName("green_point" .. iter_7_0)
		local var_7_12 = arg_7_0:nodeByName("white_point" .. iter_7_0)

		table.insert(arg_7_0.attrIcons, var_7_0)
		table.insert(arg_7_0.attrTxts, var_7_1)
		table.insert(arg_7_0.arrows, var_7_2)
		table.insert(arg_7_0.attrValues, var_7_3)
		table.insert(arg_7_0.lockUnselecteds, var_7_4)
		table.insert(arg_7_0.lockSelecteds, var_7_5)
		table.insert(arg_7_0.fullTxts, var_7_6)
		table.insert(arg_7_0.newValues, var_7_7)
		table.insert(arg_7_0.changeValues, var_7_8)
		table.insert(arg_7_0.awardTxts, var_7_9)
		table.insert(arg_7_0.needTxts, var_7_10)
		table.insert(arg_7_0.greenPoints, var_7_11)
		table.insert(arg_7_0.whitePoints, var_7_12)
	end

	arg_7_0.nameBg = arg_7_0:nodeByName("name_bg")

	arg_7_0:nodeByName("xuanzhe_heroname"):setString(var_0_1:translation("SELECT_HERO"))

	arg_7_0.zhuanJiaTxt = arg_7_0:nodeByName("zhuanjia_txt")

	arg_7_0.zhuanJiaTxt:setString(xyd.tables.practiceType:getStyleName(xyd.WashWay.ZHUANJIA))

	arg_7_0.daShiTxt = arg_7_0:nodeByName("dashi_txt")

	arg_7_0.daShiTxt:setString(xyd.tables.practiceType:getStyleName(xyd.WashWay.DASHI))
	arg_7_0:nodeByName("switch_txt"):setString(var_0_1:translation("SWITCH_HERO"))
	arg_7_0:nodeByName("switch_pet_txt"):setString(var_0_1:translation("SWITCH_PET"))
	arg_7_0:nodeByName("auto_txt"):setString(var_0_1:translation("AUTO_WASH_TXT"))

	arg_7_0.daShiSelected = arg_7_0:nodeByName("dashi_selected")
	arg_7_0.daShiUnselected = arg_7_0:nodeByName("dashi_unselected")
	arg_7_0.daShiBg = arg_7_0:nodeByName("dashi_bg")
	arg_7_0.zhuanJiaSelected = arg_7_0:nodeByName("zhuanjia_selected")
	arg_7_0.zhuanJiaUnselected = arg_7_0:nodeByName("zhuanjia_unselected")
	arg_7_0.zhuanJiaBg = arg_7_0:nodeByName("zhuanjia_bg")
	arg_7_0.saveBtn = arg_7_0:nodeByName("save_btn")

	arg_7_0.saveBtn:setVisible(false)

	arg_7_0.saveTxt = arg_7_0:nodeByName("save_txt")

	arg_7_0.saveTxt:setVisible(false)
	arg_7_0.saveTxt:setString(var_0_1:translation("SAVE_TXT"))

	arg_7_0.washBtn = arg_7_0:nodeByName("wash_btn")
	arg_7_0.washTxt = arg_7_0:nodeByName("wash_txt")

	arg_7_0.washTxt:setString(var_0_1:translation("WASH_TXT"))

	arg_7_0.redoTxt = arg_7_0:nodeByName("redo_txt")

	arg_7_0.redoTxt:setString(var_0_1:translation("REDO_TXT"))
	arg_7_0.redoTxt:setVisible(false)
	arg_7_0.washTxt:setVisible(false)

	arg_7_0.duiHua = arg_7_0:nodeByName("duihua")

	arg_7_0:updateDialog(var_0_1:translation("SEND_PRACTICE_TIP2"), 10)

	arg_7_0.costNum = arg_7_0:nodeByName("cost_num")
	arg_7_0.timeTxt = arg_7_0:nodeByName("time_txt")

	arg_7_0.timeTxt:setVisible(false)

	arg_7_0.blessTxt = arg_7_0:nodeByName("bless_txt")

	arg_7_0.blessTxt:setVisible(false)

	arg_7_0.jinbi = arg_7_0:nodeByName("jinbi")
	arg_7_0.yuanbao = arg_7_0:nodeByName("yuanbao")

	arg_7_0.yuanbao:setVisible(false)
	arg_7_0.costNum:setString("")
	arg_7_0:nodeByName("practice_container"):setVisible(false)
	arg_7_0:nodeByName("attr_container"):setVisible(false)
	arg_7_0:nodeByName("award_container"):setVisible(false)

	arg_7_0.isTicket = false

	if arg_7_0.isTicket then
		arg_7_0:nodeByName("money_selected"):setVisible(false)
		arg_7_0:nodeByName("ticket_selected"):setVisible(true)
	else
		arg_7_0:nodeByName("money_selected"):setVisible(true)
		arg_7_0:nodeByName("ticket_selected"):setVisible(false)
	end

	local var_7_13 = arg_7_0:nodeByName("touxiang")
	local var_7_14 = "windows/fumo_window/bg_touxiang.png"
	local var_7_15 = xyd.AssetLoader.get():loadSprite(var_7_14)

	var_7_15:setAnchorPoint(cc.p(0, 0))
	var_7_13:addChild(var_7_15)
	var_7_15:setTouchEnabled(true)
	var_7_15:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
		if arg_8_0.name == "began" then
			return true
		elseif arg_8_0.name == "ended" then
			xyd.WindowManager.get():openWindow("wash_select_hero")
		end
	end)

	local var_7_16 = arg_7_0:nodeByName("wenhao")
	local var_7_17 = "windows/wash/icon_wenhao.png"
	local var_7_18 = xyd.AssetLoader.get():loadSprite(var_7_17)

	var_7_18:setAnchorPoint(cc.p(0, 0))
	var_7_16:addChild(var_7_18)

	arg_7_0.rule_btn = arg_7_0:nodeByName("top_sidebar"):nodeByName("rule")

	xyd.addTouchEvent(arg_7_0.rule_btn, function(arg_9_0, arg_9_1)
		local var_9_0 = {}

		var_9_0.title_name = "MAGIC_LAB_RULE_TITLE"
		var_9_0.rule = "MAGIC_LAB_RULE"
		var_9_0.style = xyd.RuleStyle.GREEN

		print(var_9_0.rule)
		xyd.WindowManager.get():openWindow("new_text_rule", var_9_0)
	end)
end

function var_0_0.updateSelectTicket(arg_10_0)
	if arg_10_0.isTicket then
		arg_10_0:nodeByName("money_selected"):setVisible(false)
		arg_10_0:nodeByName("ticket_selected"):setVisible(true)

		arg_10_0.practiceType = xyd.WashWay.DASHI

		for iter_10_0 = 1, 3 do
			arg_10_0.locks[iter_10_0] = 1

			arg_10_0:isSelected(false, iter_10_0)
		end
	else
		arg_10_0:nodeByName("money_selected"):setVisible(true)
		arg_10_0:nodeByName("ticket_selected"):setVisible(false)

		arg_10_0.practiceType = xyd.WashWay.NORMAL

		for iter_10_1 = 1, 3 do
			arg_10_0.locks[iter_10_1] = 0

			arg_10_0:isSelected(true, iter_10_1)
		end
	end
end

function var_0_0.updateDialog(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = {
		size = 24,
		color = cc.c3b(255, 255, 255)
	}
	local var_11_1 = xyd.AssetLoader:get():loadLabel(var_11_0)

	var_11_1:setMaxLineWidth(300)
	var_11_1:setString(arg_11_1)
	var_11_1:setPosition(0, arg_11_2)
	var_11_1:setAnchorPoint(0, 0)
	arg_11_0.duiHua:removeAllChildren()
	arg_11_0.duiHua:addChild(var_11_1)
end

function var_0_0.isSelected(arg_12_0, arg_12_1, arg_12_2)
	arg_12_0.lockUnselecteds[arg_12_2]:setVisible(arg_12_1)
	arg_12_0.lockUnselecteds[arg_12_2]:setTouchEnabled(arg_12_1)
	arg_12_0.lockSelecteds[arg_12_2]:setVisible(not arg_12_1)
	arg_12_0.lockSelecteds[arg_12_2]:setTouchEnabled(not arg_12_1)
	arg_12_0:updateConsume()
end

function var_0_0.addBtnListener(arg_13_0)
	arg_13_0:nodeByName("switch_btn"):addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.began then
			arg_13_0:nodeByName("switch_btn"):setScale(0.9)
		end

		if arg_14_1 == ccui.TouchEventType.moved then
			arg_13_0:nodeByName("switch_btn"):setScale(1)
		end

		if arg_14_1 == ccui.TouchEventType.ended then
			arg_13_0:nodeByName("switch_btn"):setScale(1)

			local function var_14_0()
				arg_13_0.changeAttrs = nil

				if arg_13_0.hero then
					arg_13_0:updatePracticeInfos()
					arg_13_0:updateHeroAttrInfos()
				end

				xyd.WindowManager.get():openWindow("wash_select_hero")
			end

			if arg_13_0:alertCloseOrSwitch(var_14_0) then
				var_14_0()
			end
		end
	end)
	arg_13_0:nodeByName("switch_pet_btn"):addTouchEventListener(function(arg_16_0, arg_16_1)
		if arg_16_1 == ccui.TouchEventType.began then
			arg_13_0:nodeByName("switch_pet_btn"):setScale(0.9)
		end

		if arg_16_1 == ccui.TouchEventType.moved then
			arg_13_0:nodeByName("switch_pet_btn"):setScale(1)
		end

		if arg_16_1 == ccui.TouchEventType.ended then
			arg_13_0:nodeByName("switch_pet_btn"):setScale(1)

			local function var_16_0()
				arg_13_0.changeAttrs = nil

				if arg_13_0.hero then
					arg_13_0:updatePracticeInfos()
					arg_13_0:updateHeroAttrInfos()
				end

				xyd.WindowManager.get():openWindow("wash_select_pet")
			end

			if arg_13_0:alertCloseOrSwitch(var_16_0) then
				var_16_0()
			end
		end
	end)
	arg_13_0:nodeByName("auto_btn"):addTouchEventListener(function(arg_18_0, arg_18_1)
		if arg_18_1 == ccui.TouchEventType.began then
			arg_13_0:nodeByName("auto_btn"):setScale(0.9)
		end

		if arg_18_1 == ccui.TouchEventType.moved then
			arg_13_0:nodeByName("auto_btn"):setScale(1)
		end

		if arg_18_1 == ccui.TouchEventType.ended then
			arg_13_0:nodeByName("auto_btn"):setScale(1)

			if not arg_13_0.hero then
				local var_18_0 = var_0_1:translation("WASH_AUTO_TIPS")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_18_0
				})

				return
			end

			local function var_18_1()
				local var_19_0 = {
					hero = arg_13_0.hero,
					ishero = arg_13_0.ishero,
					ispet = arg_13_0.ispet
				}

				arg_13_0.changeAttrs = nil

				arg_13_0:updatePracticeInfos()
				arg_13_0:updateHeroAttrInfos()
				xyd.WindowManager.get():openWindow("wash_hero_auto", var_19_0)
			end

			if arg_13_0:alertCloseOrSwitch(var_18_1) then
				var_18_1()
			end
		end
	end)
	arg_13_0:nodeByName("save_btn"):addTouchEventListener(function(arg_20_0, arg_20_1)
		if arg_20_1 == ccui.TouchEventType.began then
			arg_13_0:nodeByName("save_btn"):setScale(0.9)
		end

		if arg_20_1 == ccui.TouchEventType.moved then
			arg_13_0:nodeByName("save_btn"):setScale(1)
		end

		if arg_20_1 == ccui.TouchEventType.ended then
			arg_13_0:nodeByName("save_btn"):setScale(1)

			local var_20_0 = 0

			for iter_20_0, iter_20_1 in pairs(arg_13_0.changeAttrs) do
				var_20_0 = var_20_0 + iter_20_1
			end

			if var_20_0 < 0 then
				local var_20_1 = var_0_1:translation("WASH_ATTRS_DOWN")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_20_1, function()
					local var_21_0 = {}

					if arg_13_0.ishero then
						var_21_0.partner_id = arg_13_0.hero:getHeroID()
					elseif arg_13_0.ispet then
						var_21_0.pet_id = arg_13_0.hero:getPetID()
					end

					local var_21_1

					if arg_13_0.ishero then
						var_21_1 = xyd.mid.PRACTICE_SAVE
					elseif arg_13_0.ispet then
						var_21_1 = xyd.mid.PET_PRACTICE_SAVE
					end

					xyd.Backend.get():request(var_21_1, var_21_0, function(arg_22_0, arg_22_1)
						if arg_22_0 == xyd.error.OK then
							arg_13_0.hero:updatePractice(arg_22_1.practice_attr)
							arg_13_0:updateDialog(var_0_1:translation("SEND_PRACTICE_TIP5"), 20)

							arg_13_0.changeAttrs = nil

							arg_13_0:updatePracticeInfos()
							arg_13_0:updateHeroAttrInfos()
						end
					end)
				end, nil, nil, arg_13_0.colorMode)
			else
				local var_20_2 = {}

				if arg_13_0.ishero then
					var_20_2.partner_id = arg_13_0.hero:getHeroID()
				elseif arg_13_0.ispet then
					var_20_2.pet_id = arg_13_0.hero:getPetID()
				end

				local var_20_3

				if arg_13_0.ishero then
					var_20_3 = xyd.mid.PRACTICE_SAVE
				elseif arg_13_0.ispet then
					var_20_3 = xyd.mid.PET_PRACTICE_SAVE
				end

				xyd.Backend.get():request(var_20_3, var_20_2, function(arg_23_0, arg_23_1)
					if arg_23_0 == xyd.error.OK then
						arg_13_0.hero:updatePractice(arg_23_1.practice_attr)
						arg_13_0:updateDialog(var_0_1:translation("SEND_PRACTICE_TIP5"), 20)

						arg_13_0.changeAttrs = nil

						arg_13_0:updatePracticeInfos()
						arg_13_0:updateHeroAttrInfos()
					end
				end)
			end
		end
	end)

	for iter_13_0 = 1, 3 do
		arg_13_0.lockUnselecteds[iter_13_0]:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_24_0)
			if arg_24_0.name == "began" then
				return true
			elseif arg_24_0.name == "ended" then
				if isTicket then
					message = var_0_1:translation("XILIANQUAN_ISSECET")

					xyd.WindowManager.get():openWindow("toast", {
						message = message
					})
				end

				if arg_13_0.locks[iter_13_0] == 0 and not arg_13_0.isTicket then
					arg_13_0.locks[iter_13_0] = 1

					arg_13_0:isSelected(false, iter_13_0)
				end
			end
		end)
		arg_13_0.lockSelecteds[iter_13_0]:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_25_0)
			if arg_25_0.name == "began" then
				return true
			elseif arg_25_0.name == "ended" then
				if arg_13_0.isTicket then
					message = var_0_1:translation("XILIANQUAN_ISSECET")

					xyd.WindowManager.get():openWindow("toast", {
						message = message
					})
				end

				if arg_13_0.locks[iter_13_0] == 1 and not arg_13_0.isTicket then
					arg_13_0.locks[iter_13_0] = 0

					arg_13_0:isSelected(true, iter_13_0)
					arg_13_0:updateDialog(var_0_1:translation("SEND_PRACTICE_TIP4"), 20)
				end
			end
		end)
	end

	arg_13_0.daShiSelected:addTouchEventListener(function(arg_26_0, arg_26_1)
		if arg_26_1 == ccui.TouchEventType.ended and arg_13_0.isTicket then
			message = var_0_1:translation("XILIANQUAN_ISSECET")

			xyd.WindowManager.get():openWindow("toast", {
				message = message
			})
		end

		if arg_26_1 == ccui.TouchEventType.ended and not arg_13_0.isTicket then
			arg_13_0.practiceType = xyd.WashWay.NORMAL

			arg_13_0:updatePracticeInfos()
		end
	end)
	arg_13_0.daShiUnselected:addTouchEventListener(function(arg_27_0, arg_27_1)
		if arg_27_1 == ccui.TouchEventType.ended and arg_13_0.isTicket then
			message = var_0_1:translation("XILIANQUAN_ISSECET")

			xyd.WindowManager.get():openWindow("toast", {
				message = message
			})
		end

		if arg_27_1 == ccui.TouchEventType.ended and not arg_13_0.isTicket then
			arg_13_0.practiceType = xyd.WashWay.DASHI

			arg_13_0:updatePracticeInfos()
		end
	end)
	arg_13_0.zhuanJiaSelected:addTouchEventListener(function(arg_28_0, arg_28_1)
		if arg_28_1 == ccui.TouchEventType.ended and arg_13_0.isTicket then
			message = var_0_1:translation("XILIANQUAN_ISSECET")

			xyd.WindowManager.get():openWindow("toast", {
				message = message
			})
		end

		if arg_28_1 == ccui.TouchEventType.ended and not arg_13_0.isTicket then
			arg_13_0.practiceType = xyd.WashWay.NORMAL

			arg_13_0:updatePracticeInfos()
		end
	end)
	arg_13_0.zhuanJiaUnselected:addTouchEventListener(function(arg_29_0, arg_29_1)
		if arg_29_1 == ccui.TouchEventType.ended and arg_13_0.isTicket then
			message = var_0_1:translation("XILIANQUAN_ISSECET")

			xyd.WindowManager.get():openWindow("toast", {
				message = message
			})
		end

		if arg_29_1 == ccui.TouchEventType.ended and not arg_13_0.isTicket then
			arg_13_0.practiceType = xyd.WashWay.ZHUANJIA

			arg_13_0:updatePracticeInfos()
		end
	end)
	arg_13_0.washBtn:addTouchEventListener(function(arg_30_0, arg_30_1)
		if arg_30_1 == ccui.TouchEventType.began then
			arg_13_0:nodeByName("wash_btn"):setScale(0.9)
		end

		if arg_30_1 == ccui.TouchEventType.moved then
			arg_13_0:nodeByName("wash_btn"):setScale(1)
		end

		if arg_30_1 == ccui.TouchEventType.ended then
			arg_13_0:nodeByName("wash_btn"):setScale(1)

			if arg_13_0.isTicket then
				local var_30_0 = arg_13_0.hero:getPractice()

				if tonumber(var_30_0[1]) >= xyd.WaskAttrUpLimit and tonumber(var_30_0[2]) >= xyd.WaskAttrUpLimit and tonumber(var_30_0[3]) >= xyd.WaskAttrUpLimit then
					if arg_13_0.ispet then
						message = var_0_1:translation("PET_PRACTICE_UPLIMIT")
					elseif arg_13_0.ishero then
						message = var_0_1:translation("HERO_PRACTICE_UPLIMIT")
					end

					xyd.WindowManager.get():openWindow("toast", {
						message = message
					})
					arg_13_0.washBtn:setBrightStyle(ccui.BrightStyle.highlight)
				elseif arg_13_0.player:getBackpack():getItemNumByID(xyd.tables.misc.practiceTicketId) > 0 then
					local var_30_1 = {}
					local var_30_2

					if arg_13_0.ishero then
						var_30_1.partner_id = arg_13_0.hero:getHeroID()
						var_30_2 = xyd.mid.WASH_BY_TICKET
					elseif arg_13_0.ispet then
						var_30_1.pet_id = arg_13_0.hero:getPetID()
						var_30_2 = xyd.mid.PET_WASH_BY_TICKET
					end

					xyd.Backend.get():request(var_30_2, var_30_1, function(arg_31_0, arg_31_1)
						if arg_31_0 == xyd.error.OK then
							local var_31_0 = {
								itemID = xyd.tables.misc.practiceTicketId
							}

							var_31_0.itemNum = 1

							arg_13_0.player:getBackpack():removeItem(var_31_0)
							xyd.ModelManager.get():loadModel(xyd.ModelType.GIFT_PUSH):setSceneCondition(24)
							arg_13_0:updateInfo(arg_31_1.info)
							arg_13_0:updateDialog(var_0_1:translation("SEND_PRACTICE_TIP1"), 10)

							arg_13_0.changeAttrs = arg_31_1.add_attr

							arg_13_0:updateHeroAttrInfos()
							arg_13_0:updatePracticeInfos()
						end
					end)
				else
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("NO_WASH_TICKET")
					})
				end
			elseif arg_13_0:canWash() then
				local var_30_3 = {}

				if arg_13_0.ishero then
					var_30_3.partner_id = arg_13_0.hero:getHeroID()
					var_30_3.locks = arg_13_0.locks
					var_30_3.practice_type = arg_13_0.practiceType
				elseif arg_13_0.ispet then
					var_30_3.pet_id = arg_13_0.hero:getPetID()
					var_30_3.locks = arg_13_0.locks
					var_30_3.practice_type = arg_13_0.practiceType
				end

				local var_30_4

				if arg_13_0.ishero then
					var_30_4 = xyd.mid.PRACTICE
				elseif arg_13_0.ispet then
					var_30_4 = xyd.mid.PET_PRACTICE
				end

				xyd.Backend.get():request(var_30_4, var_30_3, function(arg_32_0, arg_32_1)
					if arg_32_0 == xyd.error.OK then
						arg_13_0:updateInfo(arg_32_1.info)
						arg_13_0:updateDialog(var_0_1:translation("SEND_PRACTICE_TIP1"), 10)

						arg_13_0.changeAttrs = arg_32_1.add_attr

						arg_13_0:updateHeroAttrInfos()
						arg_13_0:updatePracticeInfos()
					end
				end)
			end
		end
	end)
	arg_13_0:nodeByName("ticket_unselected"):addTouchEventListener(function(arg_33_0, arg_33_1)
		if arg_33_1 == ccui.TouchEventType.ended and not arg_13_0.isTicket then
			arg_13_0.isTicket = true

			arg_13_0:updateSelectTicket()
			arg_13_0:updatePracticeInfos()
		end
	end)
	arg_13_0:nodeByName("money_unselected"):addTouchEventListener(function(arg_34_0, arg_34_1)
		if arg_34_1 == ccui.TouchEventType.ended and arg_13_0.isTicket then
			arg_13_0.isTicket = false

			arg_13_0:updateSelectTicket()
			arg_13_0:updatePracticeInfos()
		end
	end)
end

function var_0_0.alertCloseOrSwitch(arg_35_0, arg_35_1)
	if not arg_35_0.changeAttrs then
		return true
	end

	local var_35_0 = {}

	table.insert(var_35_0, var_0_1:translation("LILIANG_ADD"))
	table.insert(var_35_0, var_0_1:translation("ZHILI_ZENGJIA"))
	table.insert(var_35_0, var_0_1:translation("MINJIE_ZENGJIA"))

	for iter_35_0 = 1, #arg_35_0.changeAttrs do
		if tonumber(arg_35_0.changeAttrs[iter_35_0]) > 0 then
			local var_35_1 = var_0_1:translation("WASH_CLOSE_TIP")
			local var_35_2 = var_35_0[iter_35_0] .. var_35_1

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_35_2, function()
				arg_35_1()
			end, nil, nil, arg_35_0.colorMode)

			return false
		end
	end

	return true
end

function var_0_0.initPracticeInfo(arg_37_0)
	xyd.Backend.get():request(xyd.mid.GET_PRACTICE_INFO, nil, function(arg_38_0, arg_38_1)
		if arg_38_0 == xyd.error.OK then
			arg_37_0:updateInfo(arg_38_1)

			local var_38_0, var_38_1 = xyd.db.washInfo:getWashInfo(arg_37_0.player.playerID)

			if var_38_0 and var_38_1 and var_38_0 ~= 0 then
				local var_38_2

				if var_38_1 == 0 then
					arg_37_0.ishero = true
					arg_37_0.ispet = false
					var_38_2 = arg_37_0.player:getHeroByID(var_38_0)
				else
					arg_37_0.ispet = true
					arg_37_0.ishero = false
					var_38_2 = arg_37_0.player:getPetByID(var_38_0)
				end

				arg_37_0:setHero(var_38_2, arg_37_0.ishero, arg_37_0.ispet)
			end
		end
	end)
end

function var_0_0.updateInfo(arg_39_0, arg_39_1)
	arg_39_0.lastTime = arg_39_1.last_time
	arg_39_0.baseCrystal = arg_39_1.base_crystal
	arg_39_0.baseMana = arg_39_1.base_mana
	arg_39_0.blessValue = arg_39_1.bless_value
	arg_39_0.player.practiceInfo = arg_39_1

	arg_39_0:checkPracticeRedPoint()
end

function var_0_0.randomDialog(arg_40_0)
	local var_40_0 = arg_40_0:nodeByName("role")
	local var_40_1 = {}

	table.insert(var_40_1, var_0_1:translation("SEND_PRACTICE_TIP2"))
	table.insert(var_40_1, var_0_1:translation("SEND_PRACTICE_TIP4"))
	table.insert(var_40_1, var_0_1:translation("SEND_PRACTICE_TIP3"))
	table.insert(var_40_1, var_0_1:translation("SEND_PRACTICE_TIP1"))
	table.insert(var_40_1, var_0_1:translation("SEND_PRACTICE_TIP6"))
	var_40_0:setTouchEnabled(true)
	var_40_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_41_0)
		if arg_41_0.name == "began" then
			return true
		elseif arg_41_0.name == "ended" then
			local var_41_0 = math.random(#var_40_1)

			arg_40_0:updateDialog(var_40_1[var_41_0], 20)
		end
	end)
end

function setNameLabel(arg_42_0, arg_42_1, arg_42_2, arg_42_3)
	local var_42_0 = cc.Node:create()
	local var_42_1 = arg_42_1:getName()
	local var_42_2 = arg_42_1:getColor()
	local var_42_3 = {
		color = arg_42_3 or cc.c3b(71, 56, 31),
		text = var_42_1
	}
	local var_42_4 = xyd.AssetLoader:get():loadLabel(var_42_3)

	var_42_0:addChild(var_42_4)
	var_42_4:setAnchorPoint(cc.p(0.5, 0.5))

	if arg_42_2 then
		var_42_4:enableOutline(cc.c4b(255, 255, 255, 255), 2)
	end

	local var_42_5 = {
		color = xyd.color.HERO_QUALITY[var_42_2],
		text = xyd.Color2Level[arg_42_1:getColor()]
	}

	var_42_0:setPosition(10, 2)
	var_42_0:setAnchorPoint(cc.p(0, 0))
	arg_42_0:addChild(var_42_0)
end

function var_0_0.setHero(arg_43_0, arg_43_1, arg_43_2, arg_43_3)
	arg_43_0.hero = arg_43_1
	arg_43_0.ishero = arg_43_2
	arg_43_0.ispet = arg_43_3
	arg_43_0.practiceType = xyd.WashWay.NORMAL

	arg_43_0:nodeByName("xuanzhe_heroname"):setString(var_0_1:translation(""))
	arg_43_0:nodeByName("hero_name"):removeAllChildren()
	arg_43_0:nodeByName("pet_name"):removeAllChildren()
	arg_43_0.nameBg:setVisible(true)

	if arg_43_0.ispet then
		arg_43_0:nodeByName("hero_name"):setVisible(false)
		arg_43_0:nodeByName("pet_name"):setVisible(true)
		setNameLabel(arg_43_0:nodeByName("pet_name"), arg_43_0.hero, false, cc.c4b(255, 255, 255, 255))
	else
		arg_43_0:nodeByName("hero_name"):setVisible(true)
		arg_43_0:nodeByName("pet_name"):setVisible(false)
		setNameLabel(arg_43_0:nodeByName("hero_name"), arg_43_0.hero, false, cc.c4b(255, 255, 255, 255))
	end

	local var_43_0 = arg_43_0:nodeByName("touxiang")

	var_43_0:removeAllChildren()

	local var_43_1 = xyd.AssetLoader.get():loadSprite("windows/wash/bg_touxiang.png")
	local var_43_2 = var_43_1:getWidth()
	local var_43_3 = var_43_0:getWidth()
	local var_43_4 = var_43_0:getHeight()

	var_43_1:setAnchorPoint(cc.p(0, 0.5))
	var_43_1:addTo(var_43_0)
	var_43_1:setPosition(0, var_43_4 / 2)
	arg_43_0:nodeByName("wenhao"):removeAllChildren()

	local var_43_5 = "windows/wash/icon_wenhao.png"
	local var_43_6 = xyd.AssetLoader.get():loadSprite(var_43_5)

	var_43_6:setAnchorPoint(cc.p(0, 0.5))
	var_43_6:addTo(var_43_0)
	var_43_6:setPosition(0, var_43_4 / 2)
	var_43_1:setVisible(false)

	if arg_43_0.ispet then
		xyd.setPetAvatarNewUI(var_43_0, arg_43_0.hero, nil, true)
		var_43_1:setVisible(false)
	else
		xyd.setAvatarBorderNewUI(arg_43_0.hero, var_43_0)
		var_43_1:setVisible(true)
	end

	local var_43_7 = arg_43_0.hero:getHeroType()

	for iter_43_0 = 1, 3 do
		arg_43_0.attrIcons[iter_43_0]:setVisible(var_43_7 == iter_43_0)
	end

	local var_43_8 = xyd.tables.hero:awakenItemID(arg_43_0.hero:getTableID())

	if arg_43_0.hero:awakeTwiceStage() > xyd.AwakeTwiceStage.STAGE_ONE then
		var_43_8 = xyd.tables.hero:awakeTwiceItem(arg_43_0.hero:getTableID())
	end

	local var_43_9 = arg_43_0:nodeByName("equip")

	var_43_9:removeAllChildren()
	xyd.setItemBorder(var_43_9, var_43_8, false)
	arg_43_0:updateHeroAttrInfos()

	arg_43_0.changeAttrs = nil

	arg_43_0:updateLocks()
	arg_43_0:updatePracticeInfos()
	arg_43_0:updateSelectTicket()
end

function var_0_0.updateHeroAttrInfos(arg_44_0)
	arg_44_0:nodeByName("attr_container"):setVisible(true)
	arg_44_0:nodeByName("award_container"):setVisible(true)

	local var_44_0 = arg_44_0.hero:getPractice()
	local var_44_1 = var_0_6:getPracticeNeeds(arg_44_0.hero:getTableID())
	local var_44_2 = var_0_6:getPracticeAttrType(arg_44_0.hero:getTableID())
	local var_44_3 = var_0_6:getPracticeAttrValue(arg_44_0.hero:getTableID())
	local var_44_4 = {}

	table.insert(var_44_4, var_0_1:translation("LILIANG_ACHIEVE"))
	table.insert(var_44_4, var_0_1:translation("ZHILI_ACHIEVE"))
	table.insert(var_44_4, var_0_1:translation("MINJIE_ACHIEVE"))

	for iter_44_0 = 1, 3 do
		arg_44_0.attrValues[iter_44_0]:setString(var_44_0[iter_44_0])

		local var_44_5 = var_0_5:name(var_44_2[iter_44_0])
		local var_44_6 = var_0_5:suffix(var_44_2[iter_44_0])
		local var_44_7 = string.format(var_44_4[iter_44_0], var_44_1[iter_44_0])
		local var_44_8 = var_44_5 .. " +" .. var_44_3[iter_44_0] .. var_44_6

		arg_44_0.awardTxts[iter_44_0]:setString(var_44_8)
		arg_44_0.needTxts[iter_44_0]:setString(var_44_7)

		if var_44_1[iter_44_0] <= var_44_0[iter_44_0] then
			arg_44_0.awardTxts[iter_44_0]:setColor(cc.c4b(0, 172, 53, 150))
			arg_44_0.needTxts[iter_44_0]:setColor(cc.c4b(0, 172, 53, 150))
			arg_44_0.greenPoints[iter_44_0]:setVisible(true)
			arg_44_0.whitePoints[iter_44_0]:setVisible(false)
		else
			arg_44_0.awardTxts[iter_44_0]:setColor(cc.c4b(102, 81, 66, 150))
			arg_44_0.needTxts[iter_44_0]:setColor(cc.c4b(102, 81, 66, 150))
			arg_44_0.greenPoints[iter_44_0]:setVisible(false)
			arg_44_0.whitePoints[iter_44_0]:setVisible(true)
		end

		if var_44_0[iter_44_0] >= xyd.WaskAttrUpLimit then
			arg_44_0.fullTxts[iter_44_0]:setVisible(true)
		else
			arg_44_0.fullTxts[iter_44_0]:setVisible(false)
		end

		if not arg_44_0.changeAttrs then
			arg_44_0.arrows[iter_44_0]:setVisible(false)
			arg_44_0.changeValues[iter_44_0]:setVisible(false)
			arg_44_0.newValues[iter_44_0]:setVisible(false)
			arg_44_0.washTxt:setVisible(true)
			arg_44_0.saveBtn:setVisible(false)
			arg_44_0.saveTxt:setVisible(false)
			arg_44_0.redoTxt:setVisible(false)
		else
			arg_44_0.arrows[iter_44_0]:setVisible(true)
			arg_44_0.changeValues[iter_44_0]:setVisible(true)
			arg_44_0.newValues[iter_44_0]:setVisible(true)
			arg_44_0.washTxt:setVisible(false)
			arg_44_0.saveBtn:setVisible(true)
			arg_44_0.saveTxt:setVisible(true)
			arg_44_0.redoTxt:setVisible(true)
			arg_44_0.newValues[iter_44_0]:setString(var_44_0[iter_44_0] + arg_44_0.changeAttrs[iter_44_0])

			if arg_44_0.changeAttrs[iter_44_0] > 0 then
				arg_44_0.changeValues[iter_44_0]:setString(string.format(var_0_1:translation("KUO_HAO"), "+" .. arg_44_0.changeAttrs[iter_44_0]))
				arg_44_0.changeValues[iter_44_0]:setColor(cc.c4b(0, 185, 0, 150))
			elseif arg_44_0.changeAttrs[iter_44_0] < 0 then
				arg_44_0.changeValues[iter_44_0]:setString(string.format(var_0_1:translation("KUO_HAO"), arg_44_0.changeAttrs[iter_44_0]))
				arg_44_0.changeValues[iter_44_0]:setColor(cc.c4b(255, 6, 6, 150))
			else
				arg_44_0.changeValues[iter_44_0]:setString("")
			end
		end
	end
end

function var_0_0.updateLocks(arg_45_0)
	for iter_45_0 = 1, 3 do
		arg_45_0.lockUnselecteds[iter_45_0]:setVisible(arg_45_0.locks[iter_45_0] ~= 1)
		arg_45_0.lockUnselecteds[iter_45_0]:setTouchEnabled(arg_45_0.locks[iter_45_0] ~= 1)
		arg_45_0.lockSelecteds[iter_45_0]:setVisible(arg_45_0.locks[iter_45_0] == 1)
		arg_45_0.lockSelecteds[iter_45_0]:setTouchEnabled(arg_45_0.locks[iter_45_0] == 1)
	end
end

function var_0_0.updatePracticeInfos(arg_46_0)
	arg_46_0:nodeByName("practice_container"):setVisible(true)

	if arg_46_0.practiceType == xyd.WashWay.NORMAL then
		arg_46_0.zhuanJiaUnselected:setVisible(true)
		arg_46_0.zhuanJiaUnselected:setTouchEnabled(true)
		arg_46_0.daShiUnselected:setVisible(true)
		arg_46_0.daShiUnselected:setTouchEnabled(true)
		arg_46_0.zhuanJiaSelected:setVisible(false)
		arg_46_0.zhuanJiaSelected:setTouchEnabled(false)
		arg_46_0.daShiSelected:setVisible(false)
		arg_46_0.daShiSelected:setTouchEnabled(false)
	elseif arg_46_0.practiceType == xyd.WashWay.ZHUANJIA then
		arg_46_0.zhuanJiaUnselected:setVisible(false)
		arg_46_0.zhuanJiaUnselected:setTouchEnabled(false)
		arg_46_0.daShiUnselected:setVisible(true)
		arg_46_0.daShiUnselected:setTouchEnabled(true)
		arg_46_0.zhuanJiaSelected:setVisible(true)
		arg_46_0.zhuanJiaSelected:setTouchEnabled(true)
		arg_46_0.daShiSelected:setVisible(false)
		arg_46_0.daShiSelected:setTouchEnabled(false)
	elseif arg_46_0.practiceType == xyd.WashWay.DASHI then
		arg_46_0.zhuanJiaUnselected:setVisible(true)
		arg_46_0.zhuanJiaUnselected:setTouchEnabled(true)
		arg_46_0.daShiUnselected:setVisible(false)
		arg_46_0.daShiUnselected:setTouchEnabled(false)
		arg_46_0.zhuanJiaSelected:setVisible(false)
		arg_46_0.zhuanJiaSelected:setTouchEnabled(false)
		arg_46_0.daShiSelected:setVisible(true)
		arg_46_0.daShiSelected:setTouchEnabled(true)
	end

	arg_46_0:scheduleTime()
	arg_46_0:updateConsume()
	arg_46_0.blessTxt:setString(var_0_1:translation("WASH_BLESS_VALUES") .. arg_46_0.blessValue)
	arg_46_0.blessTxt:setVisible(true)
	arg_46_0.timeTxt:setVisible(true)

	if arg_46_0.player.vip < xyd.WashLevelLimit then
		arg_46_0.daShiUnselected:setVisible(false)
		arg_46_0.daShiUnselected:setTouchEnabled(false)
		arg_46_0.daShiSelected:setVisible(false)
		arg_46_0.daShiSelected:setTouchEnabled(false)
		arg_46_0.daShiBg:setVisible(false)
		arg_46_0.daShiTxt:setVisible(false)
	end
end

function var_0_0.updateConsume(arg_47_0)
	local var_47_0 = xyd.tables.practiceType:getNum(arg_47_0.practiceType)

	arg_47_0.lockTimes = 0

	for iter_47_0 = 1, #arg_47_0.locks do
		if arg_47_0.locks[iter_47_0] == 1 then
			arg_47_0.lockTimes = arg_47_0.lockTimes + 1
		end
	end

	if arg_47_0.practiceType > 1 then
		arg_47_0.jinbi:setVisible(false)
		arg_47_0.yuanbao:setVisible(true)

		if arg_47_0.lockTimes >= 3 then
			var_47_0 = xyd.tables.practiceType:getNum(xyd.WashWay.ZHUANJIA)
		end

		local var_47_1 = xyd.tables.practiceLockType:getCryStal(arg_47_0.lockTimes)
		local var_47_2 = 0

		if arg_47_0.lockTimes == 0 then
			arg_47_0.costNum:setString(var_47_0)
		else
			local var_47_3 = arg_47_0.baseCrystal

			for iter_47_1 = 1, arg_47_0.lockTimes do
				var_47_3 = var_47_3 + var_47_1
				var_47_2 = var_47_2 + var_47_3
			end

			if tonumber(arg_47_0.leftTime) > 0 then
				arg_47_0.costNum:setString(var_47_2 + var_47_0)
			else
				arg_47_0.costNum:setString(var_47_2)
			end
		end

		if tonumber(arg_47_0.leftTime) > 0 then
			arg_47_0.costCrystal = var_47_2 + var_47_0
		else
			arg_47_0.costCrystal = var_47_2
		end
	else
		arg_47_0.yuanbao:setVisible(false)
		arg_47_0.jinbi:setVisible(true)

		local var_47_4 = xyd.tables.practiceLockType:getMana(arg_47_0.lockTimes)
		local var_47_5 = 0

		if arg_47_0.lockTimes == 0 then
			arg_47_0.costNum:setString(var_47_0)
		else
			local var_47_6 = arg_47_0.baseMana

			for iter_47_2 = 1, arg_47_0.lockTimes do
				var_47_6 = var_47_6 + var_47_4
				var_47_5 = var_47_5 + var_47_6
			end

			if tonumber(arg_47_0.leftTime) > 0 then
				arg_47_0.costNum:setString(var_47_5 + var_47_0)
			else
				arg_47_0.costNum:setString(var_47_5)
			end
		end

		arg_47_0.costMana = var_47_5 + var_47_0

		if tonumber(arg_47_0.leftTime) > 0 then
			arg_47_0.costMana = var_47_5 + var_47_0
		else
			arg_47_0.costMana = var_47_5
		end
	end

	if arg_47_0.leftTime ~= nil and tonumber(arg_47_0.leftTime) <= 0 and arg_47_0.lockTimes == 0 then
		arg_47_0.costNum:setString("0")
	end

	arg_47_0:nodeByName("ticket_cost_num"):setString(arg_47_0.player:getBackpack():getItemNumByID(xyd.tables.misc.practiceTicketId))
end

function var_0_0.scheduleTime(arg_48_0)
	local var_48_0 = tonumber(xyd.ServerTime.get():getServerTime())

	arg_48_0.leftTime = arg_48_0.lastTime + xyd.TimeGap - var_48_0

	if arg_48_0.handle then
		var_0_4.unscheduleGlobal(arg_48_0.handle)
	end

	if arg_48_0.leftTime <= 0 then
		arg_48_0.timeTxt:setString(var_0_1:translation("SUMMON_PRICE_FREE"))
	else
		local function var_48_1()
			arg_48_0.leftTime = arg_48_0.leftTime - 1

			if arg_48_0.leftTime <= 0 then
				arg_48_0.timeTxt:setString(var_0_1:translation("SUMMON_PRICE_FREE"))
			else
				local var_49_0 = math.floor(arg_48_0.leftTime / 3600)
				local var_49_1 = math.floor((arg_48_0.leftTime - 3600 * var_49_0) / 60)
				local var_49_2 = arg_48_0.leftTime - 3600 * var_49_0 - 60 * var_49_1

				if arg_48_0.timeTxt and not tolua.isnull(arg_48_0.timeTxt) then
					arg_48_0.timeTxt:setString(string.format(var_0_1:translation("WASK_TIME_COUNT"), var_49_0, var_49_1, var_49_2))
				end
			end

			arg_48_0:checkPracticeRedPoint()
		end

		var_48_1()

		arg_48_0.handle = var_0_4.scheduleGlobal(var_48_1, 1)
	end
end

function var_0_0.checkPracticeRedPoint(arg_50_0)
	local var_50_0 = false
	local var_50_1 = xyd.WindowManager.get():getWindow("sub_research")

	if var_50_1 then
		var_50_0 = var_50_1.washRedP:isVisible()
	end

	local var_50_2 = tonumber(xyd.ServerTime.get():getServerTime())
	local var_50_3 = arg_50_0.lastTime + xyd.TimeGap - var_50_2

	if var_50_3 <= 0 and not var_50_0 or var_50_3 > 0 and var_50_0 then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.CHECK_MIDDLE_RED_MARK,
			params = xyd.CheckMiddleRed.PRACTICE
		})
	end
end

function var_0_0.canWash(arg_51_0)
	arg_51_0:updateConsume()

	if arg_51_0.lockTimes > 0 then
		if arg_51_0.practiceType ~= 1 and arg_51_0.player.crystal < arg_51_0.costCrystal then
			message = var_0_1:translation("YUANBAO_BUZU")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, message, function()
				local var_52_0 = {}

				var_52_0.windowState = true

				xyd.WindowManager.get():openWindow("vip_recharge", var_52_0)
			end, nil, nil, arg_51_0.colorMode)

			return false
		elseif arg_51_0.practiceType == 1 and arg_51_0.player.mana < arg_51_0.costMana then
			message = var_0_1:translation("JINBI_BUZU")

			xyd.WindowManager.get():openWindow("toast", {
				message = message
			})

			return false
		elseif arg_51_0.blessValue < xyd.tables.practiceLockType:getBlessNum(arg_51_0.lockTimes) then
			message = var_0_1:translation("BLESS_VALUE_BUZU")

			xyd.WindowManager.get():openWindow("toast", {
				message = message
			})

			return false
		end
	elseif arg_51_0.lockTimes == 0 and arg_51_0.leftTime ~= nil and arg_51_0.leftTime > 0 then
		if arg_51_0.practiceType ~= 1 and arg_51_0.player.crystal < arg_51_0.costCrystal then
			message = var_0_1:translation("YUANBAO_BUZU")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, message, function()
				local var_53_0 = {}

				var_53_0.windowState = true

				xyd.WindowManager.get():openWindow("vip_recharge", var_53_0)
			end, nil, nil, arg_51_0.colorMode)

			return false
		elseif arg_51_0.practiceType == 1 and arg_51_0.player.mana < arg_51_0.costMana then
			message = var_0_1:translation("JINBI_BUZU")

			xyd.WindowManager.get():openWindow("toast", {
				message = message
			})

			return false
		end
	end

	local var_51_0 = arg_51_0.hero:getPractice()

	if tonumber(var_51_0[1]) >= xyd.WaskAttrUpLimit and tonumber(var_51_0[2]) >= xyd.WaskAttrUpLimit and tonumber(var_51_0[3]) >= xyd.WaskAttrUpLimit then
		if arg_51_0.ispet then
			message = var_0_1:translation("PET_PRACTICE_UPLIMIT")
		elseif arg_51_0.ishero then
			message = var_0_1:translation("HERO_PRACTICE_UPLIMIT")
		end

		xyd.WindowManager.get():openWindow("toast", {
			message = message
		})
		arg_51_0.washBtn:setBrightStyle(ccui.BrightStyle.highlight)

		return false
	end

	return true
end

function var_0_0.getCost(arg_54_0)
	local var_54_0 = xyd.tables.practiceType:getNum(arg_54_0.practiceType)
end

function var_0_0.willClose(arg_55_0, arg_55_1)
	var_0_0.super.willClose(arg_55_0, arg_55_1)

	if arg_55_0.handle then
		var_0_4.unscheduleGlobal(arg_55_0.handle)
	end

	if arg_55_0.hero then
		local var_55_0
		local var_55_1 = 0

		if arg_55_0.ispet then
			var_55_1 = 1
			var_55_0 = arg_55_0.hero:getPetID()
		else
			var_55_1 = 0
			var_55_0 = arg_55_0.hero:getHeroID()
		end

		xyd.db.washInfo:persist(arg_55_0.player.playerID, var_55_0, var_55_1)
	end
end

function var_0_0.didClose(arg_56_0, arg_56_1)
	var_0_0.super.didClose(arg_56_0, arg_56_1)
end

return var_0_0
