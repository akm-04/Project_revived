local var_0_0 = class("FifthAnniPartyGiftWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 3

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.model = xyd.ModelManager.get():loadModel(xyd.ModelType.FIFTH_ANNIVERSARY)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.data = {}
end

function var_0_0.willOpen(arg_2_0)
	arg_2_0:layout()
	arg_2_0:setButtonClick()
end

function var_0_0.didOpen(arg_3_0)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("txt_title"):setString(var_0_1:translation("FIFTH_ANNI_PARTY_TEXT_21"))
	arg_4_0:nodeByName("txt_search"):setString(var_0_1:translation("FIFTH_ANNI_PARTY_TEXT_25"))

	arg_4_0.list = cc.ui.UITableView.new({
		async = true,
		itemGap = 18,
		size = arg_4_0:nodeByName("list"):getContentSize(),
		direction = cc.ui.UITableView.DIRECTION_VERTICAL,
		itemSize = cc.size(836, 209)
	}):addTo(arg_4_0:nodeByName("list")):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.list:setDelegate(handler(arg_4_0, arg_4_0.delegate))
	arg_4_0.list:reload()
	arg_4_0:initSearchContainer()
end

function var_0_0.setButtonClick(arg_5_0)
	local var_5_0 = {
		{
			clickFunc = "clickAllRegion",
			name = var_0_1:translation("FIFTH_ANNI_PARTY_TEXT_22")
		},
		{
			clickFunc = "clickFriend",
			name = var_0_1:translation("FIFTH_ANNI_PARTY_TEXT_23")
		},
		{
			clickFunc = "clickGuild",
			name = var_0_1:translation("FIFTH_ANNI_PARTY_TEXT_24")
		},
		{
			clickFunc = "clickSearch",
			name = var_0_1:translation("FIFTH_ANNI_PARTY_TEXT_25")
		}
	}

	for iter_5_0, iter_5_1 in ipairs(var_5_0) do
		local var_5_1 = arg_5_0:nodeByName("btn_" .. iter_5_0)

		var_5_1:getChildByName("txt"):setString(iter_5_1.name)
		var_5_1:addTouchEventListener(function(arg_6_0, arg_6_1)
			if arg_6_1 == ccui.TouchEventType.ended then
				arg_5_0:setButtonsState(iter_5_0)

				if arg_5_0.selectBtnID == iter_5_0 then
					return
				end

				arg_5_0.selectBtnID = iter_5_0

				arg_5_0[iter_5_1.clickFunc](arg_5_0)
			end
		end)
	end

	arg_5_0:nodeByName("btn_search"):addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(arg_7_0, arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			if not arg_5_0.textId or arg_5_0.textId == "" then
				local var_7_0 = var_0_1:translation("FIFTH_ANNI_PARTY_TEXT_26")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_7_0
				})

				return
			end

			if arg_5_0.textId == arg_5_0.selfPlayer.playerID then
				local var_7_1 = var_0_1:translation("FIFTH_ANNI_PARTY_TEXT_40")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_7_1
				})

				return
			end

			local var_7_2 = {
				player_id = arg_5_0.textId
			}

			arg_5_0.model:partyGetPlayerInfo(var_7_2, function(arg_8_0, arg_8_1)
				if arg_8_0 == xyd.error.OK then
					local var_8_0 = {
						player_id = arg_8_1.player_info.player_id,
						player_name = arg_8_1.player_info.player_name,
						player_send_point = arg_8_1.point
					}

					xyd.WindowManager.get():openWindow("fifth_anni_party_gift_select", var_8_0)
				else
					local var_8_1 = var_0_1:translation("FIFTH_ANNI_PARTY_TEXT_27")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_8_1
					})
				end
			end)
		end
	end)

	arg_5_0.selectBtnID = 1

	arg_5_0:setButtonsState(1)
	arg_5_0[var_5_0[1].clickFunc](arg_5_0)
end

function var_0_0.setButtonsState(arg_9_0, arg_9_1)
	for iter_9_0 = 1, 4 do
		if iter_9_0 == arg_9_1 then
			arg_9_0:nodeByName("btn_" .. iter_9_0):setBrightStyle(ccui.BrightStyle.highlight)
		else
			arg_9_0:nodeByName("btn_" .. iter_9_0):setBrightStyle(ccui.BrightStyle.normal)
		end
	end
