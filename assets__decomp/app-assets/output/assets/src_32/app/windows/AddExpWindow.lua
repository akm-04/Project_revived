local var_0_0 = class("AddExpWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = require("framework.scheduler")
local var_0_3 = import("app.common.ui.SpineEffect")
local var_0_4 = xyd.tables.translation
local var_0_5 = xyd.tables.translation
local var_0_6 = xyd.tables.attr
local var_0_7 = xyd.tables.hero
local var_0_8 = xyd.tables.item
local var_0_9 = 27

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.hero = arg_1_2.hero
	arg_1_0.handler = {}
	arg_1_0.visibleHandler = {}
	arg_1_0.guideID = xyd.StoryData.get():getGuideID()
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.heroMainWnd = arg_1_2.wnd
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	arg_2_0.maxLev = xyd.tables.player:heroMaxLev(arg_2_0.selfPlayer.lev)

	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer(nil, false, false, function()
		if xyd.WindowManager.get():getWindow("selfdrink_tip") then
			xyd.WindowManager.get():closeWindow("selfdrink_tip")
			xyd.WindowManager.get():closeWindow(arg_3_0)
		else
			xyd.WindowManager.get():closeWindow(arg_3_0)
		end
	end)
	arg_3_0:playGuide()
end

function var_0_0.didClose(arg_5_0)
	if arg_5_0.handler[1] ~= nil then
		var_0_2.unscheduleGlobal(arg_5_0.handler[1])
	end

	if arg_5_0.handler[2] ~= nil then
		var_0_2.unscheduleGlobal(arg_5_0.handler[2])
	end

	if arg_5_0.visibleHandler and next(arg_5_0.visibleHandler) then
		for iter_5_0, iter_5_1 in ipairs(arg_5_0.visibleHandler) do
			var_0_2.unscheduleGlobal(iter_5_1)
		end
	end

	local var_5_0 = xyd.WindowManager.get():getWindow("hero_main")
	local var_5_1 = xyd.StoryData.get():getGuideID()

	if var_5_0 and var_5_1 == xyd.GuideStoryType.GUIDE_LEVUP_FOUR then
		var_5_0:playGuide()
	end
end

function var_0_0.willClose(arg_6_0)
	arg_6_0.heroMainWnd:setSkillContainer()
	arg_6_0.heroMainWnd:updateCollectWindow()
end

function var_0_0.layout(arg_7_0)
	local var_7_0 = arg_7_0.hero

	arg_7_0.addExpContainer = arg_7_0:nodeByName("bg")

	arg_7_0:updateExp(var_7_0)
	arg_7_0:updateExpInfoContainer()

	local var_7_1 = arg_7_0.addExpContainer:getChildByName("button_selfdrink")

	var_7_1:addTouchEventListener(function(arg_8_0, arg_8_1)
		xyd.buttonScaleAnim(var_7_1, arg_8_1)

		if arg_8_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_7_0:clickSelfDrinkButtion()
		end
	end)
	arg_7_0:nodeByName("txt_title"):setString(var_0_5:translation("HERO_MAIN_TEXT_35"))
	arg_7_0:nodeByName("text_lev"):setString(var_0_5:translation("HERO_MAIN_TEXT_10"))
	arg_7_0:nodeByName("text_exp"):setString(var_0_5:translation("HERO_MAIN_TEXT_12"))
	arg_7_0:nodeByName("txt_selfdrink"):setString(var_0_5:translation("HERO_MAIN_TEXT_36"))
end

function var_0_0.updateExp(arg_9_0, arg_9_1)
	arg_9_1 = arg_9_1 or arg_9_0.hero

	arg_9_0:nodeByName("txt_lev"):setString(arg_9_1:getLevel())

	local var_9_0 = arg_9_1:getExp() - xyd.tables.partnerExp:totalExp(arg_9_1:getLevel() - 1)

	arg_9_0:nodeByName("txt_exp"):setString(var_9_0 .. " / " .. arg_9_1:getAddExp())
end

function var_0_0.scrollListener(arg_10_0, arg_10_1)
	if arg_10_1.name == "began" then
		arg_10_0.scrollViewMoved_ = false
		arg_10_0.prevY_ = arg_10_1.y
	elseif arg_10_1.name == "moved" and 5 <= math.abs(arg_10_1.y - arg_10_0.prevY_) then
		arg_10_0.scrollViewMoved_ = true
	end
end

function var_0_0.updateExpInfoContainer(arg_11_0)
	if tolua.isnull(arg_11_0.addExpContainer) then
		return
	end

	local var_11_0 = arg_11_0.hero
	local var_11_1 = arg_11_0.addExpContainer:getChildByName("list")

	var_11_1:removeAllChildren()

	arg_11_0.expScroll = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_11_1:getWidth(), var_11_1:getHeight()),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_11_1):onScroll(handler(arg_11_0, arg_11_0.scrollListener))
	arg_11_0.expIds = {
		50001001,
		50001002,
		50001004,
		50001005,
		50005182
	}
	arg_11_0.usedItemNums = {}

	arg_11_0.expScroll:setBounceable(true)
	arg_11_0.expScroll:setDelegate(handler(arg_11_0, arg_11_0.expScrollDelegate))
	arg_11_0.expScroll:reload()
