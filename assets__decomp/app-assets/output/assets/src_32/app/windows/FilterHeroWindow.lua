local var_0_0 = class("FilterHeroWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpriteNodeButton")
local var_0_2 = import("app.common.ui.SplitLine")
local var_0_3 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.sortType = arg_1_0.selfPlayer.sortType

	local var_1_0 = arg_1_0.selfPlayer:getInitSortType()

	arg_1_0.herosPos = var_1_0.herosPos
	arg_1_0.herosType = var_1_0.herosType
	arg_1_0.herosPower = var_1_0.herosPower
	arg_1_0.herosAwaken = var_1_0.herosAwaken

	if arg_1_2 then
		arg_1_0.awakenNotShow = arg_1_2.awaken_not_show
	end
end

function var_0_0.willOpen(arg_2_0)
	if arg_2_0.awakenNotShow then
		arg_2_0:nodeByName("pos_txt_awake"):setVisible(false)

		for iter_2_0 = 1, 3 do
			arg_2_0:nodeByName("check_awake_" .. iter_2_0):setVisible(false)
			arg_2_0:nodeByName("pos_txt_awake_" .. iter_2_0):setVisible(false)
		end
	end

	arg_2_0:addText()
	arg_2_0:initCheckbox()

	local var_2_0 = var_0_2.new({
		size = 740
	})

	var_2_0:addTo(arg_2_0:background())
	var_2_0:setAnchorPoint(0.5, 0.5)
	var_2_0:setPosition(arg_2_0:nodeByName("pos_splitline"):getPosition())

	arg_2_0.confirmBtn = var_0_1.new({
		titleSize = 24,
		sprite = "windows/button/btn195_2.png",
		title = var_0_3:translation("OK"),
		clickMode = xyd.ButtonClickMode.SCALE
	})

	arg_2_0.confirmBtn:addTo(arg_2_0:background())
	arg_2_0.confirmBtn:setAnchorPoint(0.5, 0.5)
	arg_2_0.confirmBtn:setPosition(arg_2_0:nodeByName("pos_btn"):getPosition())
	arg_2_0.confirmBtn:addTouchEvent(function(arg_3_0)
		if arg_3_0.name == "began" then
			return true
		elseif arg_3_0.name == "ended" and arg_2_0:checkFilterParams() then
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.HERO_FILTER,
				filterParams = arg_2_0:getFilterParams()
			})
			arg_2_0.selfPlayer:saveHeroFilterType(arg_2_0.sortType)
			arg_2_0:close()
		end
	end)
end

function var_0_0.didOpen(arg_4_0)
	arg_4_0:addBlockLayer()
end

function var_0_0.initCheckbox(arg_5_0)
	arg_5_0.posCheckbox = {}

	for iter_5_0, iter_5_1 in pairs(xyd.HeroPosType) do
		arg_5_0.posCheckbox[iter_5_1] = arg_5_0:nodeByName("check_dis_" .. iter_5_1)

		if arg_5_0.herosPos[iter_5_1 - 1] > 0 then
			arg_5_0.posCheckbox[iter_5_1]:setSelected(true)
		else
			arg_5_0.posCheckbox[iter_5_1]:setSelected(false)
		end
	end

	arg_5_0.forceCheckbox = {}

	for iter_5_2, iter_5_3 in pairs(xyd.HeroForceType) do
		arg_5_0.forceCheckbox[iter_5_3] = arg_5_0:nodeByName("check_force_" .. iter_5_3)

		if arg_5_0.herosPower[iter_5_3] > 0 then
			arg_5_0.forceCheckbox[iter_5_3]:setSelected(true)
		else
			arg_5_0.forceCheckbox[iter_5_3]:setSelected(false)
		end
	end

	arg_5_0.attrCheckbox = {}

	for iter_5_4, iter_5_5 in pairs(xyd.HeroAttrType) do
		arg_5_0.attrCheckbox[iter_5_5] = arg_5_0:nodeByName("check_attr_" .. iter_5_5)

		if arg_5_0.herosType[iter_5_5] > 0 then
			arg_5_0.attrCheckbox[iter_5_5]:setSelected(true)
		else
			arg_5_0.attrCheckbox[iter_5_5]:setSelected(false)
		end
	end

	arg_5_0.awakeCheckbox = {}

	for iter_5_6, iter_5_7 in pairs(xyd.HeroAwakeType) do
		arg_5_0.awakeCheckbox[iter_5_7] = arg_5_0:nodeByName("check_awake_" .. iter_5_7)

		if arg_5_0.herosAwaken[iter_5_7] > 0 then
			arg_5_0.awakeCheckbox[iter_5_7]:setSelected(true)
		else
			arg_5_0.awakeCheckbox[iter_5_7]:setSelected(false)
		end
	end
