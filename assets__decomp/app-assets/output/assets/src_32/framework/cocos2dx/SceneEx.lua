local var_0_0 = cc
local var_0_1 = var_0_0.Scene

function var_0_1.setAutoCleanupEnabled(arg_1_0)
	arg_1_0:addNodeEventListener(var_0_0.NODE_EVENT, function(arg_2_0)
		dump(arg_2_0)

		if arg_2_0.name == "exit" and arg_1_0.autoCleanupImages_ and next(arg_1_0.autoCleanupImages_) then
			for iter_2_0, iter_2_1 in pairs(arg_1_0.autoCleanupImages_) do
				display.removeSpriteFrameByImageName(iter_2_0)
			end

			arg_1_0.autoCleanupImages_ = nil
		end
	end)
end

function var_0_1.markAutoCleanupImage(arg_3_0, arg_3_1)
	if not arg_3_0.autoCleanupImages_ then
		arg_3_0.autoCleanupImages_ = {}
	end

	arg_3_0.autoCleanupImages_[arg_3_1] = true

	return arg_3_0
end
