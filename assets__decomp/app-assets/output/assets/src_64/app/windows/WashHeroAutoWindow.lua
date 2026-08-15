local var_0_0 = class("WashHeroAutoWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)

	arg_2_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_2_0.container = arg_2_0:nodeByName("container")
	arg_2_0.wayFlag = xyd.WashWay.NORMAL
	arg_2_0.timesFlag = 1
	arg_2_0.hero = arg_2_1.hero
	arg_2_0.ishero = arg_2_1.ishero
	arg_2_0.ispet = arg_2_1.ispet
	arg_2_0.oldPracticeAttr = arg_2_0.hero:getPractice()
	arg_2_0.info = {}

	arg_2_0:initRequest()
	arg_2_0:layout()
	arg_2_0:setBtn()
end

function var_0_0.initRequest(arg_3_0)
	local var_3_0

	if arg_3_0.ishero then
		var_3_0 = xyd.mid.GET_PRACTICE_INFO
	elseif arg_3_0.ispet then
		var_3_0 = xyd.mid.PET_GET_PRACTICE_INFO
	end

	xyd.Backend.get():request(var_3_0, nil, function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK then
			arg_3_0.info = arg_4_1
		end
	end)
end

function var_0_0.didOpen(arg_5_0)
	var_0_0.super.didOpen(arg_5_0, params)
	arg_5_0:addBlockLayer()
end

function var_0_0.layout(arg_6_0)
	local var_6_0 = arg_6_0.container:getChildByName("wash_way_txt")
	local var_6_1 = arg_6_0.container:getChildByName("wash_lianxu_txt")
	local var_6_2 = arg_6_0.container:getChildByName("xiaohao_txt")
	local var_6_3 = arg_6_0.container:getChildByName("conditions_txt")
	local var_6_4 = arg_6_0.container:getChildByName("up_txt_1")
	local var_6_5 = arg_6_0.container:getChildByName("up_txt_2")
	local var_6_6 = arg_6_0.container:getChildByName("up_txt_3")
	local var_6_7 = arg_6_0.container:getChildByName("up_txt_4")
	local var_6_8 = arg_6_0.container:getChildByName("start_wash")

	var_6_0:setString(var_0_1:translation("WASH_WAY_TXT"))
	var_6_1:setString(var_0_1:translation("WASH_LIANXU_TXT"))
	var_6_2:setString(var_0_1:translation("WASH_XIAOHAO_TXT"))
	var_6_3:setString(var_0_1:translation("WASH_CONDITIONS_TXT"))
	var_6_4:setString(var_0_1:translation("WASH_UP_TXT1"))
	var_6_5:setString(var_0_1:translation("WASH_UP_TXT2"))
	var_6_6:setString(var_0_1:translation("WASH_UP_TXT3"))
	var_6_7:setString(var_0_1:translation("WASH_UP_TXT4"))

	arg_6_0.attributeTrueBtn = {}

	table.insert(arg_6_0.attributeTrueBtn, arg_6_0.container:getChildByName("tick_2"))
	table.insert(arg_6_0.attributeTrueBtn, arg_6_0.container:getChildByName("tick_3"))
	table.insert(arg_6_0.attributeTrueBtn, arg_6_0.container:getChildByName("tick_4"))
	table.insert(arg_6_0.attributeTrueBtn, arg_6_0.container:getChildByName("tick_1"))

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.attributeTrueBtn) do
		iter_6_1:setTouchEnabled(false)
		iter_6_1:setVisible(false)
	end

	arg_6_0.attributeFalseBtn = {}

	table.insert(arg_6_0.attributeFalseBtn, arg_6_0.container:getChildByName("start_squar_2"))
	table.insert(arg_6_0.attributeFalseBtn, arg_6_0.container:getChildByName("start_squar_3"))
	table.insert(arg_6_0.attributeFalseBtn, arg_6_0.container:getChildByName("start_squar_4"))
	table.insert(arg_6_0.attributeFalseBtn, arg_6_0.container:getChildByName("start_squar_1"))

	for iter_6_2, iter_6_3 in ipairs(arg_6_0.attributeFalseBtn) do
		iter_6_3:setTouchEnabled(true)
		iter_6_3:setVisible(true)
	end

	arg_6_0.washWayOptioned = {}

	;(function()
		for iter_7_0 = 1, #arg_6_0.attributeTrueBtn do
			table.insert(arg_6_0.washWayOptioned, 0)
		end
	end)()

	arg_6_0.jinbi = arg_6_0.container:getChildByName("jinbi")
	arg_6_0.yuanbao = arg_6_0.container:getChildByName("yuanbao")
	arg_6_0.jinbiNum = arg_6_0.container:getChildByName("jinbi_num")

	arg_6_0.yuanbao:setVisible(false)

	arg_6_0.lockOpen = {}

	table.insert(arg_6_0.lockOpen, arg_6_0.container:getChildByName("lockopen_2"))
	table.insert(arg_6_0.lockOpen, arg_6_0.container:getChildByName("lockopen_3"))
	table.insert(arg_6_0.lockOpen, arg_6_0.container:getChildByName("lockopen_4"))

	for iter_6_4, iter_6_5 in ipairs(arg_6_0.lockOpen) do
		iter_6_5:setTouchEnabled(true)
		iter_6_5:setVisible(true)
	end

	arg_6_0.lockClose = {}

	table.insert(arg_6_0.lockClose, arg_6_0.container:getChildByName("lockclose_2"))
	table.insert(arg_6_0.lockClose, arg_6_0.container:getChildByName("lockclose_3"))
	table.insert(arg_6_0.lockClose, arg_6_0.container:getChildByName("lockclose_4"))

	arg_6_0.lockOptioned = {}

	;(function()
		for iter_8_0 = 1, #arg_6_0.lockOpen do
			table.insert(arg_6_0.lockOptioned, 0)
		end
	end)()

	arg_6_0.timesNums = {}

	table.insert(arg_6_0.timesNums, xyd.WashTimes.TWO)
	table.insert(arg_6_0.timesNums, xyd.WashTimes.FOUR)
	table.insert(arg_6_0.timesNums, xyd.WashTimes.SIX)
	table.insert(arg_6_0.timesNums, xyd.WashTimes.EIGHT)
	table.insert(arg_6_0.timesNums, xyd.WashTimes.TEN)

	arg_6_0.washTxt = arg_6_0.container:getChildByName("way_num")

	arg_6_0.washTxt:setString(xyd.tables.practiceType:getStyleName(arg_6_0.wayFlag))

	arg_6_0.timesTxt = arg_6_0.container:getChildByName("times_num")

	arg_6_0.timesTxt:setString(arg_6_0.timesNums[1] .. var_0_1:translation("WASH_USE_TIME"))
	arg_6_0:updateComsume(arg_6_0.timesNums[arg_6_0.timesFlag])
