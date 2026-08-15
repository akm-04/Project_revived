local var_0_0 = class("TwoYearsModel", import(".BaseModel"))
local var_0_1 = 1001
local var_0_2 = xyd.tables.hero
local var_0_3 = import("app.model.Hero")
local var_0_4 = import("app.model.Pet")

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.loadInfo(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	local var_3_1 = {
		activity_id = xyd.Activities.TwoYears
	}

	var_3_0:loadSingleActivity(var_3_1, function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK then
			arg_3_0.activity = arg_4_1
			arg_3_0.details = arg_3_0.activity.details
			arg_3_0.campaignList = arg_3_0.details.campaign_list
			arg_3_0.baseInfo = arg_3_0.details.base_info
			arg_3_0.invitedList = arg_3_0.details.invited_list or {}
			arg_3_0.openCampaignID = arg_3_0.baseInfo.open_id or var_0_1

			if arg_3_2 then
				arg_3_2(arg_4_0, arg_4_1)
			end
		end
	end)
end

function var_0_0.getAnniFightHeroList(arg_5_0, arg_5_1, arg_5_2)
	xyd.Backend.get():request(xyd.mid.GET_ANNI_FIGHT_HERO_LIST, arg_5_1, function(arg_6_0, arg_6_1)
		if arg_6_0 == xyd.error.OK then
			arg_5_0.uninvitedList = arg_6_1.uninvited_list

			if arg_5_2 then
				arg_5_2(arg_6_0, arg_6_1)
			end
		end
	end)
end

function var_0_0.getAnniFightRankList(arg_7_0, arg_7_1, arg_7_2)
	xyd.Backend.get():request(xyd.mid.GET_ANNI_FIGHT_RANK_LIST, arg_7_1, function(arg_8_0, arg_8_1)
		if arg_8_0 == xyd.error.OK and arg_7_2 then
			arg_7_2(arg_8_0, arg_8_1)
		end
	end)
end

function var_0_0.getAnniFightStarAward(arg_9_0, arg_9_1, arg_9_2)
	xyd.Backend.get():request(xyd.mid.GET_ANNI_FIGHT_STAR_AWARD, arg_9_1, function(arg_10_0, arg_10_1)
		if arg_10_0 == xyd.error.OK then
			arg_9_0.baseInfo = arg_10_1.base_info
			arg_9_0.openCampaignID = arg_9_0.baseInfo.open_id or var_0_1

			arg_9_0.selfPlayer:handleRewards(arg_10_1.awards)

			if arg_9_2 then
				arg_9_2(arg_10_0, arg_10_1)
			end
		end
	end)
end

function var_0_0.getPreFightDetails(arg_11_0, arg_11_1, arg_11_2)
	xyd.Backend.get():request(xyd.mid.GET_FIGHT_MONSTER_DETAILS, arg_11_1, function(arg_12_0, arg_12_1)
		if arg_12_0 == xyd.error.OK then
			arg_11_0.monsterInfos = arg_12_1.monster_infos

			if arg_11_2 then
				arg_11_2(arg_12_0, arg_12_1)
			end
		end
	end)
end

function var_0_0.getTempEnemiesInfo(arg_13_0)
	local var_13_0 = {}

	for iter_13_0 = 1, #arg_13_0.monsterInfos do
		local var_13_1 = arg_13_0.monsterInfos[iter_13_0]

		var_13_1.health = 1
		var_13_0[tostring(var_13_1.monster_id)] = var_13_1
	end

	return var_13_0
end

function var_0_0.getSelfHeroesInfo(arg_14_0)
	local var_14_0 = {}

	for iter_14_0 = 1, #arg_14_0.invitedList do
		local var_14_1 = arg_14_0.invitedList[iter_14_0]

		var_14_1.health = 1
		var_14_0[tostring(var_14_1.table_id)] = var_14_1
	end

	return var_14_0
end

function var_0_0.anniStartFight(arg_15_0, arg_15_1, arg_15_2)
	xyd.Backend.get():request(xyd.mid.ANNI_START_FIGHT, arg_15_1, function(arg_16_0, arg_16_1)
		if arg_16_0 == xyd.error.OK and arg_15_2 then
			arg_15_2(arg_16_0, arg_16_1)
		end
	end)
end

function var_0_0.getFriendLimit(arg_17_0, arg_17_1, arg_17_2)
	xyd.Backend.get():request(xyd.mid.GIVE_FRIEND_LIMIT, arg_17_1, function(arg_18_0, arg_18_1)
		if arg_18_0 == xyd.error.OK and arg_17_2 then
			arg_17_2(arg_18_0, arg_18_1)
		end
	end)
end

function var_0_0.giveAnniMissionItem(arg_19_0, arg_19_1, arg_19_2)
	xyd.Backend.get():request(xyd.mid.GIVE_ANNI_MISSION_ITEM, arg_19_1, function(arg_20_0, arg_20_1)
		if arg_20_0 == xyd.error.OK then
			local var_20_0 = {
				itemID = arg_19_1.item_id,
				itemNum = arg_19_1.item_num
			}

			arg_19_0.selfPlayer:getBackpack():removeItem(var_20_0)

			if arg_20_1.hero_info then
				for iter_20_0, iter_20_1 in pairs(arg_19_0.uninvitedList) do
					if iter_20_1.table_id == arg_20_1.hero_info.table_id then
						arg_19_0.uninvitedList[iter_20_0] = arg_20_1.hero_info

						break
					end
				end

				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.TWO_YEARS_MISSION_COMPLETE,
					params = {
						mission_info = arg_20_1.hero_info.mission_info,
						table_id = arg_20_1.hero_info.table_id
					}
				})
			elseif arg_20_1.hero_list then
				if arg_20_1.hero_list.invited_list then
					arg_19_0.invitedList = arg_20_1.hero_list.invited_list
				end

				if arg_20_1.hero_list.uninvited_list then
					arg_19_0.uninvitedList = arg_20_1.hero_list.uninvited_list
				end

				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.TWO_YEARS_HEROES_REFRESH,
					params = {}
				})
			end

			if arg_19_2 then
				arg_19_2(arg_20_0, arg_20_1)
			end
		end
	end)
