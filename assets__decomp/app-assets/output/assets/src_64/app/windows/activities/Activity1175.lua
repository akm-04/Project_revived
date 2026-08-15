local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.summon

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.details = arg_1_0.activity.details
	arg_1_0.heroId = tonumber(arg_1_0.details.show_partner_id)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)

	arg_2_0.container = var_2_0:getChildByName("container")
	arg_2_0.summonContainer = arg_2_0.container:getChildByName("summon_container")
	arg_2_0.ruleContainer = arg_2_0.container:getChildByName("rule_container")

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = var_0_2:crystal(xyd.SummonType.Magic)
	local var_3_1 = var_0_2:crystalTen(xyd.SummonType.Magic)

	arg_3_0.summonContainer:getChildByName("ten_des"):setString(var_0_1:translation("MAGIC_SUMMON_TIP"))
	arg_3_0.summonContainer:getChildByName("bg_price1"):getChildByName("buy_amt_1"):setString(var_3_0)
	arg_3_0.summonContainer:getChildByName("bg_price10"):getChildByName("buy_amt_10"):setString(var_3_1)
	arg_3_0.summonContainer:getChildByName("switch_bg"):getChildByName("txt_switch"):setString(var_0_1:translation("MAGIC_SUMMON_TEXT1"))
	arg_3_0.ruleContainer:getChildByName("rule_title"):setString(var_0_1:translation("MAGIC_SUMMON_TEXT2"))
	arg_3_0.summonContainer:getChildByName("button_buy1"):getChildByName("txt_buy1"):setString(var_0_1:translation("MAGIC_SUMMON_TEXT3"))
	arg_3_0.summonContainer:getChildByName("button_buy10"):getChildByName("txt_buy10"):setString(var_0_1:translation("MAGIC_SUMMON_TEXT4"))

	local var_3_2 = xyd.createLabel(18, cc.c3b(167, 102, 181))

	var_3_2:setAnchorPoint(0, 1)
	var_3_2:setWidth(330)
	var_3_2:setLineHeight(27)
	var_3_2:setString(var_0_1:translation("MAGIC_SUMMON_TEXT5"))
	var_3_2:addTo(arg_3_0.ruleContainer:getChildByName("pos_rule1"))

	local var_3_3 = xyd.createLabel(18, cc.c3b(122, 105, 125))

	var_3_3:setAnchorPoint(0, 1)
	var_3_3:setWidth(330)
	var_3_3:setLineHeight(27)
	var_3_3:setString(var_0_1:translation("MAGIC_SUMMON_RULE"))
	var_3_3:addTo(arg_3_0.ruleContainer:getChildByName("pos_rule2"))
	arg_3_0.summonContainer:getChildByName("switch_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_4_0, arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local function var_4_0(arg_5_0)
				local var_5_0 = {
					partner_id = arg_5_0
				}

				xyd.Backend.get():request(xyd.mid.MAGIC_SUMMON_SWITCH_HERO, var_5_0, function(arg_6_0, arg_6_1)
					if arg_6_0 == xyd.error.OK then
						arg_3_0.details.show_partner_id = arg_5_0
						arg_3_0.heroId = arg_5_0

						arg_3_0:updateHeroIcon()
					end
				end)
			end

			local var_4_1 = {
				callback = var_4_0
			}

			xyd.WindowManager.get():openWindow("magic_summon_switch_hero", var_4_1)
		end
	end)
	arg_3_0.summonContainer:getChildByName("button_buy1"):addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(arg_7_0, arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_3_0:buy(1)
		end
	end)
	arg_3_0.summonContainer:getChildByName("button_buy10"):addTouchEventListener(function(arg_8_0, arg_8_1)
		xyd.buttonScaleAnim(arg_8_0, arg_8_1)

		if arg_8_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_3_0:buy(10)
		end
	end)
	arg_3_0:updateHeroIcon()
end

function var_0_0.updateHeroIcon(arg_9_0)
	local var_9_0 = arg_9_0.summonContainer:getChildByName("hero_bg"):getChildByName("middle_up_hero_node")

	var_9_0:removeAllChildren()
	var_9_0:setContentSize(92, 92)
	var_9_0:setAnchorPoint(0.5, 0.5)
	var_9_0:removeAllNodeEventListeners()

	if arg_9_0.heroId and arg_9_0.heroId > 0 then
		local var_9_1 = arg_9_0.selfPlayer:getHeroIgnoreAwaken(arg_9_0.heroId)

		if var_9_1 then
			xyd.setAvatarBorderNewUI(var_9_1, var_9_0)
		else
			xyd.setAvatarBorderNewUI(arg_9_0.heroId, var_9_0, 1, 0)
		end

		arg_9_0:addTip(arg_9_0.heroId, var_9_0)
	else
		local var_9_2 = "windows/activities/1175/unknown.png"

		xyd.setSpriteBorder(var_9_0, var_9_2)
	end
end

function var_0_0.buy(arg_10_0, arg_10_1)
	if not arg_10_0.heroId or arg_10_0.heroId <= 0 then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_1:translation("MAGIC_SUMMON_SELECT_HERO_TIP")
		})

		return
	end

	local var_10_0 = var_0_2:crystal(xyd.SummonType.Magic)

	if arg_10_1 > 1 then
		var_10_0 = var_0_2:crystalTen(xyd.SummonType.Magic)
	end

	if var_10_0 > arg_10_0.selfPlayer.crystal then
		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
			local var_11_0 = {}

			var_11_0.windowState = true

			xyd.WindowManager.get():openWindow("vip_recharge", var_11_0)
		end, nil, nil, xyd.ColorMode.ACTIVITY)

		return
	end

	local var_10_1 = {
		partner_id = arg_10_0.heroId,
		summon_time = arg_10_1
	}

	arg_10_0.selfPlayer:magicSummonHero(var_10_1, function(arg_12_0, arg_12_1)
		if arg_12_0 == xyd.error.OK then
			local var_12_0 = var_10_1
			local var_12_1 = {}
			local var_12_2 = {}

			for iter_12_0, iter_12_1 in pairs(arg_12_1.result) do
				if tonumber(iter_12_0) then
					table.insert(var_12_2, iter_12_1)
				end
			end

			var_12_1.items = var_12_2
			var_12_1.times = arg_10_1
			var_12_1.summonParams = var_12_0

			xyd.WindowManager.get():openWindow("magic_summon_result", var_12_1)
		end
	end)
end

function var_0_0.addTip(arg_13_0, arg_13_1, arg_13_2)
	if not arg_13_2 then
		return
	end

	arg_13_2:setTouchEnabled(true)
	arg_13_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_14_0)
		if arg_14_0.name == "began" then
			local var_14_0 = {}

			var_14_0.quality = 1
			var_14_0.isBoss = false
			var_14_0.id = arg_13_1
			var_14_0.name = xyd.tables.hero:name(arg_13_1)
			var_14_0.desc = xyd.tables.hero:getDes(arg_13_1)
			var_14_0.isHero = true

			local var_14_1 = arg_13_2:getParent():convertToWorldSpace(cc.p(arg_13_2:getPosition()))

			if not xyd.WindowManager.get():getWindow("new_item_tips") then
				local var_14_2 = xyd.WindowManager.get():openWindow("new_item_tips", var_14_0)

				xyd.adaptToWorldPosition(arg_13_2, var_14_2)
			end

			return true
		elseif arg_14_0.name == "ended" then
			wnd = xyd.WindowManager.get():closeWindow("new_item_tips")
		end
	end)
end

return var_0_0
