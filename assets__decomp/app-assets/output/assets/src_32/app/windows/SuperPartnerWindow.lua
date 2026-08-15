local var_0_0 = class("SuperPartnerWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.hero
local var_0_5 = import("app.model.Hero")
local var_0_6 = xyd.tables.item
local var_0_7 = {
	-90,
	-160,
	143,
	38,
	-21
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.superHeros = var_0_4:getSuperHeros()
	arg_1_0.current_ = 1
	arg_1_0.isSummon = false
	arg_1_0.selectType = xyd.SuperPartnerSelectType.ALL

	for iter_1_0, iter_1_1 in ipairs(arg_1_0.superHeros) do
		if not var_0_4:isLibraryShow(arg_1_0.superHeros[iter_1_0]) then
			table.remove(arg_1_0.superHeros, iter_1_0)
		end
	end

	if arg_1_2 and arg_1_2.tableID then
		local var_1_0 = arg_1_2.tableID

		if not xyd.isSuperHero(var_1_0) then
			var_1_0 = arg_1_0:getSuperHeroID(var_1_0)
		end

		for iter_1_2, iter_1_3 in ipairs(arg_1_0.superHeros) do
			if arg_1_0.superHeros[iter_1_2] == var_1_0 then
				arg_1_0.current_ = iter_1_2
			end
		end
	end
end

function var_0_0.getSuperHeroID(arg_2_0, arg_2_1)
	for iter_2_0, iter_2_1 in ipairs(arg_2_0.superHeros) do
		for iter_2_2, iter_2_3 in ipairs(var_0_4:materialHero(iter_2_1)) do
			if iter_2_3 == arg_2_1 or iter_2_3 == xyd.tables.hero:beforeAwaken(arg_2_1) then
				return iter_2_1
			end
		end
	end
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super.willOpen(arg_3_0, arg_3_1)
	arg_3_0:setButtonClick()
	arg_3_0:layout()
end

function var_0_0.setButtonClick(arg_4_0, arg_4_1)
	local var_4_0
	local var_4_1
	local var_4_2

	arg_4_0:nodeByName("button_info"):addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_4_0:nodeByName("button_info"), arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended and not arg_4_0.isSummon then
			xyd.playButtonSound()

			local var_5_0 = {
				title_name = "TAITAN_RULE_TITLE",
				rule = "TAITAN_RULE_TEXT",
				style = xyd.RuleStyle.BLUE
			}

			xyd.WindowManager.get():openWindow("new_text_rule", var_5_0)
		end
	end)
	arg_4_0:nodeByName("button_return"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended and not arg_4_0.isSummon then
			xyd.playCloseSound()
			xyd.WindowManager.get():closeWindow("super_partner")
		end
	end)
	arg_4_0:nodeByName("exchange"):addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(arg_4_0:nodeByName("exchange"), arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended and not arg_4_0.isSummon then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("super_partner_exchange", {
				tableID = arg_4_0.superHeros[arg_4_0.current_]
			})
		end
	end)
	arg_4_0:nodeByName("summon"):addTouchEventListener(function(arg_8_0, arg_8_1)
		xyd.buttonScaleAnim(arg_4_0:nodeByName("summon"), arg_8_1)

		if arg_8_1 == ccui.TouchEventType.ended and not arg_4_0.isSummon then
			xyd.playButtonSound()

			arg_4_0.isSummon = true

			local var_8_0 = "skeletons/ui_effect/super_partner/neifaguang"
			local var_8_1 = var_8_0 .. ".json"
			local var_8_2 = var_8_0 .. ".atlas"
			local var_8_3 = var_0_2.new(var_8_1, var_8_2, 1)

			var_8_3:addTo(arg_4_0:nodeByName("super_hero_effect"))
			var_8_3:setPositionX(-2)
			var_8_3:setPositionY(-8)
			var_8_3:play(function()
				var_8_3:hide()

				local var_9_0 = {
					table_id = arg_4_0.superHeros[arg_4_0.current_]
				}

				arg_4_0.selfPlayer:summonSuperHero(var_9_0, function(arg_10_0, arg_10_1)
					if arg_10_0 == xyd.error.OK then
						local var_10_0 = {
							toStone = false,
							partnerID = arg_4_0.superHeros[arg_4_0.current_]
						}

						arg_4_0:hide()

						var_10_0.star = arg_10_1.partner_info.star

						local var_10_1 = xyd.WindowManager.get():openWindow(xyd.WindowName.summonHeroWnd, var_10_0)

						cc.EventProxy.new(var_10_1, var_10_1):addEventListener(xyd.event.SUMMON_HERO_CLOSE, function()
							arg_4_0:show()
						end)
						xyd.EventDispatcher.get():dispatchEvent({
							name = xyd.event.CHECK_MIDDLE_RED_MARK,
							params = xyd.CheckMiddleRed.SUPER_PARTNER
						})
						arg_4_0:updateViews()

						arg_4_0.isSummon = false
					end
				end)
			end, false, 2)
		end
	end)
	arg_4_0:nodeByName("btn_select"):addTouchEventListener(function(arg_12_0, arg_12_1)
		xyd.buttonScaleAnim(arg_4_0:nodeByName("btn_select"), arg_12_1)

		if arg_12_1 == ccui.TouchEventType.ended and not arg_4_0.isSummon then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("super_partner_select", {
				selectType = arg_4_0.selectType
			})
		end
	end)
	arg_4_0:nodeByName("button_up"):setTouchEnabled(true)
	arg_4_0:nodeByName("button_up"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_13_0)
		if arg_13_0.name == "began" and not arg_4_0.isSummon then
			arg_4_0:nodeByName("button_up"):scale(0.9)

			var_4_0 = arg_13_0.x
			var_4_1 = arg_13_0.y
			var_4_2 = false
		elseif arg_13_0.name == "moved" then
			arg_4_0:nodeByName("button_up"):scale(1)

			local var_13_0 = arg_13_0.x
			local var_13_1 = arg_13_0.y

			if math.abs(var_13_1 - var_4_1) > 30 or math.abs(var_13_0 - var_4_0) > 30 then
				var_4_2 = true
			end
		elseif arg_13_0.name == "ended" and not var_4_2 and not arg_4_0.isSummon then
			xyd.playButtonSound()
			arg_4_0:nodeByName("button_up"):scale(1)

			arg_4_0.current_ = arg_4_0.current_ - 1

			arg_4_0:updateViews()
		end

		return true
	end)
	arg_4_0:nodeByName("button_down"):setTouchEnabled(true)
	arg_4_0:nodeByName("button_down"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_14_0)
		if arg_14_0.name == "began" and not arg_4_0.isSummon then
			arg_4_0:nodeByName("button_down"):scale(0.9)

			var_4_0 = arg_14_0.x
			var_4_1 = arg_14_0.y
			var_4_2 = false
		elseif arg_14_0.name == "moved" then
			arg_4_0:nodeByName("button_down"):scale(1)

			local var_14_0 = arg_14_0.x
			local var_14_1 = arg_14_0.y

			if math.abs(var_14_1 - var_4_1) > 30 or math.abs(var_14_0 - var_4_0) > 30 then
				var_4_2 = true
			end
		elseif arg_14_0.name == "ended" and not var_4_2 and not arg_4_0.isSummon then
			xyd.playButtonSound()
			arg_4_0:nodeByName("button_down"):scale(1)

			arg_4_0.current_ = arg_4_0.current_ + 1

			arg_4_0:updateViews()
		end

		return true
	end)