end

function var_0_0.setBtn(arg_9_0)
	arg_9_0:setNormalBtn()
	arg_9_0:setLockBtn()
	arg_9_0:setSaveAttrBtn()
end

function var_0_0.setNormalBtn(arg_10_0)
	arg_10_0.container:getChildByName("way_left_btn"):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended and arg_10_0.wayFlag > 1 then
			arg_10_0.wayFlag = arg_10_0.wayFlag - 1

			arg_10_0.washTxt:setString(xyd.tables.practiceType:getStyleName(arg_10_0.wayFlag))

			local var_11_0 = xyd.tables.practiceType:getSytle(arg_10_0.wayFlag)

			if var_11_0 == 1 then
				arg_10_0.yuanbao:setVisible(false)
				arg_10_0.jinbi:setVisible(true)
			elseif var_11_0 == 2 then
				arg_10_0.jinbi:setVisible(false)
				arg_10_0.yuanbao:setVisible(true)
			end

			arg_10_0:updateLockTimes()
			arg_10_0:updateComsume(arg_10_0.timesNums[arg_10_0.timesFlag])
		end
	end)

	local var_10_0 = 3

	if arg_10_0.player.vip < xyd.WashLevelLimit then
		var_10_0 = 2
	end

	arg_10_0.container:getChildByName("way_right_btn"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.ended and arg_10_0.wayFlag < var_10_0 then
			arg_10_0.wayFlag = arg_10_0.wayFlag + 1

			arg_10_0.washTxt:setString(xyd.tables.practiceType:getStyleName(arg_10_0.wayFlag))

			local var_12_0 = xyd.tables.practiceType:getSytle(arg_10_0.wayFlag)

			if var_12_0 == 1 then
				arg_10_0.yuanbao:setVisible(false)
				arg_10_0.jinbi:setVisible(true)
			elseif var_12_0 == 2 then
				arg_10_0.jinbi:setVisible(false)
				arg_10_0.yuanbao:setVisible(true)
			end

			arg_10_0:updateLockTimes()
			arg_10_0:updateComsume(arg_10_0.timesNums[arg_10_0.timesFlag])
		end
	end)
	arg_10_0.container:getChildByName("times_left_btn"):addTouchEventListener(function(arg_13_0, arg_13_1)
		if arg_13_1 == ccui.TouchEventType.ended and arg_10_0.timesFlag > 1 then
			arg_10_0.timesFlag = arg_10_0.timesFlag - 1

			arg_10_0.timesTxt:setString(arg_10_0.timesNums[arg_10_0.timesFlag] .. var_0_1:translation("WASH_USE_TIME"))
			arg_10_0:updateLockTimes()
			arg_10_0:updateComsume(arg_10_0.timesNums[arg_10_0.timesFlag])
		end
	end)
	arg_10_0.container:getChildByName("times_right_btn"):addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.ended and arg_10_0.timesFlag < #arg_10_0.timesNums then
			arg_10_0.timesFlag = arg_10_0.timesFlag + 1

			arg_10_0.timesTxt:setString(arg_10_0.timesNums[arg_10_0.timesFlag] .. var_0_1:translation("WASH_USE_TIME"))
			arg_10_0:updateLockTimes()
			arg_10_0:updateComsume(arg_10_0.timesNums[arg_10_0.timesFlag])
		end
	end)
	arg_10_0.container:getChildByName("start_btn"):addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_15_1 == ccui.TouchEventType.ended then
			arg_10_0:updateWashWayOptioned()

			if arg_10_0:canWash() == true then
				local var_15_0 = {
					practice_num = arg_10_0.timesNums[arg_10_0.timesFlag],
					save_types = arg_10_0.washWayOptioned
				}
				local var_15_1

				if arg_10_0.ishero then
					var_15_0.partner_id = arg_10_0.hero:getHeroID()
					var_15_0.locks = arg_10_0.lockOptioned
					var_15_0.practice_type = arg_10_0.wayFlag
					var_15_1 = xyd.mid.PRACTICE_AUTO
				elseif arg_10_0.ispet then
					var_15_0.pet_id = arg_10_0.hero:getPetID()
					var_15_0.locks = arg_10_0.lockOptioned
					var_15_0.practice_type = arg_10_0.wayFlag
					var_15_1 = xyd.mid.PET_PRACTICE_AUTO
				end

				xyd.Backend.get():request(var_15_1, var_15_0, function(arg_16_0, arg_16_1)
					if arg_16_0 == xyd.error.OK then
						local var_16_0 = {
							resultInfo = arg_16_1,
							oldPracticeAttr = arg_10_0.oldPracticeAttr,
							washWayOptioned = arg_10_0.washWayOptioned,
							practiceInfo = var_15_0,
							ishero = arg_10_0.ishero,
							ispet = arg_10_0.ispet
						}

						arg_10_0.hero:updatePractice(arg_16_1.practice_attr)
						xyd.WindowManager.get():openWindow("wash_process", var_16_0)

						arg_10_0.info = arg_16_1.info
						arg_10_0.oldPracticeAttr = arg_16_1.practice_attr

						arg_10_0:updateComsume(arg_10_0.timesNums[arg_10_0.timesFlag])

						local var_16_1 = xyd.WindowManager.get():getWindow("wash_hero")

						if var_16_1 then
							var_16_1:updateInfo(arg_16_1.info)
							var_16_1:setHero(arg_10_0.hero, arg_10_0.ishero, arg_10_0.ispet)
						end
					end
				end)
			end
		end
	end)