end

function var_0_0.anniRefreshHeroes(arg_21_0, arg_21_1, arg_21_2)
	xyd.Backend.get():request(xyd.mid.ANNI_REFRESH_HEROES, arg_21_1, function(arg_22_0, arg_22_1)
		if arg_22_0 == xyd.error.OK then
			arg_21_0.baseInfo = arg_22_1.base_info
			arg_21_0.openCampaignID = arg_21_0.baseInfo.open_id or var_0_1

			if arg_22_1.hero_list.invited_list then
				arg_21_0.invitedList = arg_22_1.hero_list.invited_list
			else
				for iter_22_0 = #arg_21_0.invitedList, 1, -1 do
					if arg_21_0.invitedList[iter_22_0].hp == 0 then
						table.remove(arg_21_0.invitedList, iter_22_0)
					end
				end
			end

			arg_21_0.uninvitedList = arg_22_1.hero_list.uninvited_list

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.TWO_YEARS_HEROES_REFRESH,
				params = {}
			})

			if arg_21_2 then
				arg_21_2(arg_22_0, arg_22_1)
			end
		end
	end)
end

function var_0_0.getHeroList(arg_23_0)
	return arg_23_0.invitedList, arg_23_0.uninvitedList
end

function var_0_0.initEnemies(arg_24_0, arg_24_1)
	local var_24_0 = {}
	local var_24_1 = {}

	for iter_24_0 = 1, #arg_24_1 do
		local var_24_2 = arg_24_1[iter_24_0]

		if var_0_2:summonType(var_24_2.monster_id) ~= 4 then
			local var_24_3 = var_0_3.new()

			var_24_3:populateWithTableID(var_24_2.monster_id)

			var_24_2.health = 1
			var_24_3.status_ = var_24_2

			table.insert(var_24_0, var_24_3)
		else
			local var_24_4 = var_0_3.new()
			local var_24_5 = var_0_4.new()

			var_24_4:populateWithTableID(var_24_2.monster_id)
			var_24_5:populate(var_24_4:toParams())

			var_24_1 = var_24_5
		end
	end

	return var_24_0, var_24_1
end

function var_0_0.getHeroStatus(arg_25_0)
	return {
		rent_list = {},
		self_list = arg_25_0:getSelfHeroesInfo()
	}
end

function var_0_0.getFightHeroes(arg_26_0)
	local var_26_0 = {}

	for iter_26_0 = 1, #arg_26_0.invitedList do
		local var_26_1 = arg_26_0.invitedList[iter_26_0]
		local var_26_2 = var_0_3.new()

		var_26_2:initUnCollected(var_26_1.table_id)

		var_26_2.heroID_ = var_26_1.table_id

		arg_26_0:formatTwoYearsHero(var_26_2)
		table.insert(var_26_0, var_26_2)
	end

	return var_26_0
end

function var_0_0.formatTwoYearsHero(arg_27_0, arg_27_1)
	arg_27_1.color_ = 16
	arg_27_1.level_ = 100
	arg_27_1.star_ = 5
end

return var_0_0
