local var_0_0 = class("SelfGuild", import(".BaseModel"))
local var_0_1 = import("framework.scheduler")

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.sentHeros_ = {}
	arg_1_0.rentPets = {}
	arg_1_0.allTeamHeros_ = {}
	arg_1_0.allTeamPets = {}
	arg_1_0.allMarchTeamHeros_ = {}
	arg_1_0.guildCampaignList = {}
	arg_1_0.guildCampaigns = {}
	arg_1_0.old_id = 0
	arg_1_0.selectHeroCounts_ = {}
	arg_1_0.handles_ = {}
	arg_1_0.chapterRewardList = {}
	arg_1_0.chapterDamageRankList = {}
	arg_1_0.guildEquipApplyTimes = 0
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
	arg_2_0:registerEvent(xyd.event.LOAD_SELF_GUILD, handler(arg_2_0, arg_2_0.onloadTeam_))
	arg_2_0:registerEvent(xyd.event.PLAYER_LEVEL_UP, handler(arg_2_0, arg_2_0.clearRentCount_))
end

function var_0_0.onloadTeam_(arg_3_0, arg_3_1)
	local var_3_0 = arg_3_1.params

	arg_3_0.guild_id = var_3_0.guild_id

	if arg_3_0.guild_id ~= nil and arg_3_0.guild_id ~= 0 then
		arg_3_0.guild_icon = var_3_0.icon
		arg_3_0.guild_name = var_3_0.name
		arg_3_0.guild_des = var_3_0.des
		arg_3_0.apply_type = var_3_0.apply_type
		arg_3_0.members = var_3_0.members
		arg_3_0.guild_icon_frame = var_3_0.icon_frame
		arg_3_0.min_lev = var_3_0.min_allow_level
		arg_3_0.huoyue = var_3_0.huoyue

		for iter_3_0, iter_3_1 in pairs(arg_3_0.members) do
			if arg_3_0.selfPlayer.playerID == iter_3_1.player_id then
				arg_3_0.job = iter_3_1.job

				break
			end
		end

		if arg_3_0.old_id ~= arg_3_0.guild_id then
			local var_3_1 = {}

			arg_3_0.old_id = arg_3_0.guild_id
			var_3_1.roomID = arg_3_0.guild_id

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.ROOMID_UPDATE,
				params = var_3_1
			})
		end
	end
end

function var_0_0.inviteToGuild(arg_4_0, arg_4_1, arg_4_2)
	xyd.Backend.get():request(xyd.mid.INVITE_TO_GUILD, arg_4_1, function(arg_5_0, arg_5_1)
		arg_4_2(arg_5_0, arg_5_1)
	end)
end

function var_0_0.acceptInviteToGuild(arg_6_0, arg_6_1, arg_6_2)
	xyd.Backend.get():request(xyd.mid.ACCEPT_INVITE_TO_GUILD, arg_6_1, function(arg_7_0, arg_7_1)
		arg_6_2(arg_7_0, arg_7_1)
	end)
end

function var_0_0.getGuildInfo(arg_8_0, arg_8_1, arg_8_2)
	xyd.Backend.get():request(xyd.mid.GET_GUILD_INFO, arg_8_1, function(arg_9_0, arg_9_1)
		arg_8_2(arg_9_0, arg_9_1)
	end)
end

function var_0_0.sendMessage(arg_10_0, arg_10_1, arg_10_2)
	xyd.Backend.get():request(xyd.mid.MESSAGE_TEAM, arg_10_1, function(arg_11_0)
		arg_10_2(arg_11_0)
	end)
end

function var_0_0.getGuildRank(arg_12_0, arg_12_1)
	xyd.Backend.get():request(xyd.mid.GUILD_RANK, {}, function(arg_13_0, arg_13_1)
		arg_12_1(arg_13_0, arg_13_1)
	end)
end

function var_0_0.clearRentCount_(arg_14_0)
	if arg_14_0.rentCount then
		arg_14_0.rentCount = nil
	end
end

function var_0_0.loadSelfGuild(arg_15_0, arg_15_1)
	if arg_15_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_GUILD) == true then
		xyd.Backend.get():request(xyd.mid.GET_SELF_GUILD, {}, function(arg_16_0, arg_16_1)
			if arg_16_0 == xyd.error.OK then
				if arg_16_1.guild_info and arg_16_1.guild_info.guild_id and arg_16_1.guild_info.guild_id ~= 0 then
					arg_15_0.guild_id = arg_16_1.guild_info.guild_id
					arg_15_0.today_huoyue = arg_16_1.self_info.today_huoyue
					arg_15_0.huoyue = arg_16_1.guild_info.huoyue
					arg_15_0.self_all_huoyue = arg_16_1.self_info.huoyue_num
					arg_15_0.guild_icon = arg_16_1.guild_info.icon
					arg_15_0.guild_name = arg_16_1.guild_info.name
					arg_15_0.guild_des = arg_16_1.guild_info.des
					arg_15_0.apply_type = arg_16_1.guild_info.apply_type
					arg_15_0.member_nums = arg_16_1.member_nums
					arg_15_0.guild_icon_frame = arg_16_1.guild_info.icon_frame
					arg_15_0.min_lev = arg_16_1.guild_info.min_allow_level
					arg_15_0.huoyue = arg_16_1.guild_info.huoyue
					arg_15_0.guild_leader_name = arg_16_1.guild_info.guild_leader_name
					arg_15_0.job = arg_16_1.self_info.job

					if arg_15_0.old_id ~= arg_15_0.guild_id then
						local var_16_0 = {}

						arg_15_0.old_id = arg_15_0.guild_id
						var_16_0.roomID = arg_15_0.guild_id

						xyd.EventDispatcher.get():dispatchEvent({
							name = xyd.event.ROOMID_UPDATE,
							params = var_16_0
						})
					end
				else
					arg_15_0.guild_id = 0
				end
			end

			arg_15_1(arg_16_0, arg_16_1)
		end)
	end
end

function var_0_0.onLoadSelfGuild(arg_17_0, arg_17_1)
	local var_17_0 = arg_17_1.params

	if var_17_0.guild_info and var_17_0.guild_info.guild_id and var_17_0.guild_info.guild_id ~= 0 then
		arg_17_0.guild_id = var_17_0.guild_info.guild_id
		arg_17_0.today_huoyue = var_17_0.self_info.today_huoyue
		arg_17_0.huoyue = var_17_0.guild_info.huoyue
		arg_17_0.self_all_huoyue = var_17_0.self_info.huoyue_num
		arg_17_0.guild_icon = var_17_0.guild_info.icon
		arg_17_0.guild_name = var_17_0.guild_info.name
		arg_17_0.guild_des = var_17_0.guild_info.des
		arg_17_0.join_time = var_17_0.self_info.join_time or 0
		arg_17_0.apply_type = var_17_0.guild_info.apply_type
		arg_17_0.member_nums = var_17_0.member_nums
		arg_17_0.guild_icon_frame = var_17_0.guild_info.icon_frame
		arg_17_0.min_lev = var_17_0.guild_info.min_allow_level
		arg_17_0.guild_leader_name = var_17_0.guild_info.guild_leader_name
		arg_17_0.job = var_17_0.self_info.job

		if arg_17_0.old_id ~= arg_17_0.guild_id then
			local var_17_1 = {}

			arg_17_0.old_id = arg_17_0.guild_id
			var_17_1.roomID = arg_17_0.guild_id

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.ROOMID_UPDATE,
				params = var_17_1
			})
		end
	else
		arg_17_0.guild_id = 0
	end
end