end

function var_0_0.checkFilterParams(arg_6_0)
	local var_6_0

	if not arg_6_0.posCheckbox[xyd.HeroPosType.FRONT]:isSelected() and not arg_6_0.posCheckbox[xyd.HeroPosType.MIDDLE]:isSelected() and not arg_6_0.posCheckbox[xyd.HeroPosType.BACK]:isSelected() then
		var_6_0 = var_0_3:translation("HERO_FILTER_POS_TIP")
	end

	if not var_6_0 and not arg_6_0.forceCheckbox[xyd.HeroForceType.WEI]:isSelected() and not arg_6_0.forceCheckbox[xyd.HeroForceType.SHU]:isSelected() and not arg_6_0.forceCheckbox[xyd.HeroForceType.WU]:isSelected() and not arg_6_0.forceCheckbox[xyd.HeroForceType.QUN]:isSelected() then
		var_6_0 = var_0_3:translation("HERO_FILTER_POWER_TIP")
	end

	if not var_6_0 and not arg_6_0.attrCheckbox[xyd.HeroAttrType.LI]:isSelected() and not arg_6_0.attrCheckbox[xyd.HeroAttrType.ZHI]:isSelected() and not arg_6_0.attrCheckbox[xyd.HeroAttrType.MIN]:isSelected() then
		var_6_0 = var_0_3:translation("HERO_FILTER_TYPE_TIP")
	end

	if not var_6_0 and not arg_6_0.awakeCheckbox[xyd.HeroAwakeType.AWAKE]:isSelected() and not arg_6_0.awakeCheckbox[xyd.HeroAwakeType.AWAKE_TWICE]:isSelected() and not arg_6_0.awakeCheckbox[xyd.HeroAwakeType.NO_AWAKE]:isSelected() then
		var_6_0 = var_0_3:translation("HERO_FILTER_AWAKEN_TIP")
	end

	if var_6_0 then
		local var_6_1 = {
			txt = var_6_0,
			type = xyd.CommonAlertType.ONE_BTN,
			align = xyd.ui_align.CENTER
		}

		xyd.WindowManager.get():openWindow("common_alert", var_6_1)

		return false
	end

	return true
end

