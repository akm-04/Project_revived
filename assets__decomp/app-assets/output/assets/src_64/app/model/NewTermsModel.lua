local var_0_0 = class("NewTermsModel", import(".BaseModel"))
local var_0_1 = 1001
local var_0_2 = xyd.tables.hero
local var_0_3 = xyd.tables.newTermMake
local var_0_4 = import("app.model.Hero")
local var_0_5 = import("app.model.Pet")

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.charm = 0
	arg_1_0.connection = 0
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.loadInfo(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	local var_3_1 = {
		activity_id = xyd.Activities.NewTerms
	}

	var_3_0:loadSingleActivity(var_3_1, function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK then
			arg_3_0.baseInfo = arg_4_1.details.base_info
			arg_3_0.collectionItems = arg_4_1.details.collection_items
			arg_3_0.gotItems = arg_4_1.details.got_items
			arg_3_0.charm = arg_3_0.baseInfo.charm
			arg_3_0.connection = arg_3_0.baseInfo.connection

			if arg_3_2 then
				arg_3_2(arg_4_0, arg_4_1)
			end
		end
	end)
end

function var_0_0.makePresent(arg_5_0, arg_5_1, arg_5_2)
	xyd.Backend.get():request(xyd.mid.NEW_TERMS_MAKE_GIFT, arg_5_1, function(arg_6_0, arg_6_1)
		if arg_6_0 == xyd.error.OK then
			local var_6_0 = arg_5_1.id
			local var_6_1 = var_0_3:combination(var_6_0)

			for iter_6_0, iter_6_1 in pairs(var_6_1) do
				local var_6_2 = {
					itemID = iter_6_1,
					itemNum = arg_5_1.num
				}

				arg_5_0.selfPlayer:getBackpack():removeItem(var_6_2)
			end

			arg_5_0.makePresentLogs = arg_6_1.logs

			if arg_5_2 then
				arg_5_2(arg_6_0, arg_6_1)
			end
		end
	end)
end

function var_0_0.getPresent(arg_7_0, arg_7_1, arg_7_2)
	xyd.Backend.get():request(xyd.mid.NEW_TERMS_GET_CONNECTION_GIFT, arg_7_1, function(arg_8_0, arg_8_1)
		if arg_8_0 == xyd.error.OK and arg_7_2 then
			arg_7_2(arg_8_0, arg_8_1)
		end
	end)
end

function var_0_0.givePresent(arg_9_0, arg_9_1, arg_9_2)
	xyd.Backend.get():request(xyd.mid.NEW_TERMS_SEND_ITEM, arg_9_1, function(arg_10_0, arg_10_1)
		if arg_10_0 == xyd.error.OK then
			if arg_10_1.connection then
				arg_9_0.connection = arg_10_1.connection or 0
			end

			if arg_9_2 then
				arg_9_2(arg_10_0, arg_10_1)
			end
		end
	end)
end

function var_0_0.getCharmRankList(arg_11_0, arg_11_1, arg_11_2)
	xyd.Backend.get():request(xyd.mid.NEW_TERMS_GET_CHARM_RANK, arg_11_1, function(arg_12_0, arg_12_1)
		if arg_12_0 == xyd.error.OK and arg_11_2 then
			arg_11_2(arg_12_0, arg_12_1)
		end
	end)
end

function var_0_0.getConnectionRankList(arg_13_0, arg_13_1, arg_13_2)
	xyd.Backend.get():request(xyd.mid.NEW_TERMS_GET_CONNECTION_RANK, arg_13_1, function(arg_14_0, arg_14_1)
		if arg_14_0 == xyd.error.OK and arg_13_2 then
			arg_13_2(arg_14_0, arg_14_1)
		end
	end)
end

function var_0_0.getMakeLogs(arg_15_0, arg_15_1, arg_15_2)
	xyd.Backend.get():request(xyd.mid.NEW_TERMS_GET_MAKE_LOGS, arg_15_1, function(arg_16_0, arg_16_1)
		if arg_16_0 == xyd.error.OK and arg_15_2 then
			arg_15_2(arg_16_0, arg_16_1)
		end
	end)
end

function var_0_0.getReceiveLogs(arg_17_0, arg_17_1, arg_17_2)
	xyd.Backend.get():request(xyd.mid.NEW_TERMS_GET_RECEIVE_LOGS, arg_17_1, function(arg_18_0, arg_18_1)
		if arg_18_0 == xyd.error.OK and arg_17_2 then
			arg_17_2(arg_18_0, arg_18_1)
		end
	end)
end

function var_0_0.getRecommendList(arg_19_0, arg_19_1, arg_19_2)
	xyd.Backend.get():request(xyd.mid.NEW_TERMS_GET_RECOMMEND_LIST, arg_19_1, function(arg_20_0, arg_20_1)
		if arg_20_0 == xyd.error.OK and arg_19_2 then
			arg_19_2(arg_20_0, arg_20_1)
		end
	end)
end

return var_0_0
