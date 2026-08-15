local var_0_0 = class("TeamTeaTalkReceiveWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	arg_2_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_2_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("title_words"):setString(var_0_2:translation("TEA_TALK_RECEIVE_TITLE"))
	xyd.setItemBorder(arg_3_0:nodeByName("icon_container"), arg_3_0.guild.teaTalkSelfWishInfo.item_id)

	local var_3_0 = #arg_3_0.guild.teaTalkGiftList

	if var_3_0 == 2 then
		arg_3_0:nodeByName("giver_container_3"):setVisible(false)
		arg_3_0:nodeByName("bg"):height(arg_3_0:nodeByName("bg"):getHeight() - 100)
		arg_3_0:nodeByName("background"):setPositionY(arg_3_0:nodeByName("background"):getPositionY() - 50)
		arg_3_0:nodeByName("bg"):setPositionY(arg_3_0:nodeByName("bg"):getPositionY() + 100)
	elseif var_3_0 == 1 then
		arg_3_0:nodeByName("giver_container_3"):setVisible(false)
		arg_3_0:nodeByName("giver_container_2"):setVisible(false)
		arg_3_0:nodeByName("bg"):height(arg_3_0:nodeByName("bg"):getHeight() - 200)
		arg_3_0:nodeByName("background"):setPositionY(arg_3_0:nodeByName("background"):getPositionY() - 100)
		arg_3_0:nodeByName("bg"):setPositionY(arg_3_0:nodeByName("bg"):getPositionY() + 200)
	end

	for iter_3_0 = 1, 3 do
		if arg_3_0.guild.teaTalkGiftList[iter_3_0] then
			local var_3_1 = arg_3_0.guild.teaTalkGiftList[iter_3_0]
			local var_3_2 = arg_3_0:nodeByName("giver_container_" .. iter_3_0)

			xyd.setPlayerAvatar(var_3_2:getChildByName("avatar_container"), {
				showLevel = false,
				avatar_id = var_3_1.avatar_id,
				avatar_frame_id = var_3_1.avatar_frame_id
			})
			var_3_2:getChildByName("name_text"):setString(var_3_1.player_name)
			var_3_2:getChildByName("lev_text"):setString(var_3_1.lev)
			var_3_2:getChildByName("region"):setString("S" .. xyd.getPlayerRegion(var_3_1.player_id))

			if var_3_1.conquer_lev and var_3_1.conquer_lev > 0 then
				local var_3_3 = {
					x = -1.5,
					y = 2.5
				}

				xyd.setConquerLev(var_3_1.conquer_lev, var_3_2:getChildByName("lev_text"), var_3_2:getChildByName("level_bg"), var_3_3, false, 0.75, nil, var_3_1.conquer_loop_id)
			else
				var_3_2:getChildByName("lev_text"):setString(var_3_1.lev)
			end
		end
	end

	local var_3_4 = xyd.tables.item:name(arg_3_0.guild.teaTalkSelfWishInfo.item_id)

	arg_3_0:nodeByName("item_text"):setString(var_3_4 .. " × " .. var_3_0)
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super:didOpen(arg_4_1)
	arg_4_0:addBlockLayer()
end

function var_0_0.didClose(arg_5_0, arg_5_1)
	var_0_0.super:didClose(arg_5_1)
	arg_5_0.guild:teaTalkConfirm(function(arg_6_0, arg_6_1)
		if arg_6_0 == xyd.error.OK then
			if arg_6_1.award then
				xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():addItem({
					itemID = arg_6_1.award.item,
					itemNum = arg_6_1.award.num
				})
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.DRINK_NOTIF
			})
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.FRESH_STONE_QUEST
			})
		end
	end)
end

return var_0_0
