local var_0_0 = class("StateVariable")

function var_0_0.ctor(arg_1_0)
	local var_1_0 = xyd.db.openStateVariableData()

	arg_1_0:reset()
end

function var_0_0.reset(arg_2_0)
	arg_2_0.state_ = {}
end

function var_0_0.getState(arg_3_0, arg_3_1, arg_3_2)
	if not arg_3_1 or not arg_3_2 then
		return
	end

	arg_3_0:reset()

	local var_3_0 = xyd.db.openStateVariableData():prepare("SELECT * FROM stateVariable WHERE playerID = ? AND name = ?")

	var_3_0:bind_values(arg_3_1, arg_3_2)
	var_3_0:step()
	var_3_0:reset()

	for iter_3_0 in var_3_0:nrows() do
		table.insert(arg_3_0.state_, iter_3_0)
	end

	if arg_3_0.state_ and #arg_3_0.state_ > 0 and arg_3_0.state_[1].state then
		return arg_3_0.state_[1].state or 0
	else
		return 0
	end
end

function var_0_0.addState(arg_4_0, arg_4_1)
	if not arg_4_1.playerID or not arg_4_1.name or not arg_4_1.state then
		return
	end

	arg_4_1.id = xyd.generateUUID() or ""

	local var_4_0 = xyd.db.openStateVariableData():prepare("        INSERT INTO stateVariable (id, playerID, name, state) VALUES (?, ?, ?, ?)\n    ")

	var_4_0:bind_values(arg_4_1.id, arg_4_1.playerID, arg_4_1.name, arg_4_1.state)
	var_4_0:step()
	var_4_0:reset()
end

function var_0_0.setState(arg_5_0, arg_5_1)
	if not arg_5_1.playerID or not arg_5_1.name or not arg_5_1.state then
		return
	end

	arg_5_0:getState(arg_5_1.playerID, arg_5_1.name)

	if #arg_5_0.state_ == 0 then
		arg_5_0:addState(arg_5_1)

		return
	end

	local var_5_0 = xyd.db.openStateVariableData():prepare("        UPDATE stateVariable SET state = ? WHERE playerID = ? and name = ?\n    ")

	var_5_0:bind_values(arg_5_1.state, arg_5_1.playerID, arg_5_1.name)
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

function var_0_0.deleteState(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = xyd.db.openStateVariableData():prepare("DELETE FROM stateVariable WHERE playerID = ? and name = ?")

	var_7_0:bind_values(arg_7_1, arg_7_2)
	var_7_0:step()
	var_7_0:reset()
end

return var_0_0
