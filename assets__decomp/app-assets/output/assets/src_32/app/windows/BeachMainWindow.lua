local var_0_0 = class("BeachMainWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = import("app.common.ui.SpineEffect")
local var_0_4 = import("framework.scheduler")
local var_0_5 = import("app.modules.battle.BeachFighterModel")
local var_0_6 = xyd.tables.translation
local var_0_7 = 80
local var_0_8 = 10
local var_0_9 = 6000
local var_0_10 = 40
local var_0_11 = 0.4
local var_0_12 = 5000
local var_0_13 = 10001094
local var_0_14 = 22
local var_0_15 = 32
local var_0_16 = 20
local var_0_17 = 25
local var_0_18 = 1
local var_0_19 = 0
local var_0_20 = 1
local var_0_21 = cc.c3b(29, 66, 255)
local var_0_22 = cc.c3b(255, 11, 29)

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.beach = xyd.ModelManager.get():loadModel(xyd.ModelType.BEACH_ACTIVITY)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:setTouchEnabled(true)
	arg_2_0:endAttack()
	arg_2_0:initData()
	arg_2_0:scheduleUpdate()
	arg_2_0:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, function(...)
		arg_2_0:update_(...)
	end)
	arg_2_0.contentView_:setTouchSwallowEnabled(false)
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super:didOpen(arg_4_1)
	arg_4_0:addBgMusic()
	arg_4_0:layout()
end

function var_0_0.initData(arg_5_0)
	arg_5_0.fishMatrix = {}
	arg_5_0.connectBegin = false
	arg_5_0.connectEnd = false
	arg_5_0.connectIndex = {}
	arg_5_0.allBlocks = {}
	arg_5_0.isCrit = false
	arg_5_0.explodeSoundPaths = {}
	arg_5_0.explodeSoundPaths[1] = xyd.tables.sound:getSound("beach_pink_explode")
	arg_5_0.explodeSoundPaths[2] = xyd.tables.sound:getSound("beach_blue_explode")
	arg_5_0.explodeSoundPaths[3] = xyd.tables.sound:getSound("beach_red_explode")
	arg_5_0.connectSoundPath = xyd.tables.sound:getSound("beach_connect")
	arg_5_0.openChestSoundPath = xyd.tables.sound:getSound("click_drop_items")
	arg_5_0.dropChestSoundPath = xyd.tables.sound:getSound("battle_loot")
	arg_5_0.bgEffectPaths = {}
	arg_5_0.bgEffectPaths[1] = "skeletons/ui_effect/beach/beach_jelly_move"
	arg_5_0.bgEffectPaths[2] = "skeletons/ui_effect/beach/beach_bubble_move"
	arg_5_0.bgEffectPaths[3] = "skeletons/ui_effect/beach/beach_bubble_move"
end

function var_0_0.initLocalOrder(arg_6_0)
	arg_6_0:nodeByName("attack_btn"):setLocalZOrder(10)
	arg_6_0:nodeByName("left_attack_times_txt"):setLocalZOrder(10)
	arg_6_0:nodeByName("left_attack_times"):setLocalZOrder(10)
end