function var_0_0.loadOtherGuild(arg_18_0, arg_18_1, arg_18_2)
	local var_18_0 = arg_18_2 or {}

	xyd.Backend.get():request(xyd.mid.GET_SELF_GUILD, var_18_0, function(arg_19_0, arg_19_1)
		if arg_19_0 == xyd.error.OK then
			if arg_19_1.member_nums then
				arg_18_0.other_guild_id = arg_19_1.guild_info.guild_id
				arg_18_0.other_guild_name = arg_19_1.guild_info.name
				arg_18_0.other_guild_icon = arg_19_1.guild_info.icon
				arg_18_0.other_apply_type = arg_19_1.guild_info.apply_type
				arg_18_0.other_guild_icon_frame = arg_19_1.guild_info.icon_frame
				arg_18_0.other_min_lev = arg_19_1.guild_info.min_allow_level
				arg_18_0.other_guild_des = arg_19_1.guild_info.des
				arg_18_0.other_member_nums = arg_19_1.member_nums
				arg_18_0.other_huoyue = arg_19_1.guild_info.huoyue
				arg_18_0.other_guild_leader = arg_19_1.guild_info.guild_leader
				arg_18_0.other_guild_leader_name = arg_19_1.guild_info.guild_leader_name
			else
				arg_18_0.other_guild_id = 0
			end
		end

		arg_18_1(arg_19_0, arg_19_1)
	end)
end

function var_0_0.loadTeam(arg_20_0, arg_20_1)
	xyd.Backend.get():request(xyd.mid.LOAD_TEAM_BY_ID, {}, function(arg_21_0, arg_21_1)
		arg_20_1(arg_21_0, arg_21_1)
	end)
end

function var_0_0.quitTeam(arg_22_0, arg_22_1)
	xyd.Backend.get():request(xyd.mid.LEAVE_TEAM, {}, function(arg_23_0)
		if arg_23_0 == xyd.error.OK then
			arg_22_0.guild_id = 0

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.DRINK_NOTIF
			})
		end

		arg_22_1(arg_23_0)
	end)
end

function var_0_0.getData(arg_24_0, arg_24_1)
	xyd.Backend.get():request(xyd.mid.GET_DATA_TEAM, {}, function(arg_25_0, arg_25_1)
		if arg_25_0 == xyd.error.OK then
			arg_24_0.guild_data = {}

			if arg_25_1 and arg_25_1.guild_log then
				for iter_25_0, iter_25_1 in pairs(arg_25_1.guild_log) do
					if iter_25_1.type ~= xyd.GuildDataType.Treat then
						table.insert(arg_24_0.guild_data, iter_25_1)
					end
				end

				table.sort(arg_24_0.guild_data, function(arg_26_0, arg_26_1)
					return arg_26_0.time > arg_26_1.time
				end)
			end
		end

		arg_24_1(arg_25_0, arg_25_1)
	end)
end

function var_0_0.setExchangeDrink(arg_27_0, arg_27_1, arg_27_2)
	local var_27_0 = arg_27_1 or {}

	if not var_27_0.num then
		local var_27_1 = 0
	end

	xyd.Backend.get():request(xyd.mid.EXCHANGE_DRINK, var_27_0, function(arg_28_0, arg_28_1)
		if arg_28_0 == xyd.error.OK then
			arg_27_0.normal_drink_times = arg_28_1.drink_info.normal_drink_times
			arg_27_0.huoyue = arg_28_1.guild_huoyue
			arg_27_0.daily_exchange = arg_28_1.drink_info.daily_exchange
			arg_27_0.normal_time = math.floor(arg_28_1.drink_info.normal_time)
		end

		arg_27_2(arg_28_0, arg_28_1)
	end)
end

function var_0_0.loadSentHeros(arg_29_0, arg_29_1)
	xyd.Backend.get():request(xyd.mid.LOAD_SENT_HEROS, {}, function(arg_30_0, arg_30_1)
		if arg_30_0 == xyd.error.OK then
			arg_29_0.sentHeros_ = arg_30_1.heroes
		end

		arg_29_1(arg_30_0, arg_30_1)
	end)
end

function var_0_0.loadRentPets(arg_31_0, arg_31_1)
	xyd.Backend.get():request(xyd.mid.LOAD_RENT_PET, {}, function(arg_32_0, arg_32_1)
		if arg_32_0 == xyd.error.OK then
			arg_31_0.rentPets = arg_32_1.pets
		end

		arg_31_1(arg_32_0, arg_32_1)
	end)
end

function var_0_0.rentHero(arg_33_0, arg_33_1, arg_33_2)
	local var_33_0 = arg_33_1 or {}

	xyd.Backend.get():request(xyd.mid.RENT_HERO, var_33_0, function(arg_34_0, arg_34_1)
		if arg_34_0 == xyd.error.OK then
			arg_33_0.sentHeros_ = arg_34_1.rent_info
		end

		arg_33_2(arg_34_0, arg_34_1)
	end)
end

function var_0_0.rentPet(arg_35_0, arg_35_1, arg_35_2)
	local var_35_0 = arg_35_1 or {}

	xyd.Backend.get():request(xyd.mid.RENT_PET, var_35_0, function(arg_36_0, arg_36_1)
		if arg_36_0 == xyd.error.OK then
			arg_35_0.rentPets = arg_36_1.rent_info
		end

		arg_35_2(arg_36_0, arg_36_1)
	end)
end

function var_0_0.loadApplyList(arg_37_0, arg_37_1)
	xyd.Backend.get():request(xyd.mid.PLAYER_LOAD_APPLY_LIST_TEAM, {}, function(arg_38_0, arg_38_1)
		if arg_38_0 == xyd.error.OK then
			arg_37_0.applyTeams = arg_38_1
		end

		arg_37_1(arg_38_0, arg_38_1)
	end)
end

function var_0_0.loadAllApply(arg_39_0, arg_39_1)
	xyd.Backend.get():request(xyd.mid.LOAD_APPLY_LIST_TEAM, {}, function(arg_40_0, arg_40_1)
		arg_39_0.apply_players = arg_40_1

		arg_39_1(arg_40_0, arg_40_1)
	end)
end

function var_0_0.refuseApply(arg_41_0, arg_41_1, arg_41_2)
	local var_41_0 = arg_41_1 or {}

	xyd.Backend.get():request(xyd.mid.REFUSE_APPLY_TEAM, var_41_0, function(arg_42_0, arg_42_1)
		arg_41_0.apply_players = arg_42_1

		arg_41_2(arg_42_0, arg_42_1)
	end)
end

function var_0_0.acceptApply(arg_43_0, arg_43_1, arg_43_2)
	local var_43_0 = arg_43_1 or {}

	xyd.Backend.get():request(xyd.mid.ACCEPT_APPLY_TEAM, var_43_0, function(arg_44_0, arg_44_1)
		arg_43_0.apply_players = arg_44_1

		arg_43_2(arg_44_0, arg_44_1)
	end)
end

function var_0_0.loadAllTeam(arg_45_0, arg_45_1)
	xyd.Backend.get():request(xyd.mid.LOAD_ALL_TEAMS, {}, function(arg_46_0, arg_46_1)
		if arg_46_0 == xyd.error.OK then
			arg_45_0.allTeams = arg_46_1.guild_infos or {}
		end

		arg_45_1(arg_46_0, arg_46_1)
	end)
end

function var_0_0.getJoinTime(arg_47_0)
	return arg_47_0.join_time or 0
end

function var_0_0.applyTeam(arg_48_0, arg_48_1, arg_48_2)
	local var_48_0 = arg_48_1 or {}

	xyd.Backend.get():request(xyd.mid.APPLY_TEAM, var_48_0, function(arg_49_0, arg_49_1)
		arg_48_2(arg_49_0, arg_49_1)

		arg_48_0.join_time = xyd.ServerTime.get():getServerTime()
	end)
end

