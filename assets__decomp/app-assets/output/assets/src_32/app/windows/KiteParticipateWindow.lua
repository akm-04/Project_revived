local var_0_0 = class("KiteParticipateWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.playerLev = arg_1_0.selfPlayer.lev
	arg_1_0.playerId = arg_1_0.selfPlayer.playerID
	arg_1_0.playerName = arg_1_0.selfPlayer.playerName
	arg_1_0.kite = xyd.ModelManager.get():loadModel(xyd.ModelType.KITE)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:nodeByName("tip_txt"):setString(var_0_1:translation("ELECTION_TIP"))
	arg_2_0:nodeByName("hero_name"):setString(arg_2_0.playerName)

	local var_2_0 = {
		avatar_id = arg_2_0.selfPlayer:getMyCurrentAvatarID(),
		avatar_frame_id = arg_2_0.selfPlayer.avatarFrame
	}

	xyd.setPlayerAvatar(arg_2_0:nodeByName("hero_avtar"), var_2_0)
	arg_2_0:initEditBox()
	arg_2_0:nodeByName("confirm_btn"):addTouchEventListener(function(arg_3_0, arg_3_1)
		if arg_3_1 == ccui.TouchEventType.ended then
			local var_3_0 = {
				content = arg_2_0.message
			}

			if not var_3_0.content or var_3_0.content == "" then
				var_3_0.content = var_0_1:translation("ELECTION_MANIFESTO")
			end

			arg_2_0.kite:signUpKiteKing(var_3_0, function(arg_4_0, arg_4_1)
				if arg_4_0 == xyd.error.OK then
					local var_4_0 = xyd.WindowManager.get():getWindow("kite_election")

					var_4_0:nodeByName("no_one_participate_txt"):setVisible(false)

					var_4_0.have_signed_up = 1
					var_4_0.rank = arg_4_1.self_rank
					var_4_0.voteNum = arg_4_1.self_info.votes_num

					var_4_0:updateSelfInfo()

					var_4_0.electionListItems = arg_4_1.rank_list

					var_4_0.electionList:reload()
					xyd.WindowManager.get():closeWindow(arg_2_0)
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("SIGN_UP_SUCCEED")
					})
				end
			end)
		end
	end)
end

function var_0_0.initEditBox(arg_5_0)
	arg_5_0:nodeByName("edit_desc"):setString("")

	local var_5_0 = "windows/login/transparent.png"

	arg_5_0.editbox_ = ccui.EditBox:create(cc.size(506, 140), var_5_0)

	arg_5_0:nodeByName("edit_container"):addChild(arg_5_0.editbox_)
	arg_5_0.editbox_:setAnchorPoint(cc.p(0, 0))
	arg_5_0.editbox_:setPosition(0, 0)
	arg_5_0.editbox_:registerScriptEditBoxHandler(handler(arg_5_0, arg_5_0.inputboxEventHandler))
	arg_5_0.editbox_:setInputFlag(3)

	if not arg_5_0.message or arg_5_0.message == "" then
		arg_5_0:nodeByName("edit_desc"):setString(var_0_1:translation("ELECTION_MANIFESTO"))
	else
		arg_5_0:nodeByName("edit_desc"):setString(arg_5_0.message)
	end
end

function var_0_0.inputboxEventHandler(arg_6_0, arg_6_1)
	if arg_6_1 == "began" then
		if not arg_6_0.message or arg_6_0.message == "" then
			arg_6_0:nodeByName("edit_desc"):setString("")
		else
			arg_6_0.editbox_:setText(arg_6_0:nodeByName("edit_desc"):getString())
			arg_6_0:nodeByName("edit_desc"):setString("")
		end
	end

	if arg_6_1 == "return" then
		local var_6_0 = arg_6_0.editbox_:getText()

		if var_6_0 == "" then
			arg_6_0.message = ""

			arg_6_0:nodeByName("edit_desc"):setString(var_0_1:translation("ELECTION_MANIFESTO"))
		else
			if xyd.utf8len(var_6_0) > 20 then
				var_6_0 = xyd.getTextstr(var_6_0, 1, 20)
			end

			arg_6_0.message = var_6_0

			arg_6_0:nodeByName("edit_desc"):setString(var_6_0)
		end

		arg_6_0.editbox_:setText("")
		arg_6_0.editbox_:setVisible(true)
	end
end

function var_0_0.didOpen(arg_7_0, arg_7_1)
	var_0_0.super:didOpen(arg_7_1)
	arg_7_0:addBlockLayer(cc.c4b(0, 0, 0, 225), true)
end

return var_0_0