function var_0_0.layout(arg_7_0)
	arg_7_0:initLocalOrder()
	arg_7_0:initLabel()
	arg_7_0:initProgressBar()
	arg_7_0:updateCritCostLabel()
	arg_7_0:updateCritBtnStyle(true)
	arg_7_0:layoutHeroAttackView()
	arg_7_0:layoutConnectLineView()
	arg_7_0:registerTouchEvent()
	arg_7_0:updateAttackTimes()
	arg_7_0:addBgEffect()
	arg_7_0:nodeByName("attack_btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_7_0:nodeByName("attack_btn"):setTouchEnabled(false)
			arg_7_0.contentView_:setTouchEnabled(false)

			if arg_7_0.beach:isGameOver() then
				local var_8_0 = var_0_1:translation("BEACH_GAME_OVER")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_8_0
				})
				arg_7_0:nodeByName("attack_btn"):setTouchEnabled(true)
				arg_7_0.contentView_:setTouchEnabled(true)

				return
			end

			if arg_7_0.isWaitGetAward then
				arg_7_0:openChestTip()
				arg_7_0:nodeByName("attack_btn"):setTouchEnabled(true)
				arg_7_0.contentView_:setTouchEnabled(true)

				return
			end

			local function var_8_1()
				local var_9_0 = {
					attack_path = arg_7_0.connectIndex,
					boss_attack_times = arg_7_0.beach:getBossAttackTimes()
				}

				if arg_7_0.isCrit then
					var_9_0.with_critical = 1
				else
					var_9_0.with_critical = 0
				end

				arg_7_0.attackFishIndex = arg_7_0.allBlocks[arg_7_0.connectIndex[1]].fishIndex

				arg_7_0.beach:attack(var_9_0, function(arg_10_0, arg_10_1)
					if arg_10_0 == xyd.error.OK then
						arg_7_0.lastBossHp = arg_7_0.beach:getBossHp()
						arg_7_0.lastBossID = arg_7_0.beach:getBossID()

						arg_7_0.beach:setParams(arg_10_1.boss_info)
						arg_7_0.beach:setParams(arg_10_1)
						arg_7_0:updateAttackTimes()
						arg_7_0:playAttackAnimation()
					else
						arg_7_0:nodeByName("attack_btn"):setTouchEnabled(true)
						arg_7_0.contentView_:setTouchEnabled(true)
					end
				end)
			end

			if arg_7_0.connectIndex and next(arg_7_0.connectIndex) then
				if arg_7_0.beach:getCanAttackTimes() > 0 then
					if arg_7_0.isCrit then
						local var_8_2 = xyd.tables.misc.beachBuyCritPrice
						local var_8_3

						if arg_7_0.beach:getBuyCritTimes() + 1 > #var_8_2 then
							var_8_3 = var_8_2[#var_8_2]
						else
							var_8_3 = var_8_2[arg_7_0.beach:getBuyCritTimes() + 1]
						end

						if var_8_3 > arg_7_0.selfPlayer.crystal then
							xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
								local var_11_0 = {}

								var_11_0.windowState = true

								xyd.WindowManager.get():openWindow("vip_recharge", var_11_0)
							end, nil, nil, arg_7_0.colorMode)
							arg_7_0:nodeByName("attack_btn"):setTouchEnabled(true)
							arg_7_0.contentView_:setTouchEnabled(true)
						else
							var_8_1()

							return
						end
					else
						var_8_1()

						return
					end
				else
					local var_8_4 = xyd.tables.misc.beachBuyAttackPrice
					local var_8_5

					if arg_7_0.beach:getBuyAttackTimes() + 1 >= #var_8_4 then
						var_8_5 = var_8_4[#var_8_4]
					else
						var_8_5 = var_8_4[arg_7_0.beach:getBuyAttackTimes() + 1]
					end

					local var_8_6 = string.format(var_0_1:translation("BEACH_BUY_ATTACK"), var_8_5)

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_8_6, function()
						if var_8_5 > arg_7_0.selfPlayer.crystal then
							xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
								local var_13_0 = {}

								var_13_0.windowState = true

								xyd.WindowManager.get():openWindow("vip_recharge", var_13_0)
							end, nil, nil, arg_7_0.colorMode)
							arg_7_0:nodeByName("attack_btn"):setTouchEnabled(true)
							arg_7_0.contentView_:setTouchEnabled(true)
						else
							arg_7_0.beach:buyAttack(function(arg_14_0, arg_14_1)
								if arg_14_0 == xyd.error.OK then
									arg_7_0.beach:setParams(arg_14_1)
									arg_7_0:updateAttackTimes()

									if arg_7_0.isCrit then
										local var_14_0 = xyd.tables.misc.beachBuyCritPrice
										local var_14_1

										if arg_7_0.beach:getBuyCritTimes() + 1 > #var_14_0 then
											var_14_1 = var_14_0[#var_14_0]
										else
											var_14_1 = var_14_0[arg_7_0.beach:getBuyCritTimes() + 1]
										end

										if var_14_1 > arg_7_0.selfPlayer.crystal then
											xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
												local var_15_0 = {}

												var_15_0.windowState = true

												xyd.WindowManager.get():openWindow("vip_recharge", var_15_0)
											end, nil, nil, arg_7_0.colorMode)
											arg_7_0:nodeByName("attack_btn"):setTouchEnabled(true)
											arg_7_0.contentView_:setTouchEnabled(true)
										else
											var_8_1()

											return
										end
									else
										var_8_1()

										return
									end
								end
							end)
						end
					end, {
						lcallback = function()
							arg_7_0:nodeByName("attack_btn"):setTouchEnabled(true)
							arg_7_0.contentView_:setTouchEnabled(true)
						end
					}, 0, arg_7_0.colorMode)
				end
			else
				local var_8_7 = var_0_1:translation("BEACH_NOT_CONNECT")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_8_7
				})
				arg_7_0:nodeByName("attack_btn"):setTouchEnabled(true)
				arg_7_0.contentView_:setTouchEnabled(true)
			end
		end
	end)
	arg_7_0:nodeByName("crit_btn"):addTouchEventListener(function(arg_17_0, arg_17_1)
		if arg_17_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_7_0.isWaitGetAward then
				arg_7_0:openChestTip()

				return
			end

			arg_7_0.isCrit = not arg_7_0.isCrit

			arg_7_0:updateCritBtnStyle(true)
		end
	end)
	arg_7_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_18_0, arg_18_1)
		xyd.buttonScaleAnim(arg_7_0:nodeByName("rule_btn"), arg_18_1)

		if arg_18_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_18_0 = {
				title_name = "BEACH_RULE_TITLE",
				rule = "BEACH_RULE"
			}

			xyd.WindowManager.get():openWindow("new_text_rule", var_18_0)
		end
	end)

	if arg_7_0.beach:getCanAttackTimes() <= 0 then
		arg_7_0:nodeByName("give_up_btn"):setVisible(true)
	else
		arg_7_0:nodeByName("give_up_btn"):setVisible(false)
	end

	arg_7_0:nodeByName("give_up_btn"):addTouchEventListener(function(arg_19_0, arg_19_1)
		xyd.buttonScaleAnim(arg_7_0:nodeByName("give_up_btn"), arg_19_1)

		if arg_19_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_19_0 = var_0_1:translation("BEACH_GIVE_UP_TIP")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_19_0, function()
				arg_7_0.beach:giveUpGame(function(arg_21_0, arg_21_1)
					if arg_21_0 == xyd.error.OK then
						arg_7_0.beach:setParams(arg_21_1)
						xyd.WindowManager.get():openWindow("beach_enter_wnd")
						xyd.WindowManager.get():closeWindow(arg_7_0)
					end
				end)
			end, nil, nil, arg_7_0.colorMode)
		end
	end)
	arg_7_0:nodeByName("detail_btn"):addTouchEventListener(function(arg_22_0, arg_22_1)
		xyd.buttonScaleAnim(arg_7_0:nodeByName("detail_btn"), arg_22_1)

		if arg_22_1 == ccui.TouchEventType.began then
			arg_7_0:nodeByName("detail_btn"):setBrightStyle(ccui.BrightStyle.highlight)
		elseif arg_22_1 == ccui.TouchEventType.ended then
			arg_7_0:nodeByName("detail_btn"):setBrightStyle(ccui.BrightStyle.normal)
			xyd.WindowManager.get():openWindow("beach_detail")
		end
	end)
	arg_7_0:closeButton():addTouchEventListener(function(arg_23_0, arg_23_1)
		if arg_23_1 == ccui.TouchEventType.ended then
			local var_23_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_23_0, false)

			if arg_7_0.beach:getAwards() and next(arg_7_0.beach:getAwards()) then
				arg_7_0.selfPlayer:handleRewardsWithoutShow(arg_7_0.beach:getAwards())
				arg_7_0.beach:clearAward()
			end

			if arg_7_0.beach:isGameOver() and not arg_7_0.beach:isStart() then
				xyd.WindowManager.get():openWindow("beach_enter_wnd")
			end

			xyd.WindowManager.get():closeWindow(arg_7_0)
		end
	end)
end

function var_0_0.addBgEffect(arg_24_0)
	for iter_24_0 = 1, 3 do
		local var_24_0, var_24_1 = arg_24_0:nodeByName("effect_pos_" .. iter_24_0):getPosition()
		local var_24_2

		if iter_24_0 == 2 or iter_24_0 == 3 then
			var_24_2 = var_0_3.new(arg_24_0.bgEffectPaths[iter_24_0] .. ".json", arg_24_0.bgEffectPaths[iter_24_0] .. ".atlas", 0.7)
		else
			var_24_2 = var_0_3.new(arg_24_0.bgEffectPaths[iter_24_0] .. ".json", arg_24_0.bgEffectPaths[iter_24_0] .. ".atlas", 1)
		end

		if iter_24_0 == 3 then
			var_24_2:setFlipX(true)
		end

		var_24_2:setAnchorPoint(cc.p(0.5, 0.5))
		var_24_2:setPosition(var_24_0, var_24_1)
		var_24_2:addTo(arg_24_0:nodeByName("background"))
		var_24_2:setToSetupPose()
		var_24_2:play(nil, true)
	end
end

