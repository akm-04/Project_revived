local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SpineEffect")

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.nianBoss = xyd.ModelManager.get():loadModel(xyd.ModelType.NIAN_BOSS)
	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)
	arg_2_0.nianBoss:loadNianBoss(function(arg_3_0)
		if arg_3_0 ~= xyd.error.OK then
			print("nianboss info load faild.")
		else
			if not arg_2_0.res or arg_2_0.res == 0 then
				print("No res available.")

				return
			end

			local var_3_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

			var_3_0:addTo(arg_2_0.parent)
			var_3_0:setName("detail")
			var_3_0:setAnchorPoint(cc.p(0, 0))
			var_3_0:setPosition(0, 0)

			local var_3_1 = arg_2_0.parent:getChildByName("detail"):getChildByName("container")
			local var_3_2 = xyd.tables.activities:title(arg_2_0.activity.table_id)
			local var_3_3 = xyd.AssetLoader.get():loadSprite(var_3_2)
			local var_3_4, var_3_5 = var_3_1:getChildByName("title_pos"):getPosition()

			var_3_3:addTo(var_3_1)
			var_3_3:setAnchorPoint(cc.p(0.5, 0.5))
			var_3_3:pos(var_3_4, var_3_5)
			arg_2_0:initNianWindow()
		end
	end)
end

function var_0_0.initNianWindow(arg_4_0)
	local var_4_0 = 5
	local var_4_1 = arg_4_0.parent:getChildByName("detail"):getChildByName("container")
	local var_4_2 = var_4_1:getChildByName("model_container")
	local var_4_3 = var_4_1:getChildByName("fire_btn")
	local var_4_4 = var_4_1:getChildByName("times"):getChildByName("btn_add")
	local var_4_5 = var_4_1:getChildByName("rule_btn")
	local var_4_6 = var_4_1:getChildByName("rank_btn")
	local var_4_7 = arg_4_0.nianBoss:getNianModel()

	var_4_7:setTouchSwallowEnabled(false)

	local var_4_8 = var_4_2:getContentSize().width / 2

	var_4_7:setPosition(cc.p(var_4_8, 0))
	var_4_2:removeAllChildren()
	var_4_7:addTo(var_4_2)
	arg_4_0:updateNianWindow()

	local var_4_9 = "skeletons/nian/yanhua"
	local var_4_10 = var_4_9 .. ".json"
	local var_4_11 = var_4_9 .. ".atlas"
	local var_4_12 = var_0_2.new(var_4_10, var_4_11, 1)

	var_4_12:setAnchorPoint(cc.p(0.5, 0.5))
	var_4_12:setPosition(var_4_1:getWidth() / 2 + 2, var_4_1:getHeight() / 2 - 80)
	var_4_12:addTo(var_4_1)
	var_4_12:setScale(0.6)
	var_4_12:hide()
	var_4_4:addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if xyd.tables.refreshCost:buyBossCost(arg_4_0.nianBoss.buyBossTimes + 1) ~= 0 then
				if arg_4_0.nianBoss.buyBossTimes < xyd.tables.vip.buyElementTimes_[arg_4_0.player.vip] then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_1:translation("WORLD_BOSS_BUY_TIMES_ALERT"), xyd.tables.refreshCost:buyBossCost(arg_4_0.nianBoss.buyBossTimes + 1), var_4_0), function()
						if arg_4_0.player.crystal < xyd.tables.refreshCost:buyBossCost(arg_4_0.nianBoss.buyBossTimes + 1) then
							xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
								xyd.WindowManager.get():openWindow(xyd.WindowName.vipRecharge)
							end, nil, nil, xyd.ColorMode.ACTIVITY)
						else
							arg_4_0.nianBoss:buyTimes(function(arg_8_0)
								if arg_8_0 == xyd.error.OK then
									arg_4_0:updateNianWindow()
								end
							end)
						end
					end, nil, 0, xyd.ColorMode.ACTIVITY)
				else
					xyd.WindowManager.get():openWindow("toast", {
						message = TranslationTable:translation("ELEMENT_RESET_VIP")
					})
				end
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = TranslationTable:translation("DAILY_TIMES_OVER")
				})
			end
		end
	end)
	var_4_5:addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("nian_boss_rule")
		end
	end)

	local var_4_13 = xyd.ModelManager.get():loadModel(xyd.ModelType.ARENA)

	var_4_6:addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			var_4_13:loadRankInfo(function(arg_11_0)
				local var_11_0 = {
					sub_type = 1,
					rank_type = xyd.RankType.NB,
					rankData = var_4_13:getRankData()
				}

				xyd.WindowManager.get():openWindow(xyd.WindowName.rankWnd, var_11_0)
			end)
		end
	end)
	var_4_3:addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.ended then
			local var_12_0 = 50001049

			if arg_4_0.player:getBackpack():getItemNumByID(var_12_0) > 0 then
				local var_12_1 = {
					campaign_id = arg_4_0.nianBoss.boss_id
				}

				xyd.Backend.get():request(xyd.mid.NIAN_BOSS_FIRE, var_12_1, function(arg_13_0, arg_13_1)
					if arg_13_0 == xyd.error.OK then
						arg_4_0.nianBoss.boss_brave = arg_13_1.boss_brave
						arg_4_0.nianBoss.boss_id = arg_13_1.boss_id
						arg_4_0.nianBoss.fireNum = arg_13_1.fire_num
						arg_4_0.nianBoss.period = arg_13_1.period

						local var_13_0 = {
							itemID = var_12_0
						}

						var_13_0.itemNum = 1

						arg_4_0.player:getBackpack():removeItem(var_13_0)
						var_4_12:show()
						var_4_12:play(function()
							var_4_12:hide()
						end, false)
						var_4_7:attack(3, nil, nil, handler(arg_4_0, function()
							var_4_7:idle()
							arg_4_0:updateNianWindow()
						end))

						soundFile = xyd.tables.model:getAttack2Sound(arg_4_0.nianBoss.model_id)
					end
				end)
			else
				local var_12_2 = var_0_1:translation("NIAN_HAS_NO_FIRE")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_12_2
				})
			end
		end
	end)
	var_4_2:addTouchEventListener(function(arg_16_0, arg_16_1)
		if arg_16_1 == ccui.TouchEventType.ended and arg_4_0.nianBoss.period == 1 then
			arg_4_0.nianBoss:loadNianBoss(function(arg_17_0)
				if arg_17_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("nian_boss_battle_pre")
				end
			end)
		end
	end)
