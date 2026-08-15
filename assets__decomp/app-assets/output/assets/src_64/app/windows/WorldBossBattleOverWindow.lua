local var_0_0 = class("WorldBossBattleOverWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.my_rank = arg_1_2.my_rank
	arg_1_0.hurt = math.floor(arg_1_2.hurt)
	arg_1_0.total_hurt = math.floor(arg_1_2.total_hurt)
	arg_1_0.pre_name = arg_1_2.pre_name
	arg_1_0.pre_avatar = arg_1_2.pre_avatar
	arg_1_0.pre_avatar_frame = arg_1_2.pre_avatar_frame
	arg_1_0.pre_lev = arg_1_2.pre_lev
	arg_1_0.pre_hurt = arg_1_2.pre_hurt
	arg_1_0.pre_rank = arg_1_2.pre_rank
	arg_1_0.damage_add = arg_1_2.damage_add
	arg_1_0.fighterA = arg_1_2.fighterA
	arg_1_0.fighterB = arg_1_2.fighterB
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:init()
end

function var_0_0.init(arg_3_0)
	arg_3_0:nodeByName("rank_words"):setString(var_0_2:translation("RANKING") .. var_0_2:translation("COLON"))
	arg_3_0:nodeByName("this_time_words"):setString(var_0_2:translation("WORLD_BOSS_THIS_TIME_DAMAGE") .. var_0_2:translation("COLON"))
	arg_3_0:nodeByName("all_times_words"):setString(var_0_2:translation("HISTORY_DAMAGE") .. var_0_2:translation("COLON"))
	arg_3_0:nodeByName("all_damage_words"):setString(var_0_2:translation("HISTORY_DAMAGE") .. var_0_2:translation("COLON"))
	arg_3_0:nodeByName("his_rank_words"):setString(var_0_2:translation("HIS_RANK") .. var_0_2:translation("COLON"))
	arg_3_0:nodeByName("need_to_pass_words"):setString(var_0_2:translation("WORLD_BOSS_NEED_TO_OVER") .. var_0_2:translation("COLON"))
	arg_3_0:nodeByName("fight_over_words"):setString(var_0_2:translation("FIGHT_OVER"))
	arg_3_0:nodeByName("fight_over_words"):enableOutline(cc.c4b(35, 100, 180, 255), 1)
	arg_3_0:setRank(arg_3_0.my_rank, "my_rank_container")
	arg_3_0:nodeByName("this_time_text"):setString(arg_3_0.hurt)

	if arg_3_0.damage_add then
		arg_3_0:nodeByName("add_container"):setVisible(true)
		arg_3_0:nodeByName("right"):setString(arg_3_0.damage_add .. "）")
	else
		arg_3_0:nodeByName("add_container"):setVisible(false)
	end

	arg_3_0:nodeByName("my_damage_text"):setString(arg_3_0.total_hurt)

	if arg_3_0.pre_rank == nil then
		arg_3_0:nodeByName("bottom_container"):setVisible(false)
	else
		arg_3_0:setRank(arg_3_0.pre_rank, "rank_container")
		arg_3_0:nodeByName("his_damage_text"):setString(arg_3_0.pre_hurt)
		arg_3_0:nodeByName("lev_text"):setString(arg_3_0.pre_lev)
		arg_3_0:nodeByName("his_name_text"):setString(arg_3_0.pre_name)
		xyd.setPlayerAvatar(arg_3_0:nodeByName("icon_container"), {
			showLevel = false,
			avatar_id = arg_3_0.pre_avatar,
			avatar_frame_id = arg_3_0.pre_avatar_frame
		})
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
		if arg_6_1 == ccui.TouchEventType.ended then
			local var_6_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_6_0, false)
			arg_5_0:dispatchEvent({
				name = xyd.event.BATTLE_END_BACK_TO_MAIN
			})
		end
	end)
	arg_5_0:nodeByName("data_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow(xyd.WindowName.battleResultDataWnd, {
				herosA = arg_5_0.fighterA,
				herosB = arg_5_0.fighterB
			})
		end
	end)
end

function var_0_0.willClose(arg_8_0, arg_8_1)
	var_0_0.super:willClose(arg_8_1)
end

return var_0_0
