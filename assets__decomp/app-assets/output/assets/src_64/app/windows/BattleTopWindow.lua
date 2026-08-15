local var_0_0 = class("BattleTopWindow", import("app.common.ui.BaseWindow"))
local var_0_1

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.didOpen(arg_2_0, arg_2_1)
	arg_2_0.super.didOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.willClose(arg_3_0, arg_3_1)
	var_0_0.super.willClose(arg_3_0, arg_3_1)
	transition.stopTarget(arg_3_0:getBossBuffLabel())
end

function var_0_0.layout(arg_4_0)
	arg_4_0:setVisibleChallengeLabel(false)
	arg_4_0:getTongqianLabel():setString("0")
	arg_4_0:getAwardLabel():setString("0")
	arg_4_0:getPauseBtn()
	arg_4_0:getBossAvatarBackground():hide()
	arg_4_0:getUnlimtBackground():hide()
	arg_4_0:nodeByName("element_damage_text"):setString(xyd.tables.translation:translation("BATTLE_HARM_SUM"))
	arg_4_0:nodeByName("damage_txt"):setString(xyd.tables.translation:translation("BATTLE_HARM"))
	arg_4_0:nodeByName("degree_txt1"):setString(xyd.tables.translation:translation("NUM_TXT1"))
	arg_4_0:nodeByName("degree_txt2"):setString(xyd.tables.translation:translation("WAVE"))
	arg_4_0:nodeByName("self_kill_txt"):setString(xyd.tables.translation:translation("BATTLE_BYONESELF"))
	arg_4_0:nodeByName("text_death"):setString(xyd.tables.translation:translation("ALIVE_TXT"))
	arg_4_0:nodeByName("text_kill"):setString(xyd.tables.translation:translation("KILL_TXT"))
	arg_4_0:nodeByName("enemy_txt"):setString(xyd.tables.translation:translation("ENEMY_TXT"))
	arg_4_0:nodeByName("teammate_txt"):setString(xyd.tables.translation:translation("FRIENDLY_TXT"))
end

function var_0_0.getPauseBtn(arg_5_0)
	if not arg_5_0.puaseBtn_ then
		arg_5_0.puaseBtn_ = arg_5_0:nodeByName("btn_pause")

		arg_5_0.puaseBtn_:zorder(1)
		xyd.addTouchEvent(arg_5_0.puaseBtn_, function()
			if not ngx.ctx.battle.isEnd then
				arg_5_0:pauseClick()
			end
		end)
	end

	return arg_5_0.puaseBtn_
end

function var_0_0.getTimeLabel(arg_7_0)
	return arg_7_0:nodeByName("txt_time")
end

function var_0_0.getTongqianLabel(arg_8_0)
	return arg_8_0:nodeByName("txt_coin")
end

function var_0_0.getAwardLabel(arg_9_0)
	return arg_9_0:nodeByName("txt_award")
end

function var_0_0.getGuanQiaLabel(arg_10_0)
	return arg_10_0:nodeByName("txt_guanqia")
end

function var_0_0.getGuanQiaContainer(arg_11_0)
	return arg_11_0:nodeByName("lbl_guanqia")
end

function var_0_0.getDamageLabel(arg_12_0)
	return arg_12_0:nodeByName("label_damage")
end

function var_0_0.getDamageIcon(arg_13_0)
	return arg_13_0:nodeByName("element_damage_text")
end

function var_0_0.getBossAvatarBackSp(arg_14_0)
	return arg_14_0:nodeByName("boss_avatar")
end

function var_0_0.getAwakeDamageBar(arg_15_0)
	return arg_15_0:nodeByName("awake_damage_bar")
end

function var_0_0.getAwakeDamageLabel(arg_16_0)
	return arg_16_0:nodeByName("damage_goal")
end

function var_0_0.getAwakeSelfKillHeroLabel(arg_17_0)
	return arg_17_0:nodeByName("attack_txt")
end

function var_0_0.getAwakeSelfKillMonsterLabel(arg_18_0)
	return arg_18_0:nodeByName("awake_monster_txt")
end

function var_0_0.getAwakeDamage(arg_19_0)
	return arg_19_0:nodeByName("awake_damage_bg")
end

function var_0_0.getAwakeSelfKill(arg_20_0)
	return arg_20_0:nodeByName("awake_selfkill_bg")
end

function var_0_0.setupAvatarPos(arg_21_0)
	local var_21_0 = arg_21_0:nodeByName("boss_hp_progress_back"):getX()
	local var_21_1 = arg_21_0:nodeByName("boss_hp_progress_back"):getWidth()

	arg_21_0:getBossAvatarBackSp():x(var_21_0 + var_21_1 / 2 + arg_21_0:getBossAvatarBackSp():getWidth() / 2)
	arg_21_0:getAvatarBossContainer():x(var_21_0 + var_21_1 / 2 + arg_21_0:getBossAvatarBackSp():getWidth() / 2)
end

function var_0_0.hideElementLabel(arg_22_0)
	arg_22_0:nodeByName("lbl_guanqia"):hide()
	arg_22_0:nodeByName("label_damage"):hide()
	arg_22_0:nodeByName("element_damage_text"):hide()
	arg_22_0:nodeByName("label_buff_index"):hide()
	arg_22_0:nodeByName("boss_buff"):hide()