function var_0_0.updateCritBtnStyle(arg_25_0, arg_25_1)
	if not arg_25_0.critEffect then
		local var_25_0 = "skeletons/ui_effect/beach/button_click"
		local var_25_1 = var_25_0 .. ".json"
		local var_25_2 = var_25_0 .. ".atlas"

		arg_25_0.critEffect = var_0_3.new(var_25_1, var_25_2, 1)

		arg_25_0.critEffect:addTo(arg_25_0:nodeByName("background"))
		arg_25_0.critEffect:setPosition(arg_25_0:nodeByName("crit_btn"):getPosition())
		arg_25_0.critEffect:setAnchorPoint(cc.p(0.5, 0.5))
		arg_25_0.critEffect:setAnimation(0, "texiao", true)
		arg_25_0.critEffect:setLocalZOrder(5)
		arg_25_0:nodeByName("crit_btn"):setLocalZOrder(10)
	end

	if arg_25_0.isCrit then
		arg_25_0:nodeByName("crit_btn"):getChildByName("crit_txt"):setVisible(false)
		arg_25_0:nodeByName("crit_btn"):getChildByName("crit_active"):setVisible(true)
		arg_25_0:nodeByName("crit_btn"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_25_0.critEffect:setVisible(true)
	else
		arg_25_0:nodeByName("crit_btn"):getChildByName("crit_txt"):setVisible(true)
		arg_25_0:nodeByName("crit_btn"):getChildByName("crit_active"):setVisible(false)
		arg_25_0:nodeByName("crit_btn"):setBrightStyle(ccui.BrightStyle.normal)
		arg_25_0.critEffect:setVisible(false)
	end

	arg_25_0:updateCritCostLabel()

	if arg_25_1 then
		arg_25_0:updateProgress()
	end
end

function var_0_0.openChestTip(arg_26_0)
	local var_26_0 = var_0_1:translation("BEACH_OPEN_CHEST")

	xyd.WindowManager.get():openWindow("toast", {
		message = var_26_0
	})
end

function var_0_0.updateAttackTimes(arg_27_0)
	arg_27_0:nodeByName("left_attack_times"):setString(arg_27_0.beach:getCanAttackTimes())

	if arg_27_0.beach:getCanAttackTimes() <= 0 then
		arg_27_0:nodeByName("give_up_btn"):setVisible(true)
	else
		arg_27_0:nodeByName("give_up_btn"):setVisible(false)
	end
end

function var_0_0.registerTouchEvent(arg_28_0)
	arg_28_0.contentView_:setTouchEnabled(true)
	arg_28_0.contentView_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_29_0)
		if arg_29_0.name == "began" then
			arg_28_0:OnTouchBegan(arg_29_0)

			return true
		elseif arg_29_0.name == "moved" then
			arg_28_0:OnTouchMoved(arg_29_0)

			return true
		end
	end)
end

function var_0_0.OnTouchBegan(arg_30_0, arg_30_1)
	local var_30_0 = arg_30_0.contentView_:convertToNodeSpace(cc.p(arg_30_1.x, arg_30_1.y))

	if arg_30_0:isNotTouchBtn(var_30_0) then
		if arg_30_0.isWaitGetAward then
			arg_30_0:openChestTip()

			return true
		end

		arg_30_0.connectIndex = {}

		arg_30_0:resetBlocks()
		arg_30_0:updateProgress()
	end

	arg_30_0:addConnectBlock(var_30_0)

	return true
end

function var_0_0.isNotTouchBtn(arg_31_0, arg_31_1)
	local var_31_0 = {
		arg_31_0:nodeByName("attack_btn"),
		arg_31_0:nodeByName("crit_btn"),
		arg_31_0:nodeByName("close"),
		(arg_31_0:nodeByName("give_up_btn"))
	}

	for iter_31_0, iter_31_1 in pairs(var_31_0) do
		local var_31_1, var_31_2 = iter_31_1:getPosition()

		btnPos = arg_31_0.contentView_:convertToNodeSpace(cc.p(var_31_1, var_31_2))

		local var_31_3 = iter_31_1:getContentSize().width
		local var_31_4 = iter_31_1:getContentSize().height
		local var_31_5 = cc.rect(var_31_1 - var_31_3 / 2, var_31_2 - var_31_4 / 2, var_31_3, var_31_4)

		if cc.rectContainsPoint(var_31_5, arg_31_1) then
			return false
		end
	end

	return true
end

function var_0_0.OnTouchMoved(arg_32_0, arg_32_1)
	local var_32_0 = arg_32_0.contentView_:convertToNodeSpace(cc.p(arg_32_1.x, arg_32_1.y))

	arg_32_0:addConnectBlock(var_32_0)

	return true
end

function var_0_0.layoutHeroAttackView(arg_33_0)
	local var_33_0 = arg_33_0:nodeByName("hero_attack_view")
	local var_33_1 = var_33_0:getContentSize().width
	local var_33_2 = var_33_0:getContentSize().height
	local var_33_3 = arg_33_0.beach:getBossID()
	local var_33_4 = xyd.tables.beachBoss:getPartnerId(var_33_3)

	if arg_33_0.bossModel and arg_33_0.bossModel.bossID and arg_33_0.bossModel.bossID ~= var_33_3 or not arg_33_0.bossModel then
		if arg_33_0.bossModel then
			arg_33_0.bossModel:setVisible(false)
			arg_33_0.bossModel:removeSelf()

			arg_33_0.bossModel = nil
		end

		local var_33_5 = var_0_2.new()

		var_33_5:populateWithTableID(var_33_4)

		if xyd.tables.beachBoss:getIsSkin(var_33_3) == 1 then
			var_33_5:setSkinInfo(xyd.tables.beachBoss:getBossModelID(var_33_3))
		end

		local var_33_6 = var_33_5:getModelID()
		local var_33_7 = xyd.tables.model:scale(var_33_6)

		arg_33_0.bossModel = var_0_5.new(var_33_5, var_33_7)

		arg_33_0.bossModel:getHeroAnimation():flipX(true)
		arg_33_0.bossModel:setAnchorPoint(cc.p(0, 0))
		arg_33_0.bossModel:addTo(var_33_0)
		arg_33_0.bossModel:setPosition(var_33_1 + 70, -25)
		arg_33_0.bossModel:getHeroAnimation():idle()

		arg_33_0.bossModel.bossID = var_33_3
	end

	if not arg_33_0.heroModel then
		local var_33_8 = var_0_2.new()

		var_33_8:populateWithTableID(var_0_13)

		local var_33_9 = var_33_8:getModelID()
		local var_33_10 = xyd.tables.model:scale(var_33_9)

		arg_33_0.heroModel = var_0_5.new(var_33_8, var_33_10)

		arg_33_0.heroModel:setAnchorPoint(cc.p(0, 0))
		arg_33_0.heroModel:addTo(var_33_0)
		arg_33_0.heroModel:setPosition(-80, -25)
		arg_33_0.heroModel:getHeroAnimation():idle()
	end

	arg_33_0:nodeByName("boss_progress"):setString(var_33_3 .. "/" .. xyd.tables.beachBoss:getBossCount())
end

