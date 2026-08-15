local var_0_0 = class("HeroTuJianFilterWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpriteNodeButton")
local var_0_2 = import("app.common.ui.SplitLine")
local var_0_3 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.sortType = arg_1_0.selfPlayer.tuJianSortType or 0

	if arg_1_2 then
		arg_1_0.awakenNotShow = arg_1_2.awaken_not_show
	end

	arg_1_0:getInitSortType()
end

function var_0_0.getInitSortType(arg_2_0)
	local var_2_0
	local var_2_1
	local var_2_2
	local var_2_3
	local var_2_4

	if arg_2_0.sortType > 0 then
		var_2_0 = {
			0,
			0
		}
		var_2_1 = {
			0,
			0,
			0
		}
		var_2_2 = {
			0,
			0,
			0
		}
		var_2_3 = {
			0,
			0,
			0
		}
		var_2_4 = {
			0,
			0,
			0,
			0
		}

		local var_2_5 = {}
		local var_2_6 = arg_2_0.sortType
		local var_2_7 = 1

		while var_2_6 > 0 do
			var_2_5[var_2_7] = var_2_6 % 2
			var_2_7 = var_2_7 + 1
			var_2_6 = math.floor(var_2_6 / 2)
		end

		local var_2_8 = 1

		for iter_2_0 = 15, 1, -1 do
			if iter_2_0 <= 4 then
				if iter_2_0 == 4 then
					var_2_8 = 1
				end

				if var_2_5[iter_2_0] then
					var_2_4[var_2_8] = var_2_5[iter_2_0]
				end
			elseif iter_2_0 <= 7 then
				if iter_2_0 == 7 then
					var_2_8 = 1
				end

				if var_2_5[iter_2_0] then
					var_2_3[var_2_8] = var_2_5[iter_2_0]
				end
			elseif iter_2_0 <= 10 then
				if iter_2_0 == 10 then
					var_2_8 = 1
				end

				if var_2_5[iter_2_0] then
					var_2_2[var_2_8] = var_2_5[iter_2_0]
				end
			elseif iter_2_0 <= 13 then
				if iter_2_0 == 13 then
					var_2_8 = 1
				end

				if var_2_5[iter_2_0] then
					var_2_1[var_2_8] = var_2_5[iter_2_0]
				end
			elseif iter_2_0 <= 15 and var_2_5[iter_2_0] then
				var_2_0[var_2_8] = var_2_5[iter_2_0]
			end

			var_2_8 = var_2_8 + 1
		end
	else
		var_2_0 = {
			1,
			1
		}
		var_2_1 = {
			1,
			1,
			1
		}
		var_2_2 = {
			1,
			1,
			1
		}
		var_2_4 = {
			1,
			1,
			1,
			1
		}
		var_2_3 = {
			1,
			1,
			1
		}
	end

	dump(var_2_0)

	arg_2_0.herosFavor = var_2_0
	arg_2_0.herosPos = var_2_1
	arg_2_0.herosType = var_2_2
	arg_2_0.herosAwaken = var_2_3
	arg_2_0.herosPower = var_2_4
end

function var_0_0.willOpen(arg_3_0)
	if arg_3_0.awakenNotShow then
		arg_3_0:nodeByName("pos_txt_awake"):setVisible(false)

		for iter_3_0 = 1, 3 do
			arg_3_0:nodeByName("check_awake_" .. iter_3_0):setVisible(false)
			arg_3_0:nodeByName("pos_txt_awake_" .. iter_3_0):setVisible(false)
		end
	end

	arg_3_0:addText()
	arg_3_0:initCheckbox()

	local var_3_0 = var_0_2.new({
		size = 740
	})

	var_3_0:addTo(arg_3_0:background())
	var_3_0:setAnchorPoint(0.5, 0.5)
	var_3_0:setPosition(arg_3_0:nodeByName("pos_splitline"):getPosition())
end

