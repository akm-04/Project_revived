local var_0_0 = class("SummonWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.WindowName.summonWnd
local var_0_2 = require("framework.scheduler")
local var_0_3 = xyd.tables.translation
local var_0_4 = import("app.common.ui.SpineEffect")
local var_0_5 = xyd.tables.item
local var_0_6 = xyd.tables.summon
local var_0_7 = xyd.tables.skinDynamic
local var_0_8 = xyd.tables.model
local var_0_9 = xyd.tables.hero
local var_0_10 = "skeletons/ui_effect/summon_click/summon_click"
local var_0_11 = 50001046
local var_0_12 = 50001047
local var_0_13 = 50001024
local var_0_14 = 50001039
local var_0_15 = {
	SMALL = 2,
	SX = 4,
	MIDDLE = 3,
	MAIN = 1,
	MAGIC = 5
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.haschanged = false
	arg_1_0.isAnimation = false
	arg_1_0.wndState = var_0_15.MAIN
	arg_1_0.nextWndState = var_0_15.MAIN
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.vip = arg_1_0.selfPlayer.vip
	arg_1_0.freeTimes = arg_1_0.selfPlayer:getFreeManaNum()
	arg_1_0.timeCount1 = arg_1_0.selfPlayer:getNextFreeManaSummonTime()
	arg_1_0.timeCount2 = arg_1_0.selfPlayer:getNextFreeCrystalSummonTime()
	arg_1_0.summonStoneIndex = xyd.SummonType.StoneOne
	arg_1_0.sxSelected = 1
	arg_1_0.weekHots, arg_1_0.dayHots, arg_1_0.manaID, arg_1_0.petID, arg_1_0.middlePartnerID, arg_1_0.heroId = arg_1_0.selfPlayer:getHotSummonStone()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addAssetWnd()
	arg_2_0:layout()
	arg_2_0:onTimer()

	arg_2_0.handler = var_0_2.scheduleGlobal(handler(arg_2_0, arg_2_0.onTimer), 1)

	arg_2_0:setIDBeforeGuideWnd()
	arg_2_0:playGuide()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	arg_3_0:enterWndAction()
end

function var_0_0.onTimer(arg_4_0)
	arg_4_0.timeCount1 = arg_4_0.selfPlayer:getNextFreeManaSummonTime()
	arg_4_0.timeCount2 = arg_4_0.selfPlayer:getNextFreeCrystalSummonTime()
	arg_4_0.freeTimes = arg_4_0.selfPlayer:getFreeManaNum()

	arg_4_0:setPrice()

	local var_4_0 = false
	local var_4_1 = xyd.WindowManager.get():getWindow("main_scene_middle")

	if var_4_1 then
		var_4_0 = var_4_1.redMarks[xyd.RedMarks.SUMMON]:isVisible()
	else
		var_4_0 = true
	end

	if (arg_4_0.timeCount1 == 0 and arg_4_0.selfPlayer:getFreeManaNum() > 0 or arg_4_0.timeCount2 == 0) and not var_4_0 then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.CHECK_MIDDLE_RED_MARK,
			params = xyd.CheckMiddleRed.SUMMON
		})
	end
end

function var_0_0.layout(arg_5_0)
	arg_5_0.wndChangeAction = {}
	arg_5_0.wndChangeAction[12] = arg_5_0.wndMainToSmall
	arg_5_0.wndChangeAction[13] = arg_5_0.wndMainToMiddle
	arg_5_0.wndChangeAction[14] = arg_5_0.wndMainToSX
	arg_5_0.wndChangeAction[15] = arg_5_0.wndMainToMagic
	arg_5_0.wndChangeAction[21] = arg_5_0.wndSmallToMain
	arg_5_0.wndChangeAction[31] = arg_5_0.wndMiddleToMain
	arg_5_0.wndChangeAction[41] = arg_5_0.wndSXToMain
	arg_5_0.wndChangeAction[51] = arg_5_0.wndMagicToMain

	arg_5_0:nodeByName("top_container"):getChildByName("title_txt"):setString(var_0_3:translation("SUMMON_WND_TITLE1"))

	if arg_5_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_MAGIC_GACHA) then
		arg_5_0:nodeByName("machine4"):setVisible(true)
		arg_5_0:nodeByName("machine5"):setVisible(false)
	else
		arg_5_0:nodeByName("machine4"):setVisible(false)
		arg_5_0:nodeByName("machine5"):setVisible(true)
	end

	arg_5_0:nodeByName("return"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended and not arg_5_0.isAnimation then
			local var_6_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_6_0, false)

			if xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_SUMMON_END then
				arg_5_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_BACK1)
			end

			arg_5_0.haschanged = false

			if arg_5_0.wndState > 1 then
				arg_5_0.nextWndState = var_0_15.MAIN

				arg_5_0:changeWndState()
			else
				xyd.WindowManager.get():closeWindow(arg_5_0)
			end
		end
	end)
	arg_5_0:smallMachineSetUp()
	arg_5_0:middleMachineSetUp()
	arg_5_0:sxMachineSetUp()
	arg_5_0:magicMachineSetUp()
end

function var_0_0.addAssetWnd(arg_7_0, arg_7_1, arg_7_2)
	xyd.WindowManager.get():openWindow("asset_wnd")

	local var_7_0 = xyd.WindowManager.get():getWindow("asset_wnd")

	if arg_7_1 and arg_7_2 then
		local var_7_1, var_7_2 = var_7_0:getPosition()

		var_7_0:pos(var_7_1 + arg_7_1, var_7_2 + arg_7_2)
	end
end

function var_0_0.enterWndAction(arg_8_0)
	arg_8_0.isAnimation = true

	arg_8_0:nodeByName("top_container"):runAction(cc.Sequence:create({
		cc.MoveBy:create(0, cc.p(0, 52)),
		cc.MoveBy:create(0.3, cc.p(0, -52)),
		cc.CallFunc:create(function()
			arg_8_0.isAnimation = false
		end)
	}))
	xyd.WindowManager.get():getWindow("asset_wnd"):runAction(cc.Sequence:create({
		cc.MoveBy:create(0, cc.p(0, 52)),
		cc.MoveBy:create(0.3, cc.p(0, -52)),
		cc.CallFunc:create(function()
			return
		end)
	}))
end

function var_0_0.changeWndState(arg_11_0)
	if arg_11_0.wndState == arg_11_0.nextWndState then
		return
	end

	if arg_11_0.nextWndState > 1 and arg_11_0.wndState > 1 then
		return
	end

	arg_11_0.wndChangeAction[arg_11_0.wndState * 10 + arg_11_0.nextWndState](arg_11_0)

	arg_11_0.wndState = arg_11_0.nextWndState
end

function var_0_0.wndMainToSmall(arg_12_0)
	arg_12_0.isAnimation = true

	arg_12_0:grayOtherMachines(1)
	arg_12_0:runAction(cc.Sequence:create({
		cc.Spawn:create({
			cc.CallFunc:create(function()
				arg_12_0.clickEffect = xyd.createEffect(var_0_10)

				arg_12_0.clickEffect:addTo(arg_12_0:nodeByName("machine1"))
				arg_12_0.clickEffect:play(nil, true, nil, "texiao01")
				arg_12_0.clickEffect:pos(290, 360)
				arg_12_0:nodeByName("title_txt"):runAction(cc.Sequence:create({
					cc.FadeOut:create(1),
					cc.CallFunc:create(function()
						arg_12_0:titleChange("SUMMON_WND_TITLE2")
					end)
				}))
			end),
			cc.DelayTime:create(0.6)
		}),
		cc.Spawn:create({
			cc.CallFunc:create(function()
				arg_12_0.clickEffect:removeSelf()

				local var_15_0 = arg_12_0:nodeByName("machine_detail1")

				var_15_0:setVisible(true)
				var_15_0:getChildByName("talk_container"):setVisible(false)
				var_15_0:getChildByName("detail"):setOpacity(0)
				var_15_0:getChildByName("detail"):runAction(cc.Sequence:create({
					cc.MoveBy:create(0, cc.p(90, 0)),
					cc.Spawn:create({
						cc.FadeIn:create(0.18),
						cc.MoveBy:create(0.18, cc.p(-90, 0))
					})
				}))
				var_15_0:getChildByName("npc_pos"):setVisible(false)
				var_15_0:getChildByName("npc_pos"):runAction(cc.Sequence:create({
					cc.MoveBy:create(0, cc.p(-90, 0)),
					cc.CallFunc:create(function()
						var_15_0:getChildByName("npc_pos"):setVisible(true)
						var_15_0:getChildByName("npc_pos"):setOpacity(0)
					end),
					cc.Spawn:create({
						cc.FadeIn:create(0.18),
						cc.MoveBy:create(0.18, cc.p(90, 0))
					})
				}))
			end),
			cc.DelayTime:create(0.4)
		}),
		cc.CallFunc:create(function()
			arg_12_0.isAnimation = false

			arg_12_0:npcSpeak(arg_12_0.manaID, 1)

			if xyd.StoryData.get():getGuideID() <= xyd.GuideStoryType.GUIDE_SUMMON_FREE_TWO then
				arg_12_0:playGuide()
			end
		end)
	}))
end

function var_0_0.wndMainToMiddle(arg_18_0)
	arg_18_0.isAnimation = true

	arg_18_0:grayOtherMachines(2)
	arg_18_0:runAction(cc.Sequence:create({
		cc.Spawn:create({
			cc.CallFunc:create(function()
				arg_18_0.clickEffect = xyd.createEffect(var_0_10)

				arg_18_0.clickEffect:addTo(arg_18_0:nodeByName("machine2"))
				arg_18_0.clickEffect:play(nil, true, nil, "texiao02")
				arg_18_0.clickEffect:pos(60, 360)
				arg_18_0:nodeByName("title_txt"):runAction(cc.Sequence:create({
					cc.FadeOut:create(0.6),
					cc.CallFunc:create(function()
						arg_18_0:titleChange("SUMMON_WND_TITLE3")
					end)
				}))
			end),
			cc.DelayTime:create(0.6)
		}),
		cc.Spawn:create({
			cc.CallFunc:create(function()
				arg_18_0.clickEffect:removeSelf()

				local var_21_0 = arg_18_0:nodeByName("machine_detail2")

				var_21_0:setVisible(true)
				var_21_0:getChildByName("talk_container"):setVisible(false)
				var_21_0:getChildByName("detail"):setOpacity(0)
				var_21_0:getChildByName("detail"):runAction(cc.Sequence:create({
					cc.MoveBy:create(0, cc.p(-90, 0)),
					cc.Spawn:create({
						cc.FadeIn:create(0.18),
						cc.MoveBy:create(0.18, cc.p(90, 0))
					})
				}))
				var_21_0:getChildByName("npc_pos"):setOpacity(0)
				var_21_0:getChildByName("npc_pos"):runAction(cc.Sequence:create({
					cc.MoveBy:create(0, cc.p(90, 0)),
					cc.Spawn:create({
						cc.FadeIn:create(0.18),
						cc.MoveBy:create(0.18, cc.p(-90, 0))
					})
				}))
			end),
			cc.DelayTime:create(0.4)
		}),
		cc.CallFunc:create(function()
			arg_18_0.isAnimation = false

			arg_18_0:npcSpeak(arg_18_0.middlePartnerID, 2)

			if xyd.StoryData.get():getGuideID() <= xyd.GuideStoryType.GUIDE_SUMMON_CRYSTAL_TWO then
				arg_18_0:playGuide()
			end
		end)
	}))
end

