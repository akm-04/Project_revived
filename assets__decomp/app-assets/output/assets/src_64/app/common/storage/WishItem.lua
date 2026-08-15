local var_0_0 = class("WishItem")

function var_0_0.ctor(arg_1_0)
	cc(arg_1_0):addComponent("components.behavior.EventProtocol"):exportMethods()
	arg_1_0:load_()
end

function var_0_0.persist(arg_2_0)
	if not arg_2_0.loaded_ then
		return
	end

	local var_2_0 = xyd.db.openGameData():prepare("\t\tINSERT OR REPLACE INTO wishitems (id, refresh_time, wish_items)\n        VALUES (0, ?, ?)\n\t")

	var_2_0:bind_values(arg_2_0.refreshTime, arg_2_0.wishItems)
	var_2_0:step()
	var_2_0:reset()
end

function var_0_0.setRefreshTime(arg_3_0, arg_3_1)
	arg_3_0.refreshTime = arg_3_1

	arg_3_0:persist()
end

function var_0_0.setWishItems(arg_4_0, arg_4_1)
	arg_4_0.wishItems = arg_4_1

	arg_4_0:persist()
end

function var_0_0.getItems(arg_5_0)
	local var_5_0 = {}

	if arg_5_0.wishItems == nil then
		return var_5_0
	end

	while true do
		local var_5_1, var_5_2 = text:find("|")

		if var_5_1 == nil then
			table.insert(var_5_0, text)

			break
		else
			table.insert(var_5_0, text:sub(1, var_5_1 - 1))

			text = text:sub(var_5_2 + 1)
		end
	end

	return var_5_0
end

function var_0_0.load_(arg_6_0)
	for iter_6_0 in xyd.db.openGameData():prepare("SELECT * FROM wishitems"):nrows() do
		arg_6_0.refreshTime = tonumber(iter_6_0.refresh_time)
		arg_6_0.wish_items = tonumber(iter_6_0.wish_items)

		break
	end

	arg_6_0.loaded_ = true
end

return var_0_0
