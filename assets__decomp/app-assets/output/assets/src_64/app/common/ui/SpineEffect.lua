local var_0_0 = class("SpineEffect", function(arg_1_0, arg_1_1, arg_1_2)
	if not xyd.assetDownloadErrorLog(arg_1_0) then
		return
	end

	return sp.SkeletonAnimation:create(arg_1_0, arg_1_1, arg_1_2 or 1)
end)

function var_0_0.ctor(arg_2_0, arg_2_1, arg_2_2, arg_2_3)
	arg_2_0.leftPoint = arg_2_0:pointByName_("Pleft")
	arg_2_0.rightPoint = arg_2_0:pointByName_("Pright")
end

function var_0_0.getSizeX(arg_3_0)
	return arg_3_0.rightPoint.x - arg_3_0.leftPoint.x
end

function var_0_0.pointByName_(arg_4_0, arg_4_1)
	local var_4_0, var_4_1 = arg_4_0:getBonePosition(arg_4_1)

	var_4_0 = var_4_0 or 0
	var_4_1 = var_4_1 or 0

	return cc.p(var_4_0, var_4_1)
end

function var_0_0.play(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4)
	local function var_5_0()
		local var_6_0 = arg_5_1

		arg_5_1 = nil

		if var_6_0 ~= nil then
			var_6_0()
		end
	end

	arg_5_0:registerSpineEventHandler(function(arg_7_0)
		arg_5_0:unregisterSpineEventHandler(sp.EventType.ANIMATION_COMPLETE)
		arg_5_0:unregisterSpineEventHandler(sp.EventType.ANIMATION_EVENT)
		var_5_0()
	end, sp.EventType.ANIMATION_COMPLETE)
	arg_5_0:registerSpineEventHandler(function(arg_8_0)
		if arg_8_0.eventData ~= nil and arg_8_0.eventData.name == "hit" then
			var_5_0()
		end
	end, sp.EventType.ANIMATION_EVENT)

	if arg_5_4 then
		arg_5_0:setAnimation(0, arg_5_4, arg_5_2)
	else
		arg_5_0:setAnimation(0, "texiao", arg_5_2)
	end

	if arg_5_3 then
		arg_5_0:setTimeScale(arg_5_3)
	end
end

function var_0_0.stop(arg_9_0)
	arg_9_0:clearTracks()
end

return var_0_0
