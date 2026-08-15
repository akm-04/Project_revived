local var_0_0 = class("AllNightBossResultWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SpriteNodeButton")
local var_0_3 = xyd.tables.hero

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.info = arg_1_2
	arg_1_0.fighterA = arg_1_2.fighterA
	arg_1_0.fighterB = arg_1_2.fighterB
	arg_1_0.petA = arg_1_2.petA
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("text_my_rank"):setString(var_0_1:translation("ALL_NIGHT_BOSS_TEXT_8"))
	arg_3_0:setRank(arg_3_0.info.rank, arg_3_0:nodeByName("node_rank"))
	arg_3_0:nodeByName("text_title"):setString(var_0_1:translation("FIGHT_OVER"))
	arg_3_0:nodeByName("text_damage"):setString(var_0_1:translation("THIRD_ANNIVERSARY_BOSS_TEXT9") .. arg_3_0.info.damage)
	arg_3_0:nodeByName("text_total_damage"):setString(var_0_1:translation("THIRD_ANNIVERSARY_BOSS_TEXT10") .. arg_3_0.info.totalDamage)
	arg_3_0:nodeByName("tip"):setString(var_0_1:translation("ALL_NIGHT_BOSS_TEXT_7"))
	arg_3_0:nodeByName("btn_data"):addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_4_0, arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow(xyd.WindowName.battleResultDataWnd, {
				herosA = arg_3_0.fighterA,
				herosB = arg_3_0.fighterB,
				petA = arg_3_0.petA
			})
		end
	end)

	if not arg_3_0.info.pre_player then
		arg_3_0:nodeByName("player_container"):setVisible(false)
	else
		xyd.setPlayerAvatar(arg_3_0:nodeByName("avatar"), {
			avatar_id = arg_3_0.info.pre_player.avatar_id,
			avatar_frame_id = arg_3_0.info.pre_player.avatar_frame_id
		})

		if arg_3_0.info.pre_player.conquer_lev and arg_3_0.info.pre_player.conquer_lev > 0 then
			local var_3_0 = {
				x = -2,
				y = 2
			}

			xyd.setConquerLev(arg_3_0.info.pre_player.conquer_lev, arg_3_0:nodeByName("lev"), arg_3_0:nodeByName("level_bg"), var_3_0, nil, nil, nil, arg_3_0.info.pre_player.conquer_loop_id)
		else
			arg_3_0:nodeByName("lev"):setString(arg_3_0.info.pre_player.lev)
		end

		arg_3_0:nodeByName("name"):setString(arg_3_0.info.pre_player.player_name)
		arg_3_0:nodeByName("region"):setString("S" .. arg_3_0.info.pre_player.region)
		arg_3_0:nodeByName("text_player_rank"):setString(var_0_1:translation("THIRD_ANNIVERSARY_BOSS_TEXT11") .. arg_3_0.info.pre_player.rank)
		arg_3_0:nodeByName("text_player_damage"):setString(var_0_1:translation("THIRD_ANNIVERSARY_BOSS_TEXT12") .. arg_3_0.info.pre_player.damage)
	end

	arg_3_0:nodeByName("close"):addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_5_0, arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			local var_5_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_5_0, false)
			arg_3_0:dispatchEvent({
				name = xyd.event.BATTLE_END_BACK_TO_MAIN
			})
		end
	end)
end

function var_0_0.setRank(arg_6_0, arg_6_1, arg_6_2)
	if arg_6_1 > 3 then
		local var_6_0 = xyd.colorNumLabel(arg_6_1, "yellow1")

		var_6_0:setAnchorPoint(0, 0)
		var_6_0:setPositionY(5)
		var_6_0:addTo(arg_6_2)
	else
		arg_6_2:getChildByName("word_" .. arg_6_1):setVisible(true)
	end
end

function var_0_0.didOpen(arg_7_0, arg_7_1)
	var_0_0.super:didOpen(arg_7_1)
	arg_7_0:addBlockLayerWithNoTouchEvent()
end

return var_0_0