end

function var_0_0.expScrollDelegate(arg_12_0, arg_12_1, arg_12_2, arg_12_3)
	if cc.ui.UIListView.COUNT_TAG == arg_12_2 then
		return #arg_12_0.expIds
	elseif cc.ui.UIListView.CELL_TAG == arg_12_2 then
		local var_12_0 = arg_12_0.expScroll:dequeueItem()

		if not var_12_0 then
			var_12_0 = arg_12_0.expScroll:newItem()
		else
			var_12_0:removeAllChildren(true)
		end

		local var_12_1 = arg_12_0.expIds[arg_12_3]
		local var_12_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/exp_item.csb")
		local var_12_3 = var_12_2:getChildByName("container")

		var_12_3:getChildByName("use_num"):setVisible(false)
		var_12_3:getChildByName("use_button_container"):getChildByName("txt_drink"):setString(var_0_5:translation("HERO_MAIN_TEXT_40"))

		local var_12_4 = var_12_3:getContentSize()

		var_12_2:setContentSize(var_12_4)

		local var_12_5 = var_12_3:getChildByName("item")

		xyd.setItemBorder(var_12_5, var_12_1)

		local var_12_6 = xyd.tables.item:name(var_12_1)

		var_12_3:getChildByName("item_title"):setString(var_12_6)

		local var_12_7 = arg_12_0.selfPlayer:getBackpack():getItemNumByID(var_12_1)

		var_12_3:getChildByName("num_text"):setString(var_12_7)

		local var_12_8 = xyd.tables.item:exp(var_12_1)
		local var_12_9 = string.format(var_0_5:translation("EXP_ITEM_DESC"), var_12_8)
		local var_12_10 = {
			size = 22,
			align = cc.ui.TEXT_ALIGN_LEFT,
			valign = cc.ui.TEXT_VALIGN_BOTTOM,
			color = cc.c3b(40, 40, 40),
			dimensions = cc.size(150, 0),
			text = var_12_9
		}
		local var_12_11 = xyd.AssetLoader.get():loadLabel(var_12_10)

		var_12_11:addTo(var_12_3)
		var_12_11:setAnchorPoint(cc.p(0, 0))
		var_12_11:align(display.BOTTOM_LEFT, var_12_3:getChildByName("node_pos"):getPosition())
		var_12_11:setName("title")

		local var_12_12 = var_12_3:getChildByName("use_button_container")
		local var_12_13 = cc.ui.UIPushButton.new({
			pressed = "windows/hero/btn_blue.png",
			disabled = "windows/hero/btn_blue.png",
			normal = "windows/hero/btn_blue.png"
		})

		var_12_13:setAnchorPoint(cc.p(0.5, 0.5))

		local var_12_14 = var_12_12:getContentSize()

		var_12_13:setPosition(cc.p(var_12_14.width / 2, var_12_14.height / 2))
		var_12_13:addTo(var_12_12, -1)
		var_12_13:setTouchSwallowEnabled(false)

		arg_12_0.usedItemNums[var_12_1] = 0

		local var_12_15 = false

		var_12_13:onButtonPressed(function(arg_13_0)
			var_12_12:setScale(0.9)
			arg_12_0.layerListener:setEnabled(false)

			if arg_12_0.scrollViewMoved_ then
				return
			end

			local var_13_0 = 0

			local function var_13_1()
				if tolua.isnull(arg_12_0) then
					if arg_12_0.handler and arg_12_0.handler[1] ~= nil then
						var_0_2.unscheduleGlobal(arg_12_0.handler[1])
					end

					if arg_12_0.handler and arg_12_0.handler[2] ~= nil then
						var_0_2.unscheduleGlobal(arg_12_0.handler[2])
					end

					return
				end

				var_13_0 = var_13_0 + 0.03
				var_12_7 = arg_12_0:addExp(var_12_7, var_12_1, var_12_3)

				var_12_3:getChildByName("num_text"):setString(var_12_7)
			end

			local function var_13_2()
				if tolua.isnull(arg_12_0) then
					if arg_12_0.handler and arg_12_0.handler[1] ~= nil then
						var_0_2.unscheduleGlobal(arg_12_0.handler[1])
					end

					if arg_12_0.handler and arg_12_0.handler[2] ~= nil then
						var_0_2.unscheduleGlobal(arg_12_0.handler[2])
					end

					return
				end

				var_13_0 = var_13_0 + 0.1

				if var_13_0 > 0.5 and var_13_0 <= 4 then
					var_12_15 = true
					var_12_7 = arg_12_0:addExp(var_12_7, var_12_1, var_12_3)

					var_12_3:getChildByName("num_text"):setString(var_12_7)
				elseif var_13_0 > 4 then
					arg_12_0.handler[2] = var_0_2.scheduleGlobal(var_13_1, 0.03)

					var_0_2.unscheduleGlobal(arg_12_0.handler[1])
				else
					var_12_15 = false
				end
			end

			var_12_15 = false
			arg_12_0.handler[1] = var_0_2.scheduleGlobal(var_13_2, 0.1)
		end)
		var_12_13:onButtonRelease(function(arg_16_0)
			arg_12_0.layerListener:setEnabled(true)
			var_12_12:setScale(1)

			if arg_12_0.handler[1] ~= nil then
				var_0_2.unscheduleGlobal(arg_12_0.handler[1])
			end

			if arg_12_0.handler[2] ~= nil then
				var_0_2.unscheduleGlobal(arg_12_0.handler[2])
			end

			if var_12_15 == false then
				var_12_7 = arg_12_0:addExp(var_12_7, var_12_1, var_12_3)

				var_12_3:getChildByName("num_text"):setString(var_12_7)
			end

			var_12_13:setButtonEnabled(false)
			arg_12_0.selfPlayer:addPartnerExp({
				item_id = var_12_1,
				partner_id = arg_12_0.hero:getHeroID(),
				item_num = arg_12_0.usedItemNums[var_12_1],
				total_num = arg_12_0.selfPlayer:getBackpack():getItemNumByID(var_12_1)
			}, function(arg_17_0, arg_17_1, arg_17_2)
				if not tolua.isnull(var_12_13) then
					var_12_13:setButtonEnabled(true)
				end

				if arg_17_0 == xyd.error.OK then
					if arg_17_2.item_id then
						local var_17_0 = arg_17_2.item_id
						local var_17_1 = arg_17_2.partner_exp
						local var_17_2 = arg_17_2.total_num

						arg_12_0.selfPlayer:getBackpack():setItemNumByID(var_17_0, var_17_2)

						local var_17_3 = xyd.tables.player:heroMaxLev(arg_12_0.selfPlayer.lev)

						arg_12_0.hero:setExp(var_17_1, var_17_3)
					else
						arg_12_0.refresh_ = true
						var_12_7 = arg_12_0.selfPlayer:getBackpack():getItemNumByID(var_12_1)

						if not tolua.isnull(var_12_3) then
							var_12_3:getChildByName("num_text"):setString(var_12_7)
						end

						if arg_12_0.levelUpCount_ and arg_12_0.levelUpCount_ > 0 then
							local var_17_4 = {}

							table.insert(var_17_4, arg_12_0.levelUpCount_ * var_0_7:getHeroAttrGrow(arg_12_0.hero:getTableID(), xyd.AttributeType.STRENGTH, arg_12_0.hero:getStar()))
							table.insert(var_17_4, arg_12_0.levelUpCount_ * var_0_7:getHeroAttrGrow(arg_12_0.hero:getTableID(), xyd.AttributeType.WISE, arg_12_0.hero:getStar()))
							table.insert(var_17_4, arg_12_0.levelUpCount_ * var_0_7:getHeroAttrGrow(arg_12_0.hero:getTableID(), xyd.AttributeType.AGILE, arg_12_0.hero:getStar()))

							local var_17_5 = arg_12_0.heroMainWnd:getHeroModel()

							arg_12_0.isShow = true

							var_17_5:win(false, handler(arg_12_0.heroMainWnd, arg_12_0.heroMainWnd.setIsShow))
							var_17_5:playAttribute(arg_12_0.heroMainWnd:getFloatAttrs(var_17_4))
						end

						arg_12_0.levelUpCount_ = 0

						arg_12_0.heroMainWnd:CheckOneClick()
						arg_12_0.heroMainWnd:updateSuperHero()
					end

					arg_12_0.heroMainWnd:updateEquip()
				elseif arg_17_2.item_id then
					local var_17_6 = arg_17_2.item_id
					local var_17_7 = arg_17_2.partner_exp
					local var_17_8 = arg_17_2.total_num

					arg_12_0.selfPlayer:getBackpack():setItemNumByID(var_17_6, var_17_8)

					local var_17_9 = xyd.tables.player:heroMaxLev(arg_12_0.selfPlayer.lev)

					arg_12_0.hero:setExp(var_17_7, var_17_9)
				end

				arg_12_0:playGuide()
			end)

			arg_12_0.usedItemNums[var_12_1] = 0
		end)
		var_12_2:setAnchorPoint(0, 0)
		var_12_2:setPosition(0, 0)
		var_12_2:setTouchSwallowEnabled(false)
		var_12_0:setItemSize(var_12_4.width, var_12_4.height + 10)
		var_12_0:addContent(var_12_2)

		return var_12_0
	end