end

function var_0_0.didOpen(arg_15_0, arg_15_1)
	return
end

function var_0_0.didClose(arg_16_0, arg_16_1)
	var_0_0.super:didClose(arg_16_1)
end

function var_0_0.layout(arg_17_0)
	arg_17_0:updateViews()

	local var_17_0 = "skeletons/ui_effect/super_partner/jitanzhuti"
	local var_17_1 = var_17_0 .. ".json"
	local var_17_2 = var_17_0 .. ".atlas"
	local var_17_3 = var_0_2.new(var_17_1, var_17_2, 1)

	var_17_3:addTo(arg_17_0:nodeByName("bg_effect"))
	var_17_3:play(nil, true)
	arg_17_0:nodeByName("text_close_title"):setString(var_0_3:translation("TAITAN_TEXT_12"))
	arg_17_0:nodeByName("word_exchange"):setString(var_0_3:translation("TAITAN_TEXT_13"))

	local var_17_4 = {
		id = xyd.tables.misc.taitanItemID,
		lev = xyd.tables.item:level(xyd.tables.misc.taitanItemID)
	}

	if xyd.tables.item:type(xyd.tables.misc.taitanItemID) == -1 then
		var_17_4.tipsType = 0
		var_17_4.desc1 = xyd.tables.hero:getDes(xyd.tables.misc.taitanItemID)
	elseif specialItem then
		var_17_4.tipsType = 1
		var_17_4.id = -3
	else
		var_17_4.tipsType = 1
		var_17_4.desc1 = xyd.tables.item:desc1(xyd.tables.misc.taitanItemID)
		var_17_4.desc2 = xyd.tables.item:desc2(xyd.tables.misc.taitanItemID)
	end

	var_17_4.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(xyd.tables.misc.taitanItemID)
	var_17_4.name = xyd.tables.item:name(xyd.tables.misc.taitanItemID)