function var_0_0.cancelApply(arg_50_0, arg_50_1, arg_50_2)
	local var_50_0 = arg_50_1 or {}

	xyd.Backend.get():request(xyd.mid.CANCEL_APPLY_TEAM, var_50_0, function(arg_51_0, arg_51_1)
		arg_50_2(arg_51_0, arg_51_1)
	end)
end

function var_0_0.createTeam(arg_52_0, arg_52_1, arg_52_2)
	xyd.Backend.get():request(xyd.mid.CREATE_TEAM, arg_52_1, function(arg_53_0)
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.DRINK_NOTIF
		})
		arg_52_2(arg_53_0)
	end)
end

function var_0_0.dissolutionTeam(arg_54_0, arg_54_1)
	xyd.Backend.get():request(xyd.mid.DISSOLUTION_TEAM, {}, function(arg_55_0)
		if arg_55_0 == xyd.error.OK then
			arg_54_0.guild_id = 0
			arg_54_0.selfPlayer.guildID = 0

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.DRINK_NOTIF
			})
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.CLOSE_GUILD_CHAT
			})
		end

		arg_54_1(arg_55_0)
	end)
end

function var_0_0.kickTeam(arg_56_0, arg_56_1, arg_56_2)
	xyd.Backend.get():request(xyd.mid.KICK_TEAM, arg_56_1, function(arg_57_0, arg_57_1)
		if arg_57_0 == xyd.error.OK then
			arg_56_0.members = arg_57_1
			arg_56_0.member_nums = arg_56_0.member_nums - 1
		end

		arg_56_2(arg_57_0, arg_57_1)
	end)
end

function var_0_0.setJob(arg_58_0, arg_58_1, arg_58_2)
	local var_58_0 = arg_58_1 or {}

	xyd.Backend.get():request(xyd.mid.APPOINT_JOB_TEAM, var_58_0, function(arg_59_0, arg_59_1)
		arg_58_2(arg_59_0, arg_59_1)
	end)
end

function var_0_0.getRentBack(arg_60_0, arg_60_1, arg_60_2)
	local var_60_0 = arg_60_1 or {}

	xyd.Backend.get():request(xyd.mid.CANCEL_RENT_HERO, var_60_0, function(arg_61_0, arg_61_1)
		if arg_61_0 == xyd.error.OK then
			arg_60_0.sentHeros_ = arg_61_1.rent_list
		end

		arg_60_2(arg_61_0, arg_61_1)
	end)
end

function var_0_0.getRentPetBack(arg_62_0, arg_62_1, arg_62_2)
	local var_62_0 = arg_62_1 or {}

	xyd.Backend.get():request(xyd.mid.CANCEL_RENT_PET, var_62_0, function(arg_63_0, arg_63_1)
		if arg_63_0 == xyd.error.OK then
			arg_62_0.rentPets = arg_63_1.rent_list
		end

		arg_62_2(arg_63_0, arg_63_1)
	end)
end

function var_0_0.loadAllTeamHeros(arg_64_0, arg_64_1, arg_64_2)
	local var_64_0 = arg_64_1 or {}

	if not var_64_0.load_place then
		var_64_0.load_place = 0
	end

	if arg_64_0.rentCount and not var_64_0.rent_type then
		var_64_0.rent_count = arg_64_0.rentCount
	end

	var_64_0.campaign_type = var_64_0.campaign_type or var_64_0.rent_type

	if arg_64_0.loadPlace and var_64_0.load_place ~= arg_64_0.loadPlace then
		var_64_0.rent_count = nil
		arg_64_0.rentCount = nil
	end

	xyd.Backend.get():request(xyd.mid.GET_RENT_HEROS, var_64_0, function(arg_65_0, arg_65_1)
		if arg_65_0 == xyd.error.OK then
			local var_65_0

			if arg_65_1.guild_rent_heroes then
				var_65_0 = arg_65_1.guild_rent_heroes
			end

			local var_65_1 = arg_65_1.tutor_rent_heroes

			if var_65_0 and var_65_0.rent_type and var_65_0.rent_type == xyd.CampaignType.MARCH then
				arg_64_0.allMarchTeamHeros_ = var_65_0.partners or {}
			end

			if not arg_64_0.rentCount or var_65_0 and arg_64_0.rentCount ~= var_65_0.rent_count then
				arg_64_0.allTeamHeros_ = var_65_0 and var_65_0.partners or {}
				arg_64_0.rentCount = arg_65_1.rent_count
			end

			arg_64_0.tutorRentHeroes = var_65_1

			if var_64_0.load_place and var_64_0.load_place == 1 then
				arg_64_0.loadPlace = 1
			else
				arg_64_0.loadPlace = 0
			end
		end

		arg_64_2(arg_65_0, arg_65_1)
	end)
end

function var_0_0.loadAllTeamPets(arg_66_0, arg_66_1, arg_66_2)
	local var_66_0 = arg_66_1 or {}

	if not var_66_0.load_place then
		var_66_0.load_place = 0
	end

	if arg_66_0.rentPetCount and not var_66_0.rent_type then
		var_66_0.rent_count = arg_66_0.rentPetCount
	end

	if arg_66_0.loadPetPlace and var_66_0.load_place ~= arg_66_0.loadPetPlace then
		var_66_0.rent_count = nil
		arg_66_0.rentPetCount = nil
	end

	xyd.Backend.get():request(xyd.mid.LOAD_CAN_RENT_PET_LIST, var_66_0, function(arg_67_0, arg_67_1)
		if arg_67_0 == xyd.error.OK then
			if not arg_66_0.rentPetCount or arg_66_0.rentPetCount ~= arg_67_1.rent_count then
				arg_66_0.allTeamPets = arg_67_1.pets or {}
				arg_66_0.rentPetCount = arg_67_1.rent_count
			end

			if var_66_0.load_place and var_66_0.load_place == 1 then
				arg_66_0.loadPetPlace = 1
			else
				arg_66_0.loadPetPlace = 0
			end
		end

		arg_66_2(arg_67_0, arg_67_1)
	end)
end

function var_0_0.settingTeam(arg_68_0, arg_68_1, arg_68_2)
	local var_68_0 = arg_68_1 or {}

	xyd.Backend.get():request(xyd.mid.SETTING_TEAM, var_68_0, function(arg_69_0)
		if arg_69_0 == xyd.error.OK then
			arg_68_0.guild_icon = var_68_0.icon
			arg_68_0.icon_frame = var_68_0.icon_frame
			arg_68_0.min_allow_level = var_68_0.min_allow_level
			arg_68_0.apply_type = var_68_0.apply_type
			arg_68_0.guild_name = var_68_0.name

			arg_68_2(arg_69_0)
		end
	end)
end

function var_0_0.loadDrinkInfo(arg_70_0, arg_70_1)
	xyd.Backend.get():request(xyd.mid.LOAD_DRINK_INFO, {}, function(arg_71_0, arg_71_1)
		arg_70_0.normal_drink_times = arg_71_1.normal_drink_times
		arg_70_0.special_drink_times = arg_71_1.special_drink_times
		arg_70_0.normal_time = arg_71_1.normal_time
		arg_70_0.special_time = arg_71_1.special_time
		arg_70_0.drink_status = arg_71_1.buy_drink_status
		arg_70_0.daily_exchange = arg_71_1.daily_exchange
		arg_70_0.free_have_drink = arg_71_1.free_have_drink or 1
		arg_70_0.normal_have_drink = arg_71_1.normal_have_drink or 1
		arg_70_0.special_have_drink = arg_71_1.special_have_drink or 1
		arg_70_0.drink_times = arg_70_0.free_have_drink + arg_70_0.normal_have_drink + arg_70_0.special_have_drink

		arg_70_1(arg_71_0)
	end)
end