end

function var_0_0.addExp(arg_18_0, arg_18_1, arg_18_2, arg_18_3)
	local var_18_0 = arg_18_0.hero

	arg_18_0.levelUpCount_ = arg_18_0.levelUpCount_ or 0

	local var_18_1 = var_18_0:getExp()
	local var_18_2 = xyd.tables.partnerExp:totalExp(arg_18_0.maxLev)
	local var_18_3 = xyd.tables.item:exp(arg_18_2)

	if arg_18_1 <= 0 then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_5:translation("EXP_ITEM_ABSENCE")
		})
	elseif var_18_2 <= var_18_1 then
		local var_18_4 = xyd.tables.sound:getSound("train_exp_max")

		audio.playSound(var_18_4, false)
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_5:translation("EXP_FULL")
		})
	else
		arg_18_0.usedItemNums[arg_18_2] = arg_18_0.usedItemNums[arg_18_2] + 1
		arg_18_1 = arg_18_1 - 1

		local var_18_5 = clone(var_18_0:getLevel())

		var_18_0:addExp(var_18_3, arg_18_0.maxLev)
		arg_18_0.heroMainWnd:updateExp(var_18_0)
		arg_18_0.heroMainWnd:updateAttrScore(var_18_0)
		arg_18_0:updateExp(var_18_0)

		if var_18_5 < var_18_0:getLevel() then
			arg_18_0.levelUpCount_ = arg_18_0.levelUpCount_ + var_18_0:getLevel() - var_18_5

			arg_18_0:playLevelUpEffect(arg_18_3)
			arg_18_0.heroMainWnd:playLevelUpEffect(arg_18_3)
			arg_18_0.heroMainWnd:updateEquip(var_18_0)
		else
			arg_18_0:playEatExpEffect(arg_18_3)
			arg_18_0.heroMainWnd:playEatExpEffect(arg_18_3)
		end

		if not tolua.isnull(arg_18_3) then
			arg_18_3:getChildByName("use_num"):setVisible(true)
			arg_18_3:getChildByName("use_num"):setString("X" .. arg_18_0.usedItemNums[arg_18_2])
		end

		if arg_18_0.visibleHandler[arg_18_2] ~= nil then
			var_0_2.unscheduleGlobal(arg_18_0.visibleHandler[arg_18_2])
		end

		if not tolua.isnull(arg_18_3) then
			local var_18_6 = arg_18_3:getChildByName("use_num")

			arg_18_0.visibleHandler[arg_18_2] = var_0_2.performWithDelayGlobal(function()
				if not tolua.isnull(arg_18_3) then
					var_18_6:setVisible(false)
				end
			end, 0.1)
		end
	end

	return arg_18_1