function var_0_0.wndMainToSX(arg_23_0)
	arg_23_0.isAnimation = true

	arg_23_0:grayOtherMachines(3)
	arg_23_0:runAction(cc.Sequence:create({
		cc.Spawn:create({
			cc.CallFunc:create(function()
				arg_23_0.clickEffect = xyd.createEffect(var_0_10)

				arg_23_0.clickEffect:addTo(arg_23_0:nodeByName("machine3"))
				arg_23_0.clickEffect:play(nil, true, nil, "texiao04")
				arg_23_0.clickEffect:pos(640, 360)
				arg_23_0:nodeByName("title_txt"):runAction(cc.Sequence:create({
					cc.FadeOut:create(0.6),
					cc.CallFunc:create(function()
						arg_23_0:titleChange("SUMMON_WND_TITLE4")
					end)
				}))
			end),
			cc.DelayTime:create(0.4)
		}),
		cc.Spawn:create({
			cc.CallFunc:create(function()
				arg_23_0.clickEffect:removeSelf()

				local var_26_0 = arg_23_0:nodeByName("machine_detail3")

				var_26_0:setVisible(true)
				var_26_0:getChildByName("talk_container"):setVisible(false)
				var_26_0:getChildByName("detail"):setVisible(true)
				var_26_0:getChildByName("detail"):setScale(0, 0.01)
				var_26_0:getChildByName("detail"):runAction(cc.Sequence:create({
					cc.DelayTime:create(0.03),
					cc.ScaleTo:create(0.15, 1, 0.01),
					cc.DelayTime:create(0.03),
					cc.ScaleTo:create(0.15, 1, 1)
				}))
				var_26_0:getChildByName("npc_pos"):setVisible(true)
				var_26_0:getChildByName("npc_pos"):setOpacity(0)
				var_26_0:getChildByName("npc_pos"):runAction(cc.Sequence:create({
					cc.MoveBy:create(0, cc.p(90, 0)),
					cc.DelayTime:create(0.12),
					cc.Spawn:create({
						cc.FadeIn:create(0.15),
						cc.MoveBy:create(0.15, cc.p(-90, 0))
					})
				}))
			end),
			cc.DelayTime:create(0.6)
		}),
		cc.CallFunc:create(function()
			arg_23_0.isAnimation = false

			arg_23_0:npcSpeak(arg_23_0.weekHots[arg_23_0.sxSelected], 3)
		end)
	}))
end

function var_0_0.wndMainToMagic(arg_28_0)
	arg_28_0.isAnimation = true

	arg_28_0:grayOtherMachines(4)

	local var_28_0 = "skeletons/ui_effect/summon_click/mofaniudanji"

	arg_28_0:runAction(cc.Sequence:create({
		cc.Spawn:create({
			cc.CallFunc:create(function()
				arg_28_0.clickEffect = xyd.createEffect(var_28_0)

				arg_28_0.clickEffect:addTo(arg_28_0:nodeByName("machine4"))
				arg_28_0.clickEffect:play(nil, true, nil, "texiao01")
				arg_28_0.clickEffect:pos(-227, 360)
				arg_28_0:nodeByName("title_txt"):runAction(cc.Sequence:create({
					cc.FadeOut:create(0.6),
					cc.CallFunc:create(function()
						arg_28_0:titleChange("SUMMON_WND_TITLE5")
					end)
				}))
			end),
			cc.DelayTime:create(0.4)
		}),
		cc.Spawn:create({
			cc.CallFunc:create(function()
				arg_28_0.clickEffect:removeSelf()

				local var_31_0 = arg_28_0:nodeByName("machine_detail4")

				var_31_0:setVisible(true)
				var_31_0:getChildByName("talk_container"):setVisible(false)
				var_31_0:getChildByName("detail"):setVisible(true)
				var_31_0:getChildByName("detail"):setScale(0, 0.01)
				var_31_0:getChildByName("detail"):runAction(cc.Sequence:create({
					cc.DelayTime:create(0.03),
					cc.ScaleTo:create(0.15, 1, 0.01),
					cc.DelayTime:create(0.03),
					cc.ScaleTo:create(0.15, 1, 1)
				}))
				var_31_0:getChildByName("npc_pos"):setVisible(true)
				var_31_0:getChildByName("npc_pos"):setOpacity(0)
				var_31_0:getChildByName("npc_pos"):runAction(cc.Sequence:create({
					cc.MoveBy:create(0, cc.p(90, 0)),
					cc.DelayTime:create(0.12),
					cc.Spawn:create({
						cc.FadeIn:create(0.15),
						cc.MoveBy:create(0.15, cc.p(-90, 0))
					})
				}))
			end),
			cc.DelayTime:create(0.6)
		}),
		cc.CallFunc:create(function()
			arg_28_0.isAnimation = false

			if arg_28_0.heroId then
				arg_28_0:npcSpeak(arg_28_0.heroId, 4)
			end
		end)
	}))
end

function var_0_0.wndSmallToMain(arg_33_0)
	arg_33_0.isAnimation = true

	arg_33_0:runAction(cc.Sequence:create({
		cc.CallFunc:create(function()
			arg_33_0:lightOtherMachines(1)
			arg_33_0:titleChange("SUMMON_WND_TITLE1")

			local var_34_0 = arg_33_0:nodeByName("machine_detail1")

			var_34_0:getChildByName("talk_container"):setVisible(false)
			var_34_0:getChildByName("detail"):runAction(cc.Spawn:create({
				cc.FadeOut:create(0.18),
				cc.MoveBy:create(0.18, cc.p(90, 0))
			}))
			var_34_0:getChildByName("npc_pos"):runAction(cc.Spawn:create({
				cc.FadeOut:create(0.18),
				cc.MoveBy:create(0.18, cc.p(-90, 0))
			}))
		end),
		cc.DelayTime:create(0.18),
		cc.CallFunc:create(function()
			arg_33_0.isAnimation = false

			local var_35_0 = arg_33_0:nodeByName("machine_detail1")

			var_35_0:setVisible(false)
			var_35_0:getChildByName("detail"):setOpacity(255)
			var_35_0:getChildByName("detail"):runAction(cc.MoveBy:create(0, cc.p(-90, 0)))
			var_35_0:getChildByName("npc_pos"):setOpacity(255)
			var_35_0:getChildByName("npc_pos"):runAction(cc.MoveBy:create(0, cc.p(90, 0)))

			if xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_SUMMON_CRYSTAL_ONE then
				arg_33_0:playGuide()
			end
		end)
	}))
end

function var_0_0.wndMiddleToMain(arg_36_0)
	arg_36_0.isAnimation = true

	arg_36_0:runAction(cc.Sequence:create({
		cc.CallFunc:create(function()
			arg_36_0:lightOtherMachines(2)
			arg_36_0:titleChange("SUMMON_WND_TITLE1")

			local var_37_0 = arg_36_0:nodeByName("machine_detail2")

			var_37_0:getChildByName("talk_container"):setVisible(false)
			var_37_0:getChildByName("detail"):runAction(cc.Spawn:create({
				cc.FadeOut:create(0.18),
				cc.MoveBy:create(0.18, cc.p(-90, 0))
			}))
			var_37_0:getChildByName("npc_pos"):runAction(cc.Spawn:create({
				cc.FadeOut:create(0.18),
				cc.MoveBy:create(0.18, cc.p(90, 0))
			}))
		end),
		cc.DelayTime:create(0.18),
		cc.CallFunc:create(function()
			arg_36_0.isAnimation = false

			local var_38_0 = arg_36_0:nodeByName("machine_detail2")

			var_38_0:setVisible(false)
			var_38_0:getChildByName("detail"):setOpacity(255)
			var_38_0:getChildByName("detail"):runAction(cc.MoveBy:create(0, cc.p(90, 0)))
			var_38_0:getChildByName("npc_pos"):setOpacity(255)
			var_38_0:getChildByName("npc_pos"):runAction(cc.MoveBy:create(0, cc.p(-90, 0)))

			if xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_SUMMON_END then
				arg_36_0:playGuide()
			end
		end)
	}))
end

function var_0_0.wndSXToMain(arg_39_0)
	arg_39_0.isAnimation = true

	arg_39_0:runAction(cc.Sequence:create({
		cc.CallFunc:create(function()
			arg_39_0:lightOtherMachines(3)
			arg_39_0:titleChange("SUMMON_WND_TITLE1")

			local var_40_0 = arg_39_0:nodeByName("machine_detail3")

			var_40_0:getChildByName("talk_container"):setVisible(false)
			var_40_0:getChildByName("detail"):runAction(cc.Sequence:create({
				cc.ScaleTo:create(0.18, 1, 0)
			}))
			var_40_0:getChildByName("npc_pos"):runAction(cc.Spawn:create({
				cc.FadeOut:create(0.18),
				cc.MoveBy:create(0.18, cc.p(90, 0))
			}))
		end),
		cc.DelayTime:create(0.18),
		cc.CallFunc:create(function()
			arg_39_0.isAnimation = false

			local var_41_0 = arg_39_0:nodeByName("machine_detail3")

			var_41_0:setVisible(false)
			var_41_0:getChildByName("detail"):setOpacity(255)
			var_41_0:getChildByName("detail"):setScale(1, 1)
			var_41_0:getChildByName("npc_pos"):setOpacity(255)
			var_41_0:getChildByName("npc_pos"):runAction(cc.MoveBy:create(0, cc.p(-90, 0)))
		end)
	}))
end

function var_0_0.wndMagicToMain(arg_42_0)
	arg_42_0.isAnimation = true

	arg_42_0:runAction(cc.Sequence:create({
		cc.CallFunc:create(function()
			arg_42_0:lightOtherMachines(4)
			arg_42_0:titleChange("SUMMON_WND_TITLE1")

			local var_43_0 = arg_42_0:nodeByName("machine_detail4")

			var_43_0:getChildByName("talk_container"):setVisible(false)
			var_43_0:getChildByName("detail"):runAction(cc.Sequence:create({
				cc.ScaleTo:create(0.18, 1, 0)
			}))
			var_43_0:getChildByName("npc_pos"):runAction(cc.Spawn:create({
				cc.FadeOut:create(0.18),
				cc.MoveBy:create(0.18, cc.p(90, 0))
			}))
		end),
		cc.DelayTime:create(0.18),
		cc.CallFunc:create(function()
			arg_42_0.isAnimation = false

			local var_44_0 = arg_42_0:nodeByName("machine_detail4")

			var_44_0:setVisible(false)
			var_44_0:getChildByName("detail"):setOpacity(255)
			var_44_0:getChildByName("detail"):setScale(1, 1)
			var_44_0:getChildByName("npc_pos"):setOpacity(255)
			var_44_0:getChildByName("npc_pos"):runAction(cc.MoveBy:create(0, cc.p(-90, 0)))
		end)
	}))
end

function var_0_0.grayOtherMachines(arg_45_0, arg_45_1)
	for iter_45_0 = 1, 5 do
		repeat
			if iter_45_0 == arg_45_1 then
				break
			end

			arg_45_0:nodeByName("machine" .. iter_45_0):runAction(cc.TintBy:create(0.6, -100, -100, -100))
		until true
	end
end

function var_0_0.lightOtherMachines(arg_46_0, arg_46_1)
	for iter_46_0 = 1, 5 do
		repeat
			if iter_46_0 == arg_46_1 then
				break
			end

			local var_46_0 = cc.TintBy:create(0.18, -100, -100, -100)

			arg_46_0:nodeByName("machine" .. iter_46_0):runAction(var_46_0:reverse())
		until true
	end
end