function var_0_0.buyDrink(arg_72_0, arg_72_1, arg_72_2)
	local var_72_0 = arg_72_1 or {}

	xyd.Backend.get():request(xyd.mid.BUY_DRINK, var_72_0, function(arg_73_0, arg_73_1)
		arg_72_0.normal_have_drink = arg_73_1.drink_info.normal_have_drink
		arg_72_0.special_have_drink = arg_73_1.drink_info.special_have_drink
		arg_72_0.drink_status = arg_73_1.drink_info.buy_drink_status

		arg_72_2(arg_73_0, arg_73_1)
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.DRINK_NOTIF
		})
	end)
end

function var_0_0.doDrink(arg_74_0, arg_74_1, arg_74_2)
	local var_74_0 = arg_74_1 or {}

	xyd.Backend.get():request(xyd.mid.DO_DRINK, var_74_0, function(arg_75_0, arg_75_1)
		if arg_75_1.member_name == nil or arg_75_1.member_name == "" then
			arg_74_0.treat_player = xyd.tables.translation:translation("GUILD")
		else
			arg_74_0.treat_player = arg_75_1.member_name
		end

		if var_74_0.type == 2 then
			arg_74_0.normal_drink_times = arg_74_0.normal_drink_times - 1
		elseif var_74_0.type == 3 then
			arg_74_0.special_drink_times = arg_74_0.special_drink_times - 1
		end

		arg_74_0.free_have_drink = arg_75_1.drink_info.free_have_drink or 1
		arg_74_0.normal_have_drink = arg_75_1.drink_info.normal_have_drink or 1
		arg_74_0.special_have_drink = arg_75_1.drink_info.special_have_drink or 1
		arg_74_0.drink_times = arg_74_0.free_have_drink + arg_74_0.normal_have_drink + arg_74_0.special_have_drink

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.DRINK_NOTIF
		})
		arg_74_2(arg_75_0, arg_75_1)
	end)
end

function var_0_0.updateDes(arg_76_0, arg_76_1, arg_76_2)
	local var_76_0 = arg_76_1 or {}

	xyd.Backend.get():request(xyd.mid.UPDATE_DES_TEAM, var_76_0, function(arg_77_0)
		if arg_77_0 == xyd.error.OK then
			arg_76_0.guild_des = var_76_0.des

			arg_76_2(arg_77_0)
		end
	end)
end

function var_0_0.loadGuildCampaignList(arg_78_0, arg_78_1)
	xyd.Backend.get():request(xyd.mid.LOAD_GUILD_CAMPAIGN_LIST, {}, function(arg_79_0, arg_79_1)
		if arg_79_0 == xyd.error.OK then
			arg_78_0.guildCampaignList = arg_79_1.chapter_list
			arg_78_0.team_chapter_id = arg_78_0:findGuildCurrentChapter()
		end

		arg_78_1(arg_79_0)
	end)
end

function var_0_0.loadGuildMap(arg_80_0, arg_80_1)
	if arg_80_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_GUILD) == true and arg_80_0.guild_id and arg_80_0.guild_id > 0 then
		xyd.Backend.get():request(xyd.mid.LOAD_GUILD_MAP, {}, function(arg_81_0, arg_81_1)
			if arg_81_0 == xyd.error.OK then
				arg_80_0.guildCampaigns = arg_81_1.copy_list
				arg_80_0.guildCampaignList = arg_81_1.chapter_list
				arg_80_0.team_chapter_id = arg_80_0:findGuildCurrentChapter()
			end

			arg_80_1(arg_81_0, arg_81_1)
		end)
	else
		arg_80_1()
	end
end

function var_0_0.loadGuildMapDetail(arg_82_0, arg_82_1, arg_82_2)
	local var_82_0 = arg_82_1 or {}

	xyd.Backend.get():request(xyd.mid.LOAD_GUILD_MAP_DETAIL, var_82_0, function(arg_83_0, arg_83_1)
		arg_82_2(arg_83_0, arg_83_1)
	end)
end

function var_0_0.openGuildChapter(arg_84_0, arg_84_1, arg_84_2)
	local var_84_0 = arg_84_1 or {}

	xyd.Backend.get():request(xyd.mid.OPEN_CHAPTER, var_84_0, function(arg_85_0, arg_85_1)
		if arg_85_0 == xyd.error.OK then
			arg_84_0.huoyue = arg_85_1.guild_huoyue
			arg_84_0.guildCampaignList = arg_85_1.chapter_list
		end

		arg_84_2(arg_85_0, arg_85_1)
	end)
end

function var_0_0.resetGuildChapter(arg_86_0, arg_86_1, arg_86_2)
	local var_86_0 = arg_86_1 or {}

	xyd.Backend.get():request(xyd.mid.RESET_CHAPTER, var_86_0, function(arg_87_0, arg_87_1)
		if arg_87_0 == xyd.error.OK then
			arg_86_0.huoyue = arg_87_1.guild_huoyue
			arg_86_0.guildCampaignList = arg_87_1.chapter_list
		end

		arg_86_2(arg_87_0, arg_87_1)
	end)
end

function var_0_0.loadGuildRewards(arg_88_0, arg_88_1, arg_88_2)
	local var_88_0 = arg_88_1 or {}

	xyd.Backend.get():request(xyd.mid.LOAD_GUILD_AWARD_LIST, var_88_0, function(arg_89_0, arg_89_1)
		if arg_89_0 == xyd.error.OK then
			for iter_89_0, iter_89_1 in pairs(arg_89_1.award_infos) do
				arg_88_0.chapterRewardList[iter_89_1.award_id] = iter_89_1
			end

			arg_88_0.nextApplyTime = arg_89_1.award_next_time
			arg_88_0.appliedInfo = arg_89_1.self_apply_info
			arg_88_0.guildEquipApplyTimes = arg_89_1.guild_equip_apply_times
		end

		arg_88_2(arg_89_0, arg_89_1)
	end)
end

function var_0_0.applyReward(arg_90_0, arg_90_1, arg_90_2)
	local var_90_0 = arg_90_1 or {}

	xyd.Backend.get():request(xyd.mid.APPLY_REWARD, var_90_0, function(arg_91_0, arg_91_1)
		if arg_91_0 == xyd.error.OK then
			for iter_91_0, iter_91_1 in pairs(arg_91_1.award_infos) do
				arg_90_0.chapterRewardList[iter_91_1.award_id] = iter_91_1
			end

			arg_90_0.nextApplyTime = arg_91_1.award_next_time
			arg_90_0.appliedInfo = arg_91_1.self_apply_info
			arg_90_0.guildEquipApplyTimes = arg_91_1.guild_equip_apply_times
		end

		arg_90_2(arg_91_0, arg_91_1)
	end)
end

function var_0_0.loadChapterDamageRank(arg_92_0, arg_92_1, arg_92_2)
	local var_92_0 = arg_92_1 or {}

	xyd.Backend.get():request(xyd.mid.GUILD_CHAPTER_DAMAGE_RANK, var_92_0, function(arg_93_0, arg_93_1)
		if arg_93_0 == xyd.error.OK then
			arg_92_0.chapterDamageRankList = arg_93_1.rank_list
		end

		arg_92_2(arg_93_0, arg_93_1)
	end)
end

function var_0_0.loadAllDamageRank(arg_94_0, arg_94_1, arg_94_2)
	local var_94_0 = arg_94_1 or {}

	xyd.Backend.get():request(xyd.mid.GUILF_ALL_SERVER_DAMAGE_RANK, var_94_0, function(arg_95_0, arg_95_1)
		if arg_95_0 == xyd.error.OK then
			arg_94_0.allFastKillerInfo = arg_95_1.fast_boss_killer
			arg_94_0.allBossKillerInfo = arg_95_1.boss_killer
			arg_94_0.allDamageRankList = arg_95_1.rank_list
		end

		arg_94_2(arg_95_0, arg_95_1)
	end)
