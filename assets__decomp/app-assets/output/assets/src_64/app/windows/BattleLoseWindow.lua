local var_0_0 = class("BattleLoseWindow", import("app.common.ui.BaseWindow"))
local var_0_1
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = xyd.tables.translation
local var_0_4 = {
	xyd.FunctionID.ID_HERO,
	xyd.FunctionID.ID_HERO,
	xyd.FunctionID.ID_SUMMON,
	xyd.FunctionID.ID_PET,
	xyd.FunctionID.ID_PRACTICE,
	xyd.FunctionID.ID_FUMO
}
local var_0_5 = {
	"girls_up",
	"skill_up",
	"summon_girls",
	"pet_up",
	"practice_girls",
	"fumo"
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.fighterA = arg_1_2.fighterA
	arg_1_0.fighterB = arg_1_2.fighterB
	arg_1_0.petA = arg_1_2.petA
	arg_1_0.petB = arg_1_2.petB
	arg_1_0.isTimeOut = arg_1_2.is_timeout
	arg_1_0.campaignType = arg_1_2.campaignType
	arg_1_0.campaignID = arg_1_2.campaignID
	arg_1_0.allParams = arg_1_2.allParams
end

function var_0_0.didOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayerWithNoTouchEvent(cc.c4b(0, 0, 0, 150))
	arg_2_0:playGuide()
end

function var_0_0.playGuide(arg_3_0, arg_3_1)
	if xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_PET_TWO then
		local var_3_0 = arg_3_0:nodeByName("btn_return")
		local var_3_1 = var_3_0:getPositionX()
		local var_3_2 = var_3_0:getPositionY()

		xyd.WindowManager.get():closeWindow("guide")
		xyd.WindowManager.get():openWindow("guide")

		local var_3_3 = xyd.WindowManager.get():getWindow("guide")
		local var_3_4 = var_3_3:convertToNodeSpace(var_3_0:getParent():convertToWorldSpace(cc.p(var_3_1, var_3_2)))

		var_3_3:addNode()
		var_3_3:setStencil(var_3_0:getContentSize().width, var_3_0:getContentSize().height, var_3_4.x, var_3_4.y, 0)
	end
end

function var_0_0.willClose(arg_4_0, arg_4_1)
	if arg_4_0.effect_ then
		arg_4_0.effect_:clearTracks()
		arg_4_0.effect_:removeSelf()
	end
end

function var_0_0.didClose(arg_5_0, arg_5_1)
	return
end

function var_0_0.backgroundAction(arg_6_0)
	arg_6_0:nodeByName("back"):setVisible(true)
	arg_6_0:nodeByName("back"):setScaleX(0)
	arg_6_0:nodeByName("back"):runAction(cc.ScaleTo:create(0.2, 1, 1))
	arg_6_0:nodeByName("back_up"):runAction(cc.Sequence:create({
		cc.MoveBy:create(0, cc.p(-1080, 0)),
		cc.CallFunc:create(function()
			arg_6_0:nodeByName("back_up"):setVisible(true)
		end),
		cc.MoveBy:create(0.2, cc.p(1080, 0))
	}))
	arg_6_0:nodeByName("back_down"):runAction(cc.Sequence:create({
		cc.MoveBy:create(0, cc.p(1080, 0)),
		cc.CallFunc:create(function()
			arg_6_0:nodeByName("back_down"):setVisible(true)
		end),
		cc.MoveBy:create(0.2, cc.p(-1080, 0))
	}))
end

function var_0_0.layout(arg_9_0)
	arg_9_0.clipper = display.newClippingRectangleNode(cc.rect(0, 583, 1280, 137))

	arg_9_0.clipper:addTo(arg_9_0:nodeByName("effect_layer"))

	arg_9_0.lightEffect = xyd.createEffect("skeletons/ui_effect/battle_end/lose_light")

	arg_9_0.lightEffect:addTo(arg_9_0.clipper)
	arg_9_0.lightEffect:play(function()
		arg_9_0.lightEffect:play(nil, true, nil, "texiao02")
	end, nil, nil, "texiao01")
	arg_9_0.lightEffect:pos(640, 473)

	arg_9_0.smallStarEffect = xyd.createEffect("skeletons/ui_effect/battle_end/lose_star")

	arg_9_0.smallStarEffect:addTo(arg_9_0:nodeByName("star_layer"))
	arg_9_0.smallStarEffect:pos(640, 360)
	arg_9_0:backgroundAction()

	if arg_9_0.isTimeOut then
		arg_9_0.smallStarEffect:play(function()
			arg_9_0:nodeByName("time_over"):setLocalZOrder(10)
		end, nil, nil, "texiao02")
	else
		arg_9_0.smallStarEffect:play(function()
			arg_9_0:nodeByName("battle_lose"):setLocalZOrder(10)
		end, nil, nil, "texiao01")
	end

	arg_9_0:getReturnButton()
	arg_9_0:getDataButton()
	arg_9_0:getReplayButton()

	if arg_9_0.campaignType == xyd.CampaignType.SUPER_ARENA then
		arg_9_0.peakArena = xyd.ModelManager.get():loadModel(xyd.ModelType.PEAK_ARENA)

		local var_9_0 = arg_9_0.peakArena:getBattleResult()

		for iter_9_0, iter_9_1 in ipairs(var_9_0) do
			local var_9_1 = iter_9_1 > 0 and "1" or "2"

			xyd.AssetLoader.get():loadSprite("images/battle/super_arena_" .. var_9_1 .. ".png"):align(display.CENTER, 120 + iter_9_0 * 70, 550):addTo(arg_9_0)
		end
	end

	arg_9_0:addItemEvent()
end

function var_0_0.addItemEvent(arg_13_0)
	local var_13_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	local var_13_1 = arg_13_0:nodeByName("option1")
	local var_13_2 = arg_13_0:nodeByName("option2")

	var_13_1:setTouchEnabled(true)
	var_13_2:setTouchEnabled(true)

	local var_13_3 = {}

	for iter_13_0, iter_13_1 in ipairs(var_0_4) do
		if var_13_0:isFuncOpen(iter_13_1) then
			table.insert(var_13_3, iter_13_0)
		end
	end

	for iter_13_2 = 1, 2 do
		local var_13_4 = math.random(1, #var_13_3)
		local var_13_5 = var_13_3[var_13_4]
		local var_13_6 = "windows/battle/battle_lose/" .. var_0_5[var_13_5] .. ".png"
		local var_13_7

		if iter_13_2 == 1 then
			var_13_7 = var_13_1
		else
			var_13_7 = var_13_2
		end

		xyd.nodeEventSample(var_13_7, nil, function(arg_14_0)
			xyd.playButtonSound()
			arg_13_0:dispatchEvent({
				name = xyd.event.BATTLE_END_BACK_TO_MAIN,
				click_id = var_13_5
			})
		end)
		arg_13_0:nodeByName("img_option" .. iter_13_2):setTexture(var_13_6)
		arg_13_0:nodeByName("txt_option" .. iter_13_2):setString(var_0_3:translation("DEFEAT_TEXT_HEADLINE" .. var_13_5))
		arg_13_0:nodeByName("txt_desc" .. iter_13_2):setString(var_0_3:translation("DEFEAT_TEXT_EXPLAIN" .. var_13_5))
		arg_13_0:nodeByName("txt_hit" .. iter_13_2):setString(var_0_3:translation("DEFEAT_TEXT_BUTTON"))
		table.remove(var_13_3, var_13_4)
	end

	arg_13_0:nodeByName("txt_hint"):setString(var_0_3:translation("DEFEAT_TEXT_TOP"))
	var_13_1:runAction(cc.Sequence:create({
		cc.MoveBy:create(0, cc.p(-735, 0)),
		cc.DelayTime:create(0.2),
		cc.CallFunc:create(function()
			var_13_1:setVisible(true)
		end),
		cc.MoveBy:create(0.1, cc.p(740, 0)),
		cc.MoveBy:create(0.13, cc.p(-10, 0)),
		cc.MoveBy:create(0.33, cc.p(5, 0))
	}))
	var_13_2:runAction(cc.Sequence:create({
		cc.MoveBy:create(0, cc.p(735, 0)),
		cc.DelayTime:create(0.2),
		cc.CallFunc:create(function()
			var_13_2:setVisible(true)
		end),
		cc.MoveBy:create(0.1, cc.p(-740, 0)),
		cc.MoveBy:create(0.13, cc.p(10, 0)),
		cc.MoveBy:create(0.33, cc.p(-5, 0))
	}))
	arg_13_0:nodeByName("word_back"):runAction(cc.Sequence:create({
		cc.DelayTime:create(0.53),
		cc.CallFunc:create(function()
			arg_13_0:nodeByName("word_back"):setVisible(true)
			arg_13_0:nodeByName("word_back"):setOpacity(0)
		end),
		cc.FadeIn:create(0.13)
	}))
end

function var_0_0.getLoseTittle(arg_18_0)
	local var_18_0 = arg_18_0:nodeByName("battle_lose"):getChildByName("1")

	var_18_0:runAction(cc.Sequence:create({
		cc.DelayTime:create(0.23),
		cc.MoveBy:create(0, cc.p(0, 177)),
		cc.CallFunc:create(function()
			var_18_0:setVisible(true)
		end),
		cc.Spawn:create({
			cc.RotateBy:create(0.33, -24),
			cc.MoveBy:create(0.33, cc.p(0, -180))
		}),
		cc.Spawn:create({
			cc.RotateBy:create(0.16, 2),
			cc.MoveBy:create(0.16, cc.p(0, 6))
		}),
		cc.MoveBy:create(0.2, cc.p(0, -3))
	}))

	local var_18_1 = arg_18_0:nodeByName("battle_lose"):getChildByName("2")

	var_18_1:runAction(cc.Sequence:create({
		cc.DelayTime:create(0.23),
		cc.MoveBy:create(0, cc.p(0, 177)),
		cc.CallFunc:create(function()
			var_18_1:setVisible(true)
		end),
		cc.Spawn:create({
			cc.RotateBy:create(0.33, 9),
			cc.MoveBy:create(0.33, cc.p(0, -180))
		}),
		cc.Spawn:create({
			cc.RotateBy:create(0.2, 14),
			cc.MoveBy:create(0.2, cc.p(0, 6))
		}),
		cc.Spawn:create({
			cc.RotateBy:create(0.23, 38),
			cc.MoveBy:create(0.23, cc.p(29, -24))
		}),
		cc.Spawn:create({
			cc.RotateBy:create(0.13, 8),
			cc.MoveBy:create(0.13, cc.p(8, -12))
		}),
		cc.MoveBy:create(0.06, cc.p(0, 2)),
		cc.MoveBy:create(0.16, cc.p(0, -2))
	}))
end

function var_0_0.getOverTimeTittle(arg_21_0)
	local var_21_0 = arg_21_0:nodeByName("time_over"):getChildByName("1")

	var_21_0:runAction(cc.Sequence:create({
		cc.MoveBy:create(0, cc.p(0, 172)),
		cc.DelayTime:create(0.16),
		cc.CallFunc:create(function()
			var_21_0:setVisible(true)
		end),
		cc.MoveBy:create(0.33, cc.p(0, -175)),
		cc.MoveBy:create(0.16, cc.p(0, 6)),
		cc.Spawn:create({
			cc.MoveBy:create(0.2, cc.p(0, -6)),
			cc.RotateBy:create(0.2, -9)
		}),
		cc.MoveBy:create(0.03, cc.p(0, -3))
	}))

	for iter_21_0 = 2, 3 do
		local var_21_1 = arg_21_0:nodeByName("time_over"):getChildByName(tostring(iter_21_0))

		var_21_1:runAction(cc.Sequence:create({
			cc.MoveBy:create(0, cc.p(0, 172)),
			cc.DelayTime:create(0.23 + (iter_21_0 - 2) * 0.06),
			cc.CallFunc:create(function()
				var_21_1:setVisible(true)
			end),
			cc.MoveBy:create(0.33, cc.p(0, -175)),
			cc.MoveBy:create(0.16, cc.p(0, 6)),
			cc.MoveBy:create(0.2, cc.p(0, -3))
		}))
	end

	local var_21_2 = arg_21_0:nodeByName("time_over"):getChildByName("4")

	var_21_2:runAction(cc.Sequence:create({
		cc.MoveBy:create(0, cc.p(0, 172)),
		cc.DelayTime:create(0.33),
		cc.CallFunc:create(function()
			var_21_2:setVisible(true)
		end),
		cc.Spawn:create({
			cc.RotateBy:create(0.33, 9),
			cc.MoveBy:create(0.33, cc.p(0, -175))
		}),
		cc.Spawn:create({
			cc.RotateBy:create(0.2, 9),
			cc.MoveBy:create(0.2, cc.p(0, 16))
		}),
		cc.Spawn:create({
			cc.RotateBy:create(0.23, 42),
			cc.MoveBy:create(0.23, cc.p(29, -26))
		}),
		cc.Spawn:create({
			cc.RotateBy:create(0.13, 8),
			cc.MoveBy:create(0.13, cc.p(9, -9))
		}),
		cc.MoveBy:create(0.06, cc.p(0, 6)),
		cc.MoveBy:create(0.16, cc.p(0, -6))
	}))
end

function var_0_0.getReturnButton(arg_25_0)
	arg_25_0.returnBtn_ = arg_25_0:nodeByName("btn_return")

	xyd.nodeEventSample(arg_25_0.returnBtn_, nil, function(arg_26_0)
		xyd.playButtonSound()
		arg_25_0:clickReturnButton()
	end)
	arg_25_0.returnBtn_:setTouchEnabled(false)
	arg_25_0.returnBtn_:runAction(cc.Sequence:create({
		cc.DelayTime:create(1.23),
		cc.CallFunc:create(function()
			arg_25_0.returnBtn_:setVisible(true)
			arg_25_0.returnBtn_:setOpacity(0)
		end),
		cc.FadeIn:create(0.2),
		cc.CallFunc:create(function()
			arg_25_0.returnBtn_:setTouchEnabled(true)
		end)
	}))
end

function var_0_0.clickReturnButton(arg_29_0)
	arg_29_0:dispatchEvent({
		name = xyd.event.BATTLE_END_BACK_TO_MAIN
	})
end

function var_0_0.getDataButton(arg_30_0)
	if arg_30_0.campaignType == xyd.CampaignType.SNOW then
		return
	end

	arg_30_0.dataBtn_ = arg_30_0:nodeByName("btn_data")

	xyd.nodeEventSample(arg_30_0.dataBtn_, nil, function(arg_31_0)
		xyd.playButtonSound()
		xyd.WindowManager.get():openWindow(xyd.WindowName.battleResultDataWnd, {
			herosA = arg_30_0.fighterA,
			herosB = arg_30_0.fighterB,
			petA = arg_30_0.petA,
			petB = arg_30_0.petB,
			campaignID = arg_30_0.campaignID,
			campaignType = arg_30_0.campaignType
		})
	end)
	arg_30_0.dataBtn_:setTouchEnabled(false)
	arg_30_0.dataBtn_:runAction(cc.Sequence:create({
		cc.DelayTime:create(1.23),
		cc.CallFunc:create(function()
			arg_30_0.dataBtn_:setVisible(true)
			arg_30_0.dataBtn_:setOpacity(0)
		end),
		cc.FadeIn:create(0.2),
		cc.CallFunc:create(function()
			arg_30_0.dataBtn_:setTouchEnabled(true)
		end)
	}))
end

function var_0_0.getReplayButton(arg_34_0)
	if not arg_34_0.allParams or arg_34_0.allParams.peak_fight_first or arg_34_0.allParams.campaignType == xyd.CampaignType.REGION_CASUAL or arg_34_0.campaignType == xyd.CampaignType.SNOW then
		return
	end

	if not arg_34_0.allParams.battleType or arg_34_0.allParams.battleType ~= xyd.BattleType.ReplayReport then
		return
	end

	arg_34_0.replayBtn_ = arg_34_0:nodeByName("btn_replay")

	xyd.nodeEventSample(arg_34_0.replayBtn_, nil, function(arg_35_0)
		xyd.playButtonSound()

		local var_35_0 = arg_34_0.allParams

		if arg_34_0.allParams.campaignType ~= xyd.CampaignType.FRIEND_FIGHT then
			arg_34_0:dispatchEvent({
				name = xyd.event.BATTLE_END_BACK_TO_MAIN
			})
		else
			arg_34_0:dispatchEvent({
				name = xyd.event.BATTLE_END_WATCH_REGION_REPLAY
			})
		end

		xyd.pushBattleScene(var_35_0)
	end)
	arg_34_0.replayBtn_:setTouchEnabled(false)
	arg_34_0.replayBtn_:runAction(cc.Sequence:create({
		cc.DelayTime:create(1.23),
		cc.CallFunc:create(function()
			arg_34_0.replayBtn_:setVisible(true)
			arg_34_0.replayBtn_:setOpacity(0)
		end),
		cc.FadeIn:create(0.2),
		cc.CallFunc:create(function()
			arg_34_0.replayBtn_:setTouchEnabled(true)
		end)
	}))
end

return var_0_0