function var_0_0.titleChange(arg_47_0, arg_47_1)
	local var_47_0 = var_0_3:translation(arg_47_1)
	local var_47_1 = ""
	local var_47_2 = string.sub(var_47_0, 1, #var_47_0)
	local var_47_3 = arg_47_0:nodeByName("title_txt")

	var_47_3:setString(var_47_1)
	var_47_3:setOpacity(255)

	if arg_47_0.txtHandler then
		var_0_2.unscheduleGlobal(arg_47_0.txtHandler)
	end

	arg_47_0.txtHandler = var_0_2.scheduleGlobal(function()
		if #var_47_2 > 0 then
			local var_48_0 = string.byte(var_47_2, 1)
			local var_48_1 = var_48_0 > -127 and var_48_0 < 0 and 3 or 1

			if var_48_1 > #var_47_2 then
				var_47_2 = ""
			elseif var_48_1 == #var_47_2 then
				var_47_1 = var_47_1 .. var_47_2
				var_47_2 = ""
			else
				var_47_1 = var_47_1 .. string.sub(var_47_2, 1, var_48_1)
				var_47_2 = string.sub(var_47_2, var_48_1 + 1, #var_47_2)
			end

			var_47_3:setString(var_47_1)
		elseif not tolua.isnull(arg_47_0) then
			var_0_2.unscheduleGlobal(arg_47_0.txtHandler)

			arg_47_0.txtHandler = nil
		end
	end, 0.03)
end

function var_0_0.smallMachineSetUp(arg_49_0)
	arg_49_0:nodeByName("machine1"):setTouchEnabled(true)
	arg_49_0:nodeByName("machine1"):setVisible(true)
	arg_49_0:nodeByName("machine1"):getChildByName("time_txt"):setString(var_0_3:translation("MACHINE_FREE_TXT_AFTER"))
	arg_49_0:nodeByName("machine1"):getChildByName("no_free_time"):setString(var_0_3:translation("SUMMON_MIANFEIYONGWAN"))
	arg_49_0:nodeByName("machine1"):getChildByName("free_txt"):setString(var_0_3:translation("SUMMON_MANA_FREE_LABEL"))

	local var_49_0 = display.newNode()

	var_49_0:size(210, 430)
	var_49_0:pos(125, 335)
	var_49_0:setAnchorPoint(0.5, 0.5)
	var_49_0:addTo(arg_49_0:nodeByName("machine1"))
	var_49_0:setTouchEnabled(true)
	var_49_0:setTouchSwallowEnabled(true)
	var_49_0:setName("touch_node")
	var_49_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_50_0)
		if arg_50_0.name == "ended" and not arg_49_0.isAnimation and arg_49_0.wndState == var_0_15.MAIN then
			arg_49_0.nextWndState = var_0_15.SMALL

			arg_49_0:changeWndState()

			if xyd.StoryData.get():getGuideID() <= xyd.GuideStoryType.GUIDE_SUMMON_FREE_TWO then
				arg_49_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_SUMMON_MANA)

				if xyd.WindowManager.get():isWindowOpen("guide") then
					xyd.WindowManager.get():closeWindow("guide")
				end
			end
		end

		return true
	end)
	arg_49_0:nodeByName("machine_detail1"):setVisible(false)

	local var_49_1 = arg_49_0:nodeByName("machine_detail1"):getChildByName("detail")
	local var_49_2 = var_49_1:getChildByName("hero_container")

	xyd.setAvatarBorder(arg_49_0.manaID, var_49_2:getChildByName("hero"), 1, var_0_9:initialStar(arg_49_0.manaID))
	var_49_2:getChildByName("hero_name"):setString(xyd.tables.hero:name(arg_49_0.manaID))
	var_49_2:getChildByName("hero_name"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	var_49_2:getChildByName("hero_desc"):setString(xyd.tables.hero:getDes(arg_49_0.manaID))
	var_49_1:getChildByName("title"):getChildByName("txt"):setString(var_0_3:translation("SMALL_MACHINE_TIP1"))
	var_49_1:getChildByName("desc"):setString(var_0_3:translation("SUMMON_SEND_ITEM_INFO1"))
	var_49_1:getChildByName("desc"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	var_49_1:getChildByName("desc2"):setString(var_0_3:translation("SUMMON_BUY10_INFO1"))
	var_49_1:getChildByName("desc2"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	var_49_1:getChildByName("time"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	var_49_1:getChildByName("time_des"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	var_49_1:getChildByName("free_time"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	var_49_1:getChildByName("btn_one"):getChildByName("txt"):setString(var_0_3:translation("MACHINE_BUY_ONE"))
	var_49_1:getChildByName("btn_ten"):getChildByName("txt"):setString(var_0_3:translation("MACHINE_BUY_TEN"))
	arg_49_0:goldBuy1Btn()
	arg_49_0:goldBuy10Btn()

	local var_49_3

	if var_0_8:dynamicType(arg_49_0.manaID) > 0 then
		local var_49_4 = var_0_7:path(arg_49_0.manaID)
		local var_49_5 = var_0_7:homeCardScale(arg_49_0.manaID)
		local var_49_6 = var_0_7:pos(arg_49_0.manaID, xyd.SkinDynamicPosType.MAIN_SCENE)

		var_49_3 = xyd.EffectLoader.new(var_49_4, 3, var_49_5, var_49_6)

		var_49_3:setOpacity(50)
	else
		var_49_3 = xyd.SpriteLoader.new(xyd.tables.model:transparentCard(arg_49_0.manaID), nil, nil, xyd.DefaultImageType.HOME_CARD)
	end

	local var_49_7 = xyd.tables.libraryHomeCard:x(arg_49_0.manaID)
	local var_49_8 = xyd.tables.libraryHomeCard:y(arg_49_0.manaID)

	arg_49_0:nodeByName("machine_detail1"):getChildByName("npc_pos"):addChild(var_49_3)
	var_49_3:setPosition(var_49_7, var_49_8)
	var_49_3:setAnchorPoint(0.5, 0)
	var_49_3:setTouchEnabled(true)

	local var_49_9 = xyd.tables.hero:clickDialog(arg_49_0.manaID)
	local var_49_10 = xyd.tables.hero:dialogSounds(arg_49_0.manaID)
	local var_49_11 = xyd.tables.hero:soundTimes(arg_49_0.manaID)
	local var_49_12 = arg_49_0:nodeByName("machine_detail1"):getChildByName("talk_container")

	var_49_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_51_0)
		if arg_51_0.name == "ended" and not arg_49_0.isAnimation then
			arg_49_0:npcSpeak(arg_49_0.manaID, 1)
		end

		return true
	end)
end

function var_0_0.middleMachineSetUp(arg_52_0)
	arg_52_0:nodeByName("machine2"):setTouchEnabled(true)
	arg_52_0:nodeByName("machine2"):setVisible(true)
	arg_52_0:nodeByName("machine2"):getChildByName("time_txt"):setString(var_0_3:translation("MACHINE_FREE_TXT_AFTER"))
	arg_52_0:nodeByName("machine2"):getChildByName("free_txt"):setString(var_0_3:translation("MIDDLE_MACHINE_FREE_TXT"))

	local var_52_0 = display.newNode()

	var_52_0:size(225, 570)
	var_52_0:pos(132.5, 375)
	var_52_0:setAnchorPoint(0.5, 0.5)
	var_52_0:addTo(arg_52_0:nodeByName("machine2"))
	var_52_0:setTouchEnabled(true)
	var_52_0:setTouchSwallowEnabled(true)
	var_52_0:setName("touch_node")
	var_52_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_53_0)
		if arg_53_0.name == "ended" and not arg_52_0.isAnimation and arg_52_0.wndState == var_0_15.MAIN then
			arg_52_0.nextWndState = var_0_15.MIDDLE

			arg_52_0:changeWndState()

			if xyd.StoryData.get():getGuideID() <= xyd.GuideStoryType.GUIDE_SUMMON_CRYSTAL_TWO then
				arg_52_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_SUMMON_CRYSTAL)

				if xyd.WindowManager.get():isWindowOpen("guide") then
					xyd.WindowManager.get():closeWindow("guide")
				end
			end
		end

		return true
	end)
	arg_52_0:nodeByName("machine_detail2"):setVisible(false)

	local var_52_1 = arg_52_0:nodeByName("machine_detail2"):getChildByName("detail")
	local var_52_2 = var_52_1:getChildByName("hero_container")

	xyd.setAvatarBorder(arg_52_0.middlePartnerID, var_52_2:getChildByName("hero"), 1, var_0_9:initialStar(arg_52_0.middlePartnerID))
	var_52_2:getChildByName("hero_name"):setString(xyd.tables.hero:name(arg_52_0.middlePartnerID))
	var_52_2:getChildByName("hero_name"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	var_52_2:getChildByName("hero_desc"):setString(xyd.tables.hero:getDes(arg_52_0.middlePartnerID))
	var_52_1:getChildByName("title"):getChildByName("txt"):setString(var_0_3:translation("MIDDLE_MACHINE_TIP1"))
	var_52_1:getChildByName("desc"):setString(var_0_3:translation("SUMMON_SEND_ITEM_INFO2"))
	var_52_1:getChildByName("desc"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	var_52_1:getChildByName("desc2"):setString(var_0_3:translation("SUMMON_BUY10_INFO2"))
	var_52_1:getChildByName("desc2"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	var_52_1:getChildByName("time"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	var_52_1:getChildByName("time_des"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	var_52_1:getChildByName("free_once"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	var_52_1:getChildByName("btn_one"):getChildByName("txt"):setString(var_0_3:translation("MACHINE_BUY_ONE"))
	var_52_1:getChildByName("btn_ten"):getChildByName("txt"):setString(var_0_3:translation("MACHINE_BUY_TEN"))

	local var_52_3 = var_52_1:getChildByName("hot_pet_container")

	xyd.setAvatarBorder(arg_52_0.petID, var_52_3, 1, 0)

	local var_52_4 = display.newNode()

	var_52_4:setContentSize(var_52_3:getContentSize())
	var_52_4:setAnchorPoint(0, 0)
	var_52_4:pos(0, 0)
	var_52_4:addTo(var_52_3)
	arg_52_0:addTip(arg_52_0.petID, var_52_4)
	var_52_1:getChildByName("shop"):setVisible(false)
	var_52_1:getChildByName("shop"):setTouchEnabled(true)
	var_52_1:getChildByName("shop"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_54_0)
		if arg_52_0.isAnimation then
			return true
		end

		if arg_54_0.name == "began" then
			var_52_1:getChildByName("shop"):setScale(0.9)
		elseif arg_54_0.name == "moved" then
			var_52_1:getChildByName("shop"):setScale(1)
		elseif arg_54_0.name == "ended" then
			xyd.playButtonSound()
			var_52_1:getChildByName("shop"):setScale(1)
			xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP):loadShopList({}, function()
				xyd.WindowManager.get():openWindow("shop", {
					shop_type = xyd.ShopType.SUMMON
				})
			end)
		end

		return true
	end)
	var_52_1:getChildByName("hero_show"):setTouchEnabled(true)
	var_52_1:getChildByName("hero_show"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_56_0)
		if arg_52_0.isAnimation then
			return true
		end

		if arg_56_0.name == "began" then
			var_52_1:getChildByName("hero_show"):setScale(0.9)
		elseif arg_56_0.name == "moved" then
			var_52_1:getChildByName("hero_show"):setScale(1)
		elseif arg_56_0.name == "ended" then
			xyd.playButtonSound()
			var_52_1:getChildByName("hero_show"):setScale(1)
			xyd.WindowManager.get():openWindow("summon_list_show", {
				type = 1,
				id = arg_52_0.middlePartnerID
			})
		end

		return true
	end)
	arg_52_0:crystalBuy1Btn()
	arg_52_0:crystalBuy10Btn()

	local var_52_5

	if var_0_8:dynamicType(arg_52_0.middlePartnerID) > 0 then
		local var_52_6 = var_0_7:path(arg_52_0.middlePartnerID)
		local var_52_7 = var_0_7:homeCardScale(arg_52_0.middlePartnerID)
		local var_52_8 = var_0_7:pos(arg_52_0.middlePartnerID, xyd.SkinDynamicPosType.MAIN_SCENE)

		var_52_5 = xyd.EffectLoader.new(var_52_6, 3, var_52_7, var_52_8)
	else
		var_52_5 = xyd.SpriteLoader.new(xyd.tables.model:transparentCard(arg_52_0.middlePartnerID), nil, nil, xyd.DefaultImageType.HOME_CARD)
	end

	local var_52_9 = xyd.tables.libraryHomeCard:x(arg_52_0.middlePartnerID)
	local var_52_10 = xyd.tables.libraryHomeCard:y(arg_52_0.middlePartnerID)

	arg_52_0:nodeByName("machine_detail2"):getChildByName("npc_pos"):addChild(var_52_5)
	var_52_5:setPosition(var_52_9, var_52_10)
	var_52_5:setAnchorPoint(0.5, 0)
	var_52_5:setTouchEnabled(true)
	var_52_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_57_0)
		if arg_57_0.name == "ended" and not arg_52_0.isAnimation then
			arg_52_0:npcSpeak(arg_52_0.middlePartnerID, 2)
		end

		return true
	end)
end

function var_0_0.sxMachineSetUp(arg_58_0)
	arg_58_0:nodeByName("machine3"):setTouchEnabled(true)
	arg_58_0:nodeByName("machine3"):setVisible(true)

	local var_58_0 = display.newNode()

	var_58_0:size(200, 550)
	var_58_0:pos(185, 305)
	var_58_0:setAnchorPoint(0.5, 0.5)
	var_58_0:addTo(arg_58_0:nodeByName("machine3"))
	var_58_0:setTouchEnabled(true)
	var_58_0:setTouchSwallowEnabled(false)
	var_58_0:setName("touch_node")
	var_58_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_59_0)
		if arg_59_0.name == "ended" and not arg_58_0.isAnimation and arg_58_0.wndState == var_0_15.MAIN then
			arg_58_0.nextWndState = var_0_15.SX

			arg_58_0:changeWndState()
		end

		return true
	end)
	arg_58_0:nodeByName("machine_detail3"):setVisible(false)

	local var_58_1 = arg_58_0:nodeByName("machine_detail3"):getChildByName("detail")

	var_58_1:setVisible(false)
	var_58_1:getChildByName("title1"):getChildByName("txt"):setString(var_0_3:translation("SUMMON_STONE_WEEK_HOT"))
	var_58_1:getChildByName("title2"):getChildByName("txt"):setString(var_0_3:translation("SUMMON_STONE_DAY_HOT"))

	for iter_58_0 = 1, 2 do
		local var_58_2 = arg_58_0:nodeByName("machine3"):getChildByName("hero" .. iter_58_0)
		local var_58_3 = xyd.tables.model:avatar(tonumber(arg_58_0.weekHots[iter_58_0]))
		local var_58_4 = xyd.SpriteLoader.new(var_58_3, nil, nil, xyd.DefaultImageType.SKILL_ICON)

		xyd.displaySpriteOnContainer(var_58_4, var_58_2, true)

		local var_58_5 = var_58_1:getChildByName("hero_container" .. iter_58_0)

		xyd.setAvatarBorder(arg_58_0.weekHots[iter_58_0], var_58_5:getChildByName("hero"), 1, var_0_9:initialStar(arg_58_0.weekHots[iter_58_0]))
		var_58_5:getChildByName("hero_name"):setString(xyd.tables.hero:name(arg_58_0.weekHots[iter_58_0]))
		var_58_5:getChildByName("hero_name"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
		var_58_5:getChildByName("hero_desc"):setString(xyd.tables.hero:getDes(arg_58_0.weekHots[iter_58_0]))
		var_58_5:getChildByName("clip"):setVisible(iter_58_0 == arg_58_0.sxSelected)
		var_58_5:getChildByName("bg"):setVisible(iter_58_0 ~= arg_58_0.sxSelected)

		local var_58_6 = display.newNode()
		local var_58_7 = var_58_5:getContentSize()

		var_58_6:size(var_58_7.width, var_58_7.height)
		var_58_6:setTouchEnabled(true)
		var_58_6:setTouchSwallowEnabled(true)
		var_58_6:setAnchorPoint(0, 0)
		var_58_6:addTo(var_58_5)
		var_58_6:setPosition(0, 0)
		var_58_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_60_0)
			if arg_60_0.name == "ended" and not arg_58_0.isAnimation then
				arg_58_0.summonStoneIndex = iter_58_0

				arg_58_0:changeSelectedSX(iter_58_0)
			end

			return true
		end)
	end

	for iter_58_1 = 1, 3 do
		local var_58_8 = var_58_1:getChildByName("day_hero" .. iter_58_1)

		xyd.setAvatarBorder(arg_58_0.dayHots[iter_58_1], var_58_8, 1, var_0_9:initialStar(arg_58_0.dayHots[iter_58_1]))
		var_58_1:getChildByName("hero_name" .. iter_58_1):setString(xyd.tables.hero:name(arg_58_0.dayHots[iter_58_1]))
		var_58_1:getChildByName("hero_name" .. iter_58_1):enableOutline(cc.c4b(255, 255, 255, 255), 2)

		local var_58_9 = display.newNode()

		var_58_9:setContentSize(var_58_8:getContentSize())
		var_58_9:addTo(var_58_8)
		var_58_9:pos(0, 0)
		var_58_9:setAnchorPoint(0, 0)
		arg_58_0:addTip(arg_58_0.dayHots[iter_58_1], var_58_9)
	end

	arg_58_0.sxEffect = xyd.createEffect(var_0_10)

	arg_58_0.sxEffect:addTo(arg_58_0:nodeByName("machine3"))
	arg_58_0.sxEffect:play(nil, true, nil, "texiao03")
	arg_58_0.sxEffect:pos(640, 360)
	arg_58_0:sxBuy1Btn()

	local var_58_10

	if var_0_8:dynamicType(arg_58_0.weekHots[arg_58_0.sxSelected]) > 0 then
		local var_58_11 = var_0_7:path(arg_58_0.weekHots[arg_58_0.sxSelected])
		local var_58_12 = var_0_7:homeCardScale(arg_58_0.weekHots[arg_58_0.sxSelected])
		local var_58_13 = var_0_7:pos(arg_58_0.middlePartnerID, xyd.SkinDynamicPosType.MAIN_SCENE)

		var_58_10 = xyd.EffectLoader.new(var_58_11, 3, var_58_12, var_58_13)
	else
		var_58_10 = xyd.SpriteLoader.new(xyd.tables.model:transparentCard(arg_58_0.weekHots[arg_58_0.sxSelected]), nil, nil, xyd.DefaultImageType.HOME_CARD)
	end

	local var_58_14 = xyd.tables.libraryHomeCard:x(arg_58_0.weekHots[arg_58_0.sxSelected])
	local var_58_15 = xyd.tables.libraryHomeCard:y(arg_58_0.weekHots[arg_58_0.sxSelected])

	arg_58_0:nodeByName("machine_detail3"):getChildByName("npc_pos"):addChild(var_58_10)
	var_58_10:setPosition(var_58_14, var_58_15)
	var_58_10:setAnchorPoint(0.5, 0)
	var_58_10:setTouchEnabled(true)
	var_58_10:setScale(var_58_10:getScaleX() * 0.9)
	var_58_10:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_61_0)
		if arg_61_0.name == "ended" and not arg_58_0.isAnimation then
			arg_58_0:npcSpeak(arg_58_0.weekHots[arg_58_0.sxSelected], 3)
		end

		return true
	end)
