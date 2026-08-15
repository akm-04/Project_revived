local var_0_0 = class("WashProcessWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = require("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.result = arg_1_2.resultInfo
	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.oldPracticeAttr = arg_1_2.oldPracticeAttr
	arg_1_0.oldPractice = clone(arg_1_0.oldPracticeAttr)
	arg_1_0.washWayOptioned = arg_1_2.washWayOptioned
	arg_1_0.params = arg_1_2.practiceInfo
	arg_1_0.wayFlag = arg_1_2.practice_type
	arg_1_0.ishero = arg_1_2.ishero
	arg_1_0.ispet = arg_1_2.ispet
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addBlockLayer(cc.c4b(0, 0, 0, 0), false, true, handler(arg_2_0, arg_2_0.click))

	arg_2_0.second = 1
	arg_2_0.playEnd = false
	arg_2_0.costCrysta = 0
	arg_2_0.costMana = 0

	arg_2_0:updateComsume(xyd.WashTimes.TEN)
	arg_2_0:layout()
	arg_2_0:setBtn()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:play(arg_3_0.result, arg_3_0.params.practice_num)
end

function var_0_0.layout(arg_4_0)
	arg_4_0.container = arg_4_0:nodeByName("container")
	arg_4_0.giveupTxt = arg_4_0.container:getChildByName("giveup_txt")

	arg_4_0.giveupTxt:setString(string.format(var_0_1:translation("WASH_GIVEUP_TIME"), 0))
	arg_4_0.container:getChildByName("shuxing1_txt"):setString(var_0_1:translation("WASH_ATTRIBUTE_LI"))
	arg_4_0.container:getChildByName("shuxing2_txt"):setString(var_0_1:translation("WASH_ATTRIBUTE_ZHI"))
	arg_4_0.container:getChildByName("shuxing3_txt"):setString(var_0_1:translation("WASH_ATTRIBUTE_MIN"))

	local var_4_0 = arg_4_0.container:getChildByName("title_txt")

	var_4_0:setString(var_0_1:translation("STATR_WASH"))
	var_4_0:enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_4_0.container:getChildByName("more"):setString(var_0_1:translation("WASH_MORE"))

	arg_4_0.shuxingLiliang = arg_4_0.container:getChildByName("shuxing_liliang_txt")

	arg_4_0.shuxingLiliang:setString(var_0_1:translation("WASH_ATTRIBUTE_LILIANG"))

	arg_4_0.shuxingMinjie = arg_4_0.container:getChildByName("shuxing_minjie_txt")

	arg_4_0.shuxingMinjie:setString(var_0_1:translation("WASH_ATTRIBUTE_MINJIE"))

	arg_4_0.shuxingZhili = arg_4_0.container:getChildByName("shuxing_zhili_txt")

	arg_4_0.shuxingZhili:setString(var_0_1:translation("WASH_ATTRIBUTE_ZHILI"))
	arg_4_0.container:getChildByName("gap5"):setString(tostring(10) .. var_0_1:translation("WASH_USE_TIME"))

	arg_4_0.li = arg_4_0.container:getChildByName("li_num")
	arg_4_0.min = arg_4_0.container:getChildByName("min_num")
	arg_4_0.zhi = arg_4_0.container:getChildByName("zhi_num_")
	arg_4_0.liChange = arg_4_0.container:getChildByName("li_change_num")
	arg_4_0.minChange = arg_4_0.container:getChildByName("min_change_num")
	arg_4_0.zhiChange = arg_4_0.container:getChildByName("zhi_change_num")
	arg_4_0.liliang = arg_4_0.container:getChildByName("liliang_old_num")
	arg_4_0.minjie = arg_4_0.container:getChildByName("minjie_old_num")
	arg_4_0.zhili = arg_4_0.container:getChildByName("zhili_old_num")
	arg_4_0.jiantou1 = arg_4_0.container:getChildByName("jiantou1")
	arg_4_0.jiantou2 = arg_4_0.container:getChildByName("jiantou2")
	arg_4_0.jiantou3 = arg_4_0.container:getChildByName("jiantou3")
	arg_4_0.newLiliang = arg_4_0.container:getChildByName("liliang_new_num")
	arg_4_0.newMinjie = arg_4_0.container:getChildByName("minjie_new_num")
	arg_4_0.newZhili = arg_4_0.container:getChildByName("zhili_new_num")

	arg_4_0:setViewChange(false)

	arg_4_0.listContainer = arg_4_0.container:getChildByName("list")
	arg_4_0.list = cc.ui.UIListView.new({
		async = false,
		viewRect = cc.rect(0, 0, 450, 180),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_4_0.listContainer)
	arg_4_0.last1 = arg_4_0.oldPracticeAttr[1]
	arg_4_0.last2 = arg_4_0.oldPracticeAttr[2]
	arg_4_0.last3 = arg_4_0.oldPracticeAttr[3]
end

function var_0_0.click(arg_5_0)
	if arg_5_0.handle then
		var_0_2.unscheduleGlobal(arg_5_0.handle)
	end

	if arg_5_0.playEnd == true then
		xyd.WindowManager.get():closeWindow("wash_process")
	end

	if arg_5_0.playEnd == false then
		arg_5_0.playEnd = true

		arg_5_0:parsingResult(arg_5_0.result)

		if arg_5_0.result.is_adds[#arg_5_0.result.is_adds] == 0 then
			arg_5_0.giveupTxt:setString(string.format(var_0_1:translation("WASH_GIVEUP_TIME"), #arg_5_0.result.is_adds))
		elseif arg_5_0.result.is_adds[#arg_5_0.result.is_adds] == 1 then
			arg_5_0.giveupTxt:setString(string.format(var_0_1:translation("WASH_SAVE_TIME"), #arg_5_0.result.is_adds))
		end

		local var_5_0 = xyd.WindowManager.get():getWindow("wash_hero_auto")

		if var_5_0 then
			arg_5_0.oldPracticeAttr = var_5_0.oldPracticeAttr
			arg_5_0.oldPractice = clone(var_5_0.oldPracticeAttr)

			arg_5_0.list:scrollTo(0, 0)
		end
	end
end

function var_0_0.play(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = 0.03333333333333333
	local var_6_1 = 5
	local var_6_2 = var_6_1 / xyd.tables.misc.fps
	local var_6_3 = var_6_1 % xyd.tables.misc.fps

	local function var_6_4()
		if var_6_2 >= arg_6_2 + 0.001 then
			if arg_6_0.handle then
				arg_6_0.playEnd = true
				arg_6_0.oldPracticeAttr = clone(arg_6_0.oldPractice)

				var_0_2.unscheduleGlobal(arg_6_0.handle)
			end
		elseif var_6_3 ~= 0 then
			arg_6_0:updateProcess(10, var_6_2)
		elseif var_6_3 == 0 then
			arg_6_0:setViewProcess(arg_6_1, arg_6_2 + 1, var_6_2)
		end

		if var_6_2 <= arg_6_2 then
			arg_6_0.list:scrollTo(0, -180 * arg_6_2 + 180 * var_6_2)
		end

		var_6_1 = var_6_1 + 5
		var_6_2 = var_6_1 / xyd.tables.misc.fps
		var_6_3 = var_6_1 % xyd.tables.misc.fps
	end

	arg_6_0:parsingResult(arg_6_1)
	var_6_4()

	arg_6_0.handle = var_0_2.scheduleGlobal(var_6_4, var_6_0)
end

function var_0_0.setViewProcess(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	if arg_8_3 == arg_8_2 then
		-- block empty
	else
		arg_8_0:updateProcess(10, arg_8_3)

		local var_8_0 = arg_8_1.add_attrs
		local var_8_1 = arg_8_1.is_adds

		arg_8_0.liChange:removeAllChildren()
		arg_8_0.minChange:removeAllChildren()
		arg_8_0.zhiChange:removeAllChildren()

		local var_8_2 = {
			size = 24,
			color = cc.c3b(240, 0, 0)
		}
		local var_8_3 = xyd.AssetLoader:get():loadLabel(var_8_2)

		var_8_3:setMaxLineWidth(300)

		if arg_8_0:getSign(var_8_0[arg_8_3][1]) ~= nil then
			var_8_3:setString(string.format(var_0_1:translation("KUO_HAO"), arg_8_0:getSign(var_8_0[arg_8_3][1]) .. var_8_0[arg_8_3][1]))
			var_8_3:setColor(cc.c3b(0, 240, 0))
		elseif var_8_0[arg_8_3][1] < 0 then
			var_8_3:setString(string.format(var_0_1:translation("KUO_HAO"), var_8_0[arg_8_3][1]))
		else
			var_8_3:setString("")
		end

		arg_8_0.liChange:addChild(var_8_3)
		var_8_3:setAnchorPoint(0.5, 0.5)
		var_8_3:setPosition(5, -10)

		if tonumber(var_8_0[arg_8_3][1]) < -99 then
			var_8_3:setAnchorPoint(0.5, 0.5)
			var_8_3:setPosition(5, -10)
		end

		local var_8_4 = xyd.AssetLoader:get():loadLabel(var_8_2)

		var_8_4:setMaxLineWidth(300)

		if arg_8_0:getSign(var_8_0[arg_8_3][2]) ~= nil then
			var_8_4:setString(string.format(var_0_1:translation("KUO_HAO"), arg_8_0:getSign(var_8_0[arg_8_3][2]) .. var_8_0[arg_8_3][2]))
			var_8_4:setColor(cc.c3b(0, 240, 0))
		elseif var_8_0[arg_8_3][2] < 0 then
			var_8_4:setString(string.format(var_0_1:translation("KUO_HAO"), var_8_0[arg_8_3][2]))
		else
			var_8_4:setString("")
		end

		arg_8_0.zhiChange:addChild(var_8_4)
		var_8_4:setAnchorPoint(0.5, 0.5)
		var_8_4:setPosition(10, -11)

		if tonumber(var_8_0[arg_8_3][2]) < -99 then
			var_8_4:setAnchorPoint(0.5, 0.5)
			var_8_4:setPosition(10, -11)
		end

		local var_8_5 = xyd.AssetLoader:get():loadLabel(var_8_2)

		var_8_5:setMaxLineWidth(300)

		if arg_8_0:getSign(var_8_0[arg_8_3][3]) ~= nil then
			var_8_5:setString(string.format(var_0_1:translation("KUO_HAO"), arg_8_0:getSign(var_8_0[arg_8_3][3]) .. var_8_0[arg_8_3][3]))
			var_8_5:setColor(cc.c3b(0, 240, 0))
		elseif var_8_0[arg_8_3][3] < 0 then
			var_8_5:setString(string.format(var_0_1:translation("KUO_HAO"), var_8_0[arg_8_3][3]))
		else
			var_8_5:setString("")
		end

		arg_8_0.minChange:addChild(var_8_5)
		var_8_5:setAnchorPoint(0.5, 0.5)
		var_8_5:setPosition(10, -10)

		if tonumber(var_8_0[arg_8_3][3]) < -99 then
			var_8_5:setAnchorPoint(0.5, 0.5)
			var_8_5:setPosition(10, -10)
		end

		if var_8_1[arg_8_3] == 0 then
			arg_8_0.li:setString(arg_8_0.oldPractice[1])
			arg_8_0.min:setString(arg_8_0.oldPractice[3])
			arg_8_0.zhi:setString(arg_8_0.oldPractice[2])
			arg_8_0.giveupTxt:setString(string.format(var_0_1:translation("WASH_GIVEUP_TIME"), arg_8_3))
		elseif var_8_1[arg_8_3] == 1 then
			arg_8_0.oldPractice[1] = arg_8_0.oldPractice[1] + var_8_0[arg_8_3][1]
			arg_8_0.oldPractice[2] = arg_8_0.oldPractice[2] + var_8_0[arg_8_3][2]
			arg_8_0.oldPractice[3] = arg_8_0.oldPractice[3] + var_8_0[arg_8_3][3]

			arg_8_0.li:setString(arg_8_0.oldPractice[1])
			arg_8_0.zhi:setString(arg_8_0.oldPractice[2])
			arg_8_0.min:setString(arg_8_0.oldPractice[3])
			arg_8_0.giveupTxt:setString(string.format(var_0_1:translation("WASH_SAVE_TIME"), arg_8_3))
		end
	end
end

function var_0_0.getSign(arg_9_0, arg_9_1)
	local var_9_0 = tonumber(arg_9_1)

	if var_9_0 > 0 then
		return "+"
	elseif var_9_0 == 0 then
		return nil
	else
		return nil
	end
end

function var_0_0.setViewChange(arg_10_0, arg_10_1)
	arg_10_0.jiantou1:setVisible(arg_10_1)
	arg_10_0.jiantou2:setVisible(arg_10_1)
	arg_10_0.jiantou3:setVisible(arg_10_1)
	arg_10_0.shuxingLiliang:setVisible(arg_10_1)
	arg_10_0.shuxingZhili:setVisible(arg_10_1)
	arg_10_0.shuxingMinjie:setVisible(arg_10_1)
	arg_10_0.liliang:setVisible(arg_10_1)
	arg_10_0.minjie:setVisible(arg_10_1)
	arg_10_0.zhili:setVisible(arg_10_1)
	arg_10_0.newLiliang:setVisible(arg_10_1)
	arg_10_0.newMinjie:setVisible(arg_10_1)
	arg_10_0.newZhili:setVisible(arg_10_1)
end

function var_0_0.parsingResult(arg_11_0, arg_11_1)
	arg_11_0.liliang:setString(arg_11_0.oldPracticeAttr[1])
	arg_11_0.zhili:setString(arg_11_0.oldPracticeAttr[2])
	arg_11_0.minjie:setString(arg_11_0.oldPracticeAttr[3])

	local var_11_0 = arg_11_1.add_attrs
	local var_11_1 = arg_11_1.is_adds
	local var_11_2 = {}

	for iter_11_0 = 1, #arg_11_0.oldPracticeAttr do
		table.insert(var_11_2, 0)
	end

	arg_11_0.list:removeAllItems()

	for iter_11_1 = 1, #var_11_0 do
		local var_11_3 = arg_11_0.list:newItem()
		local var_11_4 = display.newNode()
		local var_11_5 = xyd.AssetLoader.get():loadNodeFromJson("windows/wash_progress/item.csb")
		local var_11_6 = var_11_5:getChildByName("container")

		var_11_6:getChildByName("liliang_txt"):setString(var_0_1:translation("LILIANG_ADD"))
		var_11_6:getChildByName("minjie_txt"):setString(var_0_1:translation("MINJIE_ZENGJIA"))
		var_11_6:getChildByName("zhili_txt"):setString(var_0_1:translation("ZHILI_ZENGJIA"))

		local var_11_7 = var_11_6:getChildByName("liliang_old_num")
		local var_11_8 = var_11_6:getChildByName("minjie_old_num")
		local var_11_9 = var_11_6:getChildByName("zhili_old_num")
		local var_11_10 = var_11_6:getChildByName("liliang_new_num")
		local var_11_11 = var_11_6:getChildByName("minjie_new_num")
		local var_11_12 = var_11_6:getChildByName("zhili_new_num")

		var_11_7:setString(arg_11_0.oldPracticeAttr[1] + var_11_2[1])
		var_11_9:setString(arg_11_0.oldPracticeAttr[2] + var_11_2[2])
		var_11_8:setString(arg_11_0.oldPracticeAttr[3] + var_11_2[3])

		local var_11_13 = var_11_6:getChildByName("give_txt")

		if var_11_1[iter_11_1] == 1 then
			var_11_2[1] = var_11_2[1] + var_11_0[iter_11_1][1]
			var_11_2[2] = var_11_2[2] + var_11_0[iter_11_1][2]
			var_11_2[3] = var_11_2[3] + var_11_0[iter_11_1][3]

			var_11_10:setString(arg_11_0.oldPracticeAttr[1] + var_11_2[1])
			var_11_12:setString(arg_11_0.oldPracticeAttr[2] + var_11_2[2])
			var_11_11:setString(arg_11_0.oldPracticeAttr[3] + var_11_2[3])

			arg_11_0.last1 = arg_11_0.oldPracticeAttr[1] + var_11_2[1]
			arg_11_0.last2 = arg_11_0.oldPracticeAttr[2] + var_11_2[2]
			arg_11_0.last3 = arg_11_0.oldPracticeAttr[3] + var_11_2[3]
		elseif var_11_1[iter_11_1] == 0 then
			var_11_10:setString(arg_11_0.last1)
			var_11_12:setString(arg_11_0.last2)
			var_11_11:setString(arg_11_0.last3)
		end

		var_11_13:setString(string.format(var_0_1:translation("WASH_COUNT_RESULR"), iter_11_1))
		var_11_5:addTo(var_11_4)
		var_11_5:setTouchEnabled(false)
		var_11_5:setAnchorPoint(cc.p(0, 0))
		var_11_5:setPosition(45, 0)
		var_11_5:setTouchSwallowEnabled(true)
		var_11_4:setContentSize(450, 180)
		var_11_3:addContent(var_11_4)
		var_11_3:setItemSize(450, 180)
		arg_11_0.list:addItem(var_11_3)
		arg_11_0.list:reload()
	end

	arg_11_0:updateResult(var_11_2)
	arg_11_0:updateProcess(xyd.WashTimes.TEN, #var_11_0)
end

function var_0_0.updateResult(arg_12_0, arg_12_1)
	arg_12_0.newLiliang:setString(arg_12_0.oldPracticeAttr[1] + arg_12_1[1])
	arg_12_0.newZhili:setString(arg_12_0.oldPracticeAttr[2] + arg_12_1[2])
	arg_12_0.newMinjie:setString(arg_12_0.oldPracticeAttr[3] + arg_12_1[3])
	arg_12_0.li:setString(arg_12_0.oldPracticeAttr[1] + arg_12_1[1])
	arg_12_0.zhi:setString(arg_12_0.oldPracticeAttr[2] + arg_12_1[2])
	arg_12_0.min:setString(arg_12_0.oldPracticeAttr[3] + arg_12_1[3])
end

function var_0_0.canWash(arg_13_0)
	arg_13_0:updateComsume(arg_13_0.params.practice_num)

	local var_13_0

	if tonumber(arg_13_0.params.practice_type) > xyd.WashWay.NORMAL and arg_13_0.player.crystal < arg_13_0.costCrystal then
		var_13_0 = var_0_1:translation("YUANBAO_BUZU")

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_13_0, function()
			local var_14_0 = {}

			var_14_0.windowState = true

			xyd.WindowManager.get():openWindow("vip_recharge", var_14_0)
		end, nil, nil, arg_13_0.colorMode)

		return false
	elseif arg_13_0.player.mana < arg_13_0.costMana then
		var_13_0 = var_0_1:translation("JINBI_BUZU")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_13_0
		})

		return false
	elseif tonumber(arg_13_0.oldPracticeAttr[1]) >= xyd.WaskAttrUpLimit and tonumber(arg_13_0.oldPracticeAttr[2]) >= xyd.WaskAttrUpLimit and tonumber(arg_13_0.oldPracticeAttr[3]) >= xyd.WaskAttrUpLimit then
		if arg_13_0.ispet then
			var_13_0 = var_0_1:translation("PET_PRACTICE_UPLIMIT")
		elseif arg_13_0.ishero then
			var_13_0 = var_0_1:translation("HERO_PRACTICE_UPLIMIT")
		end

		xyd.WindowManager.get():openWindow("toast", {
			message = var_13_0
		})

		return false
	elseif arg_13_0.lockTimes ~= 0 and arg_13_0.result.info.bless_value <= xyd.tables.practiceLockType:getBlessNum(arg_13_0.lockTimes) * arg_13_0.params.practice_num then
		local var_13_1 = var_0_1:translation("BLESS_VALUE_BUZU")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_13_1
		})

		return false
	else
		return true
	end
end

function var_0_0.updateLockTimes(arg_15_0)
	arg_15_0.lockTimes = 0

	for iter_15_0 = 1, #arg_15_0.params.locks do
		arg_15_0.lockTimes = arg_15_0.lockTimes + arg_15_0.params.locks[iter_15_0]
	end
end

function var_0_0.updateComsume(arg_16_0, arg_16_1)
	local var_16_0 = arg_16_0.result.info

	arg_16_0:updateLockTimes()

	local var_16_1 = xyd.tables.practiceType:getNum(arg_16_0.params.practice_type)

	if tonumber(arg_16_0.params.practice_type) > 1 then
		local var_16_2 = xyd.tables.practiceLockType:getCryStal(arg_16_0.lockTimes)

		if arg_16_0.lockTimes >= 3 then
			var_16_1 = xyd.tables.practiceType:getNum(2)
		end

		local var_16_3 = 0
		local var_16_4 = var_16_0.base_crystal

		for iter_16_0 = 1, arg_16_1 do
			for iter_16_1 = 1, arg_16_0.lockTimes do
				var_16_4 = var_16_4 + var_16_2
				var_16_3 = var_16_3 + var_16_4
			end
		end

		arg_16_0.costCrystal = var_16_3 + var_16_1 * arg_16_1
	else
		local var_16_5 = xyd.tables.practiceLockType:getMana(arg_16_0.lockTimes)
		local var_16_6 = 0
		local var_16_7 = var_16_0.base_mana

		for iter_16_2 = 1, arg_16_1 do
			for iter_16_3 = 1, arg_16_0.lockTimes do
				var_16_7 = var_16_7 + var_16_5
				var_16_6 = var_16_6 + var_16_7
			end
		end

		arg_16_0.costMana = var_16_6 + var_16_1 * arg_16_1
	end
end

function var_0_0.setBtn(arg_17_0)
	arg_17_0.container:getChildByName("more_btn"):addTouchEventListener(function(arg_18_0, arg_18_1)
		if arg_18_1 == ccui.TouchEventType.ended and arg_17_0:canWash() == true and arg_17_0.playEnd == true then
			local var_18_0 = {}

			arg_17_0.params.practice_num = xyd.WashTimes.TEN

			local var_18_1

			if arg_17_0.ishero then
				var_18_1 = xyd.mid.PRACTICE_AUTO
			elseif arg_17_0.ispet then
				var_18_1 = xyd.mid.PET_PRACTICE_AUTO
			end

			xyd.Backend.get():request(var_18_1, arg_17_0.params, function(arg_19_0, arg_19_1)
				if arg_19_0 == xyd.error.OK then
					arg_17_0.playEnd = false

					arg_17_0:setViewChange(false)
					arg_17_0:play(arg_19_1, arg_17_0.params.practice_num)

					arg_17_0.result = arg_19_1

					local var_19_0 = xyd.WindowManager.get():getWindow("wash_hero_auto")

					if var_19_0 then
						var_19_0.info = arg_19_1.info
						var_19_0.oldPracticeAttr = arg_19_1.practice_attr

						var_19_0:updateComsume(var_19_0.timesNums[var_19_0.timesFlag])
						var_19_0.hero:updatePractice(arg_19_1.practice_attr)
					end

					local var_19_1 = xyd.WindowManager.get():getWindow("wash_hero")

					if var_19_1 then
						var_19_1:updateInfo(arg_19_1.info)
						var_19_1:setHero(var_19_1.hero, arg_17_0.ishero, arg_17_0.ispet)
					end
				end
			end)
		end
	end)
end

function var_0_0.updateProcess(arg_20_0, arg_20_1, arg_20_2)
	local var_20_0 = math.min(arg_20_2 / arg_20_1 * 100, 100)
	local var_20_1 = arg_20_0.container:getChildByName("process_bar")

	var_20_1:setPercent(var_20_0)

	local var_20_2 = "windows/wash_progress/light_point.png"

	if arg_20_0.pointIcon == nil then
		arg_20_0.pointIcon = xyd.AssetLoader.get():loadSprite(var_20_2)

		var_20_1:addChild(arg_20_0.pointIcon)
	end

	arg_20_0.pointIcon:setPosition(var_20_1:getWidth() * arg_20_2 / arg_20_1, 20)
end

function var_0_0.willClose(arg_21_0, arg_21_1)
	var_0_0.super.willClose(arg_21_0, arg_21_1)

	if arg_21_0.handle then
		var_0_2.unscheduleGlobal(arg_21_0.handle)
	end
end

function var_0_0.didClose(arg_22_0, arg_22_1)
	var_0_0.super.didClose(arg_22_0, arg_22_1)
end

return var_0_0
