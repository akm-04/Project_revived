local var_0_0 = class("AllServerDamageWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.chapterID = arg_1_2.chapter_id
	arg_1_0.campaignID = arg_1_2.campaignID
end

function var_0_0.scrollListener(arg_2_0, arg_2_1)
	if arg_2_1.name == "began" then
		arg_2_0.scrollViewMoved_ = false
		arg_2_0.prevX_ = arg_2_1.x
		arg_2_0.prevY_ = arg_2_1.y
	elseif arg_2_1.name == "moved" then
		local var_2_0 = 20

		if var_2_0 <= math.abs(arg_2_1.x - arg_2_0.prevX_) or var_2_0 <= math.abs(arg_2_1.y - arg_2_0.prevY_) then
			arg_2_0.scrollViewMoved_ = true
		end
	end
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super:willOpen(arg_3_1)

	arg_3_0.list = cc.ui.UIListView.new({
		viewRect = cc.rect(1, 1, 741, 523),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0:nodeByName("list"))

	arg_3_0:layout()

	local var_3_0 = xyd.tables.teamDungeonSelect:chapterName(arg_3_0.chapterID)
	local var_3_1 = xyd.tables.teamCampaign:campaignName(arg_3_0.campaignID)
	local var_3_2 = var_3_0 .. "·" .. var_3_1

	arg_3_0:nodeByName("title"):setString(var_3_2 .. var_0_1:translation("GUILD_ALL_SERVER_TITLE"))
end

function var_0_0.willClose(arg_4_0, arg_4_1)
	var_0_0.super:willClose(arg_4_1)

	local var_4_0 = xyd.WindowManager.get():getWindow("apply_reward")

	if var_4_0 then
		var_4_0:layout()
	end
end

function var_0_0.layout(arg_5_0)
	arg_5_0.list:removeAllItems()

	local var_5_0 = arg_5_0.guild:getAllFastKillerInfo()
	local var_5_1 = arg_5_0.guild:getBossKillerInfo()
	local var_5_2 = arg_5_0.guild:getAllDamageRankList()

	if var_5_0 then
		local var_5_3 = display.newNode()
		local var_5_4 = arg_5_0.list:newItem()
		local var_5_5 = xyd.AssetLoader.get():loadNodeFromJson("windows/corporation_window/all_server_rank/fast_guild_item.csb")
		local var_5_6 = var_5_5:getChildByName("container")

		var_5_6:getChildByName("fast_title"):setString(var_0_1:translation("FAST_DONE_SHETUAN"))
		var_5_6:getChildByName("guild_name_desc"):setString(var_0_1:translation("SERVER_RANK_SHETUAN_NAME"))
		var_5_6:getChildByName("guild_id_desc"):setString(var_0_1:translation("GUILD_ID_DESC"))
		var_5_6:getChildByName("tongguan_time_desc"):setString(var_0_1:translation("TONGGUAN_TIME_DESC"))

		local var_5_7 = xyd.tables.teamDungeonSelect:chapterName(arg_5_0.chapterID)

		var_5_6:getChildByName("chapter_name"):setString(var_5_7 .. var_0_1:translation("GUILD_ALL_SERVER_TITLE"))
		var_5_6:getChildByName("guild_name"):setString(var_5_0.name)
		var_5_6:getChildByName("guild_id_txt"):setString(tostring(var_5_0.guild_id))
		xyd.setSkillBorder(var_5_6:getChildByName("guild_avatar"), var_5_0.icon, 0)

		local var_5_8 = var_5_0.cost_time
		local var_5_9 = math.floor(var_5_8 / 86400)
		local var_5_10 = math.floor(var_5_8 % 86400 / 3600)
		local var_5_11 = math.floor(var_5_8 % 86400 % 3600 / 60)
		local var_5_12 = ""

		if var_5_9 > 0 then
			var_5_12 = var_5_12 .. var_5_9 .. var_0_1:translation("DAY")
		end

		if var_5_10 > 0 then
			var_5_12 = var_5_12 .. var_5_10 .. var_0_1:translation("UNIT_HOUR")
		end

		if var_5_11 > 0 then
			var_5_12 = var_5_12 .. var_5_11 .. var_0_1:translation("UNIT_MINUTE")
		end

		var_5_6:getChildByName("tongguan_time_txt"):setString(var_5_12)
		var_5_5:addTo(var_5_3)
		var_5_5:setContentSize(740, 190)
		var_5_3:setContentSize(740, 190)
		var_5_3:setAnchorPoint(cc.p(0, 0))
		var_5_4:addContent(var_5_3)
		var_5_4:setItemSize(740, 190)
		arg_5_0.list:addItem(var_5_4)
	end

	if var_5_1 then
		local var_5_13 = display.newNode()
		local var_5_14 = arg_5_0.list:newItem()
		local var_5_15 = xyd.AssetLoader.get():loadNodeFromJson("windows/corporation_window/all_server_rank/first_killed_item.csb")
		local var_5_16 = var_5_15:getChildByName("container")

		var_5_16:getChildByName("first_kill_title"):setString(var_0_1:translation("FIRST_KILL_TITLE"))
		var_5_16:getChildByName("kill_time_desc"):setString(var_0_1:translation("KILL_TIME_DESC"))
		var_5_16:getChildByName("lai_zi"):setString(var_0_1:translation("LAI_ZI"))
		var_5_16:getChildByName("name_txt"):setString(var_5_1.player_name)
		var_5_16:getChildByName("guild_name_txt"):setString(var_5_1.guild_name)
		var_5_16:getChildByName("lev"):setString(var_5_1.lev)

		local var_5_17 = var_5_1.time
		local var_5_18 = os.date("%Y", var_5_17)
		local var_5_19 = os.date("%m", var_5_17)
		local var_5_20 = os.date("%d", var_5_17)
		local var_5_21 = var_5_18 .. var_0_1:translation("YEAR") .. var_5_19 .. var_0_1:translation("MONTH") .. var_5_20 .. var_0_1:translation("DAY")

		var_5_16:getChildByName("kill_time_txt"):setString(var_5_21)
		xyd.setPlayerAvatar(var_5_16:getChildByName("avatar"), {
			showLevel = false,
			avatar_id = var_5_1.avatar_id,
			avatar_frame_id = var_5_1.avatar_frame_id
		})

		if var_5_1.conquer_lev and var_5_1.conquer_lev > 0 then
			local var_5_22 = {
				x = -1.5,
				y = 2.5
			}

			xyd.setConquerLev(var_5_1.conquer_lev, var_5_16:getChildByName("lev"), var_5_16:getChildByName("avatar_kuang"), var_5_22, false, 1, nil, var_5_1.conquer_loop_id)
		else
			var_5_16:getChildByName("lev"):setString(var_5_1.lev)
		end

		var_5_15:addTo(var_5_13)
		var_5_15:setContentSize(740, 178)
		var_5_13:setContentSize(740, 178)
		var_5_14:addContent(var_5_13)
		var_5_14:setItemSize(740, 178)
		arg_5_0.list:addItem(var_5_14)
	end

	if var_5_2 and next(var_5_2) then
		local var_5_23 = display.newNode()
		local var_5_24 = arg_5_0.list:newItem()
		local var_5_25 = xyd.AssetLoader.get():loadNodeFromJson("windows/corporation_window/all_server_rank/highest_damage_title.csb")

		var_5_25:getChildByName("container"):getChildByName("title"):setString(var_0_1:translation("ALL_SERVER_HIGHEST_RECORD"))
		var_5_25:addTo(var_5_23)
		var_5_23:setContentSize(724, 50)
		var_5_24:addContent(var_5_23)
		var_5_24:setItemSize(724, 50)
		arg_5_0.list:addItem(var_5_24)

		for iter_5_0 = 1, #var_5_2 do
			local var_5_26 = var_5_2[iter_5_0]
			local var_5_27 = display.newNode()
			local var_5_28 = arg_5_0.list:newItem()
			local var_5_29 = xyd.AssetLoader.get():loadNodeFromJson("windows/corporation_window/all_server_rank/highest_damage_item.csb")
			local var_5_30 = var_5_29:getChildByName("container")

			var_5_30:getChildByName("one_time_damage_desc"):setString(var_0_1:translation("ONE_TIME_DAMAGE"))
			var_5_30:getChildByName("lai_zi"):setString(var_0_1:translation("LAI_ZI"))

			local var_5_31, var_5_32 = var_5_30:getChildByName("rank_pos"):getPosition()

			xyd.setPlayerAvatar(var_5_30:getChildByName("avatar"), {
				showLevel = false,
				avatar_id = var_5_26.avatar_id,
				avatar_frame_id = var_5_26.avatar_frame_id
			})

			if var_5_26.conquer_lev and var_5_26.conquer_lev > 0 then
				local var_5_33 = {
					x = -1.5,
					y = 2.5
				}

				xyd.setConquerLev(var_5_26.conquer_lev, var_5_30:getChildByName("lev"), var_5_30:getChildByName("avatar_kuang"), var_5_33, false, 1, nil, var_5_26.conquer_loop_id)
			else
				var_5_30:getChildByName("lev"):setString(var_5_26.lev)
			end

			var_5_30:getChildByName("guild_name_txt"):setString(var_5_26.guild_name)
			var_5_30:getChildByName("player_name"):setString(var_5_26.player_name)
			var_5_30:getChildByName("damage_txt"):setString(math.floor(var_5_26.damage))

			if var_5_26.rank <= 3 then
				local var_5_34 = xyd.AssetLoader.get():loadSprite("windows/corporation_window/damage_rank/" .. var_5_26.rank .. ".png")

				var_5_34:setAnchorPoint(cc.p(0.5, 0.5))
				var_5_34:addTo(var_5_30)
				var_5_34:setPosition(var_5_31, var_5_32)
			else
				local var_5_35 = xyd.AssetLoader.get():loadLabel(nil, "bonus")

				var_5_35:setString(var_5_26.rank)
				var_5_35:setAnchorPoint(cc.p(0.5, 0.5))
				var_5_35:addTo(var_5_30)
				var_5_35:setPosition(var_5_31, var_5_32)
			end

			local var_5_36 = var_5_26.partners

			for iter_5_1, iter_5_2 in ipairs(var_5_36) do
				local var_5_37 = iter_5_2.color
				local var_5_38 = iter_5_2.star
				local var_5_39 = iter_5_2.lev
				local var_5_40 = tonumber(iter_5_2.table_id)
				local var_5_41 = var_5_30:getChildByName("hero" .. iter_5_1)
				local var_5_42 = false

				if iter_5_2.twice_awake_stage and iter_5_2.twice_awake_stage == xyd.AwakeTwiceStage.COMPLETE then
					var_5_42 = true
				end

				if iter_5_2.current_skin_id and iter_5_2.current_skin_id ~= 0 then
					xyd.setAvatarBorder(var_5_40, var_5_41, var_5_37, var_5_38, var_5_42, nil, iter_5_2.current_skin_id, true)
				else
					xyd.setAvatarBorder(var_5_40, var_5_41, var_5_37, var_5_38, var_5_42, nil, nil, true)
				end

				local var_5_43 = xyd.AssetLoader.get():loadSprite("windows/corporation_window/all_server_rank/lev_bg.png")
				local var_5_44 = 0.6818181818181818

				var_5_43:setScaleY(var_5_44)
				var_5_43:setScaleX(0.55)
				var_5_43:addTo(var_5_41)
				var_5_43:setAnchorPoint(cc.p(0, 0.5))
				var_5_43:setPosition(3, 20)

				local var_5_45 = {
					size = 12,
					color = cc.c3b(255, 255, 255)
				}
				local var_5_46 = xyd.AssetLoader.get():loadLabel(var_5_45)

				var_5_46:setString(var_5_39)
				var_5_46:addTo(var_5_41)
				var_5_46:setAnchorPoint(cc.p(0.5, 0.5))
				var_5_46:setPosition(15, 20)
			end

			var_5_29:setContentSize(724, 177)
			var_5_27:addChild(var_5_29)
			var_5_27:setContentSize(724, 177)
			var_5_28:addContent(var_5_27)
			var_5_28:setItemSize(724, 180)
			arg_5_0.list:addItem(var_5_28)
		end
	end

	arg_5_0.list:reload()
end

function var_0_0.setAvatar(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4)
	local var_6_0 = display.newNode()

	var_6_0:setContentSize(60, 60)
	xyd.setAvatarClip(var_6_0, arg_6_1)
	var_6_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_6_0:setPosition(arg_6_2, arg_6_3)
	var_6_0:addTo(arg_6_4)

	local var_6_1 = arg_6_4:getChildByName("avatar_kuang")
	local var_6_2 = var_6_1:getLocalZOrder()

	var_6_0:setLocalZOrder(var_6_2)
	var_6_1:setLocalZOrder(var_6_2 + 1)
	arg_6_4:getChildByName("lev"):setLocalZOrder(var_6_2 + 2)
end

function var_0_0.didOpen(arg_7_0, arg_7_1)
	var_0_0.super:didOpen(arg_7_1)
	arg_7_0:addBlockLayer()
end

return var_0_0