end

function var_0_0.clickSelfDrinkButtion(arg_20_0)
	local var_20_0 = arg_20_0.hero
	local var_20_1 = 0
	local var_20_2 = {}
	local var_20_3 = 0
	local var_20_4 = var_20_0:getExp()
	local var_20_5 = xyd.tables.partnerExp:totalExp(arg_20_0.maxLev - 1)
	local var_20_6 = {
		50001001,
		50001002,
		50001004,
		50001005,
		50005182
	}

	if var_20_0:getLevel() >= arg_20_0.maxLev then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_5:translation("ALREAY_MAX_LEV")
		})

		return
	end

	local function var_20_7()
		arg_20_0.levelUpCount_ = arg_20_0.levelUpCount_ or 0

		local var_21_0 = clone(var_20_0:getLevel())

		arg_20_0.selfPlayer:addPartnerExps({
			items = var_20_2,
			partner_id = arg_20_0.hero:getHeroID()
		}, function(arg_22_0, arg_22_1, arg_22_2)
			if arg_22_0 == xyd.error.OK then
				local var_22_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/exp_item.csb"):getChildByName("container")

				var_20_0:addExp(var_20_1, xyd.tables.player:heroMaxLev(arg_20_0.selfPlayer.lev), var_22_0)

				if var_20_0:getLevel() > var_21_0 then
					arg_20_0.levelUpCount_ = arg_20_0.levelUpCount_ + var_20_0:getLevel() - var_21_0

					arg_20_0:playLevelUpEffect(var_22_0)
					arg_20_0.heroMainWnd:playLevelUpEffect(var_22_0)
				else
					arg_20_0:playEatExpEffect(var_22_0)
					arg_20_0.heroMainWnd:playEatExpEffect(var_22_0)
				end

				if arg_20_0.levelUpCount_ and arg_20_0.levelUpCount_ > 0 then
					local var_22_1 = {}

					table.insert(var_22_1, arg_20_0.levelUpCount_ * var_0_7:getHeroAttrGrow(arg_20_0.hero:getTableID(), xyd.AttributeType.STRENGTH, arg_20_0.hero:getStar()))
					table.insert(var_22_1, arg_20_0.levelUpCount_ * var_0_7:getHeroAttrGrow(arg_20_0.hero:getTableID(), xyd.AttributeType.WISE, arg_20_0.hero:getStar()))
					table.insert(var_22_1, arg_20_0.levelUpCount_ * var_0_7:getHeroAttrGrow(arg_20_0.hero:getTableID(), xyd.AttributeType.AGILE, arg_20_0.hero:getStar()))

					local var_22_2 = arg_20_0.heroMainWnd:getHeroModel()

					arg_20_0.heroMainWnd.isShow = true

					var_22_2:win(false, handler(arg_20_0.heroMainWnd, arg_20_0.heroMainWnd.setIsShow))
					var_22_2:playAttribute(arg_20_0.heroMainWnd:getFloatAttrs(var_22_1))

					arg_20_0.levelUpCount_ = 0
				end
			end

			arg_20_0.heroMainWnd:updateEquip()
			arg_20_0.heroMainWnd:updateAttrScore()
			arg_20_0:updateExp()
			arg_20_0.heroMainWnd:updateExp()
			arg_20_0:updateExpInfoContainer()
			arg_20_0.heroMainWnd:updateCard()
			arg_20_0.heroMainWnd:updateAttrLabels()
			arg_20_0.heroMainWnd:updateInfoChart()
			arg_20_0.heroMainWnd:updateRecommendInfo()
			arg_20_0.heroMainWnd:updateIntroduceText()
			arg_20_0.heroMainWnd:updateCollectWindow()
			arg_20_0.heroMainWnd:updateScrollBg()
			arg_20_0.heroMainWnd:setSkillContainer()
			arg_20_0.heroMainWnd:updateNameLabel()
			arg_20_0.heroMainWnd:CheckOneClick()
			arg_20_0.heroMainWnd:updateSuperHero()

			if xyd.WindowManager.get():getWindow("selfdrink_tip") then
				xyd.WindowManager.get():closeWindow("selfdrink_tip")
				xyd.WindowManager.get():closeWindow(arg_20_0)
			else
				xyd.WindowManager.get():closeWindow(arg_20_0)
			end
		end)
	end

	if arg_20_0:allPotionsExpInBackPack() <= 0 then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_5:translation("EXP_ITEM_ABSENCE")
		})

		return false
	end

	local var_20_8 = var_20_5 - var_20_4 + 1

	for iter_20_0, iter_20_1 in pairs(var_20_6) do
		local var_20_9 = arg_20_0.selfPlayer:getBackpack():getItemNumByID(iter_20_1)
		local var_20_10 = xyd.tables.item:exp(iter_20_1)

		if var_20_8 <= var_20_9 * var_20_10 then
			local var_20_11 = math.ceil(var_20_8 / var_20_10)
			local var_20_12 = {
				item_id = iter_20_1,
				item_num = var_20_11
			}

			if var_20_11 > 0 then
				table.insert(var_20_2, var_20_12)
			end

			var_20_8 = 0
			var_20_1 = var_20_1 + var_20_11 * var_20_10

			break
		elseif var_20_9 ~= 0 then
			var_20_8 = var_20_8 - var_20_9 * var_20_10

			local var_20_13 = {
				item_id = iter_20_1,
				item_num = var_20_9
			}

			if var_20_9 > 0 then
				table.insert(var_20_2, var_20_13)
			end

			var_20_1 = var_20_1 + var_20_9 * var_20_10
		end
	end

	local var_20_14 = {}

	for iter_20_2, iter_20_3 in pairs(var_20_2) do
		table.insert(var_20_14, {
			table_id = iter_20_3.item_id,
			item_num = iter_20_3.item_num
		})
	end

	params = {
		items = var_20_14,
		heroName = arg_20_0.hero:getName()
	}

	xyd.SelfDrinkTipWindow.open(params, function(arg_23_0)
		if arg_23_0 then
			var_20_7()
		end
	end)
