local var_0_0 = class("FlappyBirdMainWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpriteNodeButton")
local var_0_2 = xyd.tables.flappyBirdPartner
local var_0_3 = xyd.tables.flappyBirdSkill
local var_0_4 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.flappyBird = xyd.ModelManager.get():loadModel(xyd.ModelType.FLAPPY_BIRD)
	arg_1_0.heroStatus = arg_1_0.flappyBird.baseInfo.status
	arg_1_0.heroIndex = arg_1_0.flappyBird.heroIndex or 1
end

function var_0_0.willOpen(arg_2_0)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:setTexts()
	arg_3_0:setBtns()
	arg_3_0:initHeros()
end

function var_0_0.setTexts(arg_4_0)
	arg_4_0:nodeByName("text_title"):setString(var_0_4:translation("FLAPPY_BIRD_TEXT_1"))
	arg_4_0:nodeByName("text_mission"):setString(var_0_4:translation("FLAPPY_BIRD_TEXT_2"))
	arg_4_0:nodeByName("text_rank"):setString(var_0_4:translation("FLAPPY_BIRD_TEXT_3"))
	arg_4_0:nodeByName("text_score_1"):setString(var_0_4:translation("FLAPPY_BIRD_TEXT_16"))
	arg_4_0:nodeByName("text_score_2"):setString(var_0_4:translation("FLAPPY_BIRD_TEXT_5"))
	arg_4_0:nodeByName("text_start"):setString(var_0_4:translation("FLAPPY_BIRD_TEXT_6"))
	arg_4_0:nodeByName("text_practice"):setString(var_0_4:translation("FLAPPY_BIRD_TEXT_7"))
	arg_4_0:nodeByName("text_left_times"):setString(string.format(var_0_4:translation("FLAPPY_BIRD_TEXT_8"), arg_4_0.flappyBird.baseInfo.challenge_times))
	arg_4_0:nodeByName("text_left_times"):enableOutline(cc.c4b(72, 71, 96, 255), 2)
	arg_4_0:nodeByName("my_score"):setString(arg_4_0.flappyBird.rankInfo.score)
end

function var_0_0.setBtns(arg_5_0)
	local var_5_0 = var_0_1.new({
		sprite = "windows/button/btn_return.png",
		isSound = 0,
		colorModes = xyd.tables.systemColor:btnColors(xyd.ColorMode.BLUE)
	})

	var_5_0:addTo(arg_5_0)
	var_5_0:setAnchorPoint(0.5, 0.5)
	var_5_0:setPosition(44, 697)
	var_5_0:setName("return_btn")

	arg_5_0.returnBtn = var_5_0

	arg_5_0.returnBtn:addTouchEvent(function(arg_6_0)
		if arg_6_0.name == "ended" then
			xyd.playCloseSound()
			xyd.WindowManager.get():closeWindow(arg_5_0)
		end
	end)
	arg_5_0:nodeByName("btn_rule"):addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(arg_7_0, arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_7_0 = {}

			var_7_0.title_name = "FLAPPY_BIRD_RULE_TITLE"
			var_7_0.rule = "FLAPPY_BIRD_RULE_TEXT"
			var_7_0.style = xyd.RuleStyle.YELLOW

			xyd.WindowManager.get():openWindow("flappy_bird_rule", var_7_0)
		end
	end)
	arg_5_0:nodeByName("btn_start"):addTouchEventListener(function(arg_8_0, arg_8_1)
		xyd.buttonScaleAnim(arg_8_0, arg_8_1)

		if arg_8_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_5_0.flappyBird.baseInfo.challenge_times < 1 then
				local var_8_0 = var_0_4:translation("FLAPPY_BIRD_TEXT_17")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_8_0
				})
			else
				local var_8_1 = {
					hero_idx = arg_5_0.heroIndex
				}

				arg_5_0.flappyBird:startGame(var_8_1, function(arg_9_0, arg_9_1)
					if arg_9_0 == xyd.error.OK then
						xyd.EventDispatcher.get():dispatchEvent({
							name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
							params = {
								window = "flappy_bird_main"
							}
						})
						xyd.WindowManager.get():retainHistory()

						local var_9_0 = import("app.scenes.FlappyBirdScene")

						cc.Director:getInstance():pushScene(var_9_0.new({
							isPractice = false,
							heroIndex = arg_5_0.heroIndex
						}))
					end
				end)
			end
		end
	end)
	arg_5_0:nodeByName("btn_practice"):addTouchEventListener(function(arg_10_0, arg_10_1)
		xyd.buttonScaleAnim(arg_10_0, arg_10_1)

		if arg_10_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "flappy_bird_main"
				}
			})
			xyd.WindowManager.get():retainHistory()

			local var_10_0 = import("app.scenes.FlappyBirdScene")

			cc.Director:getInstance():pushScene(var_10_0.new({
				isPractice = true,
				heroIndex = arg_5_0.heroIndex
			}))
		end
	end)
	arg_5_0:nodeByName("btn_mission"):addTouchEventListener(function(arg_11_0, arg_11_1)
		xyd.buttonScaleAnim(arg_11_0, arg_11_1)

		if arg_11_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("flappy_bird_mission")
		end
	end)
	arg_5_0:nodeByName("btn_rank"):addTouchEventListener(function(arg_12_0, arg_12_1)
		xyd.buttonScaleAnim(arg_12_0, arg_12_1)

		if arg_12_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_5_0.flappyBird:getRankList(nil, function(arg_13_0, arg_13_1)
				if arg_13_0 == xyd.error.OK then
					local var_13_0 = {
						rank_info = arg_13_1,
						self_info = arg_5_0.flappyBird.rankInfo
					}

					xyd.WindowManager.get():openWindow("flappy_bird_rank", {
						data = var_13_0
					})
				end
			end)
		end
	end)