end

function var_0_0.magicMachineSetUp(arg_62_0)
	arg_62_0:nodeByName("machine4"):setTouchEnabled(true)

	local var_62_0 = display.newNode()

	var_62_0:size(400, 600)
	var_62_0:pos(200, 300)
	var_62_0:setAnchorPoint(0.5, 0.5)
	var_62_0:addTo(arg_62_0:nodeByName("machine4"))
	var_62_0:setTouchEnabled(true)
	var_62_0:setTouchSwallowEnabled(false)
	var_62_0:setName("touch_node")
	var_62_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_63_0)
		if arg_63_0.name == "ended" and not arg_62_0.isAnimation and arg_62_0.wndState == var_0_15.MAIN then
			arg_62_0.nextWndState = var_0_15.MAGIC

			arg_62_0:changeWndState()
			xyd.sendGudieBtnClick("touch_node")
		end

		return true
	end)

	local var_62_1 = "skeletons/ui_effect/summon_click/mofaniudanji"

	arg_62_0.magicEffect = xyd.createEffect(var_62_1)

	arg_62_0.magicEffect:addTo(arg_62_0:nodeByName("machine4"))
	arg_62_0.magicEffect:play(nil, true, nil, "texiao02")
	arg_62_0.magicEffect:pos(-227, 360)
	arg_62_0:nodeByName("machine_detail4"):setVisible(false)

	local var_62_2 = var_0_6:crystal(xyd.SummonType.Magic)
	local var_62_3 = var_0_6:crystalTen(xyd.SummonType.Magic)
	local var_62_4 = arg_62_0:nodeByName("machine_detail4"):getChildByName("detail")

	var_62_4:getChildByName("ten_des"):setString(var_0_3:translation("MAGIC_SUMMON_TIP"))
	var_62_4:getChildByName("bg_price1"):getChildByName("buy_amt_1"):setString(var_62_2)
	var_62_4:getChildByName("bg_price10"):getChildByName("buy_amt_10"):setString(var_62_3)
	var_62_4:getChildByName("bg_switch"):getChildByName("txt_switch"):setString(var_0_3:translation("MAGIC_SUMMON_TEXT1"))
	var_62_4:getChildByName("button_buy1"):getChildByName("txt_buy1"):setString(var_0_3:translation("MAGIC_SUMMON_TEXT3"))
	var_62_4:getChildByName("button_buy10"):getChildByName("txt_buy10"):setString(var_0_3:translation("MAGIC_SUMMON_TEXT4"))
	var_62_4:getChildByName("hero_container1"):getChildByName("hero_name"):setVisible(false)
	var_62_4:getChildByName("hero_container1"):getChildByName("hero_desc"):setVisible(false)
	var_62_4:getChildByName("btn_rule"):addTouchEventListener(function(arg_64_0, arg_64_1)
		if arg_64_1 == ccui.TouchEventType.began then
			var_62_4:getChildByName("btn_rule"):setScale(0.9)
		elseif arg_64_1 == ccui.TouchEventType.ended then
			var_62_4:getChildByName("btn_rule"):setScale(1)
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("new_text_rule", {
				title_name = "MAGIC_SUMMON_TEXT2",
				rule = "MAGIC_SUMMON_RULE"
			})
		end
	end)
	var_62_4:getChildByName("switch_btn"):addTouchEventListener(function(arg_65_0, arg_65_1)
		xyd.buttonScaleAnim(arg_65_0, arg_65_1)

		if arg_65_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local function var_65_0(arg_66_0)
				local var_66_0 = {
					partner_id = arg_66_0
				}

				xyd.Backend.get():request(xyd.mid.MAGIC_SUMMON_SWITCH_HERO, var_66_0, function(arg_67_0, arg_67_1)
					if arg_67_0 == xyd.error.OK then
						arg_62_0.heroId = arg_66_0

						arg_62_0:updateHeroIcon()
					end
				end)
			end

			local var_65_1 = {
				callback = var_65_0
			}

			xyd.WindowManager.get():openWindow("magic_summon_switch_hero", var_65_1)
		end
	end)
	var_62_4:getChildByName("button_buy1"):addTouchEventListener(function(arg_68_0, arg_68_1)
		xyd.buttonScaleAnim(arg_68_0, arg_68_1)

		if arg_68_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_62_0:buy(1)
		end
	end)
	var_62_4:getChildByName("button_buy10"):addTouchEventListener(function(arg_69_0, arg_69_1)
		xyd.buttonScaleAnim(arg_69_0, arg_69_1)

		if arg_69_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_62_0:buy(10)
		end
	end)
	arg_62_0:updateHeroIcon()