end

function var_0_0.updateTaitanNum(arg_18_0)
	arg_18_0:nodeByName("titan_num"):setString(arg_18_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc.taitanItemID))
end

function var_0_0.updateViews(arg_19_0)
	if arg_19_0.current_ <= 1 then
		arg_19_0:nodeByName("button_up"):setVisible(false)
	else
		arg_19_0:nodeByName("button_up"):setVisible(true)
	end

	if arg_19_0.current_ >= #arg_19_0.superHeros then
		arg_19_0:nodeByName("button_down"):setVisible(false)
	else
		arg_19_0:nodeByName("button_down"):setVisible(true)
	end

	local var_19_0 = arg_19_0.superHeros[arg_19_0.current_]
	local var_19_1 = var_0_4:materialHero(var_19_0)
	local var_19_2 = true
	local var_19_3 = 0

	for iter_19_0 = 1, 5 do
		local var_19_4 = arg_19_0:nodeByName("hero" .. iter_19_0)

		arg_19_0:nodeByName("hero_effect" .. iter_19_0):removeAllChildren()
		var_19_4:removeAllChildren()

		local var_19_5 = arg_19_0:nodeByName("need_num" .. iter_19_0)
		local var_19_6 = arg_19_0.selfPlayer:getHeroByTableID(var_19_1[iter_19_0]) or arg_19_0.selfPlayer:getHeroByTableID(var_0_4:afterAwaken(var_19_1[iter_19_0]))

		var_19_5:setVisible(false)

		if var_19_6 then
			xyd.setAvatarBorderNewUI(var_19_6, var_19_4)

			local var_19_7 = var_19_4:getContentSize()
			local var_19_8 = xyd.AssetLoader.get():loadSprite("windows/common/lv_di.png")

			var_19_4:addChild(var_19_8)
			var_19_8:setPosition(var_19_7.width * 27 / 120, var_19_7.height * 38 / 120)
			var_19_8:scale(var_19_7.width / var_19_4:getWidth())

			local var_19_9 = xyd.AssetLoader.get():loadLabel({
				size = 20
			})

			var_19_9:setString(var_19_6:getLevel())
			var_19_8:addChild(var_19_9)
			var_19_9:align(display.CENTER, var_19_8:getContentSize().width / 2 - 2, var_19_8:getContentSize().height / 2 + 0.5)
			var_19_9:scale(var_19_7.width / var_19_4:getWidth())
			var_19_5:setVisible(false)

			if var_19_6:getStar() == xyd.MAX_STAR_LEVEL then
				var_19_3 = var_19_3 + 1

				local var_19_10 = "skeletons/ui_effect/super_partner/xiantiao"
				local var_19_11 = var_19_10 .. ".json"
				local var_19_12 = var_19_10 .. ".atlas"
				local var_19_13 = var_0_2.new(var_19_11, var_19_12, 1)

				var_19_13:addTo(arg_19_0:nodeByName("hero_effect" .. iter_19_0))
				arg_19_0:nodeByName("hero_effect" .. iter_19_0):setRotation(var_0_7[iter_19_0])
				var_19_13:play(nil, true)
			end

			local var_19_14 = display.newNode()
			local var_19_15
			local var_19_16

			var_19_14:setContentSize(var_19_4:getContentSize())
			var_19_14:addTo(var_19_4)
			var_19_14:setTouchEnabled(true)
			var_19_14:setTouchSwallowEnabled(false)
			var_19_14:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_20_0)
				if arg_20_0.name == "began" and not arg_19_0.isSummon then
					var_19_4:scale(0.9)

					var_19_15 = arg_20_0.y
					var_19_16 = false

					return true
				elseif arg_20_0.name == "moved" then
					var_19_4:scale(1)

					local var_20_0 = arg_20_0.y

					if math.abs(var_20_0 - var_19_15) > 30 then
						var_19_16 = true
					end
				elseif arg_20_0.name == "ended" and not var_19_16 and not arg_19_0.isSummon then
					xyd.playButtonSound()
					var_19_4:scale(1)

					if xyd.WindowManager.get():isWindowOpen("hero_main") then
						xyd.WindowManager.get():closeWindow("hero_main")
					end

					local var_20_1 = {
						heros = {
							var_19_6
						}
					}

					var_20_1.current = 1

					xyd.WindowManager.get():openWindow("hero_main", var_20_1)
				end
			end)
		else
			var_19_2 = false
			var_19_6 = var_0_5.new()

			var_19_6:populateWithTableID(var_19_1[iter_19_0])
			xyd.setAvatarBorder(var_19_6, var_19_4, nil, nil, nil, true)

			local var_19_17 = xyd.AssetLoader.get():loadSprite("windows/fumo_hero/avatar_mask.png")

			var_19_17:addTo(var_19_4)
			var_19_17:setPosition(var_19_4:getContentSize().width / 2, var_19_4:getContentSize().height / 2)
			var_19_17:scale(var_19_4:getContentSize().width / var_19_17:getContentSize().width)

			if var_0_4:isSX(var_19_1[iter_19_0]) then
				var_19_5:getChildByName("num"):setString(xyd.tables.misc.taitanExchangeSXHero)
			else
				var_19_5:getChildByName("num"):setString(xyd.tables.misc.taitanExchangeHero)
			end

			local var_19_18 = xyd.AssetLoader.get():loadSprite("windows/super_partner/main/bg_plus.png")

			var_19_18:addTo(var_19_4)
			var_19_18:setPosition(var_19_4:getContentSize().width / 2, var_19_4:getContentSize().height / 2 + 15)

			local var_19_19 = {
				size = 28,
				color = cc.c3b(175, 237, 76)
			}
			local var_19_20 = xyd.AssetLoader.get():loadLabel(var_19_19)

			var_19_20:setMaxLineWidth(70)
			var_19_20:addTo(var_19_4)
			var_19_20:setString(var_0_3:translation("TAITAN_TEXT_8"))
			var_19_20:setAnchorPoint(0.5, 0.5)
			var_19_20:setPosition(var_19_4:getContentSize().width / 2, var_19_4:getContentSize().height / 2 - 35)
			var_19_17:setTouchEnabled(true)
			var_19_17:setTouchSwallowEnabled(false)
			var_19_17:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_21_0)
				if arg_21_0.name == "began" then
					var_19_4:scale(0.9)

					touchBeganY = arg_21_0.y
					isMoved = false

					return true
				elseif arg_21_0.name == "moved" then
					var_19_4:scale(1)

					local var_21_0 = arg_21_0.y

					if math.abs(var_21_0 - touchBeganY) > 30 then
						isMoved = true
					end
				elseif arg_21_0.name == "ended" and not isMoved then
					xyd.playButtonSound()
					var_19_4:scale(1)

					local var_21_1 = var_19_6
					local var_21_2 = xyd.tables.hero:stoneID(var_21_1:getTableID())

					xyd.WindowManager.get():openWindow("stone", {
						hero = var_21_1,
						itemComposeID = var_21_2
					})
				end
			end)
		end
	end

	local var_19_21 = arg_19_0.selfPlayer:getHeroByTableID(var_19_0)
	local var_19_22

	if var_19_21 then
		var_19_22 = var_19_21
	else
		var_19_22 = var_0_5.new()

		var_19_22:populateWithTableID(var_19_0)
	end

	arg_19_0:nodeByName("hero_card"):removeAllChildren()

	local var_19_23 = xyd.getSuperHeroCard(var_19_22, xyd.CardStatus.SKIN_CARD, nil, nil, nil, var_19_21)

	var_19_23:scale(arg_19_0:nodeByName("hero_card"):getContentSize().width / var_19_23:getContentSize().width)
	var_19_23:addTo(arg_19_0:nodeByName("hero_card"))
	var_19_23:setPosition(arg_19_0:nodeByName("hero_card"):getContentSize().width / 2, arg_19_0:nodeByName("hero_card"):getContentSize().height / 2)

	local var_19_24 = var_19_23:getChildByName("rare_lev")
	local var_19_25, var_19_26 = var_19_24:getPosition()

	var_19_24:setPosition(var_19_25 - 0.03 * arg_19_0:nodeByName("hero_card"):getContentSize().width, var_19_26 - 0.03 * arg_19_0:nodeByName("hero_card"):getContentSize().height)
	var_19_23:getChildByName("card_border"):setVisible(false)
	var_19_23:getChildByName("card_board_married"):setVisible(false)
	var_19_23:getChildByName("agile"):setVisible(false)
	var_19_23:getChildByName("strength"):setVisible(false)
	var_19_23:getChildByName("wise"):setVisible(false)

	local var_19_27 = var_19_22:getHeroType()

	arg_19_0:nodeByName("icon_agile"):setVisible(var_19_27 == xyd.HeroType.AGILE)
	arg_19_0:nodeByName("icon_strength"):setVisible(var_19_27 == xyd.HeroType.STRENGTH)
	arg_19_0:nodeByName("icon_wise"):setVisible(var_19_27 == xyd.HeroType.WISE)

	for iter_19_1 = 1, 4 do
		arg_19_0:nodeByName("party_" .. iter_19_1):setVisible(var_19_22:getFromType() == iter_19_1)
		var_19_23:getChildByName("party_" .. iter_19_1):setVisible(false)
	end

	if not var_19_2 then
		arg_19_0:nodeByName("tips"):setString(var_0_3:translation("TAITAN_TIPS1"))
	elseif not var_19_21 then
		if var_19_3 > 0 then
			arg_19_0:nodeByName("tips"):setString(var_0_3:translation("TAITAN_TIPS2"))
		else
			arg_19_0:nodeByName("tips"):setString(var_0_3:translation("TAITAN_TIPS1"))
		end
	elseif var_19_21:getStar() <= xyd.HERO_TOTAL_STARS then
		arg_19_0:nodeByName("tips"):setString(var_0_3:translation("TAITAN_TIPS3"))
	else
		arg_19_0:nodeByName("tips"):setString(var_0_3:translation("TAITAN_TIPS4"))
	end

	arg_19_0:nodeByName("super_hero_effect"):removeAllChildren()

	local var_19_28 = "skeletons/ui_effect/super_partner/zhongxinguangyun"
	local var_19_29 = var_19_28 .. ".json"
	local var_19_30 = var_19_28 .. ".atlas"
	local var_19_31 = var_0_2.new(var_19_29, var_19_30, 1)

	var_19_31:addTo(arg_19_0:nodeByName("super_hero_effect"))
	var_19_31:play(nil, true)

	local var_19_32 = "skeletons/ui_effect/super_partner/tubiaoguangyun"
	local var_19_33 = var_19_32 .. ".json"
	local var_19_34 = var_19_32 .. ".atlas"
	local var_19_35 = var_0_2.new(var_19_33, var_19_34, 1)

	var_19_35:addTo(arg_19_0:nodeByName("super_hero_effect"))
	var_19_35:play(nil, true)

	local var_19_36 = arg_19_0:nodeByName("super_hero")

	var_19_36:removeAllChildren()

	if var_19_21 then
		xyd.setAvatarBorder(var_19_21, var_19_36)
		arg_19_0:nodeByName("exchange"):setVisible(true)
		arg_19_0:nodeByName("summon"):setVisible(false)
		arg_19_0:nodeByName("word_exchange"):setString(var_0_3:translation("TAITAN_TEXT_13"))

		local var_19_37 = display.newNode()
		local var_19_38
		local var_19_39

		var_19_37:setContentSize(var_19_36:getContentSize())
		var_19_37:addTo(var_19_36)
		var_19_37:setTouchEnabled(true)
		var_19_37:setTouchSwallowEnabled(false)
		var_19_37:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_22_0)
			if arg_22_0.name == "began" then
				var_19_36:scale(0.9)

				var_19_38 = arg_22_0.y
				var_19_39 = false

				return true
			elseif arg_22_0.name == "moved" then
				local var_22_0 = arg_22_0.y

				if math.abs(var_22_0 - var_19_38) > 30 then
					var_19_36:scale(1)

					var_19_39 = true
				end
			elseif arg_22_0.name == "ended" and not var_19_39 then
				xyd.playButtonSound()
				var_19_36:scale(1)

				if xyd.WindowManager.get():isWindowOpen("hero_main") then
					xyd.WindowManager.get():closeWindow("hero_main")
				end

				local var_22_1 = {
					heros = {
						var_19_21
					}
				}

				var_22_1.current = 1

				xyd.WindowManager.get():openWindow("hero_main", var_22_1)
			end
		end)
	else
		arg_19_0:nodeByName("exchange"):setVisible(false)
		arg_19_0:nodeByName("summon"):setVisible(true)
		arg_19_0:nodeByName("word_summon"):setString(var_0_3:translation("TAITAN_TEXT_SUMMON"))

		var_19_21 = var_0_5.new()

		var_19_21:populateWithTableID(var_19_0)

		if not var_19_2 or var_19_3 <= 0 then
			arg_19_0:nodeByName("super_hero_effect"):removeAllChildren()
		end

		xyd.setAvatarBorder(var_19_21, var_19_36, nil, 0, nil, true)

		local var_19_40 = xyd.AssetLoader.get():loadSprite("windows/fumo_hero/avatar_mask.png")

		var_19_40:addTo(arg_19_0:nodeByName("super_hero"))
		var_19_40:setPosition(arg_19_0:nodeByName("super_hero"):getContentSize().width / 2, arg_19_0:nodeByName("super_hero"):getContentSize().height / 2)
		var_19_40:scale(arg_19_0:nodeByName("super_hero"):getContentSize().width / var_19_40:getContentSize().width)

		if var_19_2 and var_19_3 > 0 then
			var_19_40:setTouchEnabled(true)
			arg_19_0:nodeByName("summon"):setEnabled(true)
		else
			var_19_40:setTouchEnabled(false)
			arg_19_0:nodeByName("summon"):setEnabled(false)
		end

		var_19_40:setTouchSwallowEnabled(false)
	end
