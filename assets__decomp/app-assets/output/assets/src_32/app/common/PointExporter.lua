local var_0_0 = class("PointExporter")

function var_0_0.get()
	if var_0_0.INSTANCE == nil then
		var_0_0.INSTANCE = var_0_0.new()
	end

	return var_0_0.INSTANCE
end

function var_0_0.save(arg_2_0)
	print("save model points")
	arg_2_0:savePoints()
end

function var_0_0.savePoints(arg_3_0)
	local var_3_0 = mode or "wb"
	local var_3_1 = xyd.tables.model:modelIDs()
	local var_3_2 = io.open("force/model_points.csv", var_3_0)

	var_3_2:write("ID\t左点X\t左点Y\t右点X\t右点Y\t头点X\t头点Y\t胸部点X\t胸部点Y\t受击点X\t受击点Y\t脚点X\t脚点Y\t攻击点数量\t攻击点坐标X\t攻击点坐标Y\n")
	var_3_2:write("ID\tPleftX\tPleftY\tPrightX\tPrightY\tPheadX\tPheadY\tPchestX\tPchestY\tPshoujiX\tPshoujiY\tPfootX\tPfootY\tPattackNum\tPattackXs\tPattackYs\n")

	for iter_3_0, iter_3_1 in pairs(var_3_1) do
		if var_3_2 then
			print("table id : " .. iter_3_1)

			local var_3_3 = xyd.HeroAnimation.new(nil, iter_3_1, 1, {
				loadAttackEffect = true
			})
			local var_3_4 = ""
			local var_3_5 = ""

			for iter_3_2 = 1, #var_3_3.attackPoints do
				var_3_4 = var_3_4 .. math.floor(var_3_3.attackPoints[iter_3_2].x)
				var_3_5 = var_3_5 .. math.floor(var_3_3.attackPoints[iter_3_2].y)

				if iter_3_2 < #var_3_3.attackPoints then
					var_3_4 = var_3_4 .. "|"
					var_3_5 = var_3_5 .. "|"
				end
			end

			local var_3_6 = arg_3_0:generateRow(iter_3_1, var_3_3.leftPoint, var_3_3.rightPoint, var_3_3.headPoint, var_3_3.chestPoint, var_3_3.attackedPoint, var_3_3.footPoint, var_3_3.numberOfAttackAnimations, var_3_4, var_3_5)

			if var_3_2:write(var_3_6) == nil then
				print("error in writing record")

				return false
			end
		end
	end

	io.close(var_3_2)

	return true
end

function var_0_0.generateRow(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7, arg_4_8, arg_4_9, arg_4_10)
	return string.format("%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%s\t%s\n", arg_4_1, arg_4_2.x, arg_4_2.y, arg_4_3.x, arg_4_3.y, arg_4_4.x, arg_4_4.y, arg_4_5.x, arg_4_5.y, arg_4_6.x, arg_4_6.y, arg_4_7.x, arg_4_7.y, arg_4_8, arg_4_9, arg_4_10)
end

return var_0_0