end

function var_0_0.initHeros(arg_14_0)
	local var_14_0 = arg_14_0:nodeByName("list_hero")

	var_14_0:removeAllChildren()

	for iter_14_0 = 1, 4 do
		local var_14_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/flappy_bird/hero_item.csb")
		local var_14_2 = var_14_1:getChildByName("container")

		var_14_2:getChildByName("name"):setString(var_0_2:name(iter_14_0))

		local var_14_3 = var_0_2:avatar(iter_14_0)
		local var_14_4 = xyd.AssetLoader.get():loadSprite(var_14_3)
		local var_14_5 = var_0_2:skill(iter_14_0)
		local var_14_6 = var_0_2:unlockValue(iter_14_0)

		var_14_4:addTo(var_14_2:getChildByName("hero_node"))
		var_14_1:addTo(var_14_0)
		var_14_1:setPosition(0, var_14_0:getHeight() - iter_14_0 * (var_14_2:getHeight() + 20) - 20)
		var_14_1:setName("item_" .. iter_14_0)
		var_14_2:getChildByName("name"):setString(var_0_2:name(iter_14_0))
		var_14_2:getChildByName("skill_name"):setString(var_0_3:name(var_14_5))
		var_14_2:getChildByName("skill_desc"):setString(var_0_3:desc(var_14_5))

		local var_14_7 = var_14_6[1] - arg_14_0.flappyBird.baseInfo.play_times

		if var_14_7 > 0 then
			var_14_2:getChildByName("unlock_desc"):setString(string.format(var_0_2:unlockDesc(iter_14_0), var_14_7))
		else
			var_14_2:getChildByName("unlock_desc"):setString(var_0_4:translation("CHOCOLATE_CAMPAIGN_TIP2"))
		end

		var_14_2:getChildByName("name"):setColor(cc.c3b(59, 75, 127))
		var_14_2:getChildByName("skill_name"):setColor(cc.c3b(59, 75, 127))

		local var_14_8 = xyd.AssetLoader.get():loadSprite(var_0_3:icon(var_14_5))

		xyd.displaySpriteOnContainer(var_14_8, var_14_2:getChildByName("skill_icon"))
		var_14_8:setScale(var_14_8:getScale() * 0.9)

		local var_14_9 = xyd.getBorder(nil, nil, true)

		xyd.displaySpriteOnContainer(var_14_9, var_14_2:getChildByName("skill_icon"))
		var_14_2:setTouchEnabled(true)
		var_14_2:addTouchEventListener(function(arg_15_0, arg_15_1)
			if arg_15_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				if arg_14_0.heroStatus[iter_14_0] == 1 then
					arg_14_0:updateHeroSelect(iter_14_0)
				elseif arg_14_0.flappyBird.baseInfo.play_times >= var_14_6[1] then
					local var_15_0 = {
						hero_idx = iter_14_0
					}

					arg_14_0.flappyBird:unlockHero(var_15_0, function(arg_16_0, arg_16_1)
						if arg_16_0 == xyd.error.OK then
							arg_14_0.heroStatus = arg_14_0.flappyBird.baseInfo.status

							arg_14_0:initHeros()
						end
					end)
				else
					local function var_15_1()
						if arg_14_0.selfPlayer.crystal < var_14_6[2] then
							local var_17_0 = {
								title = var_0_4:translation("TIP"),
								align = xyd.ui_align.CENTER
							}

							xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
								var_0_4:translation("ZUANSHI_ABSENCE")
							}, function()
								local var_18_0 = {}

								var_18_0.windowState = true
								var_18_0.chargeState = xyd.ChargeState.diamond

								xyd.WindowManager.get():closeWindow(arg_14_0.name)
								xyd.WindowManager.get():openWindow("vip_recharge", var_18_0)
							end, var_17_0, nil, xyd.ColorMode.ACTIVITY)
						else
							local var_17_1 = {
								hero_idx = iter_14_0
							}

							arg_14_0.flappyBird:unlockHero(var_17_1, function(arg_19_0, arg_19_1)
								if arg_19_0 == xyd.error.OK then
									arg_14_0.heroStatus = arg_14_0.flappyBird.baseInfo.status

									arg_14_0:initHeros()
								end
							end)
						end
					end

					local var_15_2 = {
						rcallBefore = 0,
						txt = string.format(var_0_4:translation("FLAPPY_BIRD_TEXT_12"), var_14_6[2]),
						rcallback = var_15_1,
						align = xyd.ui_align.CENTER
					}

					xyd.WindowManager.get():openWindow("common_alert", var_15_2)
				end
			end
		end)

		if arg_14_0.heroStatus[iter_14_0] ~= 1 then
			var_14_2:getChildByName("shadow"):setVisible(true)
			var_14_2:getChildByName("lock"):setVisible(true)
			var_14_2:getChildByName("unlock_desc"):setVisible(true)
			var_14_2:getChildByName("skill_name"):setVisible(false)
			var_14_2:getChildByName("skill_desc"):setVisible(false)
			var_14_2:getChildByName("skill_icon"):setVisible(false)
		end
	end

	arg_14_0:updateHeroSelect(arg_14_0.heroIndex)
