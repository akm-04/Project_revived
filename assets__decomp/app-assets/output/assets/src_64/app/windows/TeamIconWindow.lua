local var_0_0 = class("TeamIconWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0:setTouchSwallowEnabled(false)

	arg_1_0.guild = arg_1_2
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("member_text"):setString(arg_3_0.guild.member_nums)
	arg_3_0:nodeByName("id_text"):setString(arg_3_0.guild.guild_id)
	arg_3_0:nodeByName("name_text"):setString(arg_3_0.guild.guild_name)
	arg_3_0:nodeByName("des_text"):setString(arg_3_0.guild.guild_des)
	arg_3_0:nodeByName("master_text"):setString(arg_3_0.guild.guild_leader_name)
	arg_3_0:nodeByName("level_limit_text"):setString(arg_3_0.guild.min_lev)
	arg_3_0:nodeByName("member_words"):setString(var_0_2:translation("TEAM_MEMBER") .. var_0_2:translation("COLON"))
	arg_3_0:nodeByName("id_words"):setString(string.format(var_0_2:translation("PLAYER_INFO_TEAM_ID"), ""))
	arg_3_0:nodeByName("des_words"):setString(var_0_2:translation("GUILD_DES_WORDS") .. var_0_2:translation("COLON"))
	arg_3_0:nodeByName("level_limit_words"):setString(var_0_2:translation("MIN_PLAYER_LEV") .. var_0_2:translation("COLON"))
	arg_3_0:nodeByName("master_words"):setString(var_0_2:translation("TEAM_PRESIDENT") .. var_0_2:translation("COLON"))

	if xyd.getTextLen(arg_3_0.guild.guild_name) > 5 then
		local var_3_0 = arg_3_0:nodeByName("name_bg"):getContentSize().width
		local var_3_1 = arg_3_0:nodeByName("name_bg"):getContentSize().height

		if var_3_0 + 30 * (xyd.getTextLen(arg_3_0.guild.guild_name) - 6) + 10 < 350 then
			arg_3_0:nodeByName("name_bg"):setContentSize(var_3_0 + 30 * (xyd.getTextLen(arg_3_0.guild.guild_name) - 6) + 10, var_3_1)
		end
	end

	local var_3_2 = {
		size = 24,
		color = cc.c3b(255, 255, 255)
	}
	local var_3_3 = xyd.AssetLoader.get():loadLabel(var_3_2)
	local var_3_4 = arg_3_0:nodeByName("container"):getContentSize().width
	local var_3_5 = arg_3_0:nodeByName("container"):getContentSize().height

	if arg_3_0.guild.min_lev == nil then
		arg_3_0:nodeByName("level_limit_text"):setVisible(false)
		arg_3_0:nodeByName("level_limit_words"):setVisible(false)

		var_3_5 = var_3_5 - 30

		arg_3_0:addBlockLayer()
		arg_3_0:nodeByName("des_text"):setPositionY(arg_3_0:nodeByName("des_text"):getPositionY() + 30)
		arg_3_0:nodeByName("des_words"):setPositionY(arg_3_0:nodeByName("des_words"):getPositionY() + 30)
	end

	var_3_3:setMaxLineWidth(430)
	var_3_3:setString(arg_3_0.guild.guild_des)

	local var_3_6 = var_3_3:getStringNumLines()

	if var_3_6 == 1 then
		arg_3_0:nodeByName("container"):setContentSize(var_3_4, var_3_5 + 5)
	elseif var_3_6 == 2 then
		arg_3_0:nodeByName("container"):setContentSize(var_3_4, var_3_5 + 5)
	elseif var_3_6 == 3 then
		arg_3_0:nodeByName("container"):setContentSize(var_3_4, var_3_5 + 30)
	end

	arg_3_0:updateIcon(arg_3_0.guild.guild_icon)
end

function var_0_0.updateIcon(arg_4_0, arg_4_1)
	local var_4_0 = "images/icon/skill_icon/" .. arg_4_1 .. "_icon.png"
	local var_4_1 = arg_4_0:nodeByName("icon_container")
	local var_4_2 = xyd.AssetLoader.get():loadSprite(var_4_0)
	local var_4_3 = var_4_1:getContentSize()

	if not var_4_2 then
		var_4_2 = xyd.AssetLoader.get():loadSprite("images/icon/skill_icon/" .. DEFAULT_ICON .. "_icon.png")
	else
		arg_4_0.iconId = arg_4_1
	end

	local var_4_4 = var_4_1:getContentSize().width
	local var_4_5 = var_4_1:getContentSize().height
	local var_4_6 = xyd.AssetLoader:get():loadSprite("images/avatars/mask1.png")

	var_4_6:setPosition(var_4_4 / 2, var_4_5 / 2)
	var_4_6:setAnchorPoint(cc.p(0.5, 0.5))
	var_4_6:setScale(var_4_5 / var_4_6:getHeight())

	local var_4_7 = cc.ClippingNode:create()

	var_4_7:setStencil(var_4_6)
	var_4_7:setInverted(true)
	var_4_7:setAlphaThreshold(0)
	var_4_7:addChild(var_4_2)
	var_4_2:align(display.CENTER, var_4_3.width / 2, var_4_3.height / 2)
	var_4_2:scale(var_4_3.width / var_4_2:getWidth())
	var_4_1:addChild(var_4_7)

	local var_4_8 = xyd.AssetLoader:get():loadSprite("windows/corporation_window/team_icon_window/icon_bg2.png")
	local var_4_9 = clone(var_4_8:getContentSize())
	local var_4_10 = display.newNode()

	var_4_10:setName("view")
	var_4_10:setContentSize(var_4_9)
	var_4_10:setAnchorPoint(cc.p(0, 0))
	var_4_10:setPosition(cc.p(0, 0))
	var_4_10:setScale(var_4_3.width / var_4_9.width, var_4_3.height / var_4_9.height)
	var_4_1:addChild(var_4_10)
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	arg_5_0:addBlockLayer(cc.c4b(0, 0, 0, 1))
	var_0_0.super:didOpen(arg_5_1)
end

return var_0_0