end

function var_0_0.getPrepareCount(arg_96_0, arg_96_1, arg_96_2)
	local var_96_0 = arg_96_1 or {}

	xyd.Backend.get():request(xyd.mid.GUILD_FIGHT_PREPARE, var_96_0, function(arg_97_0, arg_97_1)
		if arg_97_0 == xyd.error.OK then
			local var_97_0 = xyd.ServerTime.get():getServerTime()
			local var_97_1 = 0

			if arg_97_1.stage == 1 then
				var_97_1 = 60 - (var_97_0 - arg_97_1.last_fight_time)
			elseif arg_97_1.stage == 2 then
				var_97_1 = 180 - (var_97_0 - arg_97_1.start_fight_time)
			end

			arg_96_0:setPrepareTime(var_97_1, var_96_0.copy_id, arg_97_1.stage)
		end

		arg_96_2(arg_97_0, arg_97_1)
	end)
end

function var_0_0.setPrepareTime(arg_98_0, arg_98_1, arg_98_2, arg_98_3)
	local var_98_0 = 0

	if arg_98_3 == 1 then
		var_98_0 = 60
	elseif arg_98_3 == 2 then
		var_98_0 = 180
	end

	if not (arg_98_1 <= 0) and not (var_98_0 < arg_98_1) then
		if arg_98_0.handles_[arg_98_2] then
			var_0_1.unscheduleGlobal(arg_98_0.handles_[arg_98_2])
		end

		arg_98_0.selectHeroCounts_ = {}
		arg_98_0.selectHeroCounts_[arg_98_2] = arg_98_1
		arg_98_0.handles_[arg_98_2] = var_0_1.scheduleGlobal(function()
			if not arg_98_0.selectHeroCounts_[arg_98_2] then
				if arg_98_0.handles_[arg_98_2] then
					var_0_1.unscheduleGlobal(arg_98_0.handles_[arg_98_2])
				end

				return
			end

			arg_98_0.selectHeroCounts_[arg_98_2] = arg_98_0.selectHeroCounts_[arg_98_2] - 1

			if arg_98_0.selectHeroCounts_[arg_98_2] <= 0 then
				arg_98_0.selectHeroCounts_[arg_98_2] = 0

				var_0_1.unscheduleGlobal(arg_98_0.handles_[arg_98_2])
			end
		end, 1)
	else
		if arg_98_0.handles_[arg_98_2] then
			var_0_1.unscheduleGlobal(arg_98_0.handles_[arg_98_2])
		end

		arg_98_0.selectHeroCounts_[arg_98_2] = 0
	end
end

function var_0_0.findGuildCurrentChapter(arg_100_0)
	local var_100_0 = 0

	arg_100_0.minChapterID = 100
	arg_100_0.guildChapterList = {}

	if arg_100_0.guildCampaignList and next(arg_100_0.guildCampaignList) then
		for iter_100_0, iter_100_1 in pairs(arg_100_0.guildCampaignList) do
			if iter_100_1.is_open == 1 and var_100_0 < iter_100_1.chapter_id then
				var_100_0 = iter_100_1.chapter_id
			end

			if iter_100_1.chapter_id < arg_100_0.minChapterID then
				arg_100_0.minChapterID = iter_100_1.chapter_id
			end

			arg_100_0.guildChapterList[iter_100_1.chapter_id] = iter_100_1
		end

		if var_100_0 == 0 then
			return arg_100_0.minChapterID
		else
			return var_100_0
		end
	else
		return 0
	end
end

function var_0_0.loadDistributeRecord(arg_101_0, arg_101_1)
	xyd.Backend.get():request(xyd.mid.GUILD_DISTRIBUTE_RECORD, {}, function(arg_102_0, arg_102_1)
		if arg_102_0 == xyd.error.OK then
			arg_101_0.guildDistriList = arg_102_1.logs
		end

		arg_101_1(arg_102_0, arg_102_1)
	end)
end

function var_0_0.guildWarRedPointInfo(arg_103_0, arg_103_1)
	local var_103_0 = arg_103_1.params

	if var_103_0.is_enroll then
		arg_103_0.isEnrollWar = 1
	else
		arg_103_0.isEnrollWar = 0
	end

	arg_103_0.warStep = var_103_0.step_id
end

function var_0_0.loadGuildWarRedPointInfo(arg_104_0, arg_104_1)
	xyd.Backend.get():request(xyd.mid.GUILD_WAR_RED_POINT, {}, function(arg_105_0, arg_105_1)
		if arg_105_0 == xyd.error.OK then
			arg_104_0.isEnrollWar = arg_105_1.is_enroll
			arg_104_0.warStep = arg_105_1.step_id
		end

		arg_104_1(arg_105_0, arg_105_1)
	end)
end

function var_0_0.loadGuildWarInfo(arg_106_0, arg_106_1)
	xyd.Backend.get():request(xyd.mid.GUILD_WAR_INFO, {}, function(arg_107_0, arg_107_1)
		if arg_107_0 == xyd.error.OK then
			arg_106_0.isInWar = arg_107_1.base_info.is_in_war
			arg_106_0.warEndTime = arg_107_1.base_info.end_time
			arg_106_0.warStartTime = arg_107_1.base_info.start_time
			arg_106_0.warStep = tonumber(arg_107_1.base_info.step_id)
			arg_106_0.warIsFinishMatch = arg_107_1.base_info.is_finish_match
			arg_106_0.warNextStartTime = arg_107_1.base_info.next_enroll_start_time
			arg_106_0.warSide = arg_107_1.base_info.location
			arg_106_0.isEnrollWar = arg_107_1.base_info.is_enroll
			arg_106_0.guildWarNotice = arg_107_1.base_info.notice
			arg_106_0.roundWinInfo = {}
			arg_106_0.roundWinNum = 0

			if arg_107_1.base_info.round_win_info then
				for iter_107_0, iter_107_1 in pairs(arg_107_1.base_info.round_win_info) do
					if iter_107_1.round then
						arg_106_0.roundWinInfo[iter_107_1.round] = {}
						arg_106_0.roundWinInfo[iter_107_1.round].isWin = iter_107_1.round_win
						arg_106_0.roundWinInfo[iter_107_1.round].name = iter_107_1.enemy_guild_name

						if iter_107_1.round_win == 1 then
							arg_106_0.roundWinNum = arg_106_0.roundWinNum + 1
						end
					end
				end
			end

			if arg_107_1.base_info.enemy_guild_info then
				arg_106_0.warEnemy = {}
				arg_106_0.warEnemy.des = arg_107_1.base_info.enemy_guild_info.des
				arg_106_0.warEnemy.memberNum = arg_107_1.base_info.enemy_guild_info.member_num
				arg_106_0.warEnemy.icon = arg_107_1.base_info.enemy_guild_info.icon
				arg_106_0.warEnemy.guildId = arg_107_1.base_info.enemy_guild_info.guild_id
				arg_106_0.warEnemy.leaderName = arg_107_1.base_info.enemy_guild_info.leader_name
				arg_106_0.warEnemy.name = arg_107_1.base_info.enemy_guild_info.name
			else
				arg_106_0.warEnemy = nil
			end

			arg_106_0.troopInfo = {}

			if arg_107_1.step_info and arg_107_1.step_info.troop then
				for iter_107_2, iter_107_3 in pairs(arg_107_1.step_info.troop) do
					if iter_107_3 and next(iter_107_3) then
						arg_106_0.troopInfo[iter_107_3.team_id] = {}
						arg_106_0.troopInfo[iter_107_3.team_id].formation = iter_107_3.formation
						arg_106_0.troopInfo[iter_107_3.team_id].playerId = iter_107_3.player_id
						arg_106_0.troopInfo[iter_107_3.team_id].path = iter_107_3.path
						arg_106_0.troopInfo[iter_107_3.team_id].petId = iter_107_3.pet_id
					end
				end
			end

			if arg_107_1.step_info and arg_107_1.step_info.path_win then
				local var_107_0 = 0
				local var_107_1 = 0
				local var_107_2 = false

				for iter_107_4, iter_107_5 in pairs(arg_107_1.step_info.path_win) do
					if iter_107_5 == xyd.PathWinType.WIN then
						var_107_0 = var_107_0 + 1
					elseif iter_107_5 == xyd.PathWinType.LOSE then
						var_107_1 = var_107_1 + 1
					end

					if iter_107_5 == xyd.PathWinType.NOT_END then
						var_107_2 = true
					end
				end

				arg_106_0.guildWarWin = -1

				if var_107_1 < var_107_0 then
					arg_106_0.guildWarWin = 1
				elseif var_107_0 < var_107_1 then
					arg_106_0.guildWarWin = 0
				end

				if var_107_2 == true then
					arg_106_0.guildWarWin = nil
				end

				arg_106_0.guildWarStar = var_107_0
				arg_106_0.guildWarStarEn = var_107_1
			else
				arg_106_0.guildWarWin = nil
				arg_106_0.guildWarStar = 0
				arg_106_0.guildWarStarEn = 0
			end

			if arg_107_1.buff_infos and next(arg_107_1.buff_infos) then
				arg_106_0:updateBuffsInfo(arg_107_1.buff_infos)
			end
		end

		arg_106_1(arg_107_0, arg_107_1)
	end)
