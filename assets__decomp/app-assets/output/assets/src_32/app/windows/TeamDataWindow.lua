local var_0_0 = class("TeamDataWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = var_0_1:translation("TEAM_MEMBER")
local var_0_3 = var_0_1:translation("TEAM_PRESIDENT")
local var_0_4 = var_0_1:translation("TEAM_VICE_PRESIDENT")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0:setTouchSwallowEnabled(false)

	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
end

function var_0_0.delegate(arg_2_0, arg_2_1, arg_2_2, arg_2_3)
	local var_2_0 = arg_2_0.guild.guild_data

	if cc.ui.UIListView.COUNT_TAG == arg_2_2 then
		return #var_2_0
	elseif cc.ui.UIListView.CELL_TAG == arg_2_2 then
		if arg_2_3 > #var_2_0 then
			return nil
		end

		local var_2_1 = arg_2_0.listView_:dequeueItem()

		if not var_2_1 then
			var_2_1 = arg_2_0.listView_:newItem()
		else
			var_2_1:removeAllChildren(true)
		end

		local var_2_2 = false
		local var_2_3 = var_2_0[arg_2_3]
		local var_2_4 = display.newNode()
		local var_2_5 = os.date("%m", var_2_3.time)
		local var_2_6 = os.date("%d", var_2_3.time)

		if arg_2_3 ~= 1 then
			local var_2_7 = os.date("%m", var_2_0[arg_2_3 - 1].time)
			local var_2_8 = os.date("%d", var_2_0[arg_2_3 - 1].time)

			if var_2_7 == var_2_5 then
				if var_2_8 == var_2_6 then
					var_2_2 = true
				else
					var_2_2 = false
				end
			else
				var_2_2 = false
			end
		elseif arg_2_3 == 1 then
			var_2_2 = false
		end

		arg_2_0:initCell(var_2_4, var_2_3, var_2_2)

		local var_2_9 = display.newNode()

		if arg_2_0.is_wrong_item == false then
			var_2_9:addChild(var_2_4)
		end

		if var_2_2 == true then
			var_2_9:setContentSize(arg_2_0.item_width, 40)
			var_2_1:setItemSize(arg_2_0.item_width, 40)
		else
			var_2_9:setContentSize(arg_2_0.item_width, 80)
			var_2_1:setItemSize(arg_2_0.item_width, 80)
		end

		if arg_2_0.is_wrong_item == true then
			var_2_9:setContentSize(arg_2_0.item_width, 0)
			var_2_1:setItemSize(arg_2_0.item_width, 0)
		end

		var_2_4:setPosition(10, 0)
		var_2_1:addContent(var_2_9)

		return var_2_1
	end
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super:willOpen(arg_3_1)

	arg_3_0.listView_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_3_0:nodeByName("list_container"):getWidth(), arg_3_0:nodeByName("list_container"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0:nodeByName("list_container")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.listView_:setBounceable(true)

	arg_3_0.item_width = arg_3_0:nodeByName("list_container"):getWidth()
	arg_3_0.is_wrong_item = false

	arg_3_0.listView_:setDelegate(handler(arg_3_0, arg_3_0.delegate))
	arg_3_0.listView_:reload()
	arg_3_0:layout()
	arg_3_0:nodeByName("close_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			local var_4_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_4_0, false)
			xyd.WindowManager.get():closeWindow(arg_3_0)
		end
	end)
end

function var_0_0.layout(arg_5_0)
	arg_5_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)

	arg_5_0:nodeByName("member_text"):setString(arg_5_0.guild.member_nums)
	arg_5_0:nodeByName("id_text"):setString(arg_5_0.guild.guild_id)
	arg_5_0:nodeByName("name_text"):setString(arg_5_0.guild.guild_name)
	arg_5_0:nodeByName("des_text"):setString(arg_5_0.guild.guild_des)
	arg_5_0:nodeByName("title"):setString(var_0_1:translation("SHE_TUAN_TEXT_38"))
	arg_5_0:nodeByName("member_words"):setString(var_0_1:translation("TEAM_MEMBER") .. var_0_1:translation("COLON"))
	arg_5_0:nodeByName("id_words"):setString(string.format(var_0_1:translation("PLAYER_INFO_TEAM_ID"), ""))
	arg_5_0:nodeByName("des_words"):setString(var_0_1:translation("GUILD_DES_WORDS") .. var_0_1:translation("COLON"))

	if xyd.getTextLen(arg_5_0.guild.guild_name) > 5 then
		local var_5_0 = arg_5_0:nodeByName("name_bg"):getContentSize().width
		local var_5_1 = arg_5_0:nodeByName("name_bg"):getContentSize().height

		arg_5_0:nodeByName("name_bg"):setContentSize(var_5_0 + 30 * (xyd.getTextLen(arg_5_0.guild.guild_name) - 6) + 10, var_5_1)
	else
		arg_5_0:nodeByName("name_text"):setPosition(arg_5_0:nodeByName("name_text"):getX(), arg_5_0:nodeByName("name_text"):getY())
	end

	local var_5_2 = {
		size = 24,
		color = cc.c3b(255, 255, 255)
	}
	local var_5_3 = xyd.AssetLoader.get():loadLabel(var_5_2)
	local var_5_4 = arg_5_0:nodeByName("bg"):getContentSize().width
	local var_5_5 = arg_5_0:nodeByName("bg"):getContentSize().height

	var_5_3:setMaxLineWidth(430)
	var_5_3:setString(arg_5_0.guild.guild_des)

	local var_5_6 = var_5_3:getStringNumLines()

	if var_5_6 == 1 then
		arg_5_0:nodeByName("bg"):setContentSize(var_5_4, var_5_5 - 20)
	elseif var_5_6 == 2 then
		arg_5_0:nodeByName("bg"):setContentSize(var_5_4, var_5_5 + 5)
	elseif var_5_6 == 3 then
		arg_5_0:nodeByName("bg"):setContentSize(var_5_4, var_5_5 + 30)
	end

	arg_5_0:updateIcon(arg_5_0.guild.guild_icon)
end

function var_0_0.initCell(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	local var_6_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/corporation_window/team_data_window/team_data_item.csb")
	local var_6_1 = var_6_0:getChildByName("container")
	local var_6_2 = var_6_1:getContentSize()

	var_6_0:setContentSize(var_6_2)
	arg_6_1:setContentSize(var_6_2)
	var_6_0:setName("layout")
	var_6_0:setPosition(cc.p(0, 0))
	arg_6_1:addChild(var_6_0)
	arg_6_1:setTouchSwallowEnabled(false)
	arg_6_1:setTouchEnabled(true)

	local var_6_3 = os.date("%M", arg_6_2.time)
	local var_6_4 = os.date("%H", arg_6_2.time)
	local var_6_5 = os.date("%m", arg_6_2.time)
	local var_6_6 = os.date("%d", arg_6_2.time)

	if arg_6_3 == true then
		var_6_1:getChildByName("data_text"):setVisible(false)
		var_6_1:getChildByName("item_bg"):setVisible(false)
	else
		var_6_1:getChildByName("data_text"):setString(string.format(var_0_1:translation("TEAM_DATA_DATE"), var_6_5, var_6_6))
	end

	var_6_1:getChildByName("time_text"):setString(string.format("%02d:%02d", var_6_4, var_6_3))

	local var_6_7

	if arg_6_2.player_job then
		if arg_6_2.player_job == 0 then
			var_6_7 = var_0_2
		elseif arg_6_2.player_job == 1 then
			var_6_7 = var_0_3
		else
			var_6_7 = var_0_4
		end
	end

	local var_6_8 = var_6_1:getChildByName("detials_text")

	var_6_8:setString("")

	local var_6_9 = {}

	if arg_6_2.type == xyd.GuildDataType.Create then
		table.insert(var_6_9, arg_6_2.player_name)
	elseif arg_6_2.type == xyd.GuildDataType.Message then
		table.insert(var_6_9, var_6_7)
		table.insert(var_6_9, arg_6_2.player_name)
	elseif arg_6_2.type == xyd.GuildDataType.Kick then
		if arg_6_2.player_name and arg_6_2.member_name and var_6_7 then
			table.insert(var_6_9, var_6_7)
			table.insert(var_6_9, arg_6_2.player_name)
			table.insert(var_6_9, arg_6_2.member_name)
		end
	elseif arg_6_2.type == xyd.GuildDataType.Join then
		if arg_6_2.player_name then
			table.insert(var_6_9, arg_6_2.player_name)
		end
	elseif arg_6_2.type == xyd.GuildDataType.AllowJoin then
		if arg_6_2.player_name and arg_6_2.member_name and var_6_7 then
			table.insert(var_6_9, var_6_7)
			table.insert(var_6_9, arg_6_2.player_name)
			table.insert(var_6_9, arg_6_2.member_name)
		end
	elseif arg_6_2.type == xyd.GuildDataType.Quit then
		table.insert(var_6_9, arg_6_2.player_name)
	elseif arg_6_2.type == xyd.GuildDataType.FinalHit then
		table.insert(var_6_9, arg_6_2.chapter_id)
		table.insert(var_6_9, arg_6_2.player_name)
	elseif arg_6_2.type == xyd.GuildDataType.OpenChapter then
		table.insert(var_6_9, arg_6_2.player_name)
		table.insert(var_6_9, arg_6_2.chapter_id)
	elseif arg_6_2.type == xyd.GuildDataType.ResetChapter then
		table.insert(var_6_9, arg_6_2.player_name)
		table.insert(var_6_9, arg_6_2.chapter_id)
	elseif arg_6_2.type == xyd.GuildDataType.Treat then
		-- block empty
	elseif arg_6_2.type == xyd.GuildDataType.TurnLeader then
		table.insert(var_6_9, arg_6_2.player_name)
		table.insert(var_6_9, arg_6_2.member_name)
	elseif arg_6_2.type == xyd.GuildDataType.ViceLeader then
		table.insert(var_6_9, arg_6_2.member_name)
	elseif arg_6_2.type == xyd.GuildDataType.RemovalJob then
		table.insert(var_6_9, arg_6_2.member_name)
	elseif arg_6_2.type == xyd.GuildDataType.ExchangeDrink then
		table.insert(var_6_9, arg_6_2.member_name)
		table.insert(var_6_9, arg_6_2.num)
		table.insert(var_6_9, arg_6_2.huoyue)
	end

	arg_6_0:colorWords(var_6_8, arg_6_2, var_6_9)
end

function var_0_0.colorWords(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	local var_7_0 = display.newNode()
	local var_7_1 = xyd.tables.guildData:words(arg_7_2.type)
	local var_7_2 = 0
	local var_7_3 = 1
	local var_7_4 = false

	while true do
		local var_7_5 = string.find(var_7_1, "{")
		local var_7_6 = string.find(var_7_1, "}")

		if var_7_5 and var_7_6 then
			local var_7_7 = string.sub(var_7_1, 1, var_7_5 - 1)
			local var_7_8 = arg_7_3[var_7_3]

			var_7_3 = var_7_3 + 1
			var_7_1 = string.sub(var_7_1, var_7_6 + 1, #var_7_1)

			if var_7_5 < var_7_6 then
				local var_7_9 = display.newTTFLabel({
					font = "fonts/main_font.ttf",
					size = 22,
					text = var_7_7,
					color = cc.c3b(152, 83, 53),
					align = cc.TEXT_ALIGNMENT_LEFT
				})

				var_7_0:addChild(var_7_9)
				var_7_9:setPosition(var_7_2, 3)
				var_7_9:setAnchorPoint(cc.p(0, 0))

				var_7_2 = var_7_2 + var_7_9:getContentSize().width + 3

				local var_7_10 = display.newTTFLabel({
					font = "fonts/main_font.ttf",
					size = 22,
					text = var_7_8,
					color = cc.c3b(54, 54, 54),
					align = cc.TEXT_ALIGNMENT_LEFT
				})

				var_7_0:addChild(var_7_10)
				var_7_10:setPosition(var_7_2, 3)
				var_7_10:setAnchorPoint(cc.p(0, 0))

				var_7_2 = var_7_2 + var_7_10:getContentSize().width + 3

				if var_7_8 == nil then
					arg_7_0.is_wrong_item = true

					break
				else
					arg_7_0.is_wrong_item = false
				end
			else
				print("wrong data.")

				break
			end
		elseif var_7_5 or var_7_6 then
			print("Wrong data.")

			break
		else
			local var_7_11 = display.newTTFLabel({
				font = "fonts/main_font.ttf",
				size = 22,
				text = var_7_1,
				color = cc.c3b(152, 83, 53),
				align = cc.TEXT_ALIGNMENT_LEFT
			})

			var_7_0:addChild(var_7_11)
			var_7_11:setPosition(var_7_2, 3)
			var_7_11:setAnchorPoint(cc.p(0, 0))

			break
		end
	end

	arg_7_1:addChild(var_7_0)
end

function var_0_0.didOpen(arg_8_0, arg_8_1)
	arg_8_0:addBlockLayer()
	var_0_0.super:didOpen(arg_8_1)
end

function var_0_0.scrollListener(arg_9_0, arg_9_1)
	if arg_9_1.name == "began" then
		arg_9_0.startClick_ = true
		arg_9_0.prevY_ = arg_9_1.y
	elseif arg_9_1.name == "moved" and 20 <= math.abs(arg_9_1.y - arg_9_0.prevY_) then
		arg_9_0.startClick_ = false
	end
end

function var_0_0.updateIcon(arg_10_0, arg_10_1)
	print(arg_10_1)

	local var_10_0 = "images/icon/skill_icon/" .. arg_10_1 .. "_icon.png"
	local var_10_1 = arg_10_0:nodeByName("icon_container")
	local var_10_2 = xyd.AssetLoader.get():loadSprite(var_10_0)
	local var_10_3 = var_10_1:getContentSize()

	if not var_10_2 then
		var_10_2 = xyd.AssetLoader.get():loadSprite("images/icon/skill_icon/" .. DEFAULT_ICON .. "_icon.png")
	else
		arg_10_0.iconId = arg_10_1
	end

	local var_10_4 = var_10_1:getContentSize().width
	local var_10_5 = var_10_1:getContentSize().height
	local var_10_6 = xyd.AssetLoader:get():loadSprite("images/avatars/mask1.png")

	var_10_6:setPosition(var_10_4 / 2, var_10_5 / 2)
	var_10_6:setAnchorPoint(cc.p(0.5, 0.5))
	var_10_6:setScale(var_10_5 / var_10_6:getHeight())

	local var_10_7 = cc.ClippingNode:create()

	var_10_7:setStencil(var_10_6)
	var_10_7:setInverted(true)
	var_10_7:setAlphaThreshold(0)
	var_10_7:addChild(var_10_2)
	var_10_2:align(display.CENTER, var_10_3.width / 2, var_10_3.height / 2)
	var_10_2:scale(var_10_3.width / var_10_2:getWidth())
	var_10_1:addChild(var_10_7)

	local var_10_8 = xyd.AssetLoader:get():loadSprite("windows/corporation_window/team_icon_window/icon_bg2.png")
	local var_10_9 = clone(var_10_8:getContentSize())
	local var_10_10 = display.newNode()

	var_10_10:setName("view")
	var_10_10:setContentSize(var_10_9)
	var_10_10:setAnchorPoint(cc.p(0, 0))
	var_10_10:setPosition(cc.p(0, 0))
	var_10_10:setScale(var_10_3.width / var_10_9.width, var_10_3.height / var_10_9.height)
	var_10_1:addChild(var_10_10)
end

return var_0_0