function var_0_0.layoutBloodLabel(arg_34_0, arg_34_1, arg_34_2, arg_34_3)
	if not arg_34_0.bloodContainer then
		arg_34_0.bloodContainer = display.newNode()

		arg_34_0.bloodContainer:addTo(arg_34_0:nodeByName("background"))
		arg_34_0.bloodContainer:setAnchorPoint(cc.p(0.5, 0.5))
		arg_34_0.bloodContainer:setLocalZOrder(100)

		local var_34_0, var_34_1 = arg_34_0:nodeByName("progress_pos"):getPosition()

		arg_34_0.bloodContainer:setPosition(var_34_0, var_34_1 + 12)
	end

	arg_34_0.bloodContainer:removeAllChildren()

	local var_34_2 = 0
	local var_34_3 = {
		size = 22,
		color = var_0_21
	}
	local var_34_4 = xyd.AssetLoader.get():loadLabel(var_34_3)

	var_34_4:setString(arg_34_1)
	var_34_4:enableOutline(cc.c4b(255, 255, 255, 240), 1)
	var_34_4:addTo(arg_34_0.bloodContainer)
	var_34_4:setPosition(0, 0)

	local var_34_5 = var_34_2 + var_34_4:getContentSize().width
	local var_34_6

	if arg_34_2 then
		local var_34_7 = {
			size = 22,
			color = var_0_22
		}

		var_34_6 = xyd.AssetLoader.get():loadLabel(var_34_7)

		var_34_6:setString(" - " .. arg_34_2)
		var_34_6:enableOutline(cc.c4b(255, 255, 255, 240), 1)
		var_34_6:addTo(arg_34_0.bloodContainer)
	end

	if var_34_6 then
		var_34_6:setPosition(var_34_5, 0)

		var_34_5 = var_34_5 + var_34_6:getContentSize().width
	end

	local var_34_8 = {
		size = 22,
		color = var_0_21
	}
	local var_34_9 = xyd.AssetLoader.get():loadLabel(var_34_8)

	var_34_9:setString(" / " .. arg_34_3)
	var_34_9:enableOutline(cc.c4b(255, 255, 255, 240), 1)
	var_34_9:setPosition(var_34_5, 0)
	var_34_9:addTo(arg_34_0.bloodContainer)

	local var_34_10 = var_34_5 + var_34_9:getContentSize().width

	arg_34_0.bloodContainer:setContentSize(var_34_10, var_34_4:getContentSize().height)
end

function var_0_0.initProgressBar(arg_35_0)
	if not arg_35_0.progressBar then
		arg_35_0.progressBar = cc.ProgressTimer:create(cc.Sprite:create("windows/beach_activity/main_wnd/progress_bar1.png"))

		arg_35_0.progressBar:addTo(arg_35_0:nodeByName("background"))
		arg_35_0.progressBar:setAnchorPoint(cc.p(0.5, 0.5))
		arg_35_0.progressBar:setPosition(arg_35_0:nodeByName("progress_pos"):getPosition())
		arg_35_0.progressBar:setLocalZOrder(10)
		arg_35_0.progressBar:setType(cc.PROGRESS_TIMER_TYPE_BAR)
		arg_35_0.progressBar:setMidpoint(cc.p(0, 0))
		arg_35_0.progressBar:setBarChangeRate(cc.p(1, 0))

		local var_35_0 = cc.ProgressTo:create(0, 100)

		arg_35_0.progressBar:runAction(cc.Repeat:create(var_35_0, 1))
	end

	if not arg_35_0.bgProgressBar then
		arg_35_0.bgProgressBar = cc.ProgressTimer:create(cc.Sprite:create("windows/beach_activity/main_wnd/progress_bar2.png"))

		arg_35_0.bgProgressBar:addTo(arg_35_0:nodeByName("background"))
		arg_35_0.bgProgressBar:setAnchorPoint(cc.p(0.5, 0.5))
		arg_35_0.bgProgressBar:setPosition(arg_35_0:nodeByName("progress_pos"):getPosition())
		arg_35_0.bgProgressBar:setLocalZOrder(5)
		arg_35_0.bgProgressBar:setType(cc.PROGRESS_TIMER_TYPE_BAR)
		arg_35_0.bgProgressBar:setMidpoint(cc.p(0, 0))
		arg_35_0.bgProgressBar:setBarChangeRate(cc.p(1, 0))

		local var_35_1 = cc.ProgressTo:create(0, 100)

		arg_35_0.bgProgressBar:runAction(cc.Repeat:create(var_35_1, 1))
	end

	local var_35_2 = arg_35_0.beach:getBossID()
	local var_35_3 = arg_35_0.beach:getBossHp()
	local var_35_4 = xyd.tables.beachBoss:getBossHp(var_35_2)

	arg_35_0:layoutBloodLabel(var_35_3, nil, var_35_4)
end

function var_0_0.updateProgress(arg_36_0)
	local var_36_0 = arg_36_0.beach:getBossID()
	local var_36_1 = arg_36_0.beach:getBossHp()
	local var_36_2 = xyd.tables.beachBoss:getBossHp(var_36_0)
	local var_36_3 = var_36_1 / var_36_2 * 100
	local var_36_4 = 0

	for iter_36_0, iter_36_1 in pairs(arg_36_0.connectIndex) do
		if arg_36_0.allBlocks[iter_36_1] then
			local var_36_5 = arg_36_0.allBlocks[iter_36_1].fishIndex
			local var_36_6 = 0

			if var_36_5 == 1 then
				var_36_6 = xyd.tables.misc.pinkDamage
			elseif var_36_5 == 2 then
				var_36_6 = xyd.tables.misc.blueDamage
			elseif var_36_5 == 3 then
				var_36_6 = xyd.tables.misc.redDamage
			end

			if arg_36_0.isCrit then
				var_36_6 = var_36_6 * xyd.tables.misc.beachCritNum
			end

			var_36_4 = var_36_4 + var_36_6
		end
	end

	arg_36_0.attackDamage = var_36_4

	local var_36_7
	local var_36_8 = (var_36_1 - var_36_4) / var_36_2 * 100

	if var_36_8 < 100 and var_36_8 > 99 then
		var_36_7 = math.floor(var_36_8)
	elseif var_36_8 > 0 and var_36_8 < 1 then
		var_36_7 = math.ceil(var_36_8)
	else
		var_36_7 = var_36_8
	end

	local var_36_9 = cc.ProgressTo:create(0, var_36_7)

	arg_36_0.progressBar:runAction(cc.Repeat:create(var_36_9, 1))

	local var_36_10 = cc.ProgressTo:create(0, var_36_3)

	arg_36_0.bgProgressBar:runAction(cc.Repeat:create(var_36_10, 1))

	if var_36_4 == 0 then
		arg_36_0:layoutBloodLabel(var_36_1, nil, var_36_2)
	else
		arg_36_0:layoutBloodLabel(var_36_1, var_36_4, var_36_2)
	end
end