end

function var_0_0.updateHeroIcon(arg_70_0)
	local var_70_0 = arg_70_0:nodeByName("machine_detail4"):getChildByName("detail")
	local var_70_1 = var_70_0:getChildByName("hero_container1"):getChildByName("middle_up_hero_node")

	var_70_1:removeAllChildren()
	var_70_1:setContentSize(100, 100)
	var_70_1:setAnchorPoint(0.5, 0.5)
	var_70_1:removeAllNodeEventListeners()

	if arg_70_0.heroId and arg_70_0.heroId > 0 then
		local var_70_2 = arg_70_0.selfPlayer:getHeroIgnoreAwaken(arg_70_0.heroId)

		if var_70_2 then
			xyd.setAvatarBorderNewUI(arg_70_0.heroId, var_70_1, var_70_2:getColor(), var_70_2:getStar())
		else
			xyd.setAvatarBorderNewUI(arg_70_0.heroId, var_70_1, 1, 0)
		end

		var_70_0:getChildByName("hero_container1"):getChildByName("hero_name"):setVisible(true)
		var_70_0:getChildByName("hero_container1"):getChildByName("hero_desc"):setVisible(true)
		var_70_0:getChildByName("hero_container1"):getChildByName("hero_tips"):setVisible(false)

		local var_70_3 = xyd.tables.hero:name(arg_70_0.heroId)
		local var_70_4 = xyd.tables.hero:getDes(arg_70_0.heroId)

		var_70_0:getChildByName("hero_container1"):getChildByName("hero_name"):setString(var_70_3)
		var_70_0:getChildByName("hero_container1"):getChildByName("hero_desc"):setString(var_70_4)
		arg_70_0:nodeByName("machine_detail4"):getChildByName("npc_pos"):removeAllChildren()

		local var_70_5

		if var_0_8:dynamicType(arg_70_0.heroId) > 0 then
			local var_70_6 = var_0_7:path(arg_70_0.heroId)
			local var_70_7 = var_0_7:homeCardScale(arg_70_0.heroId)
			local var_70_8 = var_0_7:pos(arg_70_0.heroId, xyd.SkinDynamicPosType.MAIN_SCENE)

			var_70_5 = xyd.EffectLoader.new(var_70_6, 3, var_70_7, var_70_8)
		else
			var_70_5 = xyd.SpriteLoader.new(xyd.tables.model:transparentCard(arg_70_0.heroId), nil, nil, xyd.DefaultImageType.HOME_CARD)
		end

		local var_70_9 = xyd.tables.libraryHomeCard:x(arg_70_0.heroId)
		local var_70_10 = xyd.tables.libraryHomeCard:y(arg_70_0.heroId)

		arg_70_0:nodeByName("machine_detail4"):getChildByName("npc_pos"):addChild(var_70_5)
		var_70_5:setPosition(var_70_9, var_70_10)
		var_70_5:setAnchorPoint(0.5, 0)
		var_70_5:setTouchEnabled(true)
		var_70_5:setScale(var_70_5:getScaleX() * 0.9)
		arg_70_0:npcSpeak(arg_70_0.heroId, 4)
		var_70_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_71_0)
			if arg_71_0.name == "ended" and not arg_70_0.isAnimation then
				arg_70_0:npcSpeak(arg_70_0.heroId, 4)
			end

			return true
		end)
	else
		local var_70_11 = "windows/summon/unknown.png"
		local var_70_12 = xyd.AssetLoader:get():loadSprite(var_70_11)
		local var_70_13 = var_70_12:getContentSize().height

		var_70_12:setScale(100 / var_70_13)
		var_70_1:addChild(var_70_12)
		var_70_12:setPosition(50, 50)
		var_70_12:setAnchorPoint(cc.p(0.5, 0.5))
		var_70_12:setTouchEnabled(true)
		var_70_12:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_72_0)
			if arg_72_0.name == "began" then
				return true
			elseif arg_72_0.name == "ended" then
				xyd.playButtonSound()

				local function var_72_0(arg_73_0)
					local var_73_0 = {
						partner_id = arg_73_0
					}

					xyd.Backend.get():request(xyd.mid.MAGIC_SUMMON_SWITCH_HERO, var_73_0, function(arg_74_0, arg_74_1)
						if arg_74_0 == xyd.error.OK then
							arg_70_0.heroId = arg_73_0

							arg_70_0:updateHeroIcon()
						end
					end)
				end

				local var_72_1 = {
					callback = var_72_0
				}

				xyd.WindowManager.get():openWindow("magic_summon_switch_hero", var_72_1)
			end
		end)
		var_70_0:getChildByName("hero_container1"):getChildByName("hero_tips"):setVisible(true)
		var_70_0:getChildByName("hero_container1"):getChildByName("hero_tips"):setString(var_0_3:translation("MAGIC_SUMMON_TEXT6"))
		var_70_0:getChildByName("hero_container1"):getChildByName("hero_name"):setVisible(false)
		var_70_0:getChildByName("hero_container1"):getChildByName("hero_desc"):setVisible(false)
		arg_70_0:nodeByName("machine_detail4"):getChildByName("npc_pos"):removeAllChildren()
	end

	var_70_1:setTouchEnabled(true)
	var_70_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_75_0)
		if arg_75_0.name == "began" then
			return true
		elseif arg_75_0.name == "ended" then
			xyd.playButtonSound()

			local function var_75_0(arg_76_0)
				local var_76_0 = {
					partner_id = arg_76_0
				}

				xyd.Backend.get():request(xyd.mid.MAGIC_SUMMON_SWITCH_HERO, var_76_0, function(arg_77_0, arg_77_1)
					if arg_77_0 == xyd.error.OK then
						arg_70_0.heroId = arg_76_0

						arg_70_0:updateHeroIcon()
					end
				end)
			end

			local var_75_1 = {
				callback = var_75_0
			}

			xyd.WindowManager.get():openWindow("magic_summon_switch_hero", var_75_1)
		end
	end)
end

function var_0_0.buy(arg_78_0, arg_78_1)
	if not arg_78_0.heroId or arg_78_0.heroId <= 0 then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_3:translation("MAGIC_SUMMON_SELECT_HERO_TIP")
		})

		return
	end

	local var_78_0 = var_0_6:crystal(xyd.SummonType.Magic)

	if arg_78_1 > 1 then
		var_78_0 = var_0_6:crystalTen(xyd.SummonType.Magic)
	end

	if var_78_0 > arg_78_0.selfPlayer.crystal then
		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_3:translation("ZUANSHI_ABSENCE"), function()
			local var_79_0 = {}

			var_79_0.windowState = true

			xyd.WindowManager.get():openWindow("vip_recharge", var_79_0)
		end, nil, nil, xyd.ColorMode.ACTIVITY)

		return
	end

	local var_78_1 = {
		partner_id = arg_78_0.heroId,
		summon_time = arg_78_1
	}

	arg_78_0.selfPlayer:magicSummonHero(var_78_1, function(arg_80_0, arg_80_1)
		if arg_80_0 == xyd.error.OK then
			local var_80_0 = var_78_1
			local var_80_1 = {}
			local var_80_2 = {}

			for iter_80_0, iter_80_1 in pairs(arg_80_1.result) do
				if tonumber(iter_80_0) then
					table.insert(var_80_2, iter_80_1)
				end
			end

			var_80_1.items = var_80_2
			var_80_1.times = arg_78_1
			var_80_1.summonParams = var_80_0
			var_80_1.stick_items = arg_80_1.stick_items

			xyd.WindowManager.get():openWindow("magic_summon_result", var_80_1)
		end
	end)
end

function var_0_0.npcSpeak(arg_81_0, arg_81_1, arg_81_2)
	local var_81_0 = xyd.tables.hero:clickDialog(arg_81_1)
	local var_81_1 = xyd.tables.hero:dialogSounds(arg_81_1)
	local var_81_2 = xyd.tables.hero:soundTimes(arg_81_1)
	local var_81_3 = arg_81_0:nodeByName("machine_detail" .. arg_81_2):getChildByName("talk_container")

	arg_81_0.selfPlayer:playHeroSound(var_81_1[1], var_81_2[1], function()
		if arg_81_0 and not tolua.isnull(arg_81_0) then
			var_81_3:setVisible(false)
		end
	end)
	var_81_3:getChildByName("content"):setString(var_81_0[1])
	var_81_3:setVisible(true)
end

function var_0_0.hideTalkContainer(arg_83_0)
	for iter_83_0 = 1, 3 do
		arg_83_0:nodeByName("machine_detail" .. iter_83_0):getChildByName("talk_container"):setVisible(false)
	end
end

function var_0_0.changeSelectedSX(arg_84_0, arg_84_1)
	if arg_84_1 == arg_84_0.sxSelected then
		return
	end

	arg_84_0.sxSelected = arg_84_1

	local var_84_0 = arg_84_0:nodeByName("machine_detail3"):getChildByName("detail")

	for iter_84_0 = 1, 2 do
		local var_84_1 = var_84_0:getChildByName("hero_container" .. iter_84_0)

		var_84_1:getChildByName("clip"):setVisible(iter_84_0 == arg_84_1)
		var_84_1:getChildByName("bg"):setVisible(iter_84_0 ~= arg_84_1)
	end

	arg_84_0:nodeByName("machine_detail3"):getChildByName("npc_pos"):removeAllChildren()

	local var_84_2

	if var_0_8:dynamicType(arg_84_0.weekHots[arg_84_0.sxSelected]) > 0 then
		local var_84_3 = var_0_7:path(arg_84_0.weekHots[arg_84_0.sxSelected])
		local var_84_4 = var_0_7:homeCardScale(arg_84_0.weekHots[arg_84_0.sxSelected])
		local var_84_5 = var_0_7:pos(arg_84_0.middlePartnerID, xyd.SkinDynamicPosType.MAIN_SCENE)

		var_84_2 = xyd.EffectLoader.new(var_84_3, 2, var_84_4, var_84_5)
	else
		var_84_2 = xyd.SpriteLoader.new(xyd.tables.model:transparentCard(arg_84_0.weekHots[arg_84_0.sxSelected]), nil, nil, xyd.DefaultImageType.HOME_CARD)
	end

	local var_84_6 = xyd.tables.libraryHomeCard:x(arg_84_0.weekHots[arg_84_0.sxSelected])
	local var_84_7 = xyd.tables.libraryHomeCard:y(arg_84_0.weekHots[arg_84_0.sxSelected])

	arg_84_0:nodeByName("machine_detail3"):getChildByName("npc_pos"):addChild(var_84_2)
	var_84_2:setPosition(var_84_6, var_84_7)
	var_84_2:setAnchorPoint(0.5, 0)
	var_84_2:setTouchEnabled(true)
	var_84_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_85_0)
		if arg_85_0.name == "ended" and not arg_84_0.isAnimation then
			arg_84_0:npcSpeak(arg_84_0.weekHots[arg_84_0.sxSelected], 3)
		end

		return true
	end)
	arg_84_0:npcSpeak(arg_84_0.weekHots[arg_84_0.sxSelected], 3)
end

function var_0_0.setPrice(arg_86_0)
	arg_86_0:smallPriceSetUp()
	arg_86_0:middlePriceSetUp()
	arg_86_0:sxPriceSetUp()
end

