local var_0_0 = class("RegionRankItem", function()
	return cc.Node:create()
end)
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_2_0, arg_2_1, arg_2_2)
	arg_2_0:contentView()

	arg_2_0.regionArena = xyd.ModelManager.get():loadModel(xyd.ModelType.REGION_ARENA)
	arg_2_0.myRank = arg_2_1
	arg_2_0.rankNum = arg_2_2
	arg_2_0.container = arg_2_0:contentView():nodeByName("container")
	arg_2_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	arg_2_0:setContentSize(arg_2_0.container:getContentSize())
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:contentView():nodeByName("player_name"):setString(arg_3_0.myRank.name)
	arg_3_0:contentView():nodeByName("player_server"):setString(arg_3_0.myRank.server)
	arg_3_0:contentView():nodeByName("player_lev"):setString(arg_3_0.myRank.level)
	xyd.setPlayerAvatar(arg_3_0:contentView():nodeByName("avatar"), {
		avatar_id = arg_3_0.myRank.avatar_id,
		avatar_frame_id = arg_3_0.myRank.avatar_frame_id
	})

	local var_3_0 = arg_3_0:contentView():nodeByName("rank_1")
	local var_3_1 = arg_3_0:contentView():nodeByName("rank_2")
	local var_3_2 = arg_3_0:contentView():nodeByName("rank_3")

	if arg_3_0.rankNum == 1 then
		var_3_0:setVisible(true)
		var_3_1:setVisible(false)
		var_3_2:setVisible(false)
	elseif arg_3_0.rankNum == 2 then
		var_3_0:setVisible(false)
		var_3_1:setVisible(true)
		var_3_2:setVisible(false)
	elseif arg_3_0.rankNum == 3 then
		var_3_0:setVisible(false)
		var_3_1:setVisible(false)
		var_3_2:setVisible(true)
	else
		var_3_0:setVisible(false)
		var_3_1:setVisible(false)
		var_3_2:setVisible(false)

		local var_3_3 = xyd.AssetLoader.get():loadLabel(nil, "rankFonts")

		var_3_3:setString(arg_3_0.rankNum)
		var_3_3:setAnchorPoint(cc.p(0.5, 0.5))
		var_3_3:setPosition(arg_3_0:contentView():nodeByName("rank_3"):getPosition())
		var_3_3:setScale(0.8)
		var_3_3:addTo(arg_3_0)
	end

	arg_3_0:registerTouchEvent()
end

function var_0_0.registerTouchEvent(arg_4_0)
	local var_4_0 = arg_4_0.container

	arg_4_0:contentView():setTouchEnabled(true)
	arg_4_0:contentView():setTouchSwallowEnabled(false)
	arg_4_0:contentView():addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
		if arg_5_0.name == "began" then
			arg_4_0.prevX_ = arg_5_0.x
			arg_4_0.prevY_ = arg_5_0.y
			arg_4_0.startClick_ = true
		elseif arg_5_0.name == "moved" then
			if math.abs(arg_5_0.y - arg_4_0.prevY_) > 10 or math.abs(arg_5_0.x - arg_4_0.prevX_) > 20 then
				arg_4_0.startClick_ = false
			end
		elseif arg_5_0.name == "ended" and arg_4_0.startClick_ then
			local var_5_0 = {
				other_player_id = arg_4_0.myRank.player_id
			}

			arg_4_0.regionArena:getFormationInfo(var_5_0, function(arg_6_0, arg_6_1)
				if arg_6_0 == xyd.error.OK then
					local var_6_0 = var_4_0:convertToNodeSpace(cc.p(arg_5_0.x, arg_5_0.y))
					local var_6_1 = {
						name = arg_4_0.myRank.name,
						level = arg_4_0.myRank.level,
						avatar_id = arg_4_0.myRank.avatar_id,
						fans = arg_6_1.be_support_num,
						avatar_frame_id = arg_4_0.myRank.avatar_frame_id,
						point = arg_4_0.myRank.point,
						server = "(" .. arg_4_0.myRank.region .. ")" .. arg_4_0.myRank.region_name,
						wins = arg_4_0.myRank.win_times,
						guild = arg_4_0.myRank.guild_name,
						heroes = arg_6_1.heros,
						rank = tonumber(arg_6_1.region_rank)
					}

					if arg_6_1.pet_info then
						var_6_1.pet = arg_6_1.pet_info
					end

					xyd.WindowManager.get():openWindow("region_arena_team_info", {
						is_challenge = true,
						team = arg_6_1,
						enemy_id = arg_4_0.myRank.player_id
					})
				end
			end)
		end

		return true
	end)
end

function var_0_0.contentView(arg_7_0)
	if arg_7_0.contentView_ == nil then
		arg_7_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_7_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/across_arena/region_rank_item.csb"))
		arg_7_0.contentView_:addTo(arg_7_0)
		arg_7_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_7_0.contentView_
end

return var_0_0
