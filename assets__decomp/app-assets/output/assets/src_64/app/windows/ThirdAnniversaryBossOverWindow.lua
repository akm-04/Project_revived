local var_0_0 = class("ThirdAnniversaryBossOverWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.my_rank = arg_1_2.my_rank
	arg_1_0.hurt = math.floor(arg_1_2.self_damage)
	arg_1_0.total_hurt = math.floor(arg_1_2.total_damage)
	arg_1_0.pre_name = arg_1_2.pre_name
	arg_1_0.pre_avatar = arg_1_2.pre_avatar
	arg_1_0.pre_avatar_frame = arg_1_2.pre_avatar_frame
	arg_1_0.pre_lev = arg_1_2.pre_lev
	arg_1_0.pre_damage = arg_1_2.pre_damage
	arg_1_0.pre_rank = arg_1_2.pre_rank
	arg_1_0.fighterA = arg_1_2.fighterA
	arg_1_0.fighterB = arg_1_2.fighterB
	arg_1_0.petA = arg_1_2.petA
	arg_1_0.petB = arg_1_2.petB
	arg_1_0.pre_conquer_lev = arg_1_2.conquer_lev
	arg_1_0.pre_conquer_loop_id = arg_1_2.conquer_loop_id
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:init()
end

function var_0_0.init(arg_3_0)
	arg_3_0:nodeByName("text_rank"):setString(var_0_2:translation("THIRD_ANNIVERSARY_BOSS_TEXT8"))
	arg_3_0:nodeByName("text_harm"):setString(var_0_2:translation("THIRD_ANNIVERSARY_BOSS_TEXT9"))
	arg_3_0:nodeByName("text_total_harm"):setString(var_0_2:translation("THIRD_ANNIVERSARY_BOSS_TEXT10"))
	arg_3_0:nodeByName("his_rank_word"):setString(var_0_2:translation("THIRD_ANNIVERSARY_BOSS_TEXT11"))
	arg_3_0:nodeByName("all_damage"):setString(var_0_2:translation("THIRD_ANNIVERSARY_BOSS_TEXT12"))
	arg_3_0:nodeByName("title"):setString(var_0_2:translation("THIRD_ANNIVERSARY_BOSS_TXT8"))
	arg_3_0:setRank(arg_3_0.my_rank, "my_rank")
	arg_3_0:nodeByName("harm"):setString(arg_3_0.hurt)
	arg_3_0:nodeByName("total_harm"):setString(arg_3_0.total_hurt)

	if arg_3_0.pre_rank == nil then
		arg_3_0:nodeByName("his_rank_panel"):setVisible(false)
	else
		arg_3_0:nodeByName("his_rank"):setString(arg_3_0.pre_rank)
		arg_3_0:nodeByName("his_harm"):setString(arg_3_0.pre_damage)
		arg_3_0:nodeByName("his_name"):setString(arg_3_0.pre_name)
		xyd.setPlayerAvatar(arg_3_0:nodeByName("icon_container"), {
			showLevel = false,
			avatar_id = arg_3_0.pre_avatar,
			avatar_frame_id = arg_3_0.pre_avatar_frame
		})

		if arg_3_0.pre_conquer_lev and arg_3_0.pre_conquer_lev > 0 then
			arg_3_0:nodeByName("level_bg"):setVisible(false)
			xyd.setConquerLev(arg_3_0.pre_conquer_lev, arg_3_0:nodeByName("lev_txt"), arg_3_0:nodeByName("level_bg"), nil, false, 0.9, "conquer_lev_bg", arg_3_0.pre_conquer_loop_id)
		else
			arg_3_0:nodeByName("lev_txt"):setString(arg_3_0.pre_lev)
			arg_3_0:nodeByName("conquer_lev_bg"):setVisible(false)
		end
	end
end

function var_0_0.setRank(arg_4_0, arg_4_1, arg_4_2)
	arg_4_0:nodeByName(arg_4_2):removeAllChildren()

	local var_4_0 = {}

	while arg_4_1 ~= 0 do
		local var_4_1 = arg_4_1 % 10

		arg_4_1 = math.floor(arg_4_1 / 10)

		local var_4_2 = xyd.AssetLoader.get():loadSprite("images/num_blue/" .. var_4_1 .. ".png")

		var_4_2:setAnchorPoint(cc.p(0, 0.5))
		table.insert(var_4_0, var_4_2)
	end

	for iter_4_0, iter_4_1 in pairs(var_4_0) do
		if arg_4_2 then
			iter_4_1:setPosition((#var_4_0 - iter_4_0) * 30, arg_4_0:nodeByName(arg_4_2):getHeight() / 2 - 2)
			arg_4_0:nodeByName(arg_4_2):addChild(iter_4_1)
		end
	end
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	var_0_0.super:didOpen(arg_5_1)
	arg_5_0:addBlockLayerWithNoTouchEvent()
	arg_5_0:nodeByName("go_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		xyd.buttonScaleAnim(arg_5_0:nodeByName("go_btn"), arg_6_1)

		if arg_6_1 == ccui.TouchEventType.ended then
			local var_6_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_6_0, false)
			arg_5_0:dispatchEvent({
				name = xyd.event.BATTLE_END_BACK_TO_MAIN
			})
		end
	end)
	arg_5_0:nodeByName("close"):addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(arg_5_0:nodeByName("close"), arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			local var_7_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_7_0, false)
			arg_5_0:dispatchEvent({
				name = xyd.event.BATTLE_END_BACK_TO_MAIN
			})
		end
	end)
	arg_5_0:nodeByName("btn_data"):addTouchEventListener(function(arg_8_0, arg_8_1)
		xyd.buttonScaleAnim(arg_5_0:nodeByName("btn_data"), arg_8_1)

		if arg_8_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow(xyd.WindowName.battleResultDataWnd, {
				herosA = arg_5_0.fighterA,
				herosB = arg_5_0.fighterB,
				petA = arg_5_0.petA,
				petB = arg_5_0.petB
			})
		end
	end)
end

function var_0_0.willClose(arg_9_0, arg_9_1)
	var_0_0.super:willClose(arg_9_1)
end

return var_0_0