function var_0_0.smallPriceSetUp(arg_87_0)
	local var_87_0 = arg_87_0:nodeByName("machine1")
	local var_87_1 = arg_87_0:nodeByName("machine_detail1"):getChildByName("detail")

	var_87_0:getChildByName("free_txt"):setVisible(arg_87_0.freeTimes > 0 and arg_87_0.timeCount1 < 1)
	var_87_0:getChildByName("free_time"):setVisible(arg_87_0.freeTimes > 0 and arg_87_0.timeCount1 < 1)
	var_87_0:getChildByName("s_red_p"):setVisible(arg_87_0.freeTimes > 0 and arg_87_0.timeCount1 < 1)
	var_87_0:getChildByName("time"):setVisible(arg_87_0.freeTimes > 0 and arg_87_0.timeCount1 > 0)
	var_87_0:getChildByName("time_txt"):setVisible(arg_87_0.freeTimes > 0 and arg_87_0.timeCount1 > 0)
	var_87_0:getChildByName("no_free_time"):setVisible(arg_87_0.freeTimes == 0)
	var_87_1:getChildByName("time"):setVisible(arg_87_0.freeTimes > 0 and arg_87_0.timeCount1 > 0)
	var_87_1:getChildByName("time_des"):setVisible(arg_87_0.freeTimes > 0 and arg_87_0.timeCount1 > 0)
	var_87_1:getChildByName("free_time"):setVisible(arg_87_0.freeTimes == 0 or arg_87_0.timeCount1 < 1)
	var_87_1:getChildByName("gold_price_ten"):setString(var_0_6:manaTen(xyd.SummonType.Mana))

	if arg_87_0.freeTimes > 0 and arg_87_0.timeCount1 < 1 then
		var_87_0:getChildByName("free_time"):setString(arg_87_0.freeTimes .. "/5")
		var_87_1:getChildByName("free_time"):setString(var_0_3:translation("SUMMON_MANA_FREE_LABEL") .. arg_87_0.freeTimes .. "/5")
		var_87_1:getChildByName("gold_price_one"):setString(var_0_3:translation("SUMMON_PRICE_FREE"))
	else
		var_87_1:getChildByName("gold_price_one"):setString(var_0_6:mana(xyd.SummonType.Mana))

		if arg_87_0.timeCount1 > 0 then
			local var_87_2 = math.floor(arg_87_0.timeCount1 / 3600)
			local var_87_3 = math.floor(arg_87_0.timeCount1 % 3600 / 60)
			local var_87_4 = arg_87_0.timeCount1 % 60
			local var_87_5 = string.format("%02d:%02d:%02d", var_87_2, var_87_3, var_87_4)

			var_87_0:getChildByName("time"):setString(var_87_5)
			var_87_1:getChildByName("time"):setString(var_87_5)
		else
			var_87_1:getChildByName("free_time"):setString(var_0_3:translation("SUMMON_MIANFEIYONGWAN"))
		end
	end
end

function var_0_0.middlePriceSetUp(arg_88_0)
	local var_88_0 = arg_88_0:nodeByName("machine2")
	local var_88_1 = arg_88_0:nodeByName("machine_detail2"):getChildByName("detail")
	local var_88_2 = var_88_1:getChildByName("discount1")
	local var_88_3 = var_88_1:getChildByName("discount10")
	local var_88_4 = var_88_1:getChildByName("crystal_price_one")
	local var_88_5 = var_88_1:getChildByName("crystal_price_ten")

	arg_88_0:getDiscountCardNum()
	var_88_0:getChildByName("free_txt"):setVisible(arg_88_0.timeCount2 < 1)
	var_88_0:getChildByName("m_red_p"):setVisible(arg_88_0.timeCount2 < 1)
	var_88_0:getChildByName("time_txt"):setVisible(arg_88_0.timeCount2 > 0)
	var_88_0:getChildByName("time"):setVisible(arg_88_0.timeCount2 > 0)
	var_88_1:getChildByName("free_once"):setVisible(arg_88_0.timeCount2 < 1)
	var_88_1:getChildByName("time_des"):setVisible(arg_88_0.timeCount2 > 0)
	var_88_1:getChildByName("time"):setVisible(arg_88_0.timeCount2 > 0)
	var_88_1:getChildByName("free1"):setVisible(arg_88_0.timeCount2 > 0 and arg_88_0.freeDiscountNum > 0)
	var_88_1:getChildByName("crystal1"):setVisible(arg_88_0.timeCount2 < 1 or arg_88_0.freeDiscountNum < 1)
	var_88_1:getChildByName("free10"):setVisible(arg_88_0.tenfreeDiscountNum > 0)
	var_88_1:getChildByName("crystal10"):setVisible(arg_88_0.tenfreeDiscountNum < 1)
	var_88_2:setVisible(arg_88_0.timeCount2 > 0 and arg_88_0.freeDiscountNum < 1 and arg_88_0.threeDiscountNum > 0)
	var_88_3:setVisible(arg_88_0.tenfreeDiscountNum < 1)
	var_88_3:getChildByName("5"):setVisible(arg_88_0.fiveDiscountNum > 0)
	var_88_3:getChildByName("9"):setVisible(arg_88_0.fiveDiscountNum < 1)

	if arg_88_0.timeCount2 < 1 then
		var_88_4:setString(var_0_3:translation("MIDDLE_MACHINE_FREE_TXT"))
	else
		local var_88_6 = math.floor(arg_88_0.timeCount2 / 3600)
		local var_88_7 = math.floor(arg_88_0.timeCount2 % 3600 / 60)
		local var_88_8 = arg_88_0.timeCount2 % 60
		local var_88_9 = string.format("%02d:%02d:%02d", var_88_6, var_88_7, var_88_8)

		var_88_0:getChildByName("time"):setString(var_88_9)
		var_88_1:getChildByName("time"):setString(var_88_9)

		if arg_88_0.freeDiscountNum > 0 then
			var_88_4:setString(var_0_3:translation("LOW_TICKET"))
		elseif arg_88_0.threeDiscountNum > 0 then
			var_88_4:setString(var_0_6:crystal(xyd.SummonType.CrystalDiscountOne))
		else
			var_88_4:setString(var_0_6:crystal(xyd.SummonType.Crystal))
		end
	end

	if arg_88_0.tenfreeDiscountNum > 0 then
		var_88_5:setString(var_0_3:translation("HIGH_TICKET"))
	elseif arg_88_0.fiveDiscountNum > 0 then
		var_88_5:setString(var_0_6:crystal(xyd.SummonType.CrystalDiscountTen))
	else
		var_88_5:setString(var_0_6:crystalTen(xyd.SummonType.Crystal))
	end
end

function var_0_0.sxPriceSetUp(arg_89_0)
	arg_89_0:nodeByName("machine_detail3"):getChildByName("detail"):getChildByName("sx_price"):setString(var_0_6:stone(xyd.SummonType.Stone))
end

function var_0_0.goldBuy1Btn(arg_90_0)
	if arg_90_0.goldBuy1Btn_ then
		return arg_90_0.goldBuy1Btn_
	end

	arg_90_0.goldBuy1Btn_ = arg_90_0:nodeByName("machine_detail1"):getChildByName("detail"):getChildByName("btn_one")

	arg_90_0.goldBuy1Btn_:setTouchEnabled(true)
	arg_90_0.goldBuy1Btn_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_91_0)
		if arg_91_0.name == "began" then
			xyd.playButtonSound()
			arg_90_0.goldBuy1Btn_:setScale(0.9)
		elseif arg_91_0.name == "moved" then
			arg_90_0.goldBuy1Btn_:setScale(0.9)
		elseif arg_91_0.name == "ended" and not arg_90_0.isAnimation then
			arg_90_0.goldBuy1Btn_:setScale(1)

			if arg_90_0.wndState ~= var_0_15.SMALL then
				return
			end

			local var_91_0 = arg_90_0.goldBuy1Btn_:getContentSize()
			local var_91_1 = arg_90_0.goldBuy1Btn_:convertToNodeSpace(cc.p(arg_91_0.x, arg_91_0.y))

			if var_91_1.x < 0 or var_91_1.x > var_91_0.width or var_91_1.y < 0 or var_91_1.y > var_91_0.height then
				return
			end

			audio.playSound(xyd.tables.sound:getSound("draw_item_coin"))

			local var_91_2 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

			if var_91_2.mana < var_0_6:mana(xyd.SummonType.Mana) and (not (arg_90_0.freeTimes > 0) or not (arg_90_0.timeCount1 < 1)) then
				xyd.ModelManager.get():loadModel(xyd.ModelType.GIFT_PUSH):judgePush(4)
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_3:translation("JINBI_ABSENCE"), function()
					local var_92_0 = xyd.FunctionID.ID_GOLD_HAND

					if var_91_2:isFuncOpen(var_92_0) == true then
						xyd.WindowManager.get():openWindow(xyd.WindowName.goldenHand)
					else
						local var_92_1 = xyd.tables.functionOpen:level(var_92_0)
						local var_92_2 = string.format(var_0_3:translation("FUNCTION_OPEN_TIP_LEVEL"), var_92_1)

						xyd.WindowManager.get():openWindow("toast", {
							message = var_92_2
						})
					end
				end, nil, nil, arg_90_0.colorMode)
			else
				arg_90_0:goldSummon(1)
			end

			if xyd.StoryData.get():getGuideID() < xyd.GuideStoryType.GUIDE_SUMMON_FREE_THREE and xyd.WindowManager.get():isWindowOpen("guide") then
				xyd.WindowManager.get():closeWindow("guide")
			end
		end

		return true
	end)

	return arg_90_0.goldBuy1Btn_
end

function var_0_0.goldBuy10Btn(arg_93_0)
	if arg_93_0.goldBuy10Btn_ then
		return arg_93_0.goldBuy10Btn_
	end

	arg_93_0.goldBuy10Btn_ = arg_93_0:nodeByName("machine_detail1"):getChildByName("detail"):getChildByName("btn_ten")

	arg_93_0.goldBuy10Btn_:setTouchEnabled(true)
	arg_93_0.goldBuy10Btn_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_94_0)
		if arg_94_0.name == "began" then
			xyd.playButtonSound()
			arg_93_0.goldBuy10Btn_:setScale(0.9)
		elseif arg_94_0.name == "moved" then
			arg_93_0.goldBuy10Btn_:setScale(0.9)
		elseif arg_94_0.name == "ended" and not arg_93_0.isAnimation then
			arg_93_0.goldBuy10Btn_:setScale(1)

			if arg_93_0.wndState ~= var_0_15.SMALL then
				return
			end

			local var_94_0 = arg_93_0.goldBuy10Btn_:getContentSize()
			local var_94_1 = arg_93_0.goldBuy10Btn_:convertToNodeSpace(cc.p(arg_94_0.x, arg_94_0.y))

			if var_94_1.x < 0 or var_94_1.x > var_94_0.width or var_94_1.y < 0 or var_94_1.y > var_94_0.height then
				return
			end

			audio.playSound(xyd.tables.sound:getSound("draw_item_coin"))

			local var_94_2 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

			if var_94_2.mana < var_0_6:manaTen(xyd.SummonType.Mana) then
				xyd.ModelManager.get():loadModel(xyd.ModelType.GIFT_PUSH):judgePush(4)
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_3:translation("JINBI_ABSENCE"), function()
					local var_95_0 = xyd.FunctionID.ID_GOLD_HAND

					if var_94_2:isFuncOpen(var_95_0) == true then
						xyd.WindowManager.get():openWindow(xyd.WindowName.goldenHand)
					else
						local var_95_1 = xyd.tables.functionOpen:level(var_95_0)
						local var_95_2 = string.format(var_0_3:translation("FUNCTION_OPEN_TIP_LEVEL"), var_95_1)

						xyd.WindowManager.get():openWindow("toast", {
							message = var_95_2
						})
					end
				end, nil, nil, arg_93_0.colorMode)
			else
				arg_93_0:goldSummon(10)
			end
		end

		return true
	end)

	return arg_93_0.goldBuy10Btn_