end

function var_0_0.updateHeroSelect(arg_20_0, arg_20_1)
	arg_20_0.flappyBird.heroIndex = arg_20_1

	local var_20_0 = arg_20_0:nodeByName("list_hero")
	local var_20_1 = var_20_0:getChildByName("item_" .. arg_20_0.heroIndex)

	if var_20_1 then
		local var_20_2 = var_20_1:getChildByName("container")

		var_20_2:getChildByName("bg_hero_choose"):setVisible(false)
		var_20_2:getChildByName("name"):setColor(cc.c3b(59, 75, 127))
		var_20_2:getChildByName("skill_name"):setColor(cc.c3b(59, 75, 127))
	end

	arg_20_0.heroIndex = arg_20_1

	local var_20_3 = var_20_0:getChildByName("item_" .. arg_20_0.heroIndex):getChildByName("container")

	var_20_3:getChildByName("bg_hero_choose"):setVisible(true)
	var_20_3:getChildByName("name"):setColor(cc.c3b(160, 92, 55))
	var_20_3:getChildByName("skill_name"):setColor(cc.c3b(160, 92, 55))
	arg_20_0:nodeByName("node_hero"):removeAllChildren()

	local var_20_4 = var_0_2:model(arg_20_0.heroIndex)
	local var_20_5 = xyd.createEffect(var_20_4)

	var_20_5:addTo(arg_20_0:nodeByName("node_hero"))
	var_20_5:play(nil, true, nil, "fly")
	var_20_5:setName("effect")
end

return var_0_0
