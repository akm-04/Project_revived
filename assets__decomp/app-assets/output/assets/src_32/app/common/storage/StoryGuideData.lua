local var_0_0 = class("StoryGuideData")

function var_0_0.ctor(arg_1_0)
	arg_1_0:load_()
end

function var_0_0.persist(arg_2_0)
	if not arg_2_0.loaded_ then
		return
	end

	local var_2_0 = xyd.db.openGameData():prepare("        INSERT OR REPLACE INTO storyGuideData (id, storyID, guideID, funcIDs) VALUES (0, ?, ?, ?)\n    ")

	if arg_2_0.storyID == nil then
		arg_2_0.storyID = 0
	end

	if arg_2_0.guideID == nil then
		arg_2_0.guideID = 0
	end

	local var_2_1 = ""

	if arg_2_0.funcIDs ~= nil or next(arg_2_0.funcIDs) ~= nil then
		var_2_1 = table.concat(arg_2_0.funcIDs, "|")
	end

	var_2_0:bind_values(arg_2_0.storyID, arg_2_0.guideID, var_2_1)
	var_2_0:step()
	var_2_0:reset()
end

function var_0_0.reset(arg_3_0)
	arg_3_0.storyID = 0
	arg_3_0.guideID = 0
	arg_3_0.funcIDs = {}
end

function var_0_0.load_(arg_4_0)
	arg_4_0.playerID = 0
	arg_4_0.guideID = 0
	arg_4_0.storyID = 0
	arg_4_0.funcIDs = {}

	for iter_4_0 in xyd.db.openGameData():prepare("SELECT * FROM storyGuideData"):nrows() do
		arg_4_0.storyID = tonumber(iter_4_0.storyID)
		arg_4_0.guideID = tonumber(iter_4_0.guideID)

		if iter_4_0.funcIDs then
			for iter_4_1 in string.gmatch(iter_4_0.funcIDs, "[-]?%d+") do
				table.insert(arg_4_0.funcIDs, tonumber(iter_4_1))
			end
		end

		break
	end

	arg_4_0.loaded_ = true
end

return var_0_0