end

function var_0_0.updateNianWindow(arg_18_0)
	local var_18_0 = arg_18_0.parent:getChildByName("detail"):getChildByName("container")
	local var_18_1 = var_18_0:getChildByName("nian_des")
	local var_18_2 = var_18_0:getChildByName("fire_btn")
	local var_18_3 = var_18_0:getChildByName("fire_txt")
	local var_18_4 = var_18_0:getChildByName("bar_container"):getChildByName("bar")
	local var_18_5 = var_18_0:getChildByName("times")
	local var_18_6 = var_18_5:getChildByName("times_txt")
	local var_18_7 = var_18_5:getChildByName("btn_add")
	local var_18_8 = xyd.tables.misc.fireTotalNum
	local var_18_9 = arg_18_0.nianBoss.challenge_times

	var_18_1:enableOutline(cc.c4b(0, 0, 0, 155), 2)

	local var_18_10 = 50001049
	local var_18_11 = arg_18_0.player:getBackpack():getItemNumByID(var_18_10)

	if var_18_8 > arg_18_0.nianBoss.fireNum and arg_18_0.nianBoss.period == 0 then
		var_18_1:setString(var_0_1:translation("NIAN_DES_STAGE1"))
		var_18_4:setPercent(arg_18_0.nianBoss.fireNum / var_18_8 * 100)
		var_18_2:setVisible(true)
		var_18_3:setVisible(true)
		var_18_5:setVisible(false)

		if var_18_11 > 0 then
			var_18_2:setBright(true)
		else
			var_18_2:setBright(false)
		end
	elseif arg_18_0.nianBoss.period == 1 then
		var_18_1:setString(var_0_1:translation("NIAN_DES_STAGE2"))
		var_18_4:setPercent(arg_18_0.nianBoss.boss_brave / xyd.tables.nianBoss.need_brave[arg_18_0.nianBoss.boss_id] * 100)
		var_18_5:setVisible(true)
		var_18_2:setVisible(false)
		var_18_3:setVisible(false)
		var_18_6:setString(string.format(var_0_1:translation("WORLD_BOSS_LEFT_TIMES"), var_18_9, xyd.tables.misc.newYearChallengeNum))

		if var_18_9 <= 0 then
			var_18_7:setVisible(true)
		else
			var_18_7:setVisible(false)
		end
	end
end

return var_0_0