end

function var_0_0.initSearchContainer(arg_10_0)
	local var_10_0 = arg_10_0:nodeByName("bg_input"):getContentSize()
	local var_10_1 = cc.size(var_10_0.width - 16, var_10_0.height - 8)

	arg_10_0.editBox = ccui.EditBox:create(var_10_1, "windows/login/transparent.png")

	arg_10_0.editBox:setAnchorPoint(cc.p(0.5, 0.5))
	arg_10_0.editBox:registerScriptEditBoxHandler(handler(arg_10_0, arg_10_0.inputContentbox))
	arg_10_0.editBox:setInputFlag(3)
	arg_10_0.editBox:setInputMode(cc.EDITBOX_INPUT_MODE_PAD_NUMBER)
	arg_10_0.editBox:setMaxLength(40)
	arg_10_0.editBox:addTo(arg_10_0:nodeByName("search_container"))
	arg_10_0.editBox:setPosition(arg_10_0:nodeByName("bg_input"):getPosition())

	arg_10_0.textInput = arg_10_0:nodeByName("txt_input")

	if not arg_10_0.text or arg_10_0.text == "" then
		arg_10_0.textInput:setString(var_0_1:translation("FIFTH_ANNI_PARTY_TEXT_26"))
	else
		arg_10_0.textInput:setString(arg_10_0.text)
	end
end

function var_0_0.inputContentbox(arg_11_0, arg_11_1)
	if arg_11_1 == "began" then
		if not arg_11_0.textId then
			arg_11_0.textInput:setString("")
		else
			arg_11_0.editBox:setText(arg_11_0.textInput:getString())
		end
	elseif arg_11_1 == "return" then
		if not arg_11_0.editBox or tolua.isnull(arg_11_0.editBox) then
			return
		end

		local var_11_0 = arg_11_0.editBox:getText()

		if var_11_0 == "" then
			arg_11_0.textId = nil

			arg_11_0.textInput:setString(var_0_1:translation("FIFTH_ANNI_PARTY_TEXT_26"))

			return
		end

		if xyd.utf8len(var_11_0) > 10 then
			var_11_0 = xyd.utf8str(var_11_0, 1, 10)
		end

		local var_11_1 = tonumber(var_11_0)

		if not var_11_1 then
			local var_11_2 = var_0_1:translation("FIFTH_ANNI_PARTY_TEXT_26")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_11_2
			})

			arg_11_0.textId = nil

			arg_11_0.textInput:setString(var_0_1:translation("FIFTH_ANNI_PARTY_TEXT_26"))
		else
			arg_11_0.textId = math.floor(var_11_1)

			arg_11_0.textInput:setString(arg_11_0.textId)
		end

		arg_11_0.editBox:setText("")
	end
end

function var_0_0.clickAllRegion(arg_12_0)
	arg_12_0.model:partyGetRandomPlayers(nil, function(arg_13_0, arg_13_1)
		if arg_13_0 == xyd.error.OK then
			arg_12_0:nodeByName("list"):setVisible(true)
			arg_12_0:nodeByName("search_container"):setVisible(false)
			arg_12_0.list:removeAllItems()

			arg_12_0.data = {}

			for iter_13_0, iter_13_1 in ipairs(arg_13_1) do
				if iter_13_1.player_info.lev >= xyd.tables.activities:levelReq(1232) and iter_13_1.player_info.player_id ~= arg_12_0.selfPlayer.playerID then
					table.insert(arg_12_0.data, iter_13_1)
				end
			end

			arg_12_0.list:reload()
		end
	end)
end

function var_0_0.clickFriend(arg_14_0)
	arg_14_0:nodeByName("list"):setVisible(true)
	arg_14_0:nodeByName("search_container"):setVisible(false)
	arg_14_0.list:removeAllItems()

	arg_14_0.data = {}

	for iter_14_0, iter_14_1 in ipairs(arg_14_0.socialSystem.friendlist) do
		if iter_14_1.lev >= xyd.tables.activities:levelReq(1232) then
			table.insert(arg_14_0.data, iter_14_1)
		end
	end

	arg_14_0.list:reload()
end