function var_0_0.layoutConnectLineView(arg_37_0)
	arg_37_0.fishMatrix = arg_37_0:formatBlocks(xyd.tables.beachMatch:getMatchGroup(arg_37_0.beach:getMatrixID()))

	if not arg_37_0.fishMatrix then
		return
	end

	if arg_37_0.allBlocks and next(arg_37_0.allBlocks) then
		for iter_37_0, iter_37_1 in pairs(arg_37_0.allBlocks) do
			local var_37_0 = iter_37_1.row
			local var_37_1 = iter_37_1.col
			local var_37_2 = {
				fishIndex = arg_37_0.fishMatrix[var_37_0][var_37_1]
			}

			iter_37_1:setParams(var_37_2)
		end
	else
		arg_37_0.allBlocks = {}

		for iter_37_2 = 1, 4 do
			for iter_37_3 = 1, 4 do
				local var_37_3 = import("app.windows.FishCell").new()
				local var_37_4 = {
					fishIndex = arg_37_0.fishMatrix[iter_37_2][iter_37_3]
				}

				var_37_3:setParams(var_37_4)

				var_37_3.index = (iter_37_2 - 1) * 4 + iter_37_3
				var_37_3.row = iter_37_2
				var_37_3.col = iter_37_3

				var_37_3:addTo(arg_37_0:nodeByName("background"))
				var_37_3:setAnchorPoint(cc.p(0.5, 0.5))
				var_37_3:setPosition(arg_37_0:nodeByName("p" .. iter_37_2 .. "_" .. iter_37_3):getPosition())
				var_37_3:retain()
				table.insert(arg_37_0.allBlocks, var_37_3)
			end
		end
	end

	arg_37_0.contentView_:setTouchEnabled(true)
	arg_37_0:nodeByName("attack_btn"):setTouchEnabled(true)
end

function var_0_0.resetBlocks(arg_38_0)
	if arg_38_0.allBlocks and next(arg_38_0.allBlocks) then
		for iter_38_0, iter_38_1 in pairs(arg_38_0.allBlocks) do
			if not iter_38_1.isReset then
				iter_38_1:reset()
			end
		end
	end
end

function var_0_0.formatBlocks(arg_39_0, arg_39_1)
	if not arg_39_1 or not next(arg_39_1) or #arg_39_1 ~= 16 then
		return nil
	end

	local var_39_0 = {}

	for iter_39_0 = 1, #arg_39_1 do
		local var_39_1 = math.floor((iter_39_0 - 1) / 4) + 1
		local var_39_2 = (iter_39_0 - 1) % 4 + 1

		if not var_39_0[var_39_1] then
			var_39_0[var_39_1] = {}
		end

		var_39_0[var_39_1][var_39_2] = arg_39_1[iter_39_0]
	end

	return var_39_0
end

