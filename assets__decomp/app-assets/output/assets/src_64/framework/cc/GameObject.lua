local var_0_0 = import(".Registry")

return {
	extend = function(arg_1_0)
		arg_1_0.components_ = {}

		function arg_1_0.checkComponent(arg_2_0, arg_2_1)
			return arg_2_0.components_[arg_2_1] ~= nil
		end

		function arg_1_0.addComponent(arg_3_0, arg_3_1)
			local var_3_0 = var_0_0.newObject(arg_3_1)

			arg_3_0.components_[arg_3_1] = var_3_0

			var_3_0:bind_(arg_3_0)

			return var_3_0
		end

		function arg_1_0.removeComponent(arg_4_0, arg_4_1)
			local var_4_0 = arg_4_0.components_[arg_4_1]

			if var_4_0 then
				var_4_0:unbind_()
			end

			arg_4_0.components_[arg_4_1] = nil
		end

		function arg_1_0.getComponent(arg_5_0, arg_5_1)
			return arg_5_0.components_[arg_5_1]
		end

		return arg_1_0
	end
}
