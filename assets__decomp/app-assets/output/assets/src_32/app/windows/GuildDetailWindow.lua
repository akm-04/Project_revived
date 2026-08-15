local var_0_0 = class("GuildDetailWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.guildInfo = arg_1_2.guild_info
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("txt_name"):setString(var_0_1:translation("GUILD_DETAIL_TITLE_TEXT"))
	arg_4_0:nodeByName("lev_text"):setString(var_0_1:translation("GUILD_LEV_LIMIT_TEXT"))
	arg_4_0:nodeByName("declaration_text"):setString(var_0_1:translation("GUILD_DECLRATION_TEXT"))
	arg_4_0:nodeByName("live_text"):setString(var_0_1:translation("GUILD_LIVE_TEXT"))
	arg_4_0:nodeByName("num_text"):setString(var_0_1:translation("GUILD_STAFF_NUM_TEXT"))
	arg_4_0:nodeByName("guild_chief_text"):setString(var_0_1:translation("GUILD_CHIEF_TEXT"))
	arg_4_0:nodeByName("guild_id_text"):setString(var_0_1:translation("GUILD_ID_TEXT"))
	arg_4_0:nodeByName("rank_text"):setString(var_0_1:translation("GUILD_RANK_TEXT"))
	arg_4_0:nodeByName("lev_txt"):setString(arg_4_0.guildInfo.min_allow_level)
	arg_4_0:nodeByName("declaration_txt"):setString(arg_4_0.guildInfo.des)
	arg_4_0:nodeByName("live_txt"):setString(arg_4_0.guildInfo.three_huoyue)
	arg_4_0:nodeByName("num_txt"):setString(arg_4_0.guildInfo.member_num)
	arg_4_0:nodeByName("guild_chief_txt"):setString(arg_4_0.guildInfo.guild_leader_name)
	arg_4_0:nodeByName("guild_id_txt"):setString(arg_4_0.guildInfo.guild_id)
	arg_4_0:nodeByName("rank_txt"):setString(arg_4_0.guildInfo.guild_rank)
	arg_4_0:nodeByName("guild_name_txt"):setString(arg_4_0.guildInfo.name)
	arg_4_0:nodeByName("icon_container"):setContentSize(125, 125)
	arg_4_0:setTeamAvatar(arg_4_0:nodeByName("icon_container"), arg_4_0.guildInfo.icon)
end

function var_0_0.setTeamAvatar(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = xyd.AssetLoader:get():loadSprite("windows/corporation_window/team_icon_window/icon_bg.png")

	xyd.displaySpriteOnContainer(var_5_0, arg_5_1, false)
	var_5_0:setScale(1)

	local var_5_1 = "images/icon/skill_icon/" .. arg_5_2 .. "_icon.png"
	local var_5_2 = xyd.AssetLoader.get():loadSprite(var_5_1)
	local var_5_3 = arg_5_1:getContentSize()
	local var_5_4 = arg_5_1:getContentSize().width
	local var_5_5 = arg_5_1:getContentSize().height
	local var_5_6 = xyd.AssetLoader:get():loadSprite("images/avatars/mask1.png")

	var_5_6:setPosition(var_5_4 / 2, var_5_5 / 2 + 1)
	var_5_6:setAnchorPoint(cc.p(0.5, 0.5))
	var_5_6:setScale(var_5_5 / var_5_6:getHeight())

	local var_5_7 = cc.ClippingNode:create()

	var_5_7:setStencil(var_5_6)
	var_5_7:setInverted(true)
	var_5_7:setAlphaThreshold(0)
	var_5_7:addChild(var_5_2)
	var_5_2:align(display.CENTER, var_5_3.width / 2, var_5_3.height / 2 + 1)
	var_5_2:scale(var_5_3.width / var_5_2:getWidth())
	arg_5_1:addChild(var_5_7)

	local var_5_8 = xyd.AssetLoader:get():loadSprite("windows/corporation_window/team_icon_window/icon_bg2.png")
	local var_5_9 = clone(var_5_8:getContentSize())
	local var_5_10 = display.newNode()

	var_5_10:setName("view")
	var_5_10:setContentSize(var_5_9)
	var_5_10:setAnchorPoint(cc.p(0, 0))
	var_5_10:setPosition(cc.p(0, 0))
	var_5_10:setScale(var_5_3.width / var_5_9.width, var_5_3.height / var_5_9.height)
	arg_5_1:addChild(var_5_10)
end

return var_0_0