end

function var_0_0.canWash(arg_17_0)
	local var_17_0

	if arg_17_0.isTick == 0 then
		var_17_0 = var_0_1:translation("NOT_CHOOSE_CONDITION")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_17_0
		})

		return false
	elseif arg_17_0.wayFlag > 1 and arg_17_0.player.crystal < arg_17_0.costCrystal then
		var_17_0 = var_0_1:translation("YUANBAO_BUZU")

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_17_0, function()
			local var_18_0 = {}

			var_18_0.windowState = true

			xyd.WindowManager.get():openWindow("vip_recharge", var_18_0)
		end, nil, nil, arg_17_0.colorMode)

		return false
	elseif arg_17_0.wayFlag == 1 and arg_17_0.player.mana < arg_17_0.costMana then
		var_17_0 = var_0_1:translation("JINBI_BUZU")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_17_0
		})

		return false
	elseif tonumber(arg_17_0.oldPracticeAttr[xyd.Practice.Liliang]) >= xyd.WaskAttrUpLimit and tonumber(arg_17_0.oldPracticeAttr[xyd.Practice.Minjie]) >= xyd.WaskAttrUpLimit and tonumber(arg_17_0.oldPracticeAttr[xyd.Practice.Zhili]) >= xyd.WaskAttrUpLimit then
		if arg_17_0.ispet then
			var_17_0 = var_0_1:translation("PET_PRACTICE_UPLIMIT")
		elseif arg_17_0.ishero then
			var_17_0 = var_0_1:translation("HERO_PRACTICE_UPLIMIT")
		end

		xyd.WindowManager.get():openWindow("toast", {
			message = var_17_0
		})

		return false
	elseif arg_17_0.lockTimes > 0 and arg_17_0.info.bless_value <= xyd.tables.practiceLockType:getBlessNum(arg_17_0.lockTimes) * arg_17_0.washNum then
		local var_17_1 = var_0_1:translation("BLESS_VALUE_BUZU")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_17_1
		})

		return false
	else
		return true
	end
