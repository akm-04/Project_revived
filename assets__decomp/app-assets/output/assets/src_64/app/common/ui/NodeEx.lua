function cc.Node.centerPosition(arg_1_0)
	local var_1_0 = arg_1_0:getAnchorPoint()
	local var_1_1 = arg_1_0:getContentSize()

	return cc.pAdd(cc.pSub(cc.p(arg_1_0:getPosition()), cc.p(var_1_0.x * var_1_1.width, var_1_0.y * var_1_1.height)), cc.p(0.5 * var_1_1.width, 0.5 * var_1_1.height))
end
