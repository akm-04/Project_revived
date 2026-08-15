local var_0_0 = class("FriendMessagesNewestTime")

function var_0_0.ctor(arg_1_0)
	local var_1_0 = xyd.db.openFriendMessagesNewestTimeData()

	arg_1_0:reset()
end

function var_0_0.reset(arg_2_0)
	arg_2_0.times_ = {}
end

function var_0_0.getTime(arg_3_0, arg_3_1, arg_3_2)
	arg_3_0:reset()

	local var_3_0 = xyd.db.openFriendMessagesNewestTimeData():prepare("SELECT * FROM FriendMessagesNewestTime WHERE playerID = ? AND friendID = ?")

	var_3_0:bind_values(arg_3_1, arg_3_2)
	var_3_0:step()
	var_3_0:reset()

	for iter_3_0 in var_3_0:nrows() do
		table.insert(arg_3_0.times_, iter_3_0)
	end

	if arg_3_0.times_ and #arg_3_0.times_ > 0 and arg_3_0.times_[1].time then
		return arg_3_0.times_[1].time or 0
	else
		return 0
	end
end

function var_0_0.getAllTimes(arg_4_0)
	arg_4_0:reset()

	local var_4_0 = xyd.db.openFriendMessagesNewestTimeData():prepare("SELECT * FROM FriendMessagesNewestTime")

	var_4_0:bind_values()
	var_4_0:step()
	var_4_0:reset()

	for iter_4_0 in var_4_0:nrows() do
		table.insert(arg_4_0.times_, iter_4_0)
	end

	return arg_4_0.times_
end

function var_0_0.addTime(arg_5_0, arg_5_1)
	if not arg_5_1.playerID or not arg_5_1.friendID or not arg_5_1.time then
		return
	end

	arg_5_1.id = xyd.generateUUID() or ""

	local var_5_0 = xyd.db.openFriendMessagesNewestTimeData():prepare("        INSERT INTO FriendMessagesNewestTime (id, playerID, friendID, time) VALUES (?, ?, ?, ?)\n    ")

	var_5_0:bind_values(arg_5_1.id, arg_5_1.playerID, arg_5_1.friendID, arg_5_1.time)
	var_5_0:step()
	var_5_0:reset()
end

function var_0_0.setTime(arg_6_0, arg_6_1)
	if not arg_6_1.playerID or not arg_6_1.friendID or not arg_6_1.time then
		return
	end

	arg_6_0:getTime(arg_6_1.playerID, arg_6_1.friendID)

	if #arg_6_0.times_ == 0 then
		arg_6_0:addTime(arg_6_1)

		return
	end

	local var_6_0 = xyd.db.openFriendMessagesNewestTimeData():prepare("        UPDATE FriendMessagesNewestTime SET time = ? WHERE playerID = ? and friendID = ?\n    ")

	var_6_0:bind_values(arg_6_1.time, arg_6_1.playerID, arg_6_1.friendID)
	var_6_0:step()
	var_6_0:reset()
end

function var_0_0.deleteTime(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = xyd.db.openFriendMessagesNewestTimeData():prepare("DELETE FROM FriendMessagesNewestTime WHERE playerID = ? and friendID = ?")

	var_7_0:bind_values(arg_7_1, arg_7_2)
	var_7_0:step()
	var_7_0:reset()
end

return var_0_0
