local var_0_0 = class("RankList", import(".BaseModel"))
local var_0_1 = xyd.tables.rank

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.rankList_ = {}
	arg_1_0.rankListItemsInfo_ = {}

	arg_1_0:init()
end

function var_0_0.init(arg_2_0)
	local var_2_0 = var_0_1:ids()

	for iter_2_0 = 1, #var_2_0 do
		local var_2_1 = var_2_0[iter_2_0]

		if var_0_1:isShow(var_2_1) == 1 then
			local var_2_2 = var_0_1:type(var_2_1)
			local var_2_3 = var_0_1:subType(var_2_1)

			if not arg_2_0.rankList_[var_2_2] then
				arg_2_0.rankList_[var_2_2] = arg_2_0:formationVal(var_2_2, "")
			end

			local var_2_4 = arg_2_0:formationSubVal(var_2_3, nil, nil)

			table.insert(arg_2_0.rankList_[var_2_2].subList, var_2_4)
		end
	end
end

function var_0_0.getRankData(arg_3_0, arg_3_1)
	local var_3_0 = {}

	for iter_3_0, iter_3_1 in ipairs(arg_3_1) do
		local var_3_1 = var_0_1:type(iter_3_1)
		local var_3_2 = var_0_1:subType(iter_3_1)

		if not var_3_0[var_3_1] then
			var_3_0[var_3_1] = arg_3_0:formationVal(var_3_1, "")
		end

		local var_3_3 = arg_3_0:formationSubVal(var_3_2, nil, nil)

		table.insert(var_3_0[var_3_1].subList, var_3_3)
	end

	return var_3_0
end

function var_0_0.resetSpecialSubList(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4)
	if arg_4_3 then
		if arg_4_0.rankList_[arg_4_1] then
			for iter_4_0, iter_4_1 in pairs(arg_4_0.rankList_[arg_4_1].subList) do
				if iter_4_1.sub_type == arg_4_2 then
					return
				end
			end
		else
			arg_4_0.rankList_[arg_4_1] = arg_4_0:formationVal(arg_4_1, "")
		end

		local var_4_0 = arg_4_0:formationSubVal(arg_4_2, nil, nil)

		if arg_4_4 then
			table.insert(arg_4_0.rankList_[arg_4_1].subList, arg_4_4, var_4_0)
		else
			table.insert(arg_4_0.rankList_[arg_4_1].subList, var_4_0)
		end
	elseif arg_4_0.rankList_[arg_4_1] then
		for iter_4_2, iter_4_3 in ipairs(arg_4_0.rankList_[arg_4_1].subList) do
			if iter_4_3.sub_type == arg_4_2 then
				table.remove(arg_4_0.rankList_[arg_4_1].subList, iter_4_2)

				return
			end
		end
	end
end

function var_0_0.clearRealTimeInfo(arg_5_0, arg_5_1)
	for iter_5_0, iter_5_1 in pairs(arg_5_0.rankListItemsInfo_) do
		local var_5_0 = var_0_1:getIDBySubType(iter_5_0)

		if var_5_0 and (var_0_1:isRealtime(var_5_0) == 1 or arg_5_1) then
			arg_5_0:delRankInfoByType(iter_5_0)
		end
	end
end

function var_0_0.loadRankList(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	arg_6_0:clearRealTimeInfo(arg_6_2)

	local var_6_0 = {}

	for iter_6_0 = 1, #arg_6_1 do
		if not arg_6_0.rankListItemsInfo_[arg_6_1[iter_6_0]] then
			table.insert(var_6_0, arg_6_1[iter_6_0])
		end
	end

	if not next(var_6_0) then
		if arg_6_3 then
			arg_6_3(xyd.error.OK, {})
		end

		return
	end

	local var_6_1 = {
		rank_types = var_6_0
	}

	xyd.Backend.get():request(xyd.mid.LOAD_RANK_LIST, var_6_1, function(arg_7_0, arg_7_1)
		if arg_7_0 == xyd.error.OK and arg_7_1 and arg_7_1.rank_list and next(arg_7_1.rank_list) then
			local var_7_0 = arg_7_1.rank_list

			for iter_7_0 = 1, #var_7_0 do
				if var_7_0[iter_7_0] and next(var_7_0[iter_7_0]) then
					local var_7_1 = var_7_0[iter_7_0].rank_type
					local var_7_2 = var_7_0[iter_7_0].rank_info or {}

					arg_6_0:setRankInfoBySubType(var_7_1, var_7_2)
				end
			end
		end

		if arg_6_3 then
			arg_6_3(arg_7_0, arg_7_1)
		end
	end)
end

function var_0_0.getRankList(arg_8_0)
	return arg_8_0.rankList_ or {}
end

function var_0_0.getRankInfoByType(arg_9_0, arg_9_1)
	if not arg_9_0.rankListItemsInfo_[arg_9_1] then
		return arg_9_0:formationSubVal(arg_9_1, {}, {})
	end

	local var_9_0 = arg_9_0.rankListItemsInfo_[arg_9_1]
	local var_9_1 = {}

	return (arg_9_0:formationSubVal(arg_9_1, var_9_0.my_rank, var_9_0.rank_info or {}))
end

function var_0_0.setRankInfoBySubType(arg_10_0, arg_10_1, arg_10_2)
	arg_10_0.rankListItemsInfo_[arg_10_1] = arg_10_2
end

function var_0_0.delRankInfoByType(arg_11_0, arg_11_1)
	arg_11_0.rankListItemsInfo_[arg_11_1] = nil
end

function var_0_0.formationSubVal(arg_12_0, arg_12_1, arg_12_2, arg_12_3)
	local var_12_0 = var_0_1:getIDBySubType(arg_12_1)

	if not var_12_0 then
		return {}
	end

	local var_12_1 = var_0_1:title(var_12_0)
	local var_12_2 = var_0_1:infoText(var_12_0)

	return {
		sub_type = arg_12_1,
		title = var_12_1,
		info_text = var_12_2,
		rankList = arg_12_3,
		myRank = arg_12_0:getMyRank(arg_12_1, arg_12_2)
	}
end

function var_0_0.getMyRank(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0

	if type(arg_13_2) == "number" then
		var_13_0 = {
			rank = arg_13_2
		}
	elseif type(arg_13_2) == "table" then
		var_13_0 = arg_13_2
	end

	if arg_13_1 == xyd.SubRankType.ARENA_RANK then
		if arg_13_2 then
			var_13_0.score = var_13_0.rank
		end
	elseif arg_13_1 == xyd.SubRankType.SKYCITY_SUB_RANK or arg_13_1 == xyd.SubRankType.SKYCITY_SUB_RANK_2 then
		if var_13_0 and var_13_0.rank and var_13_0.rank > 0 then
			var_13_0.score = var_13_0.my_floor
		end
	elseif (arg_13_1 == xyd.SubRankType.PARADISE_GUILD_DAMAGE or arg_13_1 == xyd.SubRankType.GUILD_RANK_INFO or arg_13_1 == xyd.SubRankType.TOTAL_GUILD_RANK) and var_13_0 and arg_13_0.guild.guild_id and arg_13_0.guild.guild_id ~= 0 then
		var_13_0.name = arg_13_0.guild.guild_name
		var_13_0.icon = arg_13_0.guild.guild_icon
	end

	return var_13_0
end

function var_0_0.formationVal(arg_14_0, arg_14_1, arg_14_2)
	return {
		type = arg_14_1,
		title = arg_14_2,
		subList = {}
	}
end

return var_0_0
