local var_0_0 = class("BoardRedMark")

function var_0_0.ctor(arg_1_0)
	return
end

function var_0_0.reset(arg_2_0)
	return
end

function var_0_0.getAllNoticeIDs(arg_3_0, arg_3_1)
	local var_3_0 = {}
	local var_3_1 = xyd.db.openGameData():prepare("SELECT * FROM boardRedMark WHERE playerID = ?")

	var_3_1:bind_values(arg_3_1)
	var_3_1:step()
	var_3_1:reset()

	for iter_3_0 in var_3_1:nrows() do
		var_3_0[iter_3_0.noticeID] = 0
	end

	return var_3_0
end

function var_0_0.deleteNoticeID(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0 = xyd.db.openGameData():prepare("DELETE FROM boardRedMark WHERE playerID = ? AND noticeID = ?")

	var_4_0:bind_values(arg_4_1, arg_4_2)
	var_4_0:step()
	var_4_0:reset()
end

function var_0_0.updateNoticeID(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = xyd.db.openGameData():prepare("        INSERT OR REPLACE INTO boardRedMark (playerID, noticeID) VALUES (?, ?)\n    ")

	var_5_0:bind_values(arg_5_1, arg_5_2)
	var_5_0:step()
	var_5_0:reset()
end

function var_0_0.updateMarkedNoticeIDs(arg_6_0, arg_6_1, arg_6_2)
	for iter_6_0, iter_6_1 in pairs(arg_6_2) do
		if iter_6_1 == 0 then
			arg_6_0:deleteNoticeID(arg_6_1, iter_6_0)
		end
	end
end

return var_0_0