end

function var_0_0.createSkillTips(arg_23_0, arg_23_1, arg_23_2)
	local var_23_0, var_23_1 = arg_23_1:getPosition()
	local var_23_2 = display.newNode()
	local var_23_3 = xyd.tables.skill

	var_23_2:setAnchorPoint(cc.p(0, 0))
	var_23_2:setContentSize(arg_23_1:getContentSize())
	var_23_2:setTouchEnabled(true)
	var_23_2:setTouchSwallowEnabled(false)
	var_23_2:addTo(arg_23_1)
	var_23_2:setPosition(0, 0)
	var_23_2:setName("skill_tip")

	local var_23_4 = arg_23_0:convertToWorldSpace(cc.p(0, 0))

	var_23_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_24_0)
		if arg_24_0.name == "began" then
			local var_24_0 = {
				has_jiantou = false,
				id = arg_23_2
			}

			if not xyd.WindowManager.get():getWindow("skill_tips") then
				local var_24_1 = xyd.WindowManager.get():openWindow("skill_tips", var_24_0)

				xyd.adaptToWorldPosition(var_23_2, var_24_1)
			end

			return true
		elseif arg_24_0.name == "ended" then
			arg_23_0:closeTipWindow()
		end
	end)
end

function var_0_0.closeTipWindow(arg_25_0)
	if xyd.WindowManager.get():getWindow("skill_tips") then
		xyd.WindowManager.get():closeWindow("skill_tips")
	end
end

return var_0_0