end

function var_0_0.crystalBuy1Btn(arg_96_0)
	if arg_96_0.crystalBuy1Btn_ and not arg_96_0.haschanged then
		return crystalBuy1Btn_
	end

	if not arg_96_0.threeDiscountNum or not arg_96_0.freeDiscountNum then
		arg_96_0:getDiscountCardNum()
	end

	arg_96_0.crystalBuy1Btn_ = arg_96_0:nodeByName("machine_detail2"):getChildByName("detail"):getChildByName("btn_one")

	arg_96_0.crystalBuy1Btn_:setTouchEnabled(true)
	arg_96_0.crystalBuy1Btn_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_97_0)
		if arg_97_0.name == "began" then
			xyd.playButtonSound()
			arg_96_0.crystalBuy1Btn_:setScale(0.9)
		elseif arg_97_0.name == "moved" then
			arg_96_0.crystalBuy1Btn_:setScale(0.9)
		elseif arg_97_0.name == "ended" and not arg_96_0.isAnimation then
			arg_96_0.crystalBuy1Btn_:setScale(1)

			if arg_96_0.wndState ~= var_0_15.MIDDLE then
				return
			end

			local var_97_0 = arg_96_0.crystalBuy1Btn_:getContentSize()
			local var_97_1 = arg_96_0.crystalBuy1Btn_:convertToNodeSpace(cc.p(arg_97_0.x, arg_97_0.y))

			if var_97_1.x < 0 or var_97_1.x > var_97_0.width or var_97_1.y < 0 or var_97_1.y > var_97_0.height then
				return
			end

			audio.playSound(xyd.tables.sound:getSound("draw_item_coin"))

			local var_97_2 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

			if arg_96_0.threeDiscountNum <= 0 and arg_96_0.freeDiscountNum <= 0 then
				if var_97_2.crystal < var_0_6:crystal(xyd.SummonType.Crystal) and not (arg_96_0.timeCount2 < 1) then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_3:translation("ZUANSHI_ABSENCE"), function()
						local var_98_0 = {}

						var_98_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_98_0)
					end, nil, nil, arg_96_0.colorMode)
				else
					arg_96_0:crystalSummon(1)
				end
			elseif arg_96_0.freeDiscountNum > 0 then
				arg_96_0:crystalSummon(1)
			elseif var_97_2.crystal < var_0_6:crystal(xyd.SummonType.CrystalDiscountOne) and not (arg_96_0.timeCount2 < 1) then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_3:translation("ZUANSHI_ABSENCE"), function()
					local var_99_0 = {}

					var_99_0.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_99_0)
				end, nil, nil, arg_96_0.colorMode)
			else
				arg_96_0:crystalSummon(1)
			end

			if xyd.StoryData.get():getGuideID() < xyd.GuideStoryType.GUIDE_SUMMON_CRYSTAL_THREE and xyd.WindowManager.get():isWindowOpen("guide") then
				xyd.WindowManager.get():closeWindow("guide")
			end
		end

		return true
	end)

	return arg_96_0.crystalBuy1Btn_
end

function var_0_0.crystalBuy10Btn(arg_100_0)
	if arg_100_0.crystalBuy10Btn_ and not arg_100_0.haschanged then
		return crystalBuy10Btn_
	end

	if not arg_100_0.fiveDiscountNum or not arg_100_0.tenfreeDiscountNum then
		arg_100_0:getDiscountCardNum()
	end

	arg_100_0.crystalBuy10Btn_ = arg_100_0:nodeByName("machine_detail2"):getChildByName("detail"):getChildByName("btn_ten")

	arg_100_0.crystalBuy10Btn_:setTouchEnabled(true)
	arg_100_0.crystalBuy10Btn_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_101_0)
		if arg_101_0.name == "began" then
			xyd.playButtonSound()
			arg_100_0.crystalBuy10Btn_:setScale(0.9)
		elseif arg_101_0.name == "moved" then
			arg_100_0.crystalBuy10Btn_:setScale(0.9)
		elseif arg_101_0.name == "ended" and not arg_100_0.isAnimation then
			arg_100_0.crystalBuy10Btn_:setScale(1)

			if arg_100_0.wndState ~= var_0_15.MIDDLE then
				return
			end

			local var_101_0 = arg_100_0.crystalBuy10Btn_:getContentSize()
			local var_101_1 = arg_100_0.crystalBuy10Btn_:convertToNodeSpace(cc.p(arg_101_0.x, arg_101_0.y))

			if var_101_1.x < 0 or var_101_1.x > var_101_0.width or var_101_1.y < 0 or var_101_1.y > var_101_0.height then
				return
			end

			audio.playSound(xyd.tables.sound:getSound("draw_item_coin"))

			local var_101_2 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

			if arg_100_0.tenfreeDiscountNum <= 0 and arg_100_0.fiveDiscountNum <= 0 then
				if var_101_2.crystal < var_0_6:crystalTen(xyd.SummonType.Crystal) then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_3:translation("ZUANSHI_ABSENCE"), function()
						local var_102_0 = {}

						var_102_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_102_0)
					end, nil, nil, arg_100_0.colorMode)
				else
					arg_100_0:crystalSummon(10)
				end
			elseif arg_100_0.tenfreeDiscountNum > 0 then
				arg_100_0:crystalSummon(10)
			elseif var_101_2.crystal < var_0_6:crystal(xyd.SummonType.CrystalDiscountTen) then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_3:translation("ZUANSHI_ABSENCE"), function()
					local var_103_0 = {}

					var_103_0.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_103_0)
				end, nil, nil, arg_100_0.colorMode)
			else
				arg_100_0:crystalSummon(10)
			end
		end

		return true
	end)

	return arg_100_0.crystalBuy10Btn_
end

function var_0_0.sxBuy1Btn(arg_104_0)
	if arg_104_0.sxBuy1Btn_ then
		return arg_104_0.sxBuy1Btn_
	end

	arg_104_0.sxBuy1Btn_ = arg_104_0:nodeByName("machine_detail3"):getChildByName("detail"):getChildByName("buy")

	arg_104_0.sxBuy1Btn_:setTouchEnabled(true)
	arg_104_0.sxBuy1Btn_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_105_0)
		if arg_105_0.name == "began" then
			xyd.playButtonSound()
			arg_104_0.sxBuy1Btn_:setScale(0.9)
		elseif arg_105_0.name == "moved" then
			arg_104_0.sxBuy1Btn_:setScale(0.9)
		elseif arg_105_0.name == "ended" and not arg_104_0.isAnimation then
			arg_104_0.sxBuy1Btn_:setScale(1)

			if arg_104_0.wndState ~= var_0_15.SX then
				return
			end

			local var_105_0 = arg_104_0.sxBuy1Btn_:getContentSize()
			local var_105_1 = arg_104_0.sxBuy1Btn_:convertToNodeSpace(cc.p(arg_105_0.x, arg_105_0.y))

			if var_105_1.x < 0 or var_105_1.x > var_105_0.width or var_105_1.y < 0 or var_105_1.y > var_105_0.height then
				return
			end

			audio.playSound(xyd.tables.sound:getSound("draw_item_coin"))

			if xyd.tables.vip:soulBox(arg_104_0.vip) == 1 then
				if xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER).crystal < var_0_6:stone(xyd.SummonType.Stone) then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_3:translation("ZUANSHI_ABSENCE"), function()
						local var_106_0 = {}

						var_106_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_106_0)
					end, nil, nil, arg_104_0.colorMode)
				else
					arg_104_0:stoneSummon(1)
				end
			else
				local var_105_2 = var_0_3:translation("SOUL_BOX_LIMIT")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_105_2
				})
			end
		end

		return true
	end)

	return arg_104_0.sxBuy1Btn_
end

function var_0_0.goldSummon(arg_107_0, arg_107_1)
	local var_107_0 = {
		summon_type = xyd.SummonType.Mana
	}

	if arg_107_1 == 1 and arg_107_0.freeTimes > 0 and arg_107_0.timeCount1 < 1 then
		var_107_0.summon_index = xyd.SummonType.ManaFree
	elseif arg_107_1 == 1 then
		var_107_0.summon_index = xyd.SummonType.ManaOne
	elseif arg_107_1 == 10 then
		var_107_0.summon_index = xyd.SummonType.ManaTen
	end

	arg_107_0.selfPlayer:summonHero(var_107_0, handler(arg_107_0, arg_107_0.summonCallback))

	arg_107_0.lastType = var_107_0.summon_type

	if xyd.WindowManager.get():isWindowOpen("guide") then
		arg_107_0.selfPlayer:sendOperationLog(xyd.StatID.ID_BUY_SUMMON_MANA)
		xyd.WindowManager.get():closeWindow("guide")
	end
end

function var_0_0.crystalSummon(arg_108_0, arg_108_1)
	arg_108_0.haschanged = true

	local var_108_0 = {
		summon_type = xyd.SummonType.Crystal
	}

	arg_108_0.lastType = xyd.SummonType.Crystal

	if arg_108_1 == 1 and arg_108_0.timeCount2 < 1 then
		var_108_0.summon_type = xyd.SummonType.CrystalFree
		var_108_0.summon_index = xyd.SummonType.CrystalOne
	elseif arg_108_1 == 1 and arg_108_0.freeDiscountNum > 0 then
		var_108_0.summon_type = xyd.SummonType.CouponType1
		var_108_0.summon_index = xyd.SummonType.CouponTypeOne
		arg_108_0.lastType = xyd.SummonType.CouponType1
	elseif arg_108_1 == 1 and arg_108_0.threeDiscountNum > 0 then
		var_108_0.summon_type = xyd.SummonType.CrystalDiscountOne
		var_108_0.summon_index = xyd.SummonType.CrystalDiscountIndex
		arg_108_0.lastType = xyd.SummonType.CrystalDiscountOne
	elseif arg_108_1 == 1 and arg_108_0.threeDiscountNum <= 0 and arg_108_0.freeDiscountNum <= 0 then
		var_108_0.summon_type = xyd.SummonType.Crystal
		var_108_0.summon_index = xyd.SummonType.CrystalOne
	elseif arg_108_1 == 10 and arg_108_0.fiveDiscountNum <= 0 and arg_108_0.tenfreeDiscountNum <= 0 then
		var_108_0.summon_type = xyd.SummonType.Crystal
		var_108_0.summon_index = xyd.SummonType.CrystalTen
	elseif arg_108_1 == 10 and arg_108_0.tenfreeDiscountNum > 0 then
		var_108_0.summon_type = xyd.SummonType.CouponType2
		var_108_0.summon_index = xyd.SummonType.CouponTypeTen
		arg_108_0.lastType = xyd.SummonType.CouponType2
	elseif arg_108_1 == 10 and arg_108_0.fiveDiscountNum > 0 then
		var_108_0.summon_type = xyd.SummonType.CrystalDiscountTen
		var_108_0.summon_index = xyd.SummonType.CrystalDiscountIndex
		arg_108_0.lastType = xyd.SummonType.CrystalDiscountTen
	end

	arg_108_0.selfPlayer:summonHero(var_108_0, handler(arg_108_0, arg_108_0.summonCallback))

	if xyd.WindowManager.get():isWindowOpen("guide") then
		arg_108_0.selfPlayer:sendOperationLog(xyd.StatID.ID_BUY_SUMMON_CRYSTAL)
		xyd.WindowManager.get():closeWindow("guide")
	end
end

