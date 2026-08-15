local var_0_0 = class("FriendNewMessagesCount")

function var_0_0.ctor(arg_1_0)
	local var_1_0 = xyd.db.openFriendNewMessagesCountData()

	arg_1_0:reset()
end

function var_0_0.reset(arg_2_0)
	arg_2_0.counts_ = {}
end

function var_0_0.getCount(arg_3_0, arg_3_1, arg_3_2)
	arg_3_0:reset()

	local var_3_0 = xyd.db.openFriendNewMessagesCountData():prepare("SELECT * FROM friendNewMessagesCount WHERE playerID = ? AND friendID = ?")

	var_3_0:bind_values(arg_3_1, arg_3_2)
	var_3_0:step()
	var_3_0:reset()

	for iter_3_0 in var_3_0:nrows() do
		table.insert(arg_3_0.counts_, iter_3_0)
	end

	if arg_3_0.counts_ and #arg_3_0.counts_ > 0 and arg_3_0.counts_[1].count then
		return arg_3_0.counts_[1].count or 0
	else
		return 0
	end
end

function var_0_0.getAllCounts(arg_4_0)
	arg_4_0:reset()

	local var_4_0 = xyd.db.openFriendNewMessagesCountData():prepare("SELECT * FROM friendNewMessagesCount")

	var_4_0:bind_values()
	var_4_0:step()
	var_4_0:reset()

	for iter_4_0 in var_4_0:nrows() do
		table.insert(arg_4_0.counts_, iter_4_0)
	end

	return arg_4_0.counts_
end

function var_0_0.addCount(arg_5_0, arg_5_1)
	if not arg_5_1.playerID or not arg_5_1.friendID or not arg_5_1.count then
		return
	end

	arg_5_1.id = xyd.generateUUID() or ""

	local var_5_0 = xyd.db.openFriendNewMessagesCountData():prepare("        INSERT INTO friendNewMessagesCount (id, playerID, friendID, count) VALUES (?, ?, ?, ?)\n    ")

	var_5_0:bind_values(arg_5_1.id, arg_5_1.playerID, arg_5_1.friendID, arg_5_1.count)
	var_5_0:step()
	var_5_0:reset()
end

function var_0_0.increaseCount(arg_6_0, arg_6_1)
	if not arg_6_1.playerID or not arg_6_1.friendID or not arg_6_1.count then
		return
	end

	local var_6_0 = arg_6_0:getCount(arg_6_1.playerID, arg_6_1.friendID)

	arg_6_1.count = arg_6_1.count + var_6_0

	arg_6_0:setCount(arg_6_1)
end

function var_0_0.setCount(arg_7_0, arg_7_1)
	if not arg_7_1.playerID or not arg_7_1.friendID or not arg_7_1.count then
		return
	end

	arg_7_0:getCount(arg_7_1.playerID, arg_7_1.friendID)

	if #arg_7_0.counts_ == 0 then
		arg_7_0:addCount(arg_7_1)

		return
	end

	local var_7_0 = xyd.db.openFriendNewMessagesCountData():prepare("        UPDATE friendNewMessagesCount SET count = ? WHERE playerID = ? and friendID = ?\n    ")

	var_7_0:bind_values(arg_7_1.count, arg_7_1.playerID, arg_7_1.friendID)
	var_7_0:step()
	var_7_0:reset()
end

function var_0_0.deleteCount(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = xyd.db.openFriendNewMessagesCountData():prepare("DELETE FROM friendNewMessagesCount WHERE playerID = ? and friendID = ?")

	var_8_0:bind_values(arg_8_1, arg_8_2)
	var_8_0:step()
	var_8_0:reset()
end

return var_0_0