end

function var_0_0.allPotionsExpInBackPack(arg_24_0)
	local var_24_0 = 0
	local var_24_1 = {
		50001001,
		50001002,
		50001004,
		50001005,
		50005182
	}

	for iter_24_0, iter_24_1 in pairs(var_24_1) do
		var_24_0 = var_24_0 + arg_24_0.selfPlayer:getBackpack():getItemNumByID(iter_24_1) * xyd.tables.item:exp(iter_24_1)
	end

	return var_24_0
end

function var_0_0.playEatExpEffect(arg_25_0, arg_25_1)
	local var_25_0 = arg_25_1:getChildByName("item"):getContentSize().width
	local var_25_1 = arg_25_1:getChildByName("item"):getContentSize().height
	local var_25_2, var_25_3 = arg_25_1:getChildByName("item"):getPosition()

	if arg_25_0.clickEffect and not tolua.isnull(arg_25_0.clickEffect) then
		arg_25_0.clickEffect:removeAllChildren()
	end

	local var_25_4 = "skeletons/ui_effect/common_effect_exp_click/common_effect_exp_click"
	local var_25_5 = var_25_4 .. ".json"
	local var_25_6 = var_25_4 .. ".atlas"

	arg_25_0.clickEffect = var_0_3.new(var_25_5, var_25_6, 1)

	arg_25_0.clickEffect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_25_0.clickEffect:setPosition(var_25_2 + var_25_0 / 2, var_25_3 + var_25_1 / 2)
	arg_25_1:addChild(arg_25_0.clickEffect)
	arg_25_0.clickEffect:setScale(0.7)
	arg_25_0.clickEffect:play(nil, false)
