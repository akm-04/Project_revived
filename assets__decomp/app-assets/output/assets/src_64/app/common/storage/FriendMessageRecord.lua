local var_0_0 = class("FriendMessageRecord")

function var_0_0.ctor(arg_1_0)
	local var_1_0 = xyd.db.openFriendMessageData()

	arg_1_0:reset()
end

function var_0_0.reset(arg_2_0)
	arg_2_0.messageInfos_ = {}
end

function var_0_0.getFriendMessages(arg_3_0, arg_3_1, arg_3_2, arg_3_3)
	arg_3_0:reset()

	local var_3_0 = xyd.db.openFriendMessageData():prepare("SELECT * FROM friendMessageRecord WHERE playerID = ? AND friendID = ? ORDER BY time DESC LIMIT 0, ?")

	var_3_0:bind_values(arg_3_1, arg_3_2, arg_3_3)
	var_3_0:step()
	var_3_0:reset()

	for iter_3_0 in var_3_0:nrows() do
		table.insert(arg_3_0.messageInfos_, 1, iter_3_0)
	end

	return arg_3_0.messageInfos_
end

function var_0_0.addFriendMessage(arg_4_0, arg_4_1)
	if not arg_4_1.playerID or not arg_4_1.friendID or not arg_4_1.time or not arg_4_1.message or not arg_4_1.msgType or not arg_4_1.id or not arg_4_1.isOwnSend then
		return
	end

	local var_4_0 = xyd.db.openFriendMessageData():prepare("        INSERT INTO friendMessageRecord (id, playerID, friendID, time, message, msgType, isOwnSend) VALUES (?, ?, ?, ?, ?, ?, ?)\n    ")

	var_4_0:bind_values(arg_4_1.id, arg_4_1.playerID, arg_4_1.friendID, arg_4_1.time, arg_4_1.message, arg_4_1.msgType, arg_4_1.isOwnSend)
	var_4_0:step()
	var_4_0:reset()
end

function var_0_0.deleteFriendMessage(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = xyd.db.openFriendMessageData():prepare("DELETE FROM friendMessageRecord WHERE playerID = ? AND friendID = ?")

	var_5_0:bind_values(arg_5_1, arg_5_2)
	var_5_0:step()
	var_5_0:reset()
end

function var_0_0.deleteRecordsIfOverlimit(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	if not arg_6_1 or not arg_6_2 or not arg_6_3 then
		return
	end

	local var_6_0 = xyd.db.openFriendMessageData():prepare("        DELETE FROM friendMessageRecord WHERE id IN (SELECT id FROM friendMessageRecord WHERE playerID = ? AND friendID = ? ORDER BY time DESC LIMIT (SELECT COUNT(id) FROM friendMessageRecord WHERE playerID = ? AND friendID = ?) OFFSET ?)\n    ")

	var_6_0:bind_values(arg_6_1, arg_6_2, arg_6_1, arg_6_2, arg_6_3)
	var_6_0:step()
	var_6_0:reset()
end

return var_0_0
