local var_0_0 = class("CampaignAutoStatus")

function var_0_0.ctor(arg_1_0)
	arg_1_0:reset()

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.reset(arg_2_0)
	arg_2_0.campaignAutoData = {}
end

function var_0_0.getCampaignAutoStatus(arg_3_0, arg_3_1)
	if arg_3_0.campaignAutoData[arg_3_1] == nil then
		local var_3_0 = xyd.db.openGameData()
		local var_3_1 = arg_3_0.selfPlayer.playerID
		local var_3_2 = var_3_0:prepare("SELECT * FROM campaignAutoStatus WHERE campaignType = ? AND playerID = ?")

		var_3_2:bind_values(arg_3_1, var_3_1)
		var_3_2:step()
		var_3_2:reset()

		for iter_3_0 in var_3_2:nrows() do
			arg_3_0.campaignAutoData[arg_3_1] = iter_3_0.autoStatus

			break
		end
	end

	if arg_3_0.campaignAutoData[arg_3_1] and arg_3_0.campaignAutoData[arg_3_1] == 1 then
		return true
	end

	return false
end

function var_0_0.setCampaignAutoStatus(arg_4_0, arg_4_1, arg_4_2)
	if arg_4_1 == nil or arg_4_2 == nil then
		return
	end

	local var_4_0 = 0

	if arg_4_2 then
		var_4_0 = 1
	end

	arg_4_0.campaignAutoData[arg_4_1] = var_4_0

	local var_4_1 = xyd.db.openGameData():prepare("        INSERT OR REPLACE INTO campaignAutoStatus (campaignType, playerID, autoStatus) VALUES (?, ?, ?)\n    ")
	local var_4_2 = arg_4_0.selfPlayer.playerID

	var_4_1:bind_values(arg_4_1, var_4_2, var_4_0)
	var_4_1:step()
	var_4_1:reset()
end

return var_0_0