end

function var_0_0.guildWarUpdateForce(arg_108_0, arg_108_1, arg_108_2)
	xyd.Backend.get():request(xyd.mid.GUILD_WAR_UPDATE_FORCE, arg_108_1, function(arg_109_0, arg_109_1)
		if arg_109_0 == xyd.error.OK then
			arg_108_0.hasUpdatedForce = true
		end

		arg_108_2(arg_109_0, arg_109_1)
	end)
end

function var_0_0.guildWarFightListUpdate(arg_110_0, arg_110_1, arg_110_2)
	xyd.Backend.get():request(xyd.mid.GUILD_WAR_FIGHT_LIST, arg_110_1, function(arg_111_0, arg_111_1)
		if arg_111_0 == xyd.error.OK then
			arg_110_0.guildWarFinishList = {}
			arg_110_0.guildWarFightList = {}
			arg_110_0.guildWarWaitList = {}

			local var_111_0 = 1
			local var_111_1 = {}

			for iter_111_0, iter_111_1 in pairs(arg_111_1.enemy_queue) do
				if iter_111_1.type == 1 then
					if arg_110_0.guildWarFinishList[1] == nil then
						var_111_0 = 1
					end

					if iter_111_1.is_win ~= -1 then
						arg_110_0.guildWarFinishList[var_111_0] = {}
						arg_110_0.guildWarFinishList[var_111_0].enemy = iter_111_1
					end

					if iter_111_1.is_win == 1 then
						var_111_1[iter_111_1.team_id] = 1
					else
						var_111_1[iter_111_1.team_id] = 0
					end
				elseif iter_111_1.type == 0 then
					if arg_110_0.guildWarFightList[1] == nil then
						var_111_0 = 1
					end

					arg_110_0.guildWarFightList[var_111_0] = {}
					arg_110_0.guildWarFightList[var_111_0].enemy = iter_111_1
				elseif iter_111_1.type == -1 then
					if arg_110_0.guildWarWaitList[1] == nil then
						var_111_0 = 1
					end

					arg_110_0.guildWarWaitList[var_111_0] = {}
					arg_110_0.guildWarWaitList[var_111_0].enemy = iter_111_1
				end

				var_111_0 = var_111_0 + 1
			end

			local var_111_2 = 2
			local var_111_3 = {}

			for iter_111_2, iter_111_3 in pairs(arg_111_1.self_queue) do
				if iter_111_3.type == 1 then
					if var_111_2 ~= iter_111_3.type then
						var_111_0 = 1
						var_111_2 = iter_111_3.type
					end

					if iter_111_3.is_win ~= -1 then
						if arg_110_0.guildWarFinishList[var_111_0] == nil then
							arg_110_0.guildWarFinishList[var_111_0] = {}
						end

						arg_110_0.guildWarFinishList[var_111_0].mine = iter_111_3
					end

					if iter_111_3.is_win == 1 then
						var_111_3[iter_111_3.team_id] = 1
					else
						var_111_3[iter_111_3.team_id] = 0
					end
				elseif iter_111_3.type == 0 then
					if var_111_2 ~= iter_111_3.type then
						var_111_0 = 1
						var_111_2 = iter_111_3.type
					end

					if arg_110_0.guildWarFightList[var_111_0] == nil then
						arg_110_0.guildWarFightList[var_111_0] = {}
					end

					arg_110_0.guildWarFightList[var_111_0].mine = iter_111_3
				elseif iter_111_3.type == -1 then
					if var_111_2 ~= iter_111_3.type then
						var_111_0 = 1
						var_111_2 = iter_111_3.type
					end

					if arg_110_0.guildWarWaitList[var_111_0] == nil then
						arg_110_0.guildWarWaitList[var_111_0] = {}
					end

					arg_110_0.guildWarWaitList[var_111_0].mine = iter_111_3
				end

				var_111_0 = var_111_0 + 1
			end

			arg_110_0.guildWarEnemyTotal = arg_111_1.enemy_team_num or 0
			arg_110_0.guildWarSelfTotal = arg_111_1.self_team_num or 0

			local var_111_4 = 0

			for iter_111_4, iter_111_5 in pairs(var_111_1) do
				if iter_111_5 == 0 then
					var_111_4 = var_111_4 + 1
				end
			end

			arg_110_0.guildWarEnemyLeft = arg_110_0.guildWarEnemyTotal - var_111_4

			local var_111_5 = 0

			for iter_111_6, iter_111_7 in pairs(var_111_3) do
				if iter_111_7 == 0 then
					var_111_5 = var_111_5 + 1
				end
			end

			arg_110_0.guildWarSelfLeft = arg_110_0.guildWarSelfTotal - var_111_5
		end

		arg_110_2(arg_111_0, arg_111_1)
	end)
end

function var_0_0.guildWarEnroll(arg_112_0, arg_112_1)
	xyd.Backend.get():request(xyd.mid.GUILD_WAR_ENROLL, {}, function(arg_113_0, arg_113_1)
		if arg_113_0 == xyd.error.OK then
			arg_112_0.isEnrollWar = 1
			arg_112_0.huoyue = arg_112_0.huoyue - xyd.tables.misc.guildBattleCost
		end

		arg_112_1(arg_113_0, arg_113_1)
	end)
end

function var_0_0.guildWarAddTeam(arg_114_0, arg_114_1, arg_114_2)
	xyd.Backend.get():request(xyd.mid.GUILD_WAR_ADD_TEAM, arg_114_1, function(arg_115_0, arg_115_1)
		if arg_115_0 == xyd.error.OK then
			arg_114_0.troopInfo = {}

			for iter_115_0, iter_115_1 in pairs(arg_115_1.troop) do
				arg_114_0.troopInfo[iter_115_1.team_id] = {}
				arg_114_0.troopInfo[iter_115_1.team_id].formation = iter_115_1.formation
				arg_114_0.troopInfo[iter_115_1.team_id].playerId = iter_115_1.player_id
				arg_114_0.troopInfo[iter_115_1.team_id].path = iter_115_1.path
				arg_114_0.troopInfo[iter_115_1.team_id].petId = iter_115_1.pet_id
			end
		end

		arg_114_2(arg_115_0, arg_115_1)
	end)