end

function var_0_0.hideGuildLabel(arg_23_0)
	arg_23_0:nodeByName("lbl_coin"):hide()
	arg_23_0:nodeByName("lbl_guanqia"):hide()
	arg_23_0:nodeByName("lbl_award"):hide()
	arg_23_0:getBossHpLabel():hide()
end

function var_0_0.getBossAvatarBackground(arg_24_0)
	return arg_24_0:nodeByName("boss_bg")
end

function var_0_0.getBossHpLabel(arg_25_0)
	return arg_25_0:nodeByName("label_hp_index")
end

function var_0_0.getBossBuffLabel(arg_26_0)
	return arg_26_0:nodeByName("label_buff_index")
end

function var_0_0.getBossBuffIcon(arg_27_0)
	return arg_27_0:nodeByName("boss_buff")
end

function var_0_0.onUpdateBossBuff(arg_28_0)
	local var_28_0 = transition.sequence({
		cc.ScaleTo:create(0.3, 2),
		cc.ScaleTo:create(0.3, 1)
	})
	local var_28_1 = cc.Spawn:create(var_28_0)

	arg_28_0:getBossBuffLabel():runAction(var_28_1)
end

function var_0_0.getAvatarBossContainer(arg_29_0)
	return arg_29_0:nodeByName("avatar_container")
end

function var_0_0.getBossHpBar(arg_30_0, arg_30_1)
	return arg_30_0:nodeByName("boss_hp_bar_" .. arg_30_1)
end

function var_0_0.pauseClick(arg_31_0)
	local var_31_0 = xyd.StoryData.get():getGuideID()

	if var_31_0 == xyd.GuideStoryType.GUIDE_FIGHT_3_THREE or var_31_0 == xyd.GuideStoryType.GUIDE_FIGHT_3_FOUR then
		return
	end

	arg_31_0:dispatchEvent({
		name = xyd.event.BATTLE_PAUSED
	})

	if not xyd.WindowManager.get():isWindowOpen(xyd.WindowName.battlePausedWnd) then
		var_0_1 = xyd.WindowManager.get():openWindow(xyd.WindowName.battlePausedWnd)

		if var_0_1 ~= nil then
			cc.EventProxy.new(var_0_1, var_0_1):addEventListener(xyd.event.BATTLE_RESUMED, function()
				arg_31_0:dispatchEvent({
					name = xyd.event.BATTLE_RESUMED
				})
			end):addEventListener(xyd.event.EXIT_BATTLE, function()
				arg_31_0:dispatchEvent({
					name = xyd.event.EXIT_BATTLE
				})
			end)
		end
	end
end

function var_0_0.buttonHandler(arg_34_0, arg_34_1, arg_34_2, arg_34_3)
	if arg_34_3 == ccui.TouchEventType.ended then
		transition.stopTarget(arg_34_2)
		arg_34_2:setScale(1)
		audio.getSoundsVolume(1)
		xyd.playButtonSound()

		if arg_34_1 then
			arg_34_1(arg_34_2, arg_34_3)
		end
	elseif arg_34_3 == ccui.TouchEventType.began then
		local var_34_0 = transition.sequence({
			cc.ScaleTo:create(0.3, 1.5),
			cc.ScaleTo:create(0.3, 1)
		})
		local var_34_1 = cc.RepeatForever:create(var_34_0)

		arg_34_2:runAction(var_34_1)

		return true
	elseif arg_34_3 == ccui.TouchEventType.canceled then
		transition.stopTarget(arg_34_2)
		arg_34_2:setScale(1)
	end
end

function var_0_0.hidePauseButton(arg_35_0)
	if arg_35_0.puaseBtn_ then
		arg_35_0.puaseBtn_:setVisible(false)
	end
end

function var_0_0.showPauseButton(arg_36_0)
	if arg_36_0.puaseBtn_ then
		arg_36_0.puaseBtn_:setVisible(true)
	end
end

function var_0_0.setVisibleChallengeLabel(arg_37_0, arg_37_1)
	arg_37_0:nodeByName("challenge_protect"):setVisible(arg_37_1)
	arg_37_0:nodeByName("challenge_kill"):setVisible(arg_37_1)
end

function var_0_0.getUnlimtBackground(arg_38_0)
	return arg_38_0:nodeByName("unlimit_bg")
end

function var_0_0.showUnlimitIcons(arg_39_0)
	arg_39_0:getUnlimtBackground():show()
	arg_39_0:nodeByName("lbl_guanqia"):hide()
	arg_39_0:nodeByName("lbl_time"):hide()
end

function var_0_0.getDegreeNum(arg_40_0)
	return arg_40_0:nodeByName("degree_num")
end

function var_0_0.getUnlimitAvartarContainer(arg_41_0)
	return arg_41_0:nodeByName("defence_girl_avatar_container")
end

function var_0_0.getUnlimitAvartar(arg_42_0)
	return arg_42_0:nodeByName("defence_girl_avatar")
end

function var_0_0.getUnlimitGirlHpBar(arg_43_0)
	return arg_43_0:nodeByName("defence_girl_hp")
end

return var_0_0
