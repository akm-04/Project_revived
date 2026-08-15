local var_0_0 = class("NianBossSweepWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	arg_2_0.nian_boss = xyd.ModelManager.get():loadModel(xyd.ModelType.NIAN_BOSS)

	if arg_2_0.nian_boss.perpose then
		arg_2_0.p_avatar = arg_2_0.nian_boss.perpose.avatar
		arg_2_0.p_avatar_frame = arg_2_0.nian_boss.perpose.avatar_frame_id
	end

	arg_2_0.rank = arg_2_0.nian_boss.total_rank

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("boss_damage_text"):setString(arg_3_0.nian_boss.the_damage)
	arg_3_0:nodeByName("my_damage_text"):setString(arg_3_0.nian_boss.total_damage)
	arg_3_0:nodeByName("title_words"):setString(var_0_2:translation("SWEEP"))
	arg_3_0:nodeByName("boss_damage_words"):setString(var_0_2:translation("WORLD_BOSS_SWEEP_THIS_DAMAGE"))
	arg_3_0:nodeByName("my_damage_words"):setString(var_0_2:translation("HISTORY_DAMAGE") .. var_0_2:translation("COLON"))
	arg_3_0:nodeByName("rank_words"):setString(var_0_2:translation("RANKING") .. var_0_2:translation("COLON"))
	arg_3_0:nodeByName("need_over_words"):setString(var_0_2:translation("WORLD_BOSS_NEED_TO_OVER") .. var_0_2:translation("COLON"))
	arg_3_0:nodeByName("his_damage_words"):setString(var_0_2:translation("HISTORY_DAMAGE") .. var_0_2:translation("COLON"))
	arg_3_0:setRank(arg_3_0.rank)

	if arg_3_0.rank > 1 then
		xyd.setPlayerAvatar(arg_3_0:nodeByName("icon_container"), {
			showLevel = false,
			avatar_id = arg_3_0.p_avatar,
			avatar_frame_id = arg_3_0.p_avatar_frame
		})
		arg_3_0:nodeByName("name_text"):setString(arg_3_0.nian_boss.perpose.player_name)
		arg_3_0:nodeByName("level_text"):setString(arg_3_0.nian_boss.perpose.lev)
		arg_3_0:nodeByName("his_damage_text"):setString(math.floor(tonumber(arg_3_0.nian_boss.perpose.hurt)))
	else
		arg_3_0:nodeByName("name_text"):setVisible(false)
		arg_3_0:nodeByName("his_damage_text"):setVisible(false)
		arg_3_0:nodeByName("his_damage_words"):setVisible(false)
		arg_3_0:nodeByName("name_bg"):setVisible(false)
		arg_3_0:nodeByName("level_bg"):setVisible(false)
		arg_3_0:nodeByName("icon_container"):setVisible(false)
		arg_3_0:nodeByName("level_text"):setVisible(false)
		arg_3_0:nodeByName("need_over_words"):setVisible(false)
	end
end

function var_0_0.setRank(arg_4_0, arg_4_1)
	arg_4_0:nodeByName("rank_container"):removeAllChildren()

	local var_4_0 = {}

	while arg_4_1 and arg_4_1 ~= 0 do
		local var_4_1 = arg_4_1 % 10

		arg_4_1 = math.floor(arg_4_1 / 10)

		local var_4_2 = xyd.AssetLoader.get():loadSprite("images/num_blue/" .. var_4_1 .. ".png")

		var_4_2:setAnchorPoint(cc.p(0, 0.5))
		var_4_2:scale(0.8)
		table.insert(var_4_0, var_4_2)
	end

	for iter_4_0, iter_4_1 in pairs(var_4_0) do
		iter_4_1:setPosition((#var_4_0 - iter_4_0) * 30, arg_4_0:nodeByName("rank_container"):getHeight() / 2)
		arg_4_0:nodeByName("rank_container"):addChild(iter_4_1)
	end
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	var_0_0.super:didOpen(arg_5_1)
	arg_5_0:addBlockLayer()
	arg_5_0:nodeByName("close_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			local var_6_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_6_0, false)
			xyd.WindowManager.get():closeWindow(arg_5_0)
		end
	end)
end

return var_0_0