end

function var_0_0.guildWarLoadPath(arg_116_0, arg_116_1, arg_116_2)
	xyd.Backend.get():request(xyd.mid.GUILD_WAR_LOAD_PATH, arg_116_1, function(arg_117_0, arg_117_1)
		if arg_117_0 == xyd.error.OK then
			arg_116_0.guildWarOtherPlayer = arg_117_1.other_player_info

			if arg_116_0.guildWarOtherPlayer == nil then
				arg_116_0.guildWarOtherPlayer = {}
			end
		end

		arg_116_2(arg_117_0, arg_117_1)
	end)
end

function var_0_0.guildWarChangePath(arg_118_0, arg_118_1, arg_118_2)
	xyd.Backend.get():request(xyd.mid.GUILD_WAR_CHANGE_PATH, arg_118_1, function(arg_119_0, arg_119_1)
		if arg_119_0 == xyd.error.OK then
			for iter_119_0, iter_119_1 in pairs(arg_118_1.team_ids) do
				arg_118_0.troopInfo[iter_119_1].path = arg_118_1.path
			end
		end

		arg_118_2(arg_119_0, arg_119_1)
	end)
end

function var_0_0.guildWarSaveNotice(arg_120_0, arg_120_1, arg_120_2)
	xyd.Backend.get():request(xyd.mid.GUILD_WAR_NOTICE, arg_120_1, function(arg_121_0, arg_121_1)
		if arg_121_0 == xyd.error.OK then
			arg_120_0.guildWarNotice = arg_120_1.notice
		end

		arg_120_2(arg_121_0, arg_121_1)
	end)
end

function var_0_0.guildWarReplay(arg_122_0, arg_122_1, arg_122_2)
	xyd.Backend.get():request(xyd.mid.GUILD_WAR_REPLAY, arg_122_1, function(arg_123_0, arg_123_1)
		if arg_123_0 == xyd.error.OK then
			-- block empty
		end

		arg_122_2(arg_123_0, arg_123_1)
	end)
end

function var_0_0.guildWarRank(arg_124_0, arg_124_1, arg_124_2)
	xyd.Backend.get():request(xyd.mid.GUILD_WAR_RANK, arg_124_1, function(arg_125_0, arg_125_1)
		if arg_125_0 == xyd.error.OK then
			arg_124_0.rankData = {}

			local var_125_0 = {
				title = "FIGHT_PREPARE",
				type = xyd.RankType.FIGHT_PREPARE,
				subList = {}
			}
			local var_125_1 = false

			if arg_125_1.hero_num_rank and next(arg_125_1.hero_num_rank) then
				var_125_1 = true

				local var_125_2 = {
					info_text = "SEND_HERO_NUM_RANK",
					sub_type = 1,
					title = "SEND_HERO_RANK",
					rankList = arg_125_1.hero_num_rank.rank_list
				}

				if arg_125_1.hero_num_rank.my_rank and next(arg_125_1.hero_num_rank.my_rank) then
					var_125_2.myRank = arg_125_1.hero_num_rank.my_rank
					var_125_2.myRank.score = arg_125_1.hero_num_rank.my_rank.hero_num
				end

				table.insert(var_125_0.subList, var_125_2)
			end

			if arg_125_1.force_rank and next(arg_125_1.force_rank) then
				var_125_1 = true

				local var_125_3 = {
					info_text = "TOTAL_TEAM_POWER",
					sub_type = 2,
					title = "TEAM_POWER",
					rankList = arg_125_1.force_rank.rank_list
				}

				if arg_125_1.force_rank.my_rank and next(arg_125_1.force_rank.my_rank) then
					var_125_3.myRank = arg_125_1.force_rank.my_rank
					var_125_3.myRank.score = arg_125_1.force_rank.my_rank.force
				end

				table.insert(var_125_0.subList, var_125_3)
			end

			local var_125_4 = {
				title = "GUILD_WAR_BUFF_TITLE",
				type = xyd.RankType.BUFF,
				subList = {}
			}
			local var_125_5 = false

			if arg_125_1.buff_rank and next(arg_125_1.buff_rank) then
				var_125_5 = true

				local var_125_6 = {
					info_text = "GUILD_WAR_BUFF_RANK",
					sub_type = 1,
					title = "GUILD_WAR_BUFF_TITLE",
					rankList = arg_125_1.buff_rank.rank_list
				}

				if arg_125_1.buff_rank.my_rank and next(arg_125_1.buff_rank.my_rank) then
					var_125_6.myRank = arg_125_1.buff_rank.my_rank
				end

				table.insert(var_125_4.subList, var_125_6)
			end

			local var_125_7 = {
				title = "FIGHTING_SENCE",
				type = xyd.RankType.BATTLE,
				subList = {}
			}
			local var_125_8 = false

			if arg_125_1.battle_rank and next(arg_125_1.battle_rank) then
				var_125_8 = true

				local var_125_9 = {
					info_text = "SELF_FIGHTING_RANK",
					sub_type = 1,
					title = "SELF_FIGHTING",
					rankList = arg_125_1.battle_rank.rank_list
				}

				if arg_125_1.battle_rank.my_rank and next(arg_125_1.battle_rank.my_rank) then
					var_125_9.myRank = arg_125_1.battle_rank.my_rank
				end

				table.insert(var_125_7.subList, var_125_9)
			end

			local var_125_10 = {
				title = "GUILD_RANK_TITLE",
				type = xyd.RankType.GUILD_WIN,
				subList = {}
			}
			local var_125_11 = false

			if arg_125_1.guild_win_rank and next(arg_125_1.guild_win_rank) then
				var_125_11 = true

				local var_125_12 = {
					info_text = "COMPETITION_SCORE_DES",
					sub_type = 1,
					title = "COMPETITION_SCORE",
					rankList = arg_125_1.guild_win_rank.rank_list
				}

				if arg_125_1.guild_win_rank.my_rank and next(arg_125_1.guild_win_rank.my_rank) then
					var_125_12.myRank = arg_125_1.guild_win_rank.my_rank
				end

				table.insert(var_125_10.subList, var_125_12)
			end

			arg_124_0.rankType = xyd.RankType.FIGHT_PREPARE

			if var_125_11 == true then
				arg_124_0.rankData[xyd.RankType.GUILD_WIN] = var_125_10
				arg_124_0.rankType = xyd.RankType.GUILD_WIN
			end

			if var_125_8 == true then
				arg_124_0.rankData[xyd.RankType.BATTLE] = var_125_7
				arg_124_0.rankType = xyd.RankType.BATTLE
			end

			if var_125_1 == true then
				arg_124_0.rankData[xyd.RankType.FIGHT_PREPARE] = var_125_0
				arg_124_0.rankType = xyd.RankType.FIGHT_PREPARE
			end

			if var_125_5 == true then
				arg_124_0.rankData[xyd.RankType.BUFF] = var_125_4
			end
		end

		arg_124_2(arg_125_0, arg_125_1)
	end)
end

function var_0_0.setUseRent(arg_126_0, arg_126_1)
	if arg_126_1.tutorInfo then
		return
	end

	if not arg_126_1 or not arg_126_0.allTeamHeros_ or not next(arg_126_0.allTeamHeros_) then
		return
	end

	for iter_126_0, iter_126_1 in pairs(arg_126_0.allTeamHeros_) do
		if iter_126_1.player_id == arg_126_1.player_id then
			iter_126_1.can_rent = false
		end
	end
end

function var_0_0.setUseRentPet(arg_127_0, arg_127_1)
	if not arg_127_1 or not arg_127_0.allTeamPets or not next(arg_127_0.allTeamPets) then
		return
	end

	for iter_127_0, iter_127_1 in pairs(arg_127_0.allTeamPets) do
		if iter_127_1.player_id == arg_127_1.player_id then
			iter_127_1.can_rent = false
		end
	end