end

function var_0_0.updateWashWayOptioned(arg_19_0)
	arg_19_0.isTick = 0

	for iter_19_0 = 1, #arg_19_0.washWayOptioned do
		arg_19_0.isTick = arg_19_0.isTick + arg_19_0.washWayOptioned[iter_19_0]
	end
end

function var_0_0.updateLockTimes(arg_20_0)
	arg_20_0.lockTimes = 0

	for iter_20_0 = 1, #arg_20_0.lockOptioned do
		arg_20_0.lockTimes = arg_20_0.lockTimes + arg_20_0.lockOptioned[iter_20_0]
	end
end

function var_0_0.updateComsume(arg_21_0, arg_21_1)
	arg_21_0:updateLockTimes()

	arg_21_0.washNum = arg_21_1

	local var_21_0 = xyd.tables.practiceType:getNum(arg_21_0.wayFlag)

	if arg_21_0.wayFlag > 1 then
		local var_21_1 = xyd.tables.practiceLockType:getCryStal(arg_21_0.lockTimes)

		if arg_21_0.lockTimes >= 3 then
			var_21_0 = xyd.tables.practiceType:getNum(2)
		end

		local var_21_2 = 0
		local var_21_3 = arg_21_0.info.base_crystal

		for iter_21_0 = 1, arg_21_1 do
			for iter_21_1 = 1, arg_21_0.lockTimes do
				var_21_3 = var_21_3 + var_21_1
				var_21_2 = var_21_2 + var_21_3
			end
		end

		arg_21_0.jinbiNum:setString(var_21_2 + var_21_0 * arg_21_1)

		arg_21_0.costCrystal = var_21_2 + var_21_0 * arg_21_1
	else
		local var_21_4 = xyd.tables.practiceLockType:getMana(arg_21_0.lockTimes)
		local var_21_5 = 0
		local var_21_6 = arg_21_0.info.base_mana

		for iter_21_2 = 1, arg_21_1 do
			for iter_21_3 = 1, arg_21_0.lockTimes do
				var_21_6 = var_21_6 + var_21_4
				var_21_5 = var_21_5 + var_21_6
			end
		end

		arg_21_0.jinbiNum:setString(var_21_5 + var_21_0 * arg_21_1)

		arg_21_0.costMana = var_21_5 + var_21_0 * arg_21_1
	end
