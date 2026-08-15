local var_0_0 = class("MarchEnemies")

function var_0_0.ctor(arg_1_0)
	arg_1_0:reset()
end

function var_0_0.reset(arg_2_0)
	xyd.db.openGameData():exec("        DELETE FROM marchEnemies;\n    ")

	arg_2_0.teamData = {}
end

function var_0_0.getMarchEnemiesData(arg_3_0, arg_3_1)
	if arg_3_0.teamData[arg_3_1] == nil then
		local var_3_0 = xyd.db.openGameData():prepare("SELECT * FROM marchEnemies WHERE id = ?")

		var_3_0:bind_values(arg_3_1)
		var_3_0:step()
		var_3_0:reset()

		local var_3_1 = {}

		for iter_3_0 in var_3_0:nrows() do
			if var_3_1.team_id then
				if iter_3_0.team_id ~= var_3_1.team_id then
					print("mismatch team id: " .. iter_3_0.team_id .. ", should be " .. var_3_1.team_id)

					break
				end
			else
				var_3_1.team_id = iter_3_0.team_id
				var_3_1.team_name = iter_3_0.team_name
				var_3_1.team_avatar = iter_3_0.team_avatar
				var_3_1.team_level = iter_3_0.team_level
				var_3_1.heroes = {}
			end

			local var_3_2 = {
				partner_id = iter_3_0.partner_id,
				table_id = iter_3_0.table_id,
				level = iter_3_0.level,
				color = iter_3_0.color,
				star = iter_3_0.star,
				equips = iter_3_0.equips,
				fumo = iter_3_0.fumo
			}

			table.insert(var_3_1.heroes, var_3_2)
		end

		arg_3_0.teamData[arg_3_1] = var_3_1
	end

	return arg_3_0.teamData[arg_3_1]
end

function var_0_0.setMarchEnemiesData(arg_4_0, arg_4_1, arg_4_2)
	if arg_4_2 == nil or next(arg_4_2) == nil then
		return
	end

	local var_4_0 = arg_4_2.team_id
	local var_4_1 = arg_4_2.team_name
	local var_4_2 = arg_4_2.team_avatar or ""
	local var_4_3 = arg_4_2.team_level
	local var_4_4 = arg_4_2.heroes

	for iter_4_0, iter_4_1 in pairs(var_4_4) do
		local var_4_5 = xyd.db.openGameData():prepare("            INSERT OR REPLACE INTO arenaDefender (id, team_id, team_name, team_avatar, team_level, \n                partner_id, table_id, level, color, star, equips, fumo) \n                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)\n        ")

		var_4_5:bind_values(arg_4_1, var_4_0, var_4_1, var_4_2, var_4_3, iter_4_1.partner_id, iter_4_1.table_id, iter_4_1.level, iter_4_1.color, iter_4_1.star, iter_4_1.equips, iter_4_1.fumo)
		var_4_5:step()
		var_4_5:reset()
	end
end

return var_0_0