function var_0_0.stoneSummon(arg_109_0, arg_109_1)
	local var_109_0 = {
		summon_type = xyd.SummonType.Stone
	}

	if arg_109_1 == 1 then
		if arg_109_0.summonStoneIndex and arg_109_0.summonStoneIndex ~= 1 then
			var_109_0.summon_index = arg_109_0.summonStoneIndex
		else
			var_109_0.summon_index = xyd.SummonType.StoneOne
		end
	end

	arg_109_0.selfPlayer:summonHero(var_109_0, handler(arg_109_0, arg_109_0.summonCallback))

	arg_109_0.lastType = xyd.SummonType.Stone
end

function var_0_0.summonCallback(arg_110_0, arg_110_1, arg_110_2)
	if arg_110_1 ~= xyd.error.OK then
		return
	end

	if arg_110_0.lastType == xyd.SummonType.Crystal and xyd.StoryData.get():getGuideID() < xyd.GuideStoryType.GUIDE_SUMMON_CRYSTAL_THREE then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_SUMMON_CRYSTAL_THREE)
		xyd.StoryData.get():persist()
	elseif arg_110_0.lastType == xyd.SummonType.Mana and xyd.StoryData.get():getGuideID() < xyd.GuideStoryType.GUIDE_SUMMON_FREE_THREE then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_SUMMON_FREE_THREE)
		xyd.StoryData.get():persist()
	end

	arg_110_0:setPrice()

	if arg_110_0.lastType == xyd.SummonType.CrystalDiscountOne then
		arg_110_0.threeDiscountNum = arg_110_0.threeDiscountNum - 1

		arg_110_0.selfPlayer:getBackpack():removeItem({
			itemNum = 1,
			itemID = var_0_11
		})
	elseif arg_110_0.lastType == xyd.SummonType.CrystalDiscountTen then
		arg_110_0.fiveDiscountNum = arg_110_0.fiveDiscountNum - 1

		arg_110_0.selfPlayer:getBackpack():removeItem({
			itemNum = 1,
			itemID = var_0_12
		})
	elseif arg_110_0.lastType == xyd.SummonType.CouponType1 then
		arg_110_0.freeDiscountNum = arg_110_0.freeDiscountNum - 1

		arg_110_0.selfPlayer:getBackpack():removeItem({
			itemNum = 1,
			itemID = var_0_13
		})
	elseif arg_110_0.lastType == xyd.SummonType.CouponType2 then
		arg_110_0.tenfreeDiscountNum = arg_110_0.tenfreeDiscountNum - 1

		arg_110_0.selfPlayer:getBackpack():removeItem({
			itemNum = 1,
			itemID = var_0_14
		})
	end

	local var_110_0 = {}
	local var_110_1 = {}

	for iter_110_0, iter_110_1 in pairs(arg_110_2.result) do
		if tonumber(iter_110_0) then
			table.insert(var_110_1, iter_110_1)
		end
	end

	var_110_0.items = var_110_1
	var_110_0.reward = arg_110_2.reward
	var_110_0.lastType = arg_110_0.lastType
	var_110_0.extraAward = arg_110_2.items
	var_110_0.extraReward = arg_110_2.extra_reward
	var_110_0.sakuraItems = arg_110_2.sakura_items
	var_110_0.stick_items = arg_110_2.stick_items
	var_110_0.free = not arg_110_2.economy_

	if arg_110_0.lastType == xyd.SummonType.Stone then
		var_110_0.summonIndex = arg_110_0.summonStoneIndex
	end

	local var_110_2 = {}

	for iter_110_2, iter_110_3 in pairs(arg_110_2.result) do
		if iter_110_3.is_partner and iter_110_3.table_id then
			table.insert(var_110_2, iter_110_3.table_id)
		end
	end

	xyd.WindowManager.get():openWindow(xyd.WindowName.summonResultWnd, var_110_0)
end

function var_0_0.willClose(arg_111_0)
	if arg_111_0.handler then
		var_0_2.unscheduleGlobal(arg_111_0.handler)

		arg_111_0.handler = nil
	end

	if arg_111_0.txtHandler then
		var_0_2.unscheduleGlobal(arg_111_0.txtHandler)

		arg_111_0.txtHandler = nil
	end

	xyd.WindowManager.get():getWindow("summon"):setVisible(true)

	if xyd.WindowManager.get():isWindowOpen("guide") then
		xyd.WindowManager.get():closeWindow("guide")
	end

	if arg_111_0.longTouchHandler then
		var_0_2.unscheduleGlobal(arg_111_0.longTouchHandler)

		arg_111_0.longTouchHandler = nil
	end
end

function var_0_0.didClose(arg_112_0)
	if xyd.WindowManager.get():getWindow("asset_wnd") then
		xyd.WindowManager.get():closeWindow("asset_wnd")
	end

	local var_112_0

	if xyd.StoryData.get():getGuideID() <= xyd.GuideStoryType.GUIDE_CAMPAIGN_START then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_CAMPAIGN_START)
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.PLAY_GUIDE,
			params = {
				guide_id = xyd.GuideStoryType.GUIDE_CAMPAIGN_START
			}
		})

		var_112_0 = true
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_ACTION_START,
		params = {
			quickAction = var_112_0
		}
	})
end

function var_0_0.setIDBeforeGuideWnd(arg_113_0)
	local var_113_0 = xyd.StoryData.get():getGuideID()

	if var_113_0 <= xyd.GuideStoryType.GUIDE_SUMMON_FREE_THREE and not arg_113_0.selfPlayer:getHeroByID(2) then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_SUMMON_FREE_ONE, true)
		xyd.StoryData.get():persist()
	elseif var_113_0 <= xyd.GuideStoryType.GUIDE_SUMMON_CRYSTAL_THREE and not arg_113_0.selfPlayer:getHeroByID(3) then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_SUMMON_CRYSTAL_ONE, true)
		xyd.StoryData.get():persist()
	end
end

function var_0_0.playGuide(arg_114_0)
	local var_114_0 = xyd.StoryData.get():getGuideID()

	if xyd.WindowManager.get():isWindowOpen("guide") then
		xyd.WindowManager.get():closeWindow("guide")
	end

	if var_114_0 == xyd.GuideStoryType.GUIDE_SUMMON_FREE_ONE then
		local var_114_1 = arg_114_0:nodeByName("machine1"):getChildByName("touch_node")
		local var_114_2 = var_114_1:getPositionX()
		local var_114_3 = var_114_1:getPositionY()

		xyd.WindowManager.get():openWindow("guide")

		local var_114_4 = xyd.WindowManager.get():getWindow("guide")

		var_114_4:addNode()
		var_114_4:setStencil(var_114_1:getContentSize().width, var_114_1:getContentSize().height, var_114_2 + 339, var_114_3 - 12, 2, {
			machine1 = true,
			right = true,
			position = {
				700,
				200
			}
		})
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_SUMMON_FREE_TWO)
	elseif var_114_0 == xyd.GuideStoryType.GUIDE_SUMMON_FREE_TWO then
		local var_114_5 = arg_114_0:nodeByName("machine_detail1"):getChildByName("detail"):getChildByName("btn_one")
		local var_114_6 = var_114_5:getPositionX()
		local var_114_7 = var_114_5:getPositionY()

		xyd.WindowManager.get():openWindow("guide")

		local var_114_8 = xyd.WindowManager.get():getWindow("guide")
		local var_114_9 = var_114_8:convertToNodeSpace(var_114_5:getParent():convertToWorldSpace(cc.p(var_114_6, var_114_7)))

		var_114_8:addNode()
		var_114_8:setStencil(var_114_5:getContentSize().width, var_114_5:getContentSize().height, var_114_9.x, var_114_9.y, 3, {
			right = true,
			position = {
				350,
				200
			}
		})
	elseif var_114_0 == xyd.GuideStoryType.GUIDE_SUMMON_CRYSTAL_ONE then
		local var_114_10 = arg_114_0:nodeByName("machine2"):getChildByName("touch_node")
		local var_114_11 = var_114_10:getPositionX()
		local var_114_12 = var_114_10:getPositionY()

		xyd.WindowManager.get():openWindow("guide")

		local var_114_13 = xyd.WindowManager.get():getWindow("guide")

		var_114_13:addNode()
		var_114_13:setStencil(var_114_10:getContentSize().width, var_114_10:getContentSize().height, var_114_11 + 565, var_114_12 - 20, 3, {
			machine2 = true,
			position = {
				350,
				200
			}
		})
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_SUMMON_CRYSTAL_TWO)
	elseif var_114_0 == xyd.GuideStoryType.GUIDE_SUMMON_CRYSTAL_TWO then
		local var_114_14 = arg_114_0:nodeByName("machine_detail2"):getChildByName("detail"):getChildByName("btn_one")
		local var_114_15 = var_114_14:getPositionX()
		local var_114_16 = var_114_14:getPositionY()

		xyd.WindowManager.get():openWindow("guide")

		local var_114_17 = xyd.WindowManager.get():getWindow("guide")
		local var_114_18 = var_114_17:convertToNodeSpace(var_114_14:getParent():convertToWorldSpace(cc.p(var_114_15, var_114_16)))

		var_114_17:addNode()
		var_114_17:setStencil(var_114_14:getContentSize().width, var_114_14:getContentSize().height, var_114_18.x, var_114_18.y, 2, {
			position = {
				780,
				200
			}
		})
	elseif var_114_0 == xyd.GuideStoryType.GUIDE_SUMMON_END then
		local var_114_19 = arg_114_0:nodeByName("return")
		local var_114_20 = var_114_19:getPositionX()
		local var_114_21 = var_114_19:getPositionY()

		xyd.WindowManager.get():openWindow("guide")

		local var_114_22 = xyd.WindowManager.get():getWindow("guide")
		local var_114_23 = var_114_22:convertToNodeSpace(var_114_19:getParent():convertToWorldSpace(cc.p(var_114_20, var_114_21)))

		var_114_22:addNode()
		var_114_22:setStencil(var_114_19:getContentSize().width, var_114_19:getContentSize().height, var_114_23.x + 50, var_114_23.y - 30, 3, {
			right = true,
			position = {
				250,
				530
			}
		})
	end
end

function var_0_0.guideBack(arg_115_0)
	arg_115_0.isAnimation = true

	if xyd.WindowManager.get():isWindowOpen("guide") then
		xyd.WindowManager.get():closeWindow("guide")
	end

	arg_115_0:runAction(cc.Sequence:create({
		cc.DelayTime:create(0.2),
		cc.CallFunc:create(function()
			arg_115_0.nextWndState = 1

			arg_115_0:changeWndState()
		end)
	}))
end

function var_0_0.getDiscountCardNum(arg_117_0)
	local var_117_0 = arg_117_0.selfPlayer:getBackpack():getItemNumByID(var_0_11)
	local var_117_1 = arg_117_0.selfPlayer:getBackpack():getItemNumByID(var_0_12)
	local var_117_2 = arg_117_0.selfPlayer:getBackpack():getItemNumByID(var_0_13)
	local var_117_3 = arg_117_0.selfPlayer:getBackpack():getItemNumByID(var_0_14)

	arg_117_0.threeDiscountNum = var_117_0
	arg_117_0.fiveDiscountNum = var_117_1
	arg_117_0.freeDiscountNum = var_117_2
	arg_117_0.tenfreeDiscountNum = var_117_3

	return {
		threeDiscount = arg_117_0.threeDiscountNum,
		fiveDiscount = arg_117_0.fiveDiscountNum,
		freeDiscount = arg_117_0.freeDiscountNum,
		tenfreeDiscount = arg_117_0.tenfreeDiscountNum
	}
end

function var_0_0.addTip(arg_118_0, arg_118_1, arg_118_2)
	local var_118_0 = {
		id = arg_118_1
	}

	xyd.addTips(arg_118_2, var_118_0)
end

return var_0_0
