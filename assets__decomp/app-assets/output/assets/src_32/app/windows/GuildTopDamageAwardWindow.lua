local var_0_0 = class("GuildTopDamageAwardWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.guildCoin = arg_1_2.guild_coin
	arg_1_0.crystal = arg_1_2.crystal
	arg_1_0.harm = math.floor(arg_1_2.harm)
	arg_1_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0)
	var_0_0.super.didOpen(arg_3_0)
	arg_3_0:playEffect()
	arg_3_0:addBlockLayer()
end

function var_0_0.willClose(arg_4_0)
	var_0_0.super.willClose(arg_4_0)

	if arg_4_0.effect_ then
		arg_4_0.effect_:clearTracks()
		arg_4_0.effect_:removeSelf()
	end

	arg_4_0:dispatchEvent({
		name = xyd.event.ALERT_AWARD_CLOSE
	})
end

function var_0_0.didClose(arg_5_0)
	var_0_0.super.didClose(arg_5_0)
end

function var_0_0.layout(arg_6_0)
	arg_6_0:updateAvatar()
	arg_6_0:nodeByName("text_tittle1"):setString(xyd.tables.translation:translation("HIGHEST_HISTORY"))
	arg_6_0:nodeByName("text_shanghai"):setString(xyd.tables.translation:translation("HURT"))
	arg_6_0:nodeByName("text_tittle2"):setString(xyd.tables.translation:translation("NEW_RECORD"))
	arg_6_0:nodeByName("text_nideshanghai"):setString(xyd.tables.translation:translation("YOUR_HURT"))
	arg_6_0:nodeByName("text_dapojilu"):setString(xyd.tables.translation:translation("BREAK_ALLSERVER_RECORD"))
	arg_6_0:nodeByName("text_jiangli"):setString(xyd.tables.translation:translation("ALERT_AWARD_NAME"))
	arg_6_0:nodeByName("label_lv"):setString(arg_6_0.player_.lev)
	arg_6_0:nodeByName("label_name"):setString(arg_6_0.player_.playerName)
	arg_6_0:nodeByName("label_harm"):setString(arg_6_0.harm)
	arg_6_0:nodeByName("label_nideshanghai"):setString(arg_6_0.harm)
	arg_6_0:nodeByName("label_crystal"):setString(arg_6_0.crystal)
	arg_6_0:nodeByName("label_guild_coin"):setString(arg_6_0.guildCoin)
end

function var_0_0.updateAvatar(arg_7_0)
	local var_7_0 = arg_7_0:nodeByName("avatar_container")

	xyd.setAvatarClip(var_7_0, arg_7_0.player_.avatarId, 1)

	local var_7_1 = "images/avatar_frames/" .. xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarFrameId] .. ".png"

	if arg_7_0.player_.avatarFrame and arg_7_0.player_.avatarFrame ~= 0 then
		var_7_1 = "images/avatar_frames/" .. xyd.tables.avatar.icon_[arg_7_0.player_.avatarFrame] .. ".png"
	end

	local var_7_2 = xyd.AssetLoader.get():loadSprite(var_7_1)

	var_7_2:setPosition(40, 40)
	arg_7_0:nodeByName("avatar_frame"):addChild(var_7_2)
end

function var_0_0.playEffect(arg_8_0)
	if not arg_8_0.effect_ then
		local var_8_0 = "skeletons/ui_effect/common_effect_spin3/common_effect_spin3"
		local var_8_1 = var_8_0 .. ".json"
		local var_8_2 = var_8_0 .. ".atlas"

		arg_8_0.effect_ = var_0_1.new(var_8_1, var_8_2, 1)

		arg_8_0.effect_:pos(0, 0)
		arg_8_0.effect_:addTo(arg_8_0:nodeByName("effect_node"))
	end

	arg_8_0.effect_:play(nil, true)
end

return var_0_0