function var_0_0.didOpen(arg_4_0)
	arg_4_0:addBlockLayer()
	arg_4_0:nodeByName("txt_btn_ok"):setString(var_0_3:translation("CONFIRM_TEXT"))

	arg_4_0.confirmBtn = arg_4_0:nodeByName("btn_ok")

	arg_4_0.confirmBtn:setTouchEnabled(true)
	arg_4_0.confirmBtn:addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_4_0.confirmBtn, arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended and not arg_4_0.isSummon then
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.HERO_TUJIAN_FILTER,
				filterParams = arg_4_0:getFilterParams()
			})

			arg_4_0.selfPlayer.tuJianSortType = arg_4_0.sortType

			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
	arg_4_0:nodeByName("btn_close"):setTouchEnabled(true)
	arg_4_0:nodeByName("btn_close"):addTouchEventListener(function(arg_6_0, arg_6_1)
		xyd.buttonScaleAnim(arg_4_0:nodeByName("btn_close"), arg_6_1)

		if arg_6_1 == ccui.TouchEventType.ended and not arg_4_0.isSummon then
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
end

function var_0_0.initCheckbox(arg_7_0)
	arg_7_0.favorCheckbox = {}

	for iter_7_0, iter_7_1 in pairs(xyd.HerosFavorType) do
		arg_7_0.favorCheckbox[iter_7_1] = arg_7_0:nodeByName("check_favor_" .. iter_7_1)

		if arg_7_0.herosFavor[iter_7_1] > 0 then
			arg_7_0.favorCheckbox[iter_7_1]:setSelected(true)
		else
			arg_7_0.favorCheckbox[iter_7_1]:setSelected(false)
		end
	end

	arg_7_0.posCheckbox = {}

	for iter_7_2, iter_7_3 in pairs(xyd.HeroPosType) do
		arg_7_0.posCheckbox[iter_7_3] = arg_7_0:nodeByName("check_dis_" .. iter_7_3 - 1)

		if arg_7_0.herosPos[iter_7_3 - 1] > 0 then
			arg_7_0.posCheckbox[iter_7_3]:setSelected(true)
		else
			arg_7_0.posCheckbox[iter_7_3]:setSelected(false)
		end
	end

	arg_7_0.forceCheckbox = {}

	for iter_7_4, iter_7_5 in pairs(xyd.HeroForceType) do
		arg_7_0.forceCheckbox[iter_7_5] = arg_7_0:nodeByName("check_force_" .. iter_7_5)

		if arg_7_0.herosPower[iter_7_5] > 0 then
			arg_7_0.forceCheckbox[iter_7_5]:setSelected(true)
		else
			arg_7_0.forceCheckbox[iter_7_5]:setSelected(false)
		end
	end

	arg_7_0.attrCheckbox = {}

	for iter_7_6, iter_7_7 in pairs(xyd.HeroAttrType) do
		arg_7_0.attrCheckbox[iter_7_7] = arg_7_0:nodeByName("check_attr_" .. iter_7_7)

		if arg_7_0.herosType[iter_7_7] > 0 then
			arg_7_0.attrCheckbox[iter_7_7]:setSelected(true)
		else
			arg_7_0.attrCheckbox[iter_7_7]:setSelected(false)
		end
	end

	arg_7_0.awakeCheckbox = {}

	for iter_7_8, iter_7_9 in pairs(xyd.HeroAwakeType) do
		arg_7_0.awakeCheckbox[iter_7_9] = arg_7_0:nodeByName("check_awake_" .. iter_7_9)

		if arg_7_0.herosAwaken[iter_7_9] > 0 then
			arg_7_0.awakeCheckbox[iter_7_9]:setSelected(true)
		else
			arg_7_0.awakeCheckbox[iter_7_9]:setSelected(false)
		end
	end
end

function var_0_0.checkFilterParams(arg_8_0)
	local var_8_0

	if not arg_8_0.posCheckbox[xyd.HeroPosType.FRONT]:isSelected() and not arg_8_0.posCheckbox[xyd.HeroPosType.MIDDLE]:isSelected() and not arg_8_0.posCheckbox[xyd.HeroPosType.BACK]:isSelected() then
		var_8_0 = var_0_3:translation("HERO_FILTER_POS_TIP")
	end

	if not var_8_0 and not arg_8_0.forceCheckbox[xyd.HeroForceType.WEI]:isSelected() and not arg_8_0.forceCheckbox[xyd.HeroForceType.SHU]:isSelected() and not arg_8_0.forceCheckbox[xyd.HeroForceType.WU]:isSelected() and not arg_8_0.forceCheckbox[xyd.HeroForceType.QUN]:isSelected() then
		var_8_0 = var_0_3:translation("HERO_FILTER_POWER_TIP")
	end

	if not var_8_0 and not arg_8_0.attrCheckbox[xyd.HeroAttrType.LI]:isSelected() and not arg_8_0.attrCheckbox[xyd.HeroAttrType.ZHI]:isSelected() and not arg_8_0.attrCheckbox[xyd.HeroAttrType.MIN]:isSelected() then
		var_8_0 = var_0_3:translation("HERO_FILTER_TYPE_TIP")
	end

	if not var_8_0 and not arg_8_0.awakeCheckbox[xyd.HeroAwakeType.AWAKE]:isSelected() and not arg_8_0.awakeCheckbox[xyd.HeroAwakeType.AWAKE_TWICE]:isSelected() and not arg_8_0.awakeCheckbox[xyd.HeroAwakeType.NO_AWAKE]:isSelected() then
		var_8_0 = var_0_3:translation("HERO_FILTER_AWAKEN_TIP")
	end

	if var_8_0 then
		local var_8_1 = {
			txt = var_8_0,
			type = xyd.CommonAlertType.ONE_BTN,
			align = xyd.ui_align.CENTER
		}

		xyd.WindowManager.get():openWindow("common_alert", var_8_1)

		return false
	end

	return true
end

function var_0_0.getFilterParams(arg_9_0)
	arg_9_0.sortType = 0

	local var_9_0

	if not arg_9_0.favorCheckbox[xyd.HerosFavorType.FAVOR]:isSelected() or not arg_9_0.favorCheckbox[xyd.HerosFavorType.NO_FAVOR]:isSelected() then
		var_9_0 = ""

		for iter_9_0, iter_9_1 in pairs(arg_9_0.favorCheckbox) do
			if iter_9_1:isSelected() then
				var_9_0 = var_9_0 .. iter_9_0 .. "|"
				arg_9_0.herosFavor[iter_9_0] = 1
			else
				arg_9_0.herosFavor[iter_9_0] = 0
			end
		end
	else
		arg_9_0.herosFavor = {
			1,
			1
		}
	end

	for iter_9_2, iter_9_3 in ipairs(arg_9_0.herosFavor) do
		if iter_9_3 == 1 then
			arg_9_0.sortType = arg_9_0.sortType + math.pow(2, #arg_9_0.herosFavor - iter_9_2 + 13)
		end
	end

	local var_9_1

	if not arg_9_0.awakeCheckbox[xyd.HeroAttrType.LI]:isSelected() or not arg_9_0.awakeCheckbox[xyd.HeroAttrType.ZHI]:isSelected() or not arg_9_0.awakeCheckbox[xyd.HeroAttrType.MIN]:isSelected() then
		var_9_1 = ""

		for iter_9_4, iter_9_5 in pairs(arg_9_0.awakeCheckbox) do
			if iter_9_5:isSelected() then
				var_9_1 = var_9_1 .. iter_9_4 .. "|"
				arg_9_0.herosAwaken[iter_9_4] = 1
			else
				arg_9_0.herosAwaken[iter_9_4] = 0
			end
		end
	else
		arg_9_0.herosAwaken = {
			1,
			1,
			1
		}
	end

	for iter_9_6, iter_9_7 in ipairs(arg_9_0.herosAwaken) do
		if iter_9_7 == 1 then
			arg_9_0.sortType = arg_9_0.sortType + math.pow(2, #arg_9_0.herosAwaken - iter_9_6 + 4)
		end
	end

	local var_9_2

	if not arg_9_0.posCheckbox[xyd.HeroPosType.FRONT]:isSelected() or not arg_9_0.posCheckbox[xyd.HeroPosType.MIDDLE]:isSelected() or not arg_9_0.posCheckbox[xyd.HeroPosType.BACK]:isSelected() then
		var_9_2 = ""

		for iter_9_8, iter_9_9 in pairs(arg_9_0.posCheckbox) do
			if iter_9_9:isSelected() then
				var_9_2 = var_9_2 .. iter_9_8 .. "|"
				arg_9_0.herosPos[iter_9_8 - 1] = 1
			else
				arg_9_0.herosPos[iter_9_8 - 1] = 0
			end
		end
	else
		arg_9_0.herosPos = {
			1,
			1,
			1
		}
	end

	for iter_9_10, iter_9_11 in ipairs(arg_9_0.herosPos) do
		if iter_9_11 == 1 then
			arg_9_0.sortType = arg_9_0.sortType + math.pow(2, #arg_9_0.herosPos - iter_9_10 + 10)
		end
	end

	local var_9_3

	if not arg_9_0.attrCheckbox[xyd.HeroAttrType.LI]:isSelected() or not arg_9_0.attrCheckbox[xyd.HeroAttrType.ZHI]:isSelected() or not arg_9_0.attrCheckbox[xyd.HeroAttrType.MIN]:isSelected() then
		var_9_3 = ""

		for iter_9_12, iter_9_13 in pairs(arg_9_0.attrCheckbox) do
			if iter_9_13:isSelected() then
				var_9_3 = var_9_3 .. iter_9_12 .. "|"
				arg_9_0.herosType[iter_9_12] = 1
			else
				arg_9_0.herosType[iter_9_12] = 0
			end
		end
	else
		arg_9_0.herosType = {
			1,
			1,
			1
		}
	end

	for iter_9_14, iter_9_15 in ipairs(arg_9_0.herosType) do
		if iter_9_15 == 1 then
			arg_9_0.sortType = arg_9_0.sortType + math.pow(2, #arg_9_0.herosType - iter_9_14 + 7)
		end
	end

	local var_9_4

	if not arg_9_0.forceCheckbox[xyd.HeroForceType.WEI]:isSelected() or not arg_9_0.forceCheckbox[xyd.HeroForceType.SHU]:isSelected() or not arg_9_0.forceCheckbox[xyd.HeroForceType.WU]:isSelected() or not arg_9_0.forceCheckbox[xyd.HeroForceType.QUN]:isSelected() then
		var_9_4 = ""

		for iter_9_16, iter_9_17 in pairs(arg_9_0.forceCheckbox) do
			if iter_9_17:isSelected() then
				var_9_4 = var_9_4 .. iter_9_16 .. "|"
				arg_9_0.herosPower[iter_9_16] = 1
			else
				arg_9_0.herosPower[iter_9_16] = 0
			end
		end
	else
		arg_9_0.herosPower = {
			1,
			1,
			1,
			1
		}
	end

	for iter_9_18, iter_9_19 in ipairs(arg_9_0.herosPower) do
		if iter_9_19 == 1 then
			arg_9_0.sortType = arg_9_0.sortType + math.pow(2, #arg_9_0.herosPower - iter_9_18)
		end
	end

	return {
		favorFilter = var_9_0,
		posFilter = var_9_2,
		forceFilter = var_9_4,
		attrFilter = var_9_3,
		awakeFilter = var_9_1
	}
end

function var_0_0.addText(arg_10_0)
	arg_10_0:nodeByName("txt_title"):setString(var_0_3:translation("HERO_FILTER_TITLE"))
	arg_10_0:nodeByName("txt_favor"):setString(var_0_3:translation("HERO_FILTER_DES_5"))

	for iter_10_0, iter_10_1 in pairs(xyd.HerosFavorType) do
		arg_10_0:nodeByName("txt_favor_" .. iter_10_1):setString(var_0_3:translation("HERO_FILTER_FAVOR_" .. tostring(iter_10_1)))
	end

	arg_10_0:nodeByName("txt_dis"):setString(var_0_3:translation("HERO_FILTER_DES_1"))

	for iter_10_2, iter_10_3 in pairs(xyd.HeroPosType) do
		arg_10_0:nodeByName("txt_dis_" .. iter_10_3 - 1):setString(var_0_3:translation("HERO_FILTER_POS_" .. tostring(iter_10_3 - 1)))
	end

	arg_10_0:nodeByName("txt_force"):setString(var_0_3:translation("HERO_FILTER_DES_3"))

	for iter_10_4, iter_10_5 in pairs(xyd.HeroForceType) do
		arg_10_0:nodeByName("txt_force_" .. iter_10_5):setString(var_0_3:translation("HERO_FILTER_POWER_" .. iter_10_5))
	end

	arg_10_0:nodeByName("txt_attr"):setString(var_0_3:translation("HERO_FILTER_DES_2"))

	for iter_10_6, iter_10_7 in pairs(xyd.HeroAttrType) do
		arg_10_0:nodeByName("txt_attr_" .. iter_10_7):setString(var_0_3:translation("HERO_FILTER_TYPE_" .. iter_10_7))
	end

	arg_10_0:nodeByName("txt_awake"):setString(var_0_3:translation("HERO_FILTER_DES_4"))

	for iter_10_8, iter_10_9 in pairs(xyd.HeroAwakeType) do
		arg_10_0:nodeByName("txt_awake_" .. iter_10_9):setString(var_0_3:translation("HERO_FILTER_AWAKEN_" .. iter_10_9))
	end
end

return var_0_0