function var_0_0.addConnectBlock(arg_40_0, arg_40_1)
	if arg_40_0.connectIndex and next(arg_40_0.connectIndex) then
		local var_40_0 = arg_40_0.allBlocks[arg_40_0.connectIndex[#arg_40_0.connectIndex]]
		local var_40_1
		local var_40_2
		local var_40_3
		local var_40_4

		if #arg_40_0.connectIndex > 1 then
			local var_40_5 = arg_40_0.allBlocks[arg_40_0.connectIndex[#arg_40_0.connectIndex - 1]]
			local var_40_6 = var_40_5.row
			local var_40_7 = var_40_5.col

			var_40_4 = (var_40_6 - 1) * 4 + var_40_7
		end

		local var_40_8 = var_40_0.row
		local var_40_9 = var_40_0.col
		local var_40_10 = (var_40_8 - 1) * 4 + var_40_9

		for iter_40_0 = -1, 1 do
			for iter_40_1 = -1, 1 do
				if iter_40_0 ~= 0 or iter_40_1 ~= 0 then
					local var_40_11 = var_40_8 + iter_40_0
					local var_40_12 = var_40_9 + iter_40_1
					local var_40_13 = (var_40_11 - 1) * 4 + var_40_12

					if arg_40_0:fishPosCheck(var_40_11, var_40_12) and arg_40_0.allBlocks[var_40_13] and arg_40_0:checkCanConnect(var_40_13) and arg_40_0:locationInBlock(var_40_13, arg_40_1) then
						table.insert(arg_40_0.connectIndex, var_40_13)
						arg_40_0.allBlocks[var_40_10]:updateByConnectStatus(iter_40_1, iter_40_0, 1)

						local var_40_14 = 0
						local var_40_15 = 0

						if iter_40_0 ~= 0 then
							var_40_14 = -iter_40_0
						end

						if iter_40_1 ~= 0 then
							var_40_15 = -iter_40_1
						end

						arg_40_0.allBlocks[var_40_13]:updateByConnectStatus(var_40_15, var_40_14, 1)
						arg_40_0:updateProgress()

						return
					end

					if arg_40_0:fishPosCheck(var_40_11, var_40_12) and var_40_13 == var_40_4 and arg_40_0:locationInBlock(var_40_13, arg_40_1) then
						table.remove(arg_40_0.connectIndex, #arg_40_0.connectIndex)
						arg_40_0.allBlocks[var_40_10]:updateByConnectStatus(iter_40_1, iter_40_0, 0)

						local var_40_16 = 0
						local var_40_17 = 0

						if iter_40_0 ~= 0 then
							var_40_16 = -iter_40_0
						end

						if iter_40_1 ~= 0 then
							var_40_17 = -iter_40_1
						end

						arg_40_0.allBlocks[var_40_4]:updateByConnectStatus(var_40_17, var_40_16, 0)
						arg_40_0.allBlocks[var_40_4]:updateByConnectStatus()
						arg_40_0:updateProgress()

						return
					end
				end
			end
		end
	else
		arg_40_0.connectIndex = {}

		for iter_40_2, iter_40_3 in pairs(arg_40_0.allBlocks) do
			local var_40_18 = iter_40_3.row
			local var_40_19 = iter_40_3.col
			local var_40_20 = (var_40_18 - 1) * 4 + var_40_19

			if arg_40_0.allBlocks[var_40_20] and arg_40_0:locationInBlock(var_40_20, arg_40_1) then
				table.insert(arg_40_0.connectIndex, var_40_20)
				arg_40_0.allBlocks[var_40_20]:updateByConnectStatus()
				arg_40_0:updateProgress()

				return
			end
		end
	end
end

function var_0_0.fishPosCheck(arg_41_0, arg_41_1, arg_41_2)
	if arg_41_1 < 1 or arg_41_1 > 4 then
		return false
	end

	if arg_41_2 < 1 or arg_41_2 > 4 then
		return false
	end

	return true
end

function var_0_0.checkCanConnect(arg_42_0, arg_42_1)
	if not arg_42_0.connectIndex or not next(arg_42_0.connectIndex) then
		return true
	end

	if not arg_42_0:checkBlockConnected(arg_42_1) then
		local var_42_0 = arg_42_0.allBlocks[arg_42_0.connectIndex[#arg_42_0.connectIndex]]
		local var_42_1 = arg_42_0.fishMatrix[var_42_0.row][var_42_0.col]
		local var_42_2 = arg_42_0.allBlocks[arg_42_1]

		if var_42_1 == arg_42_0.fishMatrix[var_42_2.row][var_42_2.col] then
			return true
		end
	end

	return false
end

function var_0_0.locationInBlock(arg_43_0, arg_43_1, arg_43_2)
	local var_43_0 = arg_43_0.allBlocks[arg_43_1]

	if not var_43_0 then
		return false
	end

	local var_43_1, var_43_2 = var_43_0:getPosition()
	local var_43_3 = cc.rect(var_43_1 - var_0_7 / 2, var_43_2 - var_0_7 / 2, var_0_7, var_0_7)

	if cc.rectContainsPoint(var_43_3, arg_43_2) then
		return true
	end

	return false
end

function var_0_0.checkBlockConnected(arg_44_0, arg_44_1)
	if not arg_44_0.connectIndex or not next(arg_44_0.connectIndex) then
		return false
	end

	for iter_44_0, iter_44_1 in pairs(arg_44_0.connectIndex) do
		if iter_44_1 == arg_44_1 then
			return true
		end
	end

	return false
end

function var_0_0.playAttackAnimation(arg_45_0)
	arg_45_0.animationCrit = arg_45_0.isCrit

	arg_45_0:playFishCellAnimation()
end

function var_0_0.playFishCellAnimation(arg_46_0)
	local var_46_0 = #arg_46_0.connectIndex
	local var_46_1 = 0

	arg_46_0.explodeHandle = var_0_4.scheduleGlobal(function()
		var_46_1 = var_46_1 + 1

		if xyd.WindowManager.get():getWindow("beach_main_wnd") then
			if var_46_1 <= var_46_0 then
				local var_47_0 = arg_46_0.connectIndex[var_46_1]

				if arg_46_0.allBlocks and next(arg_46_0.allBlocks) then
					arg_46_0.allBlocks[var_47_0]:explode()
				end

				if var_46_1 + 1 <= var_46_0 then
					local var_47_1 = arg_46_0.allBlocks[arg_46_0.connectIndex[var_46_1 + 1]]
					local var_47_2 = var_47_1.row
					local var_47_3 = var_47_1.col
					local var_47_4 = arg_46_0.allBlocks[var_47_0]
					local var_47_5 = var_47_4.row
					local var_47_6 = var_47_4.col - var_47_3
					local var_47_7 = var_47_5 - var_47_2

					var_47_1:updateByConnectStatus(var_47_6, var_47_7, 0)
					var_47_1:updateByConnectStatus()
				end
			else
				arg_46_0.connectIndex = {}
				arg_46_0.isCrit = false

				arg_46_0:updateCritBtnStyle(false)
				arg_46_0:playHeroAttackAnimation()

				if arg_46_0.explodeHandle then
					var_0_4.unscheduleGlobal(arg_46_0.explodeHandle)

					arg_46_0.explodeHandle = nil
				end
			end
		elseif arg_46_0.explodeHandle then
			var_0_4.unscheduleGlobal(arg_46_0.explodeHandle)

			arg_46_0.explodeHandle = nil
		end
	end, 0.1)
end

function var_0_0.playProgressAnimation(arg_48_0)
	if not arg_48_0.lastBossHp or not arg_48_0.lastBossID then
		return
	end

	local var_48_0 = arg_48_0.beach:getBossHp()
	local var_48_1 = xyd.tables.beachBoss:getBossHp(arg_48_0.lastBossID)
	local var_48_2 = arg_48_0.lastBossHp / var_48_1 * 100

	if var_48_0 > arg_48_0.lastBossHp then
		var_48_0 = 0
	end

	local var_48_3 = var_48_0 / var_48_1 * 100
	local var_48_4 = var_48_3 - var_48_2
	local var_48_5 = cc.CallFunc:create(function()
		local var_49_0 = 0.35 + xyd.tables.battleConfig.hpProgressMoveStep * math.abs(var_48_4)
		local var_49_1 = xyd.tables.battleConfig.hpProgressBrakeBase * 2.4
		local var_49_2 = var_48_2 + var_48_4 * 0.92
		local var_49_3 = var_48_3
		local var_49_4 = cc.Sequence:create(cc.ProgressTo:create(var_49_0, var_49_2), cc.ProgressTo:create(var_49_1, var_49_3))

		arg_48_0.bgProgressBar:runActionOnce(var_49_4)
	end)

	arg_48_0:layoutBloodLabel(var_48_0, nil, var_48_1)

	local var_48_6 = cc.ProgressTo:create(0, var_48_2)

	arg_48_0.progressBar:runAction(cc.Repeat:create(var_48_6, 1))

	local var_48_7 = cc.Sequence:create(cc.ProgressTo:create(0.2, var_48_3), var_48_5)

	arg_48_0.progressBar:runActionOnce(var_48_7)
end

function var_0_0.playHeroAttackAnimation(arg_50_0, arg_50_1)
	if arg_50_0.animationCrit then
		arg_50_0.beganTime = var_0_15
	else
		arg_50_0.beganTime = var_0_14
	end

	arg_50_0:beginAttack()
end

function var_0_0.createAttackUnit(arg_51_0)
	if not arg_51_0.attackFishIndex then
		return
	end

	local var_51_0 = xyd.tables.misc.beachDandao[arg_51_0.attackFishIndex] .. ".json"
	local var_51_1 = xyd.tables.misc.beachDandao[arg_51_0.attackFishIndex] .. ".atlas"
	local var_51_2 = var_0_3.new(var_51_0, var_51_1, 1)

	var_51_2:setAnimation(0, "texiao", true)
	var_51_2:setScale(0.6)
	var_51_2:addTo(arg_51_0:nodeByName("hero_attack_view"))

	return var_51_2
end

function var_0_0.endAttack(arg_52_0)
	arg_52_0.isBeginAttack = false
	arg_52_0.beganAttackFlag = false
	arg_52_0.attackFlag = false
	arg_52_0.attackedFlag = false
	arg_52_0.beganCount = 0
	arg_52_0.attackCount = 0
	arg_52_0.attackedCount = 0
end

function var_0_0.beginAttack(arg_53_0)
	arg_53_0.isBeginAttack = true
	arg_53_0.beganAttackFlag = true
	arg_53_0.attackFlag = false
	arg_53_0.attackedFlag = false
	arg_53_0.beganCount = 0
	arg_53_0.attackCount = 0
	arg_53_0.attackedCount = 0
end

function var_0_0.refreshAfterAttack(arg_54_0)
	arg_54_0.attackFishIndex = nil
	arg_54_0.connectIndex = {}

	arg_54_0:layoutConnectLineView()
end

function var_0_0.update_(arg_55_0, arg_55_1)
	if arg_55_0.isBeginAttack then
		if arg_55_0.heroModel and arg_55_0.beganAttackFlag then
			if arg_55_0.beganCount == 0 then
				if arg_55_0.animationCrit then
					arg_55_0.heroModel:getHeroAnimation():setAnimation(0, "gongji03", false)

					arg_55_0.attackPoint = arg_55_0.heroModel:getHeroAnimation().attackPoints[3]

					audio.playSound(xyd.tables.model:getAttack4Sound(arg_55_0.heroModel.hero_:getModelID()), false)
				else
					arg_55_0.heroModel:getHeroAnimation():setAnimation(0, "gongji01", false)

					arg_55_0.attackPoint = arg_55_0.heroModel:getHeroAnimation().attackPoints[1]
				end
			end

			arg_55_0.beganCount = arg_55_0.beganCount + 1
		end

		if arg_55_0.beganCount >= arg_55_0.beganTime or arg_55_0.attackFlag then
			if arg_55_0.beganCount > 0 then
				arg_55_0.beganCount = 0

				arg_55_0.heroModel:getHeroAnimation():idle()

				arg_55_0.attackFlag = true
				arg_55_0.beganAttackFlag = false
			end

			if arg_55_0.attackCount == 0 then
				arg_55_0.attackUnit = arg_55_0:createAttackUnit()

				if not arg_55_0.attackUnit then
					arg_55_0:endAttack()

					return
				end

				local var_55_0, var_55_1 = arg_55_0.heroModel:getPosition()

				arg_55_0.beganX = var_55_0 + arg_55_0.attackPoint.x
				arg_55_0.beganY = var_55_1 + arg_55_0.attackPoint.y

				arg_55_0.attackUnit:setPosition(arg_55_0.beganX, var_55_1 + arg_55_0.beganY)

				local var_55_2 = arg_55_0.bossModel:getHeroAnimation().attackedPoint

				arg_55_0.desX, arg_55_0.desY = arg_55_0.bossModel:getPosition()
				arg_55_0.desX = arg_55_0.desX + var_55_2.x
				arg_55_0.desY = arg_55_0.desY + var_55_2.y

				if arg_55_0.desX - arg_55_0.beganX >= 0 then
					arg_55_0.speedX = var_0_17
				else
					arg_55_0.speedX = -var_0_17
				end

				if arg_55_0.desY - arg_55_0.beganY >= 0 then
					arg_55_0.speedY = var_0_19
				else
					arg_55_0.speedY = -var_0_19
				end
			end

			local var_55_3, var_55_4 = arg_55_0.attackUnit:getPosition()
			local var_55_5 = false
			local var_55_6 = false

			if math.abs(arg_55_0.desX - var_55_3) < arg_55_0.speedX or arg_55_0.speedX == 0 then
				var_55_5 = true
			else
				arg_55_0.attackUnit:setPosition(var_55_3 + arg_55_0.speedX * var_0_18, var_55_4)
			end

			if math.abs(arg_55_0.desY - var_55_4) < arg_55_0.speedY or arg_55_0.speedY == 0 then
				var_55_6 = true
			else
				local var_55_7, var_55_8 = arg_55_0.attackUnit:getPosition()

				arg_55_0.attackUnit:setPosition(var_55_7, var_55_8 + arg_55_0.speedY * var_0_20)
			end

			if var_55_5 and var_55_6 then
				arg_55_0.attackCount = 0
				arg_55_0.attackedFlag = true
				arg_55_0.attackFlag = false
			else
				arg_55_0.attackCount = arg_55_0.attackCount + 1
			end
		end

		if arg_55_0.attackedFlag then
			if arg_55_0.attackUnit and arg_55_0.attackedCount == 0 then
				if not tolua.isnull(arg_55_0.attackUnit) then
					arg_55_0.attackUnit:setVisible(false)

					if arg_55_0.hurtEffect and not tolua.isnull(arg_55_0.hurtEffect) then
						arg_55_0.hurtEffect:removeSelf()
					end

					local var_55_9 = xyd.tables.misc.beachHurt[arg_55_0.attackFishIndex]

					arg_55_0.hurtEffect = var_0_3.new(var_55_9 .. ".json", var_55_9 .. ".atlas", 1)

					arg_55_0.hurtEffect:play(function()
						if arg_55_0.hurtEffect and not tolua.isnull(arg_55_0.hurtEffect) then
							arg_55_0.hurtEffect:setVisible(false)
						end
					end, false)
					arg_55_0.hurtEffect:setAnchorPoint(cc.p(0.5, 0.5))
					arg_55_0.hurtEffect:addTo(arg_55_0:nodeByName("hero_attack_view"))

					local var_55_10, var_55_11 = arg_55_0.attackUnit:getPosition()

					arg_55_0.hurtEffect:setPosition(var_55_10, var_55_11 - 10)
					arg_55_0.attackUnit:removeSelf()
				end

				local var_55_12 = {}
				local var_55_13 = {}
				local var_55_14 = {
					x = 60,
					y = -50
				}

				var_55_13[1] = -arg_55_0.attackDamage

				if arg_55_0.animationCrit then
					var_55_13[2] = var_55_13[1]
				end

				table.insert(var_55_12, var_55_13)

				if arg_55_0.beach:isBossChange() or arg_55_0.beach:isGameOver() then
					arg_55_0.bossModel:getHeroAnimation():die()
					audio.playSound(arg_55_0.explodeSoundPaths[arg_55_0.attackFishIndex], false)
					audio.playSound(xyd.tables.model:deathSound(arg_55_0.bossModel.hero_:getModelID()), false)

					arg_55_0.bossModel.playFloat = true

					arg_55_0.bossModel:playHPDeltas(var_55_12, nil, var_55_14)
					arg_55_0:dropChest()

					arg_55_0.attackedFlag = false

					arg_55_0:playProgressAnimation()
					arg_55_0:refreshAfterAttack()
					arg_55_0:endAttack()

					return
				else
					arg_55_0.bossModel:getHeroAnimation():attacked()
					arg_55_0:dropChest()
					audio.playSound(arg_55_0.explodeSoundPaths[arg_55_0.attackFishIndex], false)

					arg_55_0.bossModel.playFloat = true

					arg_55_0.bossModel:playHPDeltas(var_55_12, nil, var_55_14)
					arg_55_0:playProgressAnimation()
					arg_55_0:refreshAfterAttack()
				end
			end

			if arg_55_0.attackedCount > var_0_16 then
				arg_55_0.bossModel:getHeroAnimation():idle()

				arg_55_0.attackedFlag = false

				arg_55_0:endAttack()
			end

			arg_55_0.attackedCount = arg_55_0.attackedCount + 1
		end
	end
end

function var_0_0.dropChest(arg_57_0)
	if not arg_57_0.beach:getAwards() then
		arg_57_0:layoutHeroAttackView()
		arg_57_0:updateProgress()

		return
	end

	arg_57_0.isWaitGetAward = true

	local var_57_0, var_57_1 = arg_57_0.bossModel:getPosition()
	local var_57_2 = "skeletons/ui_effect/effect_baoxiang/baoxiang01"
	local var_57_3 = var_0_3.new(var_57_2 .. ".json", var_57_2 .. ".atlas", 1)
	local var_57_4 = display.newNode()

	var_57_4:setContentSize(132, 122)
	var_57_4:setAnchorPoint(cc.p(0.5, 0.5))
	var_57_4:setTouchEnabled(true)
	var_57_4:setTouchSwallowEnabled(true)
	var_57_4:addTo(arg_57_0:nodeByName("hero_attack_view"))
	var_57_3:addTo(var_57_4)
	var_57_3:setAnchorPoint(cc.p(0.5, 0.5))
	var_57_3:setPosition(var_57_4:getContentSize().width / 2, var_57_4:getContentSize().height / 2)
	var_57_3:play(nil, true)
	var_57_4:setPosition(var_57_0 + 40, var_57_1 + 15)
	var_57_4:setScale(0.2)

	local var_57_5 = {
		cc.p(0, 0),
		cc.p(80, 100),
		cc.p(190, -100)
	}
	local var_57_6 = cc.CardinalSplineBy:create(0.7, var_57_5, 0)
	local var_57_7 = cc.ScaleTo:create(0.7, 0.8)
	local var_57_8 = cc.Spawn:create(cc.FadeIn:create(0.7), var_57_6, var_57_7)
	local var_57_9 = cc.Sequence:create(var_57_8, cc.CallFunc:create(function()
		var_57_4:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_59_0)
			if arg_59_0.name == "ended" then
				arg_57_0.connectIndex = {}

				arg_57_0:resetBlocks()
				arg_57_0.contentView_:setTouchEnabled(true)
				arg_57_0:nodeByName("attack_btn"):setTouchEnabled(true)

				if arg_57_0.beach:getAwards() then
					audio.playSound(arg_57_0.openChestSoundPath, false)

					if var_57_3 and not tolua.isnull(var_57_3) then
						var_57_3:setVisible(false)
						var_57_3:removeSelf()
					end

					local var_59_0 = "skeletons/ui_effect/effect_baoxiang/baoxiang02"
					local var_59_1 = var_0_3.new(var_59_0 .. ".json", var_59_0 .. ".atlas", 1)

					var_59_1:addTo(var_57_4)
					var_59_1:setAnchorPoint(cc.p(0.5, 0.5))
					var_59_1:setPosition(var_57_4:getContentSize().width / 2, var_57_4:getContentSize().height / 2)
					var_59_1:play(nil, true)
					var_0_4.performWithDelayGlobal(function()
						local var_60_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

						if arg_57_0.beach and arg_57_0.beach:getAwards() then
							local var_60_1 = xyd.tables.beachBoss:getScore(arg_57_0.lastBossID)
							local var_60_2 = string.format(var_0_6:translation("BEACH_MAIN_TXT_1"), var_60_1)

							xyd.WindowManager.get():openWindow("toast", {
								message = var_60_2
							})
							var_0_4.performWithDelayGlobal(function()
								if var_57_4 and not tolua.isnull(var_57_4) then
									var_57_4:setVisible(false)
									var_57_4:removeSelf()
								end

								if arg_57_0.layoutHeroAttackView then
									arg_57_0:layoutHeroAttackView()
								end

								if arg_57_0.updateProgress then
									arg_57_0.connectIndex = {}

									arg_57_0:updateProgress()
								end

								arg_57_0.isWaitGetAward = false

								var_60_0:handleRewards(arg_57_0.beach:getAwards(), function()
									return
								end)
								arg_57_0.beach:clearAward()

								if arg_57_0.beach:isGameOver() then
									if xyd.WindowManager.get():getWindow("beach_enter_wnd") then
										xyd.WindowManager.get():closeWindow("beach_enter_wnd")
									end

									xyd.WindowManager.get():openWindow("beach_enter_wnd")
									xyd.WindowManager.get():closeWindow(arg_57_0.name)
								end
							end, 0.4)
						end
					end, 0.4)
				end
			end

			return true
		end)
	end))

	audio.playSound(arg_57_0.dropChestSoundPath, false)
	var_57_4:runAction(var_57_9)
end

function var_0_0.addBgMusic(arg_63_0)
	audio.stopMusic()
	audio.stopAllSounds()

	local var_63_0 = xyd.tables.sound:getSound("beach_bgm")

	var_0_4.performWithDelayGlobal(function()
		if var_63_0 then
			audio.preloadMusic(var_63_0)
			audio.playMusic(var_63_0, true)
		end
	end, 1)
end

function var_0_0.updateCritCostLabel(arg_65_0)
	if arg_65_0.isCrit then
		arg_65_0:nodeByName("crit_cost_txt"):setVisible(true)
		arg_65_0:nodeByName("crit_cost_num"):setVisible(true)
		arg_65_0:nodeByName("yuanbao"):setVisible(true)

		local var_65_0 = xyd.tables.misc.beachBuyCritPrice
		local var_65_1

		if arg_65_0.beach:getBuyCritTimes() + 1 > #var_65_0 then
			var_65_1 = var_65_0[#var_65_0]
		else
			var_65_1 = var_65_0[arg_65_0.beach:getBuyCritTimes() + 1]
		end

		arg_65_0:nodeByName("crit_cost_num"):setString(var_65_1)
	else
		arg_65_0:nodeByName("crit_cost_txt"):setVisible(false)
		arg_65_0:nodeByName("crit_cost_num"):setVisible(false)
		arg_65_0:nodeByName("yuanbao"):setVisible(false)
	end
end

function var_0_0.removeBgMusic(arg_66_0)
	audio.stopMusic()
	audio.stopAllSounds()

	local var_66_0 = xyd.tables.sound:getSound("home_bg_music")

	audio.preloadMusic(var_66_0)
	audio.playMusic(var_66_0, true)
end

function var_0_0.initLabel(arg_67_0)
	arg_67_0:nodeByName("left_attack_times_txt"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
	arg_67_0:nodeByName("game_progress_txt"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
	arg_67_0:nodeByName("left_attack_times"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
	arg_67_0:nodeByName("crit_cost_txt"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
	arg_67_0:nodeByName("crit_cost_num"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
	arg_67_0:nodeByName("left_attack_times_txt"):setString(var_0_1:translation("BEACH_LEFT_ATTACK_TIMES"))
	arg_67_0:nodeByName("game_progress_txt"):setString(var_0_1:translation("BEACH_BOSS_PROGRESS"))
	arg_67_0:nodeByName("crit_cost_txt"):setString(var_0_1:translation("MANA_COST"))
	arg_67_0:nodeByName("detail_btn"):getChildByName("detail_txt"):setString(var_0_6:translation("POINT_AWARD"))
end

function var_0_0.willClose(arg_68_0)
	arg_68_0:removeBgMusic()

	if arg_68_0.explodeHandle then
		var_0_4.unscheduleGlobal(arg_68_0.explodeHandle)

		arg_68_0.explodeHandle = nil
	end
end

return var_0_0