end

function var_0_0.getTeaTalkInfo(arg_128_0, arg_128_1, arg_128_2)
	local var_128_0 = arg_128_2 or {}

	xyd.Backend.get():request(xyd.mid.GET_TEA_TALK_INFO, var_128_0, function(arg_129_0, arg_129_1)
		if arg_129_0 == xyd.error.OK then
			arg_128_0.teaTalkSelfWishInfo = arg_129_1.self_wish_info or {}

			if not var_128_0.is_self then
				arg_128_0.teaTalkOnceFlay = arg_129_1.guild_wish_flag or 0
				arg_128_0.teaTalkGiftList = arg_129_1.gift_list or {}
				arg_128_0.teaTalkWishList = arg_129_1.wish_list or {}

				arg_128_0:sortWishList()
			end

			arg_128_0:teaTalkCheckRed()
		end

		if arg_128_1 then
			arg_128_1(arg_129_0, arg_129_1)
		end
	end)
end

function var_0_0.sortWishList(arg_130_0)
	local var_130_0 = {}
	local var_130_1 = {}

	for iter_130_0, iter_130_1 in pairs(arg_130_0.teaTalkWishList) do
		if iter_130_1.wish_info.current_num == iter_130_1.wish_info.need_num then
			table.insert(var_130_1, iter_130_1)
		else
			table.insert(var_130_0, iter_130_1)
		end
	end

	arg_130_0.teaTalkWishList = var_130_0

	for iter_130_2, iter_130_3 in pairs(var_130_1) do
		table.insert(arg_130_0.teaTalkWishList, iter_130_3)
	end
end

function var_0_0.teaTalkRequest(arg_131_0, arg_131_1, arg_131_2)
	local var_131_0 = arg_131_1 or {}

	xyd.Backend.get():request(xyd.mid.TEA_TALK_QUEST, var_131_0, function(arg_132_0, arg_132_1)
		if arg_132_0 == xyd.error.OK then
			arg_131_0.teaTalkOnceFlay = arg_132_1.guild_wish_flag or 0
			arg_131_0.teaTalkGiftList = arg_132_1.gift_list or {}
			arg_131_0.teaTalkSelfWishInfo = arg_132_1.self_wish_info or {}
			arg_131_0.teaTalkWishList = arg_132_1.wish_list or {}

			arg_131_0:sortWishList()
			arg_131_0:teaTalkCheckRed()
		end

		if arg_131_2 then
			arg_131_2(arg_132_0, arg_132_1)
		end
	end)
end

function var_0_0.teaTalkPresent(arg_133_0, arg_133_1, arg_133_2)
	local var_133_0 = arg_133_1 or {}

	xyd.Backend.get():request(xyd.mid.TEA_TALK_PRESENT, var_133_0, function(arg_134_0, arg_134_1)
		if arg_134_0 == xyd.error.OK then
			arg_133_0.teaTalkWishList = arg_134_1.wish_list or {}

			arg_133_0:sortWishList()
		end

		if arg_133_2 then
			arg_133_2(arg_134_0, arg_134_1)
		end
	end)
end

function var_0_0.teaTalkConfirm(arg_135_0, arg_135_1)
	xyd.Backend.get():request(xyd.mid.TEA_TALK_CONFIRM_GIFT, {}, function(arg_136_0, arg_136_1)
		if arg_136_0 == xyd.error.OK then
			arg_135_0.teaTalkOnceFlay = arg_136_1.guild_wish_flag or 0
			arg_135_0.teaTalkGiftList = arg_136_1.gift_list or {}
			arg_135_0.teaTalkSelfWishInfo = arg_136_1.self_wish_info or {}
			arg_135_0.teaTalkWishList = arg_136_1.wish_list or {}

			arg_135_0:sortWishList()
			arg_135_0:teaTalkCheckRed()
		end

		if arg_135_1 then
			arg_135_1(arg_136_0, arg_136_1)
		end
	end)
end

function var_0_0.updateBuffsInfo(arg_137_0, arg_137_1)
	arg_137_0.buffsInfo = arg_137_1 or {}
end

function var_0_0.getBuffsInfo(arg_138_0)
	return arg_138_0.buffsInfo or {}
end

function var_0_0.addGuildBuff(arg_139_0, arg_139_1, arg_139_2)
	local var_139_0 = arg_139_1 or {}

	xyd.Backend.get():request(xyd.mid.GUILD_WAR_ADD_BUFF, var_139_0, function(arg_140_0, arg_140_1)
		if arg_140_0 == xyd.error.OK then
			arg_139_0.buffsInfo.self_buff_info = arg_140_1.buff_infos
		end

		if arg_139_2 then
			arg_139_2(arg_140_0, arg_140_1)
		end
	end)
end

function var_0_0.teaTalkInitRed(arg_141_0, arg_141_1)
	arg_141_0.teaTalkSelfWishInfo = arg_141_1.params.self_wish_info or {}

	arg_141_0:teaTalkCheckRed()
end

function var_0_0.teaTalkCheckRed(arg_142_0)
	if arg_142_0.teaTalkSelfWishInfo and arg_142_0.teaTalkSelfWishInfo.current_num and arg_142_0.teaTalkSelfWishInfo.current_num ~= 0 and arg_142_0.teaTalkSelfWishInfo.current_num == arg_142_0.teaTalkSelfWishInfo.need_num then
		arg_142_0.teaTalkFinish = true
	else
		arg_142_0.teaTalkFinish = false
	end
end

function var_0_0.getSentHeros(arg_143_0)
	return arg_143_0.sentHeros_
end

function var_0_0.getRentPets(arg_144_0)
	return arg_144_0.rentPets
end

function var_0_0.getAllTeamHeros(arg_145_0)
	return arg_145_0.allTeamHeros_
end

function var_0_0.getAllTeamPets(arg_146_0)
	return arg_146_0.allTeamPets
end

function var_0_0.getAllMarchTeamHeros(arg_147_0)
	return arg_147_0.allMarchTeamHeros_
end

function var_0_0.getSelfJob(arg_148_0)
	return arg_148_0.job
end

function var_0_0.getGuildCampaignList(arg_149_0)
	return arg_149_0.guildCampaignList
end

function var_0_0.getGuildCampaigns(arg_150_0)
	return arg_150_0.guildCampaigns
end

function var_0_0.getGuildChapterList(arg_151_0)
	return arg_151_0.guildChapterList
end

function var_0_0.getMinchapterID(arg_152_0)
	return arg_152_0.minChapterID
end

function var_0_0.getPrepareTime(arg_153_0, arg_153_1)
	return arg_153_0.selectHeroCounts_[arg_153_1]
end

function var_0_0.getGuildHuoyue(arg_154_0)
	return arg_154_0.huoyue
end

function var_0_0.getChapterRewardList(arg_155_0)
	return arg_155_0.chapterRewardList
end

function var_0_0.getNextApplyTime(arg_156_0)
	return arg_156_0.nextApplyTime
end

function var_0_0.getChapterDamageRankList(arg_157_0)
	return arg_157_0.chapterDamageRankList
end

function var_0_0.getAllFastKillerInfo(arg_158_0)
	return arg_158_0.allFastKillerInfo
end

function var_0_0.getBossKillerInfo(arg_159_0)
	return arg_159_0.allBossKillerInfo
end

function var_0_0.getAllDamageRankList(arg_160_0)
	return arg_160_0.allDamageRankList
end

function var_0_0.getDistriList(arg_161_0)
	return arg_161_0.guildDistriList
end

function var_0_0.getSelfAppliedInfo(arg_162_0)
	return arg_162_0.appliedInfo
end

return var_0_0
