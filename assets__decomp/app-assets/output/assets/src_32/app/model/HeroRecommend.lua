local var_0_0 = class("HeroRecommend", import(".BaseModel"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = xyd.tables.translation
local var_0_3 = {
	"hero_recommend",
	"hero_recommend_rank",
	"hero_recommend_detail",
	"hero_recommend_player_rank"
}

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.heros = arg_1_0.selfPlayer:getHeros()
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.getHeroScore(arg_3_0, arg_3_1, arg_3_2)
	arg_3_1 = arg_3_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_HERO_SCORE, arg_3_1, function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK then
			-- block empty
		end

		if arg_3_2 then
			arg_3_2(arg_4_0, arg_4_1)
		end
	end)
end

function var_0_0.getRecommendInfo(arg_5_0, arg_5_1, arg_5_2)
	arg_5_1 = arg_5_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_RECOMMEND_INFO, arg_5_1, function(arg_6_0, arg_6_1)
		if arg_6_0 == xyd.error.OK then
			arg_5_0:initialData(arg_6_1)
		end

		if arg_5_2 then
			arg_5_2(arg_6_0, arg_6_1)
		end
	end)
end

function var_0_0.getHeroRecommendDetail(arg_7_0, arg_7_1, arg_7_2)
	arg_7_1 = arg_7_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_HERO_RECOMMEND_DETAIL, arg_7_1, function(arg_8_0, arg_8_1)
		if arg_8_0 == xyd.error.OK then
			-- block empty
		end

		if arg_7_2 then
			arg_7_2(arg_8_0, arg_8_1)
		end
	end)
end

function var_0_0.getForceRankList(arg_9_0, arg_9_1, arg_9_2)
	arg_9_1 = arg_9_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_FORCE_RANK_LIST, arg_9_1, function(arg_10_0, arg_10_1)
		if arg_10_0 == xyd.error.OK then
			-- block empty
		end

		if arg_9_2 then
			arg_9_2(arg_10_0, arg_10_1)
		end
	end)
end

function var_0_0.initialData(arg_11_0, arg_11_1)
	arg_11_0.recommendInfo = arg_11_1
	arg_11_0.subRankList = arg_11_0.recommendInfo.sub_rank_list
	arg_11_0.totalRankList = arg_11_0.recommendInfo.total_rank_list
	arg_11_0.sxRankList = {}
	arg_11_0.notSxRankList = {}

	for iter_11_0 = 1, #arg_11_0.totalRankList do
		local var_11_0 = arg_11_0.totalRankList[iter_11_0]

		var_11_0.rank = iter_11_0

		if xyd.tables.hero:isSX(var_11_0.table_id) then
			table.insert(arg_11_0.sxRankList, var_11_0)
		else
			table.insert(arg_11_0.notSxRankList, var_11_0)
		end
	end

	arg_11_0.ownTableIds = {}

	for iter_11_1, iter_11_2 in pairs(arg_11_0.selfPlayer.heros_) do
		table.insert(arg_11_0.ownTableIds, iter_11_2:getFirstTableID())
	end

	arg_11_0.totalSubRankList = {}
	arg_11_0.collectedSubRankList = {}
	arg_11_0.unCollectedSubRankList = {}

	for iter_11_3, iter_11_4 in pairs(arg_11_0.subRankList) do
		local var_11_1 = {}
		local var_11_2 = {}
		local var_11_3 = {}

		for iter_11_5 = 1, #iter_11_4 do
			local var_11_4 = iter_11_4[iter_11_5]
			local var_11_5 = {
				table_id = var_11_4,
				rank = iter_11_5
			}

			table.insert(var_11_1, var_11_5)

			if xyd.isInTable(arg_11_0.ownTableIds, var_11_4) then
				table.insert(var_11_2, var_11_5)
			else
				table.insert(var_11_3, var_11_5)
			end
		end

		arg_11_0.totalSubRankList[iter_11_3] = var_11_1
		arg_11_0.collectedSubRankList[iter_11_3] = var_11_2
		arg_11_0.unCollectedSubRankList[iter_11_3] = var_11_3
	end
end

function var_0_0.toRecommendDetailWindow(arg_12_0, arg_12_1)
	local var_12_0 = {
		table_id = arg_12_1
	}

	arg_12_0:getHeroRecommendDetail(var_12_0, function(arg_13_0, arg_13_1)
		if arg_13_0 == xyd.error.OK then
			local var_13_0 = {
				info = arg_13_1,
				table_id = arg_12_1
			}

			if arg_13_1 and arg_13_1.force_info then
				xyd.WindowManager.get():openWindow("hero_recommend_detail", var_13_0)
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("HERO_DATA_NOT_EXIST_TIP")
				})
			end
		end
	end)
end

function var_0_0.toTujianHeroDetail(arg_14_0, arg_14_1)
	xyd.closeWindows(var_0_3)

	if xyd.WindowManager.get():getWindow("tujian_herodetail") then
		return
	end

	arg_14_0.totalIDs_ = {}
	arg_14_0.heroTotalNum_1 = {}

	for iter_14_0, iter_14_1 in ipairs(arg_14_0.heros) do
		local var_14_0 = iter_14_1:getTableID()
		local var_14_1 = xyd.getOriginHeroId(var_14_0)

		if xyd.tables.hero:isLibraryShow(var_14_1) then
			arg_14_0.totalIDs_[var_14_1] = iter_14_1

			table.insert(arg_14_0.heroTotalNum_1, iter_14_1)
		end
	end

	for iter_14_2, iter_14_3 in ipairs(xyd.tables.hero:getAllHeroes()) do
		iter_14_3 = xyd.getOriginHeroId(iter_14_3)

		if arg_14_0.totalIDs_[iter_14_3] == nil then
			local var_14_2 = var_0_1.new()

			var_14_2:initUnCollected(iter_14_3)

			if xyd.tables.hero:isLibraryShow(iter_14_3) then
				arg_14_0.totalIDs_[iter_14_3] = var_14_2

				table.insert(arg_14_0.heroTotalNum_1, var_14_2)
			end
		end
	end

	local var_14_3 = {
		heros = arg_14_0.heroTotalNum_1,
		current = arg_14_0:getCurrentIndex(arg_14_1)
	}

	xyd.WindowManager.get():openWindow("tujian_herodetail", var_14_3)
end

function var_0_0.getCurrentIndex(arg_15_0, arg_15_1)
	for iter_15_0 = 1, #arg_15_0.heroTotalNum_1 do
		if arg_15_0.heroTotalNum_1[iter_15_0]:getFirstTableID() == arg_15_1 then
			return iter_15_0
		end
	end
end

function var_0_0.handleRecommendScores(arg_16_0, arg_16_1)
	arg_16_0.heroRecommendScores = arg_16_1
end

function var_0_0.getHeroRecommendScore(arg_17_0, arg_17_1)
	if arg_17_0.heroRecommendScores and arg_17_0.heroRecommendScores[tostring(arg_17_1)] then
		return arg_17_0.heroRecommendScores[tostring(arg_17_1)]
	else
		return nil
	end
end

function var_0_0.clearRecommend(arg_18_0)
	arg_18_0.recommendInfo = nil
end

return var_0_0