function var_0_0.getFilterParams(arg_7_0)
	arg_7_0.sortType = 0

	local var_7_0

	if not arg_7_0.awakeCheckbox[xyd.HeroAttrType.LI]:isSelected() or not arg_7_0.awakeCheckbox[xyd.HeroAttrType.ZHI]:isSelected() or not arg_7_0.awakeCheckbox[xyd.HeroAttrType.MIN]:isSelected() then
		var_7_0 = ""

		for iter_7_0, iter_7_1 in pairs(arg_7_0.awakeCheckbox) do
			if iter_7_1:isSelected() then
				var_7_0 = var_7_0 .. iter_7_0 .. "|"
				arg_7_0.herosAwaken[iter_7_0] = 1
			else
				arg_7_0.herosAwaken[iter_7_0] = 0
			end
		end
	else
		arg_7_0.herosAwaken = {
			1,
			1,
			1
		}
	end

	for iter_7_2, iter_7_3 in ipairs(arg_7_0.herosAwaken) do
		if iter_7_3 == 1 then
			arg_7_0.sortType = arg_7_0.sortType + math.pow(2, #arg_7_0.herosAwaken - iter_7_2 + 10)
		end
	end

	local var_7_1

	if not arg_7_0.posCheckbox[xyd.HeroPosType.FRONT]:isSelected() or not arg_7_0.posCheckbox[xyd.HeroPosType.MIDDLE]:isSelected() or not arg_7_0.posCheckbox[xyd.HeroPosType.BACK]:isSelected() then
		var_7_1 = ""

		for iter_7_4, iter_7_5 in pairs(arg_7_0.posCheckbox) do
			if iter_7_5:isSelected() then
				var_7_1 = var_7_1 .. iter_7_4 .. "|"
				arg_7_0.herosPos[iter_7_4 - 1] = 1
			else
				arg_7_0.herosPos[iter_7_4 - 1] = 0
			end
		end
	else
		arg_7_0.herosPos = {
			1,
			1,
			1
		}
	end

	for iter_7_6, iter_7_7 in ipairs(arg_7_0.herosPos) do
		if iter_7_7 == 1 then
			arg_7_0.sortType = arg_7_0.sortType + math.pow(2, #arg_7_0.herosPos - iter_7_6 + 7)
		end
	end

	local var_7_2

	if not arg_7_0.attrCheckbox[xyd.HeroAttrType.LI]:isSelected() or not arg_7_0.attrCheckbox[xyd.HeroAttrType.ZHI]:isSelected() or not arg_7_0.attrCheckbox[xyd.HeroAttrType.MIN]:isSelected() then
		var_7_2 = ""

		for iter_7_8, iter_7_9 in pairs(arg_7_0.attrCheckbox) do
			if iter_7_9:isSelected() then
				var_7_2 = var_7_2 .. iter_7_8 .. "|"
				arg_7_0.herosType[iter_7_8] = 1
			else
				arg_7_0.herosType[iter_7_8] = 0
			end
		end
	else
		arg_7_0.herosType = {
			1,
			1,
			1
		}
	end

	for iter_7_10, iter_7_11 in ipairs(arg_7_0.herosType) do
		if iter_7_11 == 1 then
			arg_7_0.sortType = arg_7_0.sortType + math.pow(2, #arg_7_0.herosType - iter_7_10 + 4)
		end
	end

	local var_7_3

	if not arg_7_0.forceCheckbox[xyd.HeroForceType.WEI]:isSelected() or not arg_7_0.forceCheckbox[xyd.HeroForceType.SHU]:isSelected() or not arg_7_0.forceCheckbox[xyd.HeroForceType.WU]:isSelected() or not arg_7_0.forceCheckbox[xyd.HeroForceType.QUN]:isSelected() then
		var_7_3 = ""

		for iter_7_12, iter_7_13 in pairs(arg_7_0.forceCheckbox) do
			if iter_7_13:isSelected() then
				var_7_3 = var_7_3 .. iter_7_12 .. "|"
				arg_7_0.herosPower[iter_7_12] = 1
			else
				arg_7_0.herosPower[iter_7_12] = 0
			end
		end
	else
		arg_7_0.herosPower = {
			1,
			1,
			1,
			1
		}
	end

	for iter_7_14, iter_7_15 in ipairs(arg_7_0.herosPower) do
		if iter_7_15 == 1 then
			arg_7_0.sortType = arg_7_0.sortType + math.pow(2, #arg_7_0.herosPower - iter_7_14)
		end
	end

	return {
		posFilter = var_7_1,
		forceFilter = var_7_3,
		attrFilter = var_7_2,
		awakeFilter = var_7_0
	}
end

function var_0_0.addText(arg_8_0)
	arg_8_0:nodeByName("txt_title"):setString(var_0_3:translation("HERO_FILTER_TITLE"))

	local var_8_0 = xyd.createAutoFixLabel({
		height = 40,
		fontSize = 30,
		txtColor = "#44454D",
		width = 100,
		text = var_0_3:translation("HERO_FILTER_DES_1"),
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_CENTER
	})

	var_8_0:addTo(arg_8_0:background())
	var_8_0:setAnchorPoint(0, 0.5)
	var_8_0:setPosition(arg_8_0:nodeByName("pos_txt_dis"):getPosition())

	for iter_8_0, iter_8_1 in pairs(xyd.HeroPosType) do
		local var_8_1 = xyd.createAutoFixLabel({
			height = 30,
			fontSize = 26,
			txtColor = "#44454D",
			width = 100,
			text = var_0_3:translation("HERO_FILTER_POS_" .. tostring(iter_8_1 - 1)),
			align = cc.ui.TEXT_ALIGN_LEFT,
			valign = cc.ui.TEXT_VALIGN_CENTER
		})

		var_8_1:addTo(arg_8_0:background())
		var_8_1:setAnchorPoint(0, 0.5)
		var_8_1:setPosition(arg_8_0:nodeByName("pos_txt_dis_" .. iter_8_1):getPosition())
	end

	local var_8_2 = xyd.createAutoFixLabel({
		height = 40,
		fontSize = 30,
		txtColor = "#44454D",
		width = 100,
		text = var_0_3:translation("HERO_FILTER_DES_3"),
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_CENTER
	})

	var_8_2:addTo(arg_8_0:background())
	var_8_2:setAnchorPoint(0, 0.5)
	var_8_2:setPosition(arg_8_0:nodeByName("pos_txt_force"):getPosition())

	for iter_8_2, iter_8_3 in pairs(xyd.HeroForceType) do
		local var_8_3 = xyd.createAutoFixLabel({
			height = 30,
			fontSize = 26,
			txtColor = "#44454D",
			width = 100,
			text = var_0_3:translation("HERO_FILTER_POWER_" .. iter_8_3),
			align = cc.ui.TEXT_ALIGN_LEFT,
			valign = cc.ui.TEXT_VALIGN_CENTER
		})

		var_8_3:addTo(arg_8_0:background())
		var_8_3:setAnchorPoint(0, 0.5)
		var_8_3:setPosition(arg_8_0:nodeByName("pos_txt_force_" .. iter_8_3):getPosition())
	end

	local var_8_4 = xyd.createAutoFixLabel({
		height = 40,
		fontSize = 30,
		txtColor = "#44454D",
		width = 100,
		text = var_0_3:translation("HERO_FILTER_DES_2"),
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_CENTER
	})

	var_8_4:addTo(arg_8_0:background())
	var_8_4:setAnchorPoint(0, 0.5)
	var_8_4:setPosition(arg_8_0:nodeByName("pos_txt_attr"):getPosition())

	for iter_8_4, iter_8_5 in pairs(xyd.HeroAttrType) do
		local var_8_5 = xyd.createAutoFixLabel({
			height = 30,
			fontSize = 26,
			txtColor = "#44454D",
			width = 100,
			text = var_0_3:translation("HERO_FILTER_TYPE_" .. iter_8_5),
			align = cc.ui.TEXT_ALIGN_LEFT,
			valign = cc.ui.TEXT_VALIGN_CENTER
		})

		var_8_5:addTo(arg_8_0:background())
		var_8_5:setAnchorPoint(0, 0.5)
		var_8_5:setPosition(arg_8_0:nodeByName("pos_txt_attr_" .. iter_8_5):getPosition())
	end

	local var_8_6 = xyd.createAutoFixLabel({
		height = 40,
		fontSize = 30,
		txtColor = "#44454D",
		width = 100,
		text = var_0_3:translation("HERO_FILTER_DES_4"),
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_CENTER
	})

	var_8_6:addTo(arg_8_0:background())
	var_8_6:setAnchorPoint(0, 0.5)
	var_8_6:setPosition(arg_8_0:nodeByName("pos_txt_awake"):getPosition())

	if arg_8_0.awakenNotShow then
		var_8_6:setVisible(false)
	end

	for iter_8_6, iter_8_7 in pairs(xyd.HeroAwakeType) do
		local var_8_7 = xyd.createAutoFixLabel({
			height = 30,
			fontSize = 26,
			txtColor = "#44454D",
			width = 100,
			text = var_0_3:translation("HERO_FILTER_AWAKEN_" .. iter_8_7),
			align = cc.ui.TEXT_ALIGN_LEFT,
			valign = cc.ui.TEXT_VALIGN_CENTER
		})

		var_8_7:addTo(arg_8_0:background())
		var_8_7:setAnchorPoint(0, 0.5)
		var_8_7:setPosition(arg_8_0:nodeByName("pos_txt_awake_" .. iter_8_7):getPosition())

		if arg_8_0.awakenNotShow then
			var_8_7:setVisible(false)
		end
	end
end

return var_0_0
