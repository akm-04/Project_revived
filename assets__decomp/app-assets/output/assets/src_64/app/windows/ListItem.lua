local var_0_0 = class("ListItem", function()
	return cc.Node:create()
end)

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()
end

function var_0_0.contentView(arg_3_0)
	if arg_3_0.contentView_ == nil then
		arg_3_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_3_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/mailbox/mailbox_onekey_item.csb"))
		arg_3_0.contentView_:addTo(arg_3_0)
		arg_3_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_3_0.contentView_
end

function var_0_0.setParams(arg_4_0, arg_4_1, arg_4_2)
	arg_4_0.contentView_:nodeByName("num"):setString("X" .. arg_4_2)

	local var_4_0 = ""

	if arg_4_1 == "mana" then
		var_4_0 = "images/icon/eco/jinbi.png"
	elseif arg_4_1 == "crystal" then
		var_4_0 = "images/icon/eco/yuanbao.png"
	elseif arg_4_1 == "arena_coin" then
		var_4_0 = "images/icon/eco/shell.png"
	elseif arg_4_1 == "top_coin" then
		var_4_0 = "images/icon/eco/top_coin.png"
	elseif arg_4_1 == "guild_coin" then
		var_4_0 = "images/icon/eco/guild_coin.png"
	elseif arg_4_1 == "region_coin" then
		var_4_0 = "images/icon/eco/region_coin.png"
	elseif arg_4_1 == "honor_coin" then
		var_4_0 = "images/icon/eco/war_coin.png"
	elseif arg_4_1 == "march_coin" then
		var_4_0 = "images/icon/eco/march_coin.png"
	elseif arg_4_1 == "paradise_coin" then
		var_4_0 = "images/icon/eco/illusion_coin.png"
	elseif arg_4_1 == "god_war_coin" then
		var_4_0 = "images/icon/eco/academy_coin.png"
	elseif arg_4_1 == "spirit_stone" then
		var_4_0 = "images/icon/eco/spirit_stone.png"
	elseif arg_4_1 == "magic_liquid" then
		var_4_0 = "images/icon/eco/magic_liquid.png"
	elseif arg_4_1 == "magic_dust" then
		var_4_0 = "images/icon/eco/magic_dust.png"
	elseif arg_4_1 == "magic_energy" then
		var_4_0 = "images/icon/eco/magic_energy.png"
	elseif arg_4_1 == "friend_medal" then
		var_4_0 = "images/icon/eco/gay_coin.png"
	elseif arg_4_1 == "team_dungeon_coin" then
		var_4_0 = "images/icon/eco/team_dungeon_coin.png"
	else
		arg_4_0.contentView_:nodeByName("item"):removeAllChildren()
		xyd.setItemBorder(arg_4_0.contentView_:nodeByName("item"), arg_4_1)

		return
	end

	if var_4_0 ~= "" then
		arg_4_0.contentView_:nodeByName("item"):removeAllChildren()

		local var_4_1 = xyd.AssetLoader.get():loadSprite(var_4_0)
		local var_4_2 = var_4_1:getContentSize()
		local var_4_3 = arg_4_0.contentView_:nodeByName("item"):getContentSize()

		var_4_1:addTo(arg_4_0.contentView_:nodeByName("item"))
		var_4_1:setAnchorPoint(cc.p(0, 0))
		var_4_1:setPosition(cc.p(0, 0))
		var_4_1:setScale(var_4_3.width / var_4_2.width, var_4_3.width / var_4_2.height)
	end
end

return var_0_0