end

function var_0_0.playLevelUpEffect(arg_26_0, arg_26_1)
	local var_26_0 = arg_26_1:getChildByName("item"):getContentSize().width
	local var_26_1 = arg_26_1:getChildByName("item"):getContentSize().height
	local var_26_2, var_26_3 = arg_26_1:getChildByName("item"):getPosition()

	if arg_26_0.clickEffect and not tolua.isnull(arg_26_0.clickEffect) then
		arg_26_0.clickEffect:removeAllChildren()
	end

	local var_26_4 = "skeletons/ui_effect/common_effect_exp_click/common_effect_exp_click"
	local var_26_5 = var_26_4 .. ".json"
	local var_26_6 = var_26_4 .. ".atlas"

	arg_26_0.clickEffect = var_0_3.new(var_26_5, var_26_6, 1)

	arg_26_0.clickEffect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_26_0.clickEffect:setPosition(var_26_2 + var_26_0 / 2, var_26_3 + var_26_1 / 2)
	arg_26_1:addChild(arg_26_0.clickEffect)
	arg_26_0.clickEffect:setScale(0.7)
	arg_26_0.clickEffect:play(nil, false)
end

function var_0_0.playGuide(arg_27_0)
	arg_27_0.guideID = xyd.StoryData.get():getGuideID()

	if arg_27_0.guideID == xyd.GuideStoryType.GUIDE_LEVUP_THREE then
		xyd.WindowManager.get():closeWindow("guide")
		xyd.WindowManager.get():openWindow("guide")

		local var_27_0 = xyd.WindowManager.get():getWindow("guide")

		var_27_0:addNode()
		var_27_0:setStencil(150, 70, 777, 408, 3, {
			right = true,
			position = {
				200,
				250
			}
		})
		arg_27_0.expScroll:setViewCanNotScroll(true)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_LEVUP_FOUR)
		xyd.StoryData.get():persist(xyd.GuideStoryType.ACTIVITY_START)
		arg_27_0.selfPlayer:sendOperationLog(xyd.StatID.ID_LEVUP_)
	elseif arg_27_0.guideID == xyd.GuideStoryType.GUIDE_LEVUP_FOUR then
		arg_27_0.expScroll:setViewCanNotScroll(false)
		xyd.WindowManager.get():closeWindow(arg_27_0)
	end
end

return var_0_0
