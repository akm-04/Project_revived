local var_0_0 = class("FourthAnniPaintVoteWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.info = arg_1_2
	arg_1_0.playerInfo = arg_1_2.player_info
	arg_1_0.playerID = arg_1_2.player_id
	arg_1_0.voteItem = xyd.tables.misc:getValue("activity_anni_4th_vote_ticket")
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:updateLeft()
	arg_2_0:updateRight()
	arg_2_0:addBlockLayer()
end

function var_0_0.updateLeft(arg_3_0)
	arg_3_0:nodeByName("voted_num"):setString(arg_3_0.info.vote_num)
	arg_3_0:nodeByName("des"):setString(var_0_1:translation("FOURTH_ANNI_PAINT_TXT5"))

	local var_3_0 = arg_3_0:nodeByName("container")

	xyd.setPlayerAvatar(var_3_0:getChildByName("icon_container"), arg_3_0.playerInfo)

	if arg_3_0.playerInfo.conquer_lev and arg_3_0.playerInfo.conquer_lev > 0 then
		var_3_0:getChildByName("lev_txt"):setString(arg_3_0.playerInfo.conquer_lev)
		var_3_0:getChildByName("lv_bg"):setVisible(false)

		local var_3_1 = xyd.getLoopBy(arg_3_0.playerInfo.conquer_lev, arg_3_0.playerInfo.conquer_loop_id)

		if var_3_1 < 2 then
			var_3_1 = ""
		end

		var_3_0:getChildByName("conquer_lev_bg"):setTexture("images/conquer_lev" .. var_3_1 .. ".png")
	else
		var_3_0:getChildByName("lev_txt"):setString(arg_3_0.playerInfo.lev)
		var_3_0:getChildByName("conquer_lev_bg"):setVisible(false)
	end

	var_3_0:getChildByName("name_txt"):setString(arg_3_0.playerInfo.player_name)
	var_3_0:getChildByName("region_txt"):setString("S" .. tostring(xyd.getPlayerRegion(arg_3_0.playerID)))
end

function var_0_0.updateRight(arg_4_0)
	arg_4_0:nodeByName("item_name"):setString(xyd.tables.item:name(arg_4_0.voteItem))
	arg_4_0:nodeByName("have_txt"):setString(var_0_1:translation("ITEM_OWN"))
	arg_4_0:nodeByName("jian_txt"):setString(var_0_1:translation("ITEM_OWN_SUFFIX"))
	arg_4_0:nodeByName("vote_tip"):setString(var_0_1:translation("FOURTH_ANNI_PAINT_TXT4"))
	arg_4_0:nodeByName("max_txt"):setString(var_0_1:translation("MAX"))
	arg_4_0:nodeByName("cancel_txt"):setString(var_0_1:translation("CANCEL"))

	arg_4_0.voteItemNum = arg_4_0.backpack:getItemNumByID(arg_4_0.voteItem)
	arg_4_0.voteNum = 0

	arg_4_0:nodeByName("item_num"):setString(arg_4_0.voteItemNum)
	arg_4_0:nodeByName("num_txt"):setString(tostring(arg_4_0.voteNum) .. "/" .. arg_4_0.voteItemNum)
	xyd.setItemBorder(arg_4_0:nodeByName("item_container"), arg_4_0.voteItem)
	xyd.nodeEventSample(arg_4_0:nodeByName("btn_add"), nil, function()
		xyd.playButtonSound()

		if arg_4_0.voteNum >= arg_4_0.voteItemNum then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_1:translation("FOURTH_ANNI_PAINT_TXT9")
			})
		else
			arg_4_0.voteNum = arg_4_0.voteNum + 1

			arg_4_0:nodeByName("num_txt"):setString(tostring(arg_4_0.voteNum) .. "/" .. arg_4_0.voteItemNum)
		end
	end)
	xyd.nodeEventSample(arg_4_0:nodeByName("btn_sub"), nil, function()
		xyd.playButtonSound()

		if arg_4_0.voteNum <= 0 then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_1:translation("FOURTH_ANNI_PAINT_TXT10")
			})
		else
			arg_4_0.voteNum = arg_4_0.voteNum - 1

			arg_4_0:nodeByName("num_txt"):setString(tostring(arg_4_0.voteNum) .. "/" .. arg_4_0.voteItemNum)
		end
	end)
	xyd.nodeEventSample(arg_4_0:nodeByName("btn_max"), nil, function()
		xyd.playButtonSound()

		arg_4_0.voteNum = arg_4_0.voteItemNum

		arg_4_0:nodeByName("num_txt"):setString(tostring(arg_4_0.voteNum) .. "/" .. arg_4_0.voteItemNum)
	end)
	xyd.nodeEventSample(arg_4_0:nodeByName("btn_cancel"), nil, function()
		xyd.playButtonSound()
		xyd.WindowManager.get():closeWindow(arg_4_0)
	end)
	xyd.nodeEventSample(arg_4_0:nodeByName("btn_sure"), nil, function()
		xyd.playButtonSound()

		if arg_4_0.voteNum == 0 then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_1:translation("FOURTH_ANNI_PAINT_TXT20")
			})

			return
		end

		local var_9_0 = {
			txt = var_0_1:translation("FOURTH_ANNI_PAINT_TXT11"),
			rcallback = function()
				xyd.Backend.get():request(xyd.mid.FOURTH_ANNI_PAINT_VOTE, {
					voted_player = arg_4_0.playerID,
					vote_num = arg_4_0.voteNum
				}, function()
					arg_4_0.backpack:addItemsByID(arg_4_0.voteItem, -arg_4_0.voteNum)

					local var_11_0
					local var_11_1

					if arg_4_0.playerInfo.player_id == arg_4_0.selfPlayer.playerID then
						var_11_0 = xyd.WindowManager.get():getWindow("fourth_anni_paint")
					end

					local var_11_2 = xyd.WindowManager.get():getWindow("fourth_anni_paint_visit")

					if var_11_0 then
						var_11_0.voteNum = var_11_0.voteNum + arg_4_0.voteNum

						var_11_0:nodeByName("vote_num"):setString(var_11_0.voteNum)
					end

					if var_11_2 then
						var_11_2.voteNum = var_11_2.voteNum + arg_4_0.voteNum

						var_11_2:nodeByName("vote_num"):setString(var_11_2.voteNum)
					end

					xyd.WindowManager.get():closeWindow(arg_4_0)
				end)
			end
		}

		xyd.WindowManager.get():openWindow("common_alert", var_9_0)
	end)
end

return var_0_0