function var_0_0.clickGuild(arg_15_0)
	arg_15_0.guild:loadTeam(function(arg_16_0, arg_16_1)
		if arg_16_0 == xyd.error.OK then
			arg_15_0:nodeByName("list"):setVisible(true)
			arg_15_0:nodeByName("search_container"):setVisible(false)
			arg_15_0.list:removeAllItems()

			arg_15_0.data = {}

			if arg_15_0.guild.members then
				for iter_16_0, iter_16_1 in ipairs(arg_15_0.guild.members) do
					if iter_16_1.lev >= xyd.tables.activities:levelReq(1232) and iter_16_1.player_id ~= arg_15_0.selfPlayer.playerID then
						table.insert(arg_15_0.data, iter_16_1)
					end
				end
			end

			arg_15_0.list:reload()
		end
	end)
end

function var_0_0.clickSearch(arg_17_0)
	arg_17_0:nodeByName("list"):setVisible(false)
	arg_17_0:nodeByName("search_container"):setVisible(true)
end

function var_0_0.delegate(arg_18_0, arg_18_1, arg_18_2, arg_18_3)
	if arg_18_2 == cc.ui.UITableView.COUNT_TAG then
		return math.ceil(#arg_18_0.data / var_0_2)
	elseif arg_18_2 == cc.ui.UITableView.CELL_TAG then
		local var_18_0 = arg_18_0.list:getItem()
		local var_18_1 = arg_18_0:createContent(arg_18_3)

		var_18_0:addContent(var_18_1)

		return var_18_0
	end
end

function var_0_0.createContent(arg_19_0, arg_19_1)
	local var_19_0 = display.newNode()

	for iter_19_0 = 1, var_0_2 do
		local var_19_1 = (arg_19_1 - 1) * var_0_2 + iter_19_0
		local var_19_2 = arg_19_0.data[var_19_1]

		if not var_19_2 then
			break
		end

		if var_19_2.player_info then
			var_19_2 = var_19_2.player_info
		end

		local var_19_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1232/party/gift_item.csb")
		local var_19_4 = var_19_3:getChildByName("container")
		local var_19_5 = var_19_4:getContentSize()
		local var_19_6 = {
			is_new = true,
			avatar_frame_id = var_19_2.avatar_frame_id,
			avatar_id = var_19_2.avatar_id
		}

		xyd.setPlayerAvatar(var_19_4:getChildByName("avatar"), var_19_6)

		local var_19_7 = {
			lev = var_19_2.lev,
			conquerLev = var_19_2.conquer_lev,
			loopID = var_19_2.conquer_loop_id,
			fontColor = cc.c3b(80, 12, 26)
		}

		xyd.setLev(var_19_4:getChildByName("lv"), var_19_7)
		var_19_4:getChildByName("txt_name"):setString(var_19_2.player_name or var_19_2.name)
		var_19_4:getChildByName("txt_region"):setString(string.format(var_0_1:translation("FIFTH_ANNI_PARTY_TEXT_28"), xyd.getPlayerRegion(var_19_2.player_id)))
		var_19_4:setTouchSwallowEnabled(false)
		xyd.nodeEventSample(var_19_4, nil, function()
			if arg_19_0.scrollViewMoved_ then
				return
			end

			arg_19_0.model:partyGetPlayerInfo({
				player_id = var_19_2.player_id
			}, function(arg_21_0, arg_21_1)
				if arg_21_0 == xyd.error.OK then
					local var_21_0 = {
						player_id = arg_21_1.player_info.player_id,
						player_name = arg_21_1.player_info.player_name,
						player_send_point = arg_21_1.point
					}

					xyd.WindowManager.get():openWindow("fifth_anni_party_gift_select", var_21_0)
				end
			end)
		end)
		var_19_3:setPosition((iter_19_0 - 0.5) * var_19_5.width + (iter_19_0 - 1) * 16, 0.5 * var_19_5.height)
		var_19_0:addChild(var_19_3)
	end

	return var_19_0
end

function var_0_0.scrollListener(arg_22_0, arg_22_1)
	if arg_22_1.name == "began" then
		arg_22_0.scrollViewMoved_ = false
		arg_22_0.prevY_ = arg_22_1.y
	elseif arg_22_1.name == "moved" and 10 <= math.abs(arg_22_1.y - arg_22_0.prevY_) then
		arg_22_0.scrollViewMoved_ = true
	end
end

return var_0_0