end

function var_0_0.setSaveAttrBtn(arg_22_0)
	for iter_22_0, iter_22_1 in ipairs(arg_22_0.attributeTrueBtn) do
		iter_22_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_23_0)
			if arg_23_0.name == "began" then
				return true
			elseif arg_23_0.name == "ended" and arg_22_0.washWayOptioned[iter_22_0] == 1 then
				arg_22_0.washWayOptioned[iter_22_0] = 0

				iter_22_1:setVisible(false)
				iter_22_1:setTouchEnabled(false)
				arg_22_0.attributeFalseBtn[iter_22_0]:setVisible(true)
				arg_22_0.attributeFalseBtn[iter_22_0]:setTouchEnabled(true)
				arg_22_0:updateComsume(arg_22_0.timesNums[arg_22_0.timesFlag])
			end
		end)
	end

	for iter_22_2, iter_22_3 in ipairs(arg_22_0.attributeFalseBtn) do
		iter_22_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_24_0)
			if arg_24_0.name == "began" then
				return true
			elseif arg_24_0.name == "ended" and arg_22_0.washWayOptioned[iter_22_2] == 0 then
				arg_22_0.washWayOptioned[iter_22_2] = 1

				iter_22_3:setVisible(false)
				iter_22_3:setTouchEnabled(false)
				arg_22_0.attributeTrueBtn[iter_22_2]:setVisible(true)
				arg_22_0.attributeTrueBtn[iter_22_2]:setTouchEnabled(true)
				arg_22_0:updateComsume(arg_22_0.timesNums[arg_22_0.timesFlag])
			end
		end)
	end
end

function var_0_0.setLockBtn(arg_25_0)
	for iter_25_0, iter_25_1 in ipairs(arg_25_0.lockClose) do
		iter_25_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_26_0)
			if arg_26_0.name == "began" then
				return true
			elseif arg_26_0.name == "ended" and arg_25_0.lockOptioned[iter_25_0] == 1 then
				arg_25_0.lockOptioned[iter_25_0] = 0

				iter_25_1:setVisible(false)
				iter_25_1:setTouchEnabled(false)
				arg_25_0.lockOpen[iter_25_0]:setVisible(true)
				arg_25_0.lockOpen[iter_25_0]:setTouchEnabled(true)
				arg_25_0.attributeTrueBtn[iter_25_0]:setTouchEnabled(true)
				arg_25_0:updateLockTimes()
				arg_25_0:updateComsume(arg_25_0.timesNums[arg_25_0.timesFlag])
			end
		end)
	end

	for iter_25_2, iter_25_3 in ipairs(arg_25_0.lockOpen) do
		iter_25_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_27_0)
			if arg_27_0.name == "began" then
				return true
			elseif arg_27_0.name == "ended" and arg_25_0.lockOptioned[iter_25_2] == 0 then
				arg_25_0.lockOptioned[iter_25_2] = 1

				iter_25_3:setVisible(false)
				iter_25_3:setTouchEnabled(false)
				arg_25_0.lockClose[iter_25_2]:setVisible(true)
				arg_25_0.lockClose[iter_25_2]:setTouchEnabled(true)

				arg_25_0.washWayOptioned[iter_25_2] = 1

				arg_25_0.attributeTrueBtn[iter_25_2]:setVisible(true)
				arg_25_0.attributeTrueBtn[iter_25_2]:setTouchEnabled(false)
				arg_25_0.attributeFalseBtn[iter_25_2]:setVisible(false)
				arg_25_0.attributeFalseBtn[iter_25_2]:setTouchEnabled(false)
				arg_25_0:updateLockTimes()
				arg_25_0:updateComsume(arg_25_0.timesNums[arg_25_0.timesFlag])
			end
		end)
	end
end

function var_0_0.willClose(arg_28_0, arg_28_1)
	var_0_0.super.willClose(arg_28_0, arg_28_1)
end

function var_0_0.didClose(arg_29_0, arg_29_1)
	var_0_0.super.didClose(arg_29_0, arg_29_1)
end

return var_0_0
