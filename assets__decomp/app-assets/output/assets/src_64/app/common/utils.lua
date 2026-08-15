xyd = xyd or {}

require("socket")

local var_0_0 = 6

function xyd.count(arg_1_0)
	local var_1_0 = 0

	for iter_1_0, iter_1_1 in pairs(arg_1_0) do
		var_1_0 = var_1_0 + 1
	end

	return var_1_0
end

function xyd.version()
	local var_2_0 = cc.UserDefault:getInstance():getStringForKey(xyd.USER_DEFAULTS_VERSION_KEY)

	if var_2_0 == nil or #var_2_0 <= 0 then
		var_2_0 = xyd.getVersionName()
	end

	return var_2_0
end

function xyd.isZero(arg_3_0)
	return math.abs(arg_3_0) < 1e-08
end

function xyd.bool2number(arg_4_0)
	return arg_4_0 and 1 or 0
end

function xyd.utf8str(arg_5_0, arg_5_1, arg_5_2)
	local function var_5_0(arg_6_0)
		if not arg_6_0 then
			return 0
		elseif arg_6_0 > 240 then
			return 4
		elseif arg_6_0 > 225 then
			return 3
		elseif arg_6_0 > 192 then
			return 2
		else
			return 1
		end
	end

	local var_5_1 = 1

	while arg_5_1 > 1 do
		local var_5_2 = string.byte(arg_5_0, var_5_1)

		var_5_1 = var_5_1 + var_5_0(var_5_2)
		arg_5_1 = arg_5_1 - 1
	end

	local var_5_3 = var_5_1

	while arg_5_2 > 0 do
		if var_5_3 > #arg_5_0 then
			var_5_3 = #arg_5_0

			break
		end

		local var_5_4 = string.byte(arg_5_0, var_5_3)

		var_5_3 = var_5_3 + var_5_0(var_5_4)
		arg_5_2 = arg_5_2 - 1
	end

	return arg_5_0:sub(var_5_1, var_5_3 - 1)
end

function xyd.utf8len(arg_7_0)
	local function var_7_0(arg_8_0)
		if not arg_8_0 then
			return 0
		elseif arg_8_0 > 240 then
			return 4
		elseif arg_8_0 > 225 then
			return 3
		elseif arg_8_0 > 192 then
			return 2
		else
			return 1
		end
	end

	local var_7_1 = 1
	local var_7_2 = 0

	while var_7_1 <= #arg_7_0 do
		local var_7_3 = string.byte(arg_7_0, var_7_1)

		var_7_1 = var_7_1 + var_7_0(var_7_3)
		var_7_2 = var_7_2 + 1
	end

	return var_7_2
end

function xyd.getTextLen(arg_9_0)
	local function var_9_0(arg_10_0)
		if not arg_10_0 then
			return 0
		elseif arg_10_0 > 240 then
			return 4
		elseif arg_10_0 > 225 then
			return 3
		elseif arg_10_0 > 192 then
			return 2
		else
			return 1
		end
	end

	local var_9_1 = 1
	local var_9_2 = 0

	while var_9_1 <= #arg_9_0 do
		local var_9_3 = string.byte(arg_9_0, var_9_1)

		var_9_1 = var_9_1 + var_9_0(var_9_3)

		if var_9_3 > 225 and var_9_3 <= 240 then
			var_9_2 = var_9_2 + 1
		else
			var_9_2 = var_9_2 + 0.5
		end
	end

	return var_9_2
end

function xyd.getTextLenNewTTF(arg_11_0)
	local function var_11_0(arg_12_0)
		if not arg_12_0 then
			return 0
		elseif arg_12_0 > 240 then
			return 4
		elseif arg_12_0 > 225 then
			return 3
		elseif arg_12_0 > 192 then
			return 2
		else
			return 1
		end
	end

	local var_11_1 = 1
	local var_11_2 = 0

	while var_11_1 <= #arg_11_0 do
		local var_11_3 = string.byte(arg_11_0, var_11_1)

		var_11_1 = var_11_1 + var_11_0(var_11_3)

		if var_11_3 > 225 and var_11_3 <= 240 then
			var_11_2 = var_11_2 + 1
		elseif var_11_3 >= 48 and var_11_3 <= 57 then
			var_11_2 = var_11_2 + 0.65
		else
			var_11_2 = var_11_2 + 0.5
		end
	end

	return var_11_2
end

function xyd.getSplitByTextLen(arg_13_0, arg_13_1)
	local function var_13_0(arg_14_0)
		if not arg_14_0 then
			return 0
		elseif arg_14_0 > 240 then
			return 4
		elseif arg_14_0 > 225 then
			return 3
		elseif arg_14_0 > 192 then
			return 2
		else
			return 1
		end
	end

	local var_13_1 = 1
	local var_13_2 = 0

	while var_13_1 <= #arg_13_0 do
		local var_13_3 = string.byte(arg_13_0, var_13_1)

		var_13_1 = var_13_1 + var_13_0(var_13_3)

		if var_13_3 > 225 and var_13_3 <= 240 then
			var_13_2 = var_13_2 + 1
		else
			var_13_2 = var_13_2 + 0.5
		end

		if arg_13_1 <= var_13_2 then
			return xyd.getSplitUtf8Str(arg_13_0, 0, var_13_1)
		end
	end

	return arg_13_0
end

function xyd.getTextstr(arg_15_0, arg_15_1, arg_15_2)
	local function var_15_0(arg_16_0)
		if not arg_16_0 then
			return 0
		elseif arg_16_0 > 240 then
			return 4
		elseif arg_16_0 > 225 then
			return 3
		elseif arg_16_0 > 192 then
			return 2
		else
			return 1
		end
	end

	local var_15_1 = 1

	while arg_15_1 > 1 do
		local var_15_2 = string.byte(arg_15_0, var_15_1)

		var_15_1 = var_15_1 + var_15_0(var_15_2)
		arg_15_1 = arg_15_1 - 1
	end

	local var_15_3 = var_15_1

	while arg_15_2 > 0.5 do
		if var_15_3 > #arg_15_0 then
			var_15_3 = #arg_15_0 + 1

			break
		end

		local var_15_4 = string.byte(arg_15_0, var_15_3)

		var_15_3 = var_15_3 + var_15_0(var_15_4)

		if var_15_4 > 225 and var_15_4 <= 240 then
			arg_15_2 = arg_15_2 - 1
		else
			arg_15_2 = arg_15_2 - 0.5
		end
	end

	return arg_15_0:sub(var_15_1, var_15_3 - 1)
end

function xyd.getTextstrNewTTF(arg_17_0, arg_17_1, arg_17_2)
	local function var_17_0(arg_18_0)
		if not arg_18_0 then
			return 0
		elseif arg_18_0 > 240 then
			return 4
		elseif arg_18_0 > 225 then
			return 3
		elseif arg_18_0 > 192 then
			return 2
		else
			return 1
		end
	end

	local var_17_1 = 1

	while arg_17_1 > 1 do
		local var_17_2 = string.byte(arg_17_0, var_17_1)

		var_17_1 = var_17_1 + var_17_0(var_17_2)
		arg_17_1 = arg_17_1 - 1
	end

	local var_17_3 = var_17_1

	while arg_17_2 > 0.5 do
		if var_17_3 > #arg_17_0 then
			var_17_3 = #arg_17_0 + 1

			break
		end

		local var_17_4 = string.byte(arg_17_0, var_17_3)

		var_17_3 = var_17_3 + var_17_0(var_17_4)

		if var_17_4 > 225 and var_17_4 <= 240 then
			arg_17_2 = arg_17_2 - 1
		elseif var_17_4 >= 48 and var_17_4 <= 57 then
			arg_17_2 = arg_17_2 - 0.65
		else
			arg_17_2 = arg_17_2 - 0.5
		end
	end

	return arg_17_0:sub(var_17_1, var_17_3 - 1)
end

function xyd.hex2color4b(arg_19_0, arg_19_1)
	local var_19_0 = math.floor(tonumber(arg_19_0, 16))
	local var_19_1 = 0
	local var_19_2 = 0
	local var_19_3 = 0
	local var_19_4 = 255

	local function var_19_5(arg_20_0)
		return arg_20_0 % 256, math.floor(arg_20_0 / 256)
	end

	if arg_19_1 then
		var_19_4, var_19_0 = var_19_5(var_19_0)
	end

	local var_19_6, var_19_7 = var_19_5(var_19_0)
	local var_19_8, var_19_9 = var_19_5(var_19_7)
	local var_19_10, var_19_11 = var_19_5(var_19_9)

	return cc.c4b(var_19_10, var_19_8, var_19_6, var_19_4)
end

function xyd.color4b2hex(arg_21_0)
	local var_21_0 = string.format("%#x", arg_21_0.r * 256 * 256)
	local var_21_1 = string.format("%#x", arg_21_0.g * 256)
	local var_21_2 = string.format("%#x", arg_21_0.b)
	local var_21_3 = var_21_0 + var_21_1 + var_21_2
	local var_21_4 = tostring(string.format("%#x", var_21_3))

	return (string.sub(var_21_4, 3, 8))
end

function xyd.convertHex2RGB(arg_22_0)
	local var_22_0 = string.find(arg_22_0, "#")

	if not var_22_0 or var_22_0 ~= 1 then
		return
	end

	arg_22_0 = string.sub(arg_22_0, var_22_0 + 1)

	local var_22_1 = string.len(arg_22_0)

	if var_22_1 == 6 then
		return cc.c3b(tonumber(string.sub(arg_22_0, 1, 2), 16), tonumber(string.sub(arg_22_0, 3, 4), 16), tonumber(string.sub(arg_22_0, 5, 6), 16))
	elseif var_22_1 == 8 then
		return cc.c4b(tonumber(string.sub(arg_22_0, 3, 4), 16), tonumber(string.sub(arg_22_0, 5, 6), 16), tonumber(string.sub(arg_22_0, 7, 8), 16), tonumber(string.sub(arg_22_0, 1, 2), 16))
	end
end

function xyd.split(arg_23_0, arg_23_1)
	if arg_23_0 == "" or arg_23_0 == nil then
		return nil
	end

	arg_23_1 = arg_23_1 or "|"

	local var_23_0 = {}

	while true do
		local var_23_1 = string.find(arg_23_0, arg_23_1)

		if not var_23_1 then
			var_23_0[#var_23_0 + 1] = arg_23_0

			break
		end

		local var_23_2 = string.sub(arg_23_0, 1, var_23_1 - 1)

		var_23_0[#var_23_0 + 1] = var_23_2
		arg_23_0 = string.sub(arg_23_0, var_23_1 + 1, #arg_23_0)
	end

	return var_23_0
end

function xyd.splitToNumber(arg_24_0, arg_24_1)
	if arg_24_0 == "" or arg_24_0 == nil then
		return nil
	end

	local var_24_0 = {}

	while true do
		local var_24_1 = string.find(arg_24_0, arg_24_1)

		if not var_24_1 then
			var_24_0[#var_24_0 + 1] = tonumber(arg_24_0)

			break
		end

		local var_24_2 = string.sub(arg_24_0, 1, var_24_1 - 1)

		var_24_0[#var_24_0 + 1] = tonumber(var_24_2)
		arg_24_0 = string.sub(arg_24_0, var_24_1 + 1, #arg_24_0)
	end

	return var_24_0
end

function xyd.trimString(arg_25_0)
	return (string.gsub(arg_25_0, "^%s*(.-)%s*$", "%1"))
end

function xyd.rtrimString(arg_26_0)
	return (string.gsub(s, "^(.-)%s*$", "%1"))
end

function xyd.parseNumberArray(arg_27_0)
	if type(arg_27_0) ~= "string" then
		return {}
	end

	local var_27_0 = {}

	for iter_27_0 in arg_27_0:gmatch("-*%d+") do
		table.insert(var_27_0, tonumber(iter_27_0))
	end

	return var_27_0
end

function xyd.parsePositiveNumberArray(arg_28_0)
	local var_28_0 = xyd.parseNumberArray(arg_28_0)
	local var_28_1 = 1

	for iter_28_0, iter_28_1 in ipairs(var_28_0) do
		if iter_28_1 > 0 then
			var_28_0[var_28_1] = iter_28_1
			var_28_1 = var_28_1 + 1
		end
	end

	var_28_0[var_28_1] = nil

	return var_28_0
end

function xyd.scb(arg_29_0, arg_29_1)
	return function(...)
		if not tolua.isnull(arg_29_0) and arg_29_1 ~= nil then
			arg_29_1(...)
		end
	end
end

function xyd.skillInClass(arg_31_0, arg_31_1)
	for iter_31_0, iter_31_1 in ipairs(xyd.tables.skill:skillClasses(arg_31_0)) do
		if iter_31_1 == arg_31_1 then
			return true
		end
	end
end

function xyd.buffInClass(arg_32_0, arg_32_1)
	local var_32_0 = {
		arg_32_1
	}

	return xyd.buffInClasses(arg_32_0, var_32_0)
end

function xyd.buffInClasses(arg_33_0, arg_33_1)
	local var_33_0 = {}

	for iter_33_0, iter_33_1 in ipairs(arg_33_1) do
		var_33_0[iter_33_1] = true
	end

	for iter_33_2, iter_33_3 in ipairs(xyd.tables.buff:buffClasses(arg_33_0)) do
		if var_33_0[iter_33_3] then
			return true
		end
	end
end

function xyd.weightedChoise(arg_34_0)
	local var_34_0 = math.random() * xyd.list.reduce(arg_34_0, function(arg_35_0, arg_35_1)
		return arg_35_0 + arg_35_1
	end)

	for iter_34_0, iter_34_1 in ipairs(arg_34_0) do
		var_34_0 = var_34_0 - iter_34_1

		if var_34_0 < 0 then
			return iter_34_0
		end
	end

	return #arg_34_0
end

function xyd.setCascadeOpacityEnabled(arg_36_0, arg_36_1)
	arg_36_0:setCascadeOpacityEnabled(arg_36_1)

	for iter_36_0, iter_36_1 in ipairs(arg_36_0:getChildren()) do
		xyd.setCascadeOpacityEnabled(iter_36_1, arg_36_1)
	end
end

function xyd.runActionsSimultaneously(arg_37_0, arg_37_1, arg_37_2)
	local var_37_0 = 0

	local function var_37_1()
		var_37_0 = var_37_0 + 1

		if var_37_0 >= #arg_37_0 and arg_37_2 ~= nil then
			arg_37_2()
		end
	end

	for iter_37_0, iter_37_1 in ipairs(arg_37_0) do
		local var_37_2 = arg_37_1[iter_37_0]

		iter_37_1:runAction(cc.Sequence:create({
			var_37_2,
			cc.CallFunc:create(function()
				var_37_1()
			end)
		}))
	end
end

function xyd.stringDisplayHeight(arg_40_0, arg_40_1, arg_40_2)
	local var_40_0 = xyd.AssetLoader.get():loadLabel({
		text = arg_40_0,
		size = arg_40_1
	})

	var_40_0:setMaxLineWidth(arg_40_2)

	return var_40_0:getBoundingBox().height
end

function xyd.backendCallbackWrapper(arg_41_0, arg_41_1)
	return function(...)
		print("enter backendCallbackWrapper")

		if tolua.isnull(arg_41_0) then
			print("view has been autoreleased:", tostring(arg_41_0))

			return
		end

		return arg_41_1(...)
	end
end

function xyd.requestFriend(arg_43_0)
	local var_43_0 = xyd.tables.translation

	local function var_43_1(arg_44_0)
		local var_44_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SEND_REQUEST_PLAYERS)
		local var_44_1 = {
			player_id = arg_44_0
		}

		var_44_0:requestFriend(var_44_1, function(arg_45_0, arg_45_1)
			if arg_45_0 == xyd.error.OK then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_43_0:translation("REQUEST_FRIEND_COMPLETE"))
			else
				xyd.errorAlert(arg_45_1, var_43_0:translation("PLAYER_FRINED_FULL"))
			end
		end)
	end

	local function var_43_2(arg_46_0)
		local var_46_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.GET_REQUEST_PLAYERS)

		var_46_0:load(function(arg_47_0, arg_47_1)
			if arg_47_0 == xyd.error.OK then
				if var_46_0:getPlayerByID(arg_46_0) then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_43_0:translation("ALREADY_GET_FRIEND_REQUEST"))
				else
					print("checkGetRequest passed")
					var_43_1(arg_46_0)
				end
			else
				xyd.errorAlert(arg_47_1)
			end
		end)
	end

	local function var_43_3(arg_48_0)
		local var_48_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SEND_REQUEST_PLAYERS)

		var_48_0:load(function(arg_49_0, arg_49_1)
			if arg_49_0 == xyd.error.OK then
				if #var_48_0.players_ >= xyd.tables.misc.socialRequestLimit then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_43_0:translation("FRIEND_REQUEST_FULL"))
				elseif var_48_0:getPlayerByID(arg_48_0) then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_43_0:translation("ALREADY_SEND_FRIEND_REQUEST"))
				else
					print("checkSendRequest passed")
					var_43_2(arg_48_0)
				end
			else
				xyd.errorAlert(arg_49_1)
			end
		end)
	end

	return (function(arg_50_0)
		local var_50_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.FRIENDS)

		var_50_0:load(function(arg_51_0, arg_51_1)
			if arg_51_0 == xyd.error.OK then
				if #var_50_0.players_ == var_50_0.maxFriendNumLimit_ then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_43_0:translation("SELF_FRIEND_FULL"))

					return
				elseif var_50_0:getPlayerByID(arg_50_0) then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_43_0:translation("ALREADY_BE_FRIEND"))

					return
				else
					print("checkFriend passed")
					var_43_3(arg_50_0)
				end
			else
				xyd.errorAlert(arg_51_1)
			end
		end)
	end)(arg_43_0)
end

function xyd.errorAlert(arg_52_0, arg_52_1, arg_52_2)
	local var_52_0 = xyd.tables.translation:translation("NETWORK_DELAY")

	if arg_52_1 then
		var_52_0 = arg_52_1
	end

	if arg_52_0 and arg_52_0.error_code then
		local var_52_1 = xyd.tables.message:getContent(arg_52_0.error_code)

		if var_52_1 ~= "" then
			var_52_0 = var_52_1
		end
	end

	xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_52_0, arg_52_2)
end

function xyd.displaySpriteOnContainer(arg_53_0, arg_53_1, arg_53_2, arg_53_3)
	if arg_53_2 == nil then
		arg_53_2 = true
	end

	if arg_53_3 == nil then
		arg_53_3 = "center"
	end

	if arg_53_0 then
		local var_53_0 = arg_53_0:getContentSize()

		if var_53_0.width == 0 or var_53_0.height == 0 then
			var_53_0 = arg_53_0:getCascadeBoundingBox()
		end

		local var_53_1 = arg_53_1:getContentSize()

		if var_53_1.width == 0 or var_53_1.height == 0 then
			var_53_1 = arg_53_1:getCascadeBoundingBox()
		end

		if arg_53_2 then
			arg_53_0:setScale(var_53_1.width / var_53_0.width, var_53_1.height / var_53_0.height)
		end

		if arg_53_3 == "center" then
			arg_53_0:setAnchorPoint(cc.p(0.5, 0.5))
			arg_53_0:setPosition(cc.p(var_53_1.width / 2, var_53_1.height / 2))
		elseif arg_53_3 == "bottom_left" then
			arg_53_0:setAnchorPoint(cc.p(0, 0))
			arg_53_0:setPosition(cc.p(0, 0))
		elseif arg_53_3 == "bottom_right" then
			arg_53_0:setAnchorPoint(cc.p(1, 1))
			arg_53_0:setPosition(cc.p(var_53_1.width, var_53_1.height))
		end

		arg_53_1:addChild(arg_53_0)
	end
end

function xyd.refreshUIListView(arg_54_0)
	if not arg_54_0.bAsyncLoad then
		return
	end

	if #arg_54_0.items_ <= 0 then
		arg_54_0:reload()

		return
	end

	local var_54_0 = (function(arg_55_0)
		local var_55_0

		for iter_55_0, iter_55_1 in ipairs(arg_55_0.items_) do
			local var_55_1, var_55_2 = iter_55_1:getItemSize()
			local var_55_3, var_55_4 = iter_55_1:getPosition()
			local var_55_5 = iter_55_1:getAnchorPoint()
			local var_55_6 = var_55_3 - var_55_5.x * var_55_1
			local var_55_7 = var_55_4 - var_55_5.y * var_55_2

			if var_55_0 then
				var_55_0 = cc.rectUnion(var_55_0, cc.rect(var_55_6, var_55_7, var_55_1, var_55_2))
			else
				var_55_0 = cc.rect(var_55_6, var_55_7, var_55_1, var_55_2)
			end
		end

		local var_55_8 = arg_55_0.container:convertToWorldSpace(cc.p(var_55_0.x, var_55_0.y))

		var_55_0.x = var_55_8.x
		var_55_0.y = var_55_8.y

		return var_55_0
	end)(arg_54_0)
	local var_54_1 = arg_54_0:convertToNodeSpace(cc.p(var_54_0.x, var_54_0.y))
	local var_54_2 = arg_54_0.items_[1].idx_
	local var_54_3 = 0
	local var_54_4 = 0

	if cc.ui.UIScrollView.DIRECTION_VERTICAL == arg_54_0.direction then
		var_54_4 = var_54_1.y + var_54_0.height - arg_54_0.viewRect_.y - arg_54_0.viewRect_.height
	else
		var_54_3 = -arg_54_0.viewRect_.x + var_54_1.x
	end

	arg_54_0:removeAllItems()
	arg_54_0.container:setPosition(0, 0)
	arg_54_0.container:setContentSize(cc.size(0, 0))

	local var_54_5 = arg_54_0.delegate_[cc.ui.UIListView.DELEGATE](arg_54_0, cc.ui.UIListView.COUNT_TAG)

	arg_54_0.items_ = {}

	local var_54_6 = 0
	local var_54_7 = 0
	local var_54_8
	local var_54_9 = 0
	local var_54_10 = 0

	for iter_54_0 = var_54_2, var_54_5 do
		local var_54_11, var_54_12, var_54_13 = arg_54_0:loadOneItem_(cc.p(var_54_3, var_54_4), iter_54_0)

		if cc.ui.UIScrollView.DIRECTION_VERTICAL == arg_54_0.direction then
			var_54_4 = var_54_4 - var_54_13
			var_54_10 = var_54_10 + var_54_13
		else
			var_54_3 = var_54_3 + var_54_12
			var_54_9 = var_54_9 + var_54_12
		end

		if var_54_9 > arg_54_0.viewRect_.width + arg_54_0.redundancyViewVal or var_54_10 > arg_54_0.viewRect_.height + arg_54_0.redundancyViewVal then
			break
		end
	end

	if cc.ui.UIScrollView.DIRECTION_VERTICAL == arg_54_0.direction then
		arg_54_0.container:setPosition(arg_54_0.viewRect_.x, arg_54_0.viewRect_.y + arg_54_0.viewRect_.height)
	else
		arg_54_0.container:setPosition(arg_54_0.viewRect_.x, arg_54_0.viewRect_.y)
	end

	arg_54_0:increaseOrReduceItem_()
end

function xyd.elasticMoveUIScrollView(arg_56_0, arg_56_1, arg_56_2)
	local var_56_0 = arg_56_0:getScrollNodeRect()
	local var_56_1 = 0
	local var_56_2 = 0
	local var_56_3 = arg_56_0:getViewRectInWorldSpace()

	if var_56_0.width < var_56_3.width then
		if arg_56_2 then
			var_56_1 = var_56_3.x + var_56_3.width - var_56_0.x - var_56_0.width
		else
			var_56_1 = var_56_3.x - var_56_0.x
		end
	elseif var_56_0.x > var_56_3.x then
		var_56_1 = var_56_3.x - var_56_0.x
	elseif var_56_0.x + var_56_0.width < var_56_3.x + var_56_3.width then
		var_56_1 = var_56_3.x + var_56_3.width - var_56_0.x - var_56_0.width
	end

	if var_56_0.height < var_56_3.height then
		if arg_56_1 then
			var_56_2 = var_56_3.y - var_56_0.y
		else
			var_56_2 = var_56_3.y + var_56_3.height - var_56_0.y - var_56_0.height
		end
	elseif var_56_0.y > var_56_3.y then
		var_56_2 = var_56_3.y - var_56_0.y
	elseif var_56_0.y + var_56_0.height < var_56_3.y + var_56_3.height then
		var_56_2 = var_56_3.y + var_56_3.height - var_56_0.y - var_56_0.height
	end

	if var_56_1 == 0 and var_56_2 == 0 then
		return
	end

	local var_56_4, var_56_5 = arg_56_0.scrollNode:getPosition()

	arg_56_0.position_ = cc.p(var_56_4 + var_56_1, var_56_5 + var_56_2)

	arg_56_0.scrollNode:setPosition(arg_56_0.position_)
end

function xyd.formatUIText(arg_57_0, arg_57_1)
	local var_57_0 = arg_57_0:getColor()

	var_57_0.a = 255

	arg_57_0:setTextColor(var_57_0)
	arg_57_1(arg_57_0)
end

function xyd.formatAllLabels(arg_58_0, arg_58_1)
	local var_58_0 = arg_58_0:getChildren()
	local var_58_1 = arg_58_0:getChildrenCount()

	if var_58_1 < 1 then
		return
	end

	for iter_58_0 = 1, var_58_1 do
		if tolua.type(var_58_0[iter_58_0]) == "ccui.Text" then
			xyd.formatUIText(var_58_0[iter_58_0], arg_58_1)
		end

		xyd.formatAllLabels(var_58_0[iter_58_0], arg_58_1)
	end
end

function xyd.setWidgetVisible(arg_59_0, arg_59_1)
	arg_59_0:setVisible(arg_59_1)

	local var_59_0 = arg_59_0:getChildren()
	local var_59_1 = arg_59_0:getChildrenCount()

	if var_59_1 < 1 then
		return
	end

	for iter_59_0 = 1, var_59_1 do
		xyd.setWidgetVisible(var_59_0[iter_59_0], arg_59_1)
	end
end

function xyd.heroStarMiddleIconName(arg_60_0)
	if arg_60_0 == xyd.HeroRarity.WHITE then
		return "star_middle_icon_white.png"
	elseif arg_60_0 == xyd.HeroRarity.BLUE then
		return "star_middle_icon_yellow.png"
	elseif arg_60_0 == xyd.HeroRarity.PURLE then
		return "star_middle_icon_purle.png"
	else
		return ""
	end
end

function xyd.heroStarBigIconName(arg_61_0)
	if arg_61_0 == xyd.HeroRarity.WHITE then
		return "star_big_icon_white.png"
	elseif arg_61_0 == xyd.HeroRarity.BLUE then
		return "star_big_icon_yellow.png"
	elseif arg_61_0 == xyd.HeroRarity.PURLE then
		return "star_big_icon_purle.png"
	else
		return ""
	end
end

function xyd.heroStarEvolveIconName(arg_62_0)
	if arg_62_0 == xyd.HeroRarity.WHITE then
		return "star_evolve_icon_white.png"
	elseif arg_62_0 == xyd.HeroRarity.BLUE then
		return "star_evolve_icon_yellow.png"
	elseif arg_62_0 == xyd.HeroRarity.PURLE then
		return "star_evolve_icon_purle.png"
	else
		return ""
	end
end

function xyd.heroNameColor(arg_63_0)
	if arg_63_0 == xyd.HeroRarity.WHITE then
		return cc.c4b(255, 255, 255, 255)
	elseif arg_63_0 == xyd.HeroRarity.BLUE then
		return cc.c4b(255, 210, 0, 255)
	elseif arg_63_0 == xyd.HeroRarity.PURLE then
		return cc.c4b(242, 90, 220, 255)
	else
		return cc.c4b(0, 0, 0, 0)
	end
end

function xyd.heroClassMiddleIconName(arg_64_0)
	if arg_64_0 == xyd.HeroClass.WATER then
		return "water_class_hero_middle_icon.png"
	elseif arg_64_0 == xyd.HeroClass.WIND then
		return "wind_class_hero_middle_icon.png"
	elseif arg_64_0 == xyd.HeroClass.FIRE then
		return "fire_class_hero_middle_icon.png"
	elseif arg_64_0 == xyd.HeroClass.GOD then
		return "god_class_hero_middle_icon.png"
	elseif arg_64_0 == xyd.HeroClass.DEVIL then
		return "devil_class_hero_middle_icon.png"
	else
		return ""
	end
end

function xyd.heroClassBigIconName(arg_65_0)
	if arg_65_0 == xyd.HeroClass.WATER then
		return "water_class_hero_big_icon.png"
	elseif arg_65_0 == xyd.HeroClass.WIND then
		return "wind_class_hero_big_icon.png"
	elseif arg_65_0 == xyd.HeroClass.FIRE then
		return "fire_class_hero_big_icon.png"
	elseif arg_65_0 == xyd.HeroClass.GOD then
		return "god_class_hero_big_icon.png"
	elseif arg_65_0 == xyd.HeroClass.DEVIL then
		return "devil_class_hero_big_icon.png"
	else
		return ""
	end
end

function xyd.heroTypeIconName(arg_66_0)
	if arg_66_0 == xyd.HeroType.ATTACKER then
		return "hero_type_attacker.png"
	elseif arg_66_0 == xyd.HeroType.DEFENCER then
		return "hero_type_defencer.png"
	elseif arg_66_0 == xyd.HeroType.PHYSICAL then
		return "hero_type_physical.png"
	elseif arg_66_0 == xyd.HeroType.ASSISTANT then
		return "hero_type_assistant.png"
	else
		return ""
	end
end

function xyd.heroSortFunc(arg_67_0, arg_67_1)
	if arg_67_0:getStar() ~= arg_67_1:getStar() then
		return arg_67_0:getStar() > arg_67_1:getStar()
	elseif arg_67_0:getLevel() ~= arg_67_1:getLevel() then
		return arg_67_0:getLevel() > arg_67_1:getLevel()
	elseif arg_67_0:getHeroClass() ~= arg_67_1:getHeroClass() then
		return arg_67_0:getHeroClass() < arg_67_1:getHeroClass()
	elseif arg_67_0:getTableID() ~= arg_67_1:getTableID() then
		return arg_67_0:getTableID() > arg_67_1:getTableID()
	elseif arg_67_0:getAttribute(xyd.HeroAttribute.HP_LIMIT) ~= arg_67_1:getAttribute(xyd.HeroAttribute.HP_LIMIT) then
		return arg_67_0:getAttribute(xyd.HeroAttribute.HP_LIMIT) > arg_67_1:getAttribute(xyd.HeroAttribute.HP_LIMIT)
	else
		return arg_67_0:getHeroID() < arg_67_1:getHeroID()
	end
end

function xyd.playButtonSound()
	audio.playSound(xyd.tables.sound:getSound("ui_button_click"), false)
end

function xyd.playCloseSound()
	audio.playSound(xyd.tables.sound:getSound("ui_close_window"), false)
end

function xyd.playTabButtonSound()
	audio.playSound(xyd.tables.sound:getSound("ui_switch_page"), false)
end

function xyd.getFormationType(arg_71_0)
	local var_71_0

	if arg_71_0 == xyd.InstanceType.INSTANCE then
		var_71_0 = xyd.FormationType.INSTANCE
	elseif arg_71_0 == xyd.InstanceType.DUNGEON then
		var_71_0 = xyd.FormationType.DUNGEON
	else
		var_71_0 = xyd.FormationType.ARENA
	end

	return var_71_0
end

function xyd.androidPurchase(arg_72_0, arg_72_1, arg_72_2, arg_72_3, arg_72_4, arg_72_5, arg_72_6)
	if device.platform ~= "android" then
		return
	end

	local var_72_0 = xyd.Backend.get().region_
	local var_72_1 = 3

	local function var_72_2(arg_73_0)
		return
	end

	local var_72_3 = false

	if xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER).lev >= 7 then
		var_72_3 = true
	end

	arg_72_0 = arg_72_0 or {}

	local var_72_4 = ""

	for iter_72_0 = 1, #arg_72_0 do
		var_72_4 = var_72_4 .. tostring(arg_72_0[iter_72_0])

		if iter_72_0 ~= #arg_72_0 then
			var_72_4 = var_72_4 .. "|"
		end
	end

	arg_72_1 = arg_72_1 or {}

	local var_72_5 = ""

	for iter_72_1 = 1, #arg_72_1 do
		var_72_5 = var_72_5 .. tostring(arg_72_1[iter_72_1])

		if iter_72_1 ~= #arg_72_1 then
			var_72_5 = var_72_5 .. "|"
		end
	end

	local var_72_6 = "org/cocos2dx/lua/AppActivity"
	local var_72_7 = "xydPurchases"
	local var_72_8 = {
		var_72_1,
		var_72_0,
		var_72_3,
		var_72_2,
		true,
		var_72_4,
		var_72_5
	}
	local var_72_9 = "(IIZIZLjava/lang/String;Ljava/lang/String;)V"
	local var_72_10, var_72_11 = luaj.callStaticMethod(var_72_6, var_72_7, var_72_8, var_72_9)
	local var_72_12 = "xydNewPurchase"
	local var_72_13 = {
		var_72_1,
		var_72_0,
		var_72_3,
		var_72_2,
		arg_72_2,
		arg_72_3,
		arg_72_4,
		arg_72_5
	}
	local var_72_14 = "(IIZILjava/lang/String;ZLjava/lang/String;Ljava/lang/String;)V"
	local var_72_15, var_72_16 = luaj.callStaticMethod(var_72_6, var_72_12, var_72_13, var_72_14)
	local var_72_17 = "xydNPurchase"
	local var_72_18 = {
		var_72_1,
		var_72_0,
		var_72_3,
		var_72_2,
		arg_72_2,
		arg_72_4,
		arg_72_5,
		arg_72_6 or 0
	}
	local var_72_19 = "(IIZILjava/lang/String;Ljava/lang/String;Ljava/lang/String;I)V"
	local var_72_20, var_72_21 = luaj.callStaticMethod(var_72_6, var_72_17, var_72_18, var_72_19)
end

function xyd.sdkPurchase(arg_74_0, arg_74_1, arg_74_2, arg_74_3, arg_74_4, arg_74_5)
	local var_74_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	local var_74_1 = xyd.Backend.get().region_
	local var_74_2 = 3

	if device.platform == "android" then
		local function var_74_3(arg_75_0)
			return
		end

		local var_74_4 = false

		if var_74_0.lev >= 7 then
			var_74_4 = true
		end

		local var_74_5 = ""

		arg_74_2 = arg_74_2 or {}

		for iter_74_0 = 1, #arg_74_2 do
			var_74_5 = var_74_5 .. tostring(arg_74_2[iter_74_0])

			if iter_74_0 ~= #arg_74_2 then
				var_74_5 = var_74_5 .. "|"
			end
		end

		local var_74_6 = ""

		arg_74_3 = arg_74_3 or {}

		for iter_74_1 = 1, #arg_74_3 do
			var_74_6 = var_74_6 .. tostring(arg_74_3[iter_74_1])

			if iter_74_1 ~= #arg_74_3 then
				var_74_6 = var_74_6 .. "|"
			end
		end

		if arg_74_1 == nil then
			arg_74_1 = true
		end

		local var_74_7 = "org/cocos2dx/lua/AppActivity"
		local var_74_8 = "xydPurchases"
		local var_74_9 = {
			var_74_2,
			var_74_1,
			var_74_4,
			var_74_3,
			arg_74_1,
			var_74_5,
			var_74_6
		}
		local var_74_10 = "(IIZIZLjava/lang/String;Ljava/lang/String;)V"
		local var_74_11, var_74_12 = luaj.callStaticMethod(var_74_7, var_74_8, var_74_9, var_74_10)
	elseif device.platform == "ios" then
		if arg_74_2 and type(arg_74_2) ~= "number" then
			return
		end

		arg_74_2 = arg_74_2 or 0

		local var_74_13 = tostring(var_74_1)
		local var_74_14 = tostring(var_74_2)
		local var_74_15 = ""

		arg_74_3 = arg_74_3 or {}

		for iter_74_2 = 1, #arg_74_3 do
			var_74_15 = var_74_15 .. tostring(arg_74_3[iter_74_2])

			if iter_74_2 ~= #arg_74_3 then
				var_74_15 = var_74_15 .. "|"
			end
		end

		local var_74_16 = ""

		arg_74_4 = arg_74_4 or {}

		for iter_74_3 = 1, #arg_74_4 do
			var_74_16 = var_74_16 .. tostring(arg_74_4[iter_74_3])

			if iter_74_3 ~= #arg_74_4 then
				var_74_16 = var_74_16 .. "|"
			end
		end

		local var_74_17 = ""

		arg_74_5 = arg_74_5 or {}

		for iter_74_4 = 1, #arg_74_5 do
			var_74_17 = var_74_17 .. tostring(arg_74_5[iter_74_4])

			if iter_74_4 ~= #arg_74_5 then
				var_74_17 = var_74_17 .. "|"
			end
		end

		local var_74_18 = 0

		if var_74_0.lev >= 7 then
			var_74_18 = 1
		end

		local var_74_19 = 0

		if xyd.Backend.get().GMURL_ ~= nil then
			var_74_19 = 1
		end

		local var_74_20 = {
			giftbag_id = 0,
			product_id = arg_74_0,
			server_id = var_74_13,
			channel_id = var_74_14,
			new_strs = var_74_15,
			is_on = var_74_18,
			is_review = var_74_19,
			month_card_strs = var_74_16,
			giftbag_strs = var_74_17
		}

		luaoc.callStaticMethod("SdkIOS", "buy", var_74_20)
	end
end

function xyd.sdkPurchaseFinish(arg_76_0)
	if device.platform == "android" then
		local var_76_0 = ""

		arg_76_0 = arg_76_0 or {}

		for iter_76_0 = 1, #arg_76_0 do
			var_76_0 = var_76_0 .. tostring(arg_76_0[iter_76_0])

			if iter_76_0 ~= #arg_76_0 then
				var_76_0 = var_76_0 .. "|"
			end
		end

		local var_76_1 = "org/cocos2dx/lua/AppActivity"
		local var_76_2 = "xydPurchaseFinish"
		local var_76_3 = {
			var_76_0
		}
		local var_76_4 = "(Ljava/lang/String;)V"
		local var_76_5, var_76_6 = luaj.callStaticMethod(var_76_1, var_76_2, var_76_3, var_76_4)
	end
end

function xyd.sdkPickupGallery(arg_77_0)
	if device.platform == "android" then
		local var_77_0 = "org/cocos2dx/lua/AppActivity"
		local var_77_1 = "xydPickupGallery"
		local var_77_2 = 1
		local var_77_3 = {
			1,
			arg_77_0
		}
		local var_77_4 = "(II)V"
		local var_77_5, var_77_6 = luaj.callStaticMethod(var_77_0, var_77_1, var_77_3, var_77_4)
	end
end

function xyd.sdkTakePhoto(arg_78_0)
	if device.platform == "android" then
		local var_78_0 = "org/cocos2dx/lua/AppActivity"
		local var_78_1 = "xydTakePhoto"
		local var_78_2 = 1
		local var_78_3 = {
			1,
			arg_78_0
		}
		local var_78_4 = "(II)V"
		local var_78_5, var_78_6 = luaj.callStaticMethod(var_78_0, var_78_1, var_78_3, var_78_4)
	end
end

function xyd.isFunctionOpen(arg_79_0)
	local var_79_0 = xyd.tables.functionOpen:stage(arg_79_0)
	local var_79_1 = xyd.tables.functionOpen:level(arg_79_0)
	local var_79_2 = xyd.StoryData.get():getStageID()
	local var_79_3 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER).lev

	if var_79_2 < var_79_0 or var_79_3 < var_79_1 then
		return false
	end

	return true
end

function xyd.newIconAnimation()
	local var_80_0 = {
		cc.MoveBy:create(1.2, cc.p(0, 7)),
		(cc.MoveBy:create(1.2, cc.p(0, -7)))
	}
	local var_80_1 = transition.sequence(var_80_0)

	return cc.RepeatForever:create(var_80_1)
end

function xyd.highlightAnimation()
	local var_81_0 = 0.8
	local var_81_1 = cc.FadeTo:create(var_81_0, 128)
	local var_81_2 = cc.FadeTo:create(var_81_0, 255)
	local var_81_3 = cc.DelayTime:create(var_81_0)

	return cc.RepeatForever:create(cc.Sequence:create(var_81_1, var_81_2, var_81_3))
end

function xyd.isDuaringGuide()
	local var_82_0 = xyd.StoryData.get():getGuideID()
	local var_82_1 = xyd.StoryData.get():getStageID()

	if var_82_0 < xyd.GuideStoryType.GUIDE_ID_HERO_QIANGHUA or var_82_0 < xyd.GuideStoryType.GUIDE_ID_SECOND_XIANGQIAN and var_82_1 == xyd.StoryData.get().SECOND_STAGE or var_82_0 < xyd.GuideStoryType.GUIDE_ID_SET_DEFENSE and var_82_1 == xyd.StoryData.get().FIRST_MAP_LAST_STAGE then
		return true
	end

	return false
end

function xyd.functionOpenCondition(arg_83_0)
	local var_83_0 = xyd.tables.functionOpen:level(arg_83_0)
	local var_83_1 = xyd.tables.functionOpen:stage(arg_83_0)

	if var_83_0 and var_83_0 > 0 then
		xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, {
			string.format(xyd.tables.translation:translation("FUNCTION_OPEN_CONDITION_LEVEL"), var_83_0)
		})

		return
	end

	if var_83_1 and var_83_1 > 0 then
		local var_83_2 = xyd.tables.stage:name(var_83_1)

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, {
			string.format(xyd.tables.translation:translation("FUNCTION_OPEN_CONDITION_MAP"), var_83_2)
		})
	end
end

function xyd.playLevelUpAnimation()
	local var_84_0 = xyd.AssetLoader.get():loadAnimation("a_0", true)
	local var_84_1 = display.newSprite()

	var_84_1:addTo(display.getRunningScene())
	var_84_1:playAnimationOnce(var_84_0)
	var_84_1:setPosition(320, 400)
	var_84_1:setScale(2, 2)
end

function xyd.setAvatarBorder(arg_85_0, arg_85_1, arg_85_2, arg_85_3, arg_85_4, arg_85_5, arg_85_6, arg_85_7, arg_85_8, arg_85_9, arg_85_10)
	local function var_85_0(arg_86_0, arg_86_1)
		local var_86_0
		local var_86_1 = xyd.isSuperHero(arg_86_0) and arg_86_1 > xyd.MAX_STAR_LEVEL and "windows/common/small_pink_star.png" or "windows/common/small_yellow_star.png"

		return xyd.AssetLoader.get():loadSprite(var_86_1)
	end

	local var_85_1
	local var_85_2
	local var_85_3 = arg_85_2
	local var_85_4 = arg_85_3
	local var_85_5
	local var_85_6
	local var_85_7 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	local var_85_8
	local var_85_9 = false
	local var_85_10
	local var_85_11

	if type(arg_85_0) == "number" or type(arg_85_0) == "string" then
		var_85_5 = tonumber(arg_85_0)

		local var_85_12 = xyd.tables.hero:modelID(var_85_5)

		if arg_85_6 and arg_85_6 ~= 0 then
			var_85_12 = arg_85_6
		end

		var_85_1 = xyd.tables.model:avatar(var_85_12)

		if var_85_7:getHeroByTableID(var_85_5) and not arg_85_7 then
			var_85_6 = var_85_7:getHeroByTableID(var_85_5):getInscriptionKuangLevel()
		end

		if arg_85_10 then
			var_85_10 = arg_85_10
		end
	else
		if not arg_85_0 then
			return
		end

		var_85_2 = type(arg_85_2) == "boolean" and arg_85_2 == true

		local var_85_13 = arg_85_0:getModelID()

		var_85_1 = xyd.tables.model:avatar(var_85_13)
		var_85_3 = var_85_3 or arg_85_0:getColor()
		var_85_4 = var_85_4 or arg_85_0:getStar()
		arg_85_4 = arg_85_4 or arg_85_0:isAwakeTwice()
		var_85_5 = arg_85_0:getTableID()

		if arg_85_0.getInscriptionKuangLevel then
			var_85_6 = arg_85_0:getInscriptionKuangLevel()
		end

		if arg_85_0.houseExpandLev and arg_85_0.houseExpandLev > 0 then
			var_85_9 = true
		end

		local var_85_14 = arg_85_0.houseTableId

		if var_85_14 and var_85_14 > 0 then
			var_85_8 = xyd.tables.dormHouse:maintype(var_85_14)

			if var_85_8 <= 1 then
				var_85_8 = nil
			end
		end

		if not arg_85_10 then
			var_85_10 = arg_85_0:getElementType()
		else
			var_85_10 = arg_85_10
		end

		var_85_11 = arg_85_0:isActiveSP()
	end

	local var_85_15

	if arg_85_5 then
		local var_85_16 = {
			filter = {}
		}

		var_85_16.filter.name = "GRAY"
		var_85_16.filter.value = {
			0.2,
			0.3,
			0.5,
			0.1
		}
		var_85_15 = xyd.SpriteLoader.new(var_85_1, nil, var_85_16, xyd.DefaultImageType.SKILL_ICON)
	else
		var_85_15 = xyd.SpriteLoader.new(var_85_1, nil, nil, xyd.DefaultImageType.SKILL_ICON)
	end

	local var_85_17 = arg_85_1:getContentSize()

	var_85_15 = var_85_15 or xyd.AssetLoader.get():loadSprite("windows/common/common_avatar.png")

	local var_85_18 = xyd.AssetLoader:get():loadSprite("windows/common/avatar_mask.png")
	local var_85_19 = cc.ClippingNode:create()

	var_85_19:setStencil(var_85_18)
	var_85_19:setInverted(false)
	var_85_19:setAlphaThreshold(0)
	var_85_19:addChild(var_85_15)
	var_85_15:align(display.CENTER, var_85_17.width / 2, var_85_17.height / 2)
	var_85_15:scale(var_85_17.width / var_85_15:getWidth())
	var_85_18:addTo(arg_85_1, -1)
	var_85_18:align(display.CENTER, var_85_17.width / 2, var_85_17.height / 2)
	var_85_18:scale((var_85_17.width - 3) / var_85_18:getWidth())
	arg_85_1:addChild(var_85_19)

	local var_85_20 = xyd.getAvatarBorder(var_85_3)

	if xyd.tables.hero:beforeAwaken(var_85_5) > 0 then
		if arg_85_4 then
			var_85_20 = xyd.AssetLoader.get():loadSprite("windows/common/avatar_awake_twice" .. var_85_3 .. ".png")
		else
			var_85_20 = xyd.AssetLoader.get():loadSprite("windows/common/avatar_awake" .. var_85_3 .. ".png")
		end
	end

	if var_85_6 then
		var_85_20 = xyd.AssetLoader.get():loadSprite("windows/common/avatar_suit" .. var_85_6 .. ".png")
	end

	if xyd.isSuperHero(arg_85_0) then
		var_85_20 = xyd.AssetLoader.get():loadSprite("windows/common/avatar_super.png")
	end

	local var_85_21 = clone(var_85_20:getContentSize())

	xyd.displaySpriteOnContainer(var_85_20, arg_85_1, true)
	var_85_20:setName("border")

	if var_85_8 and not arg_85_9 then
		local var_85_22 = xyd.tables.dormHouseType:icon(var_85_8)

		if var_85_9 then
			var_85_22 = "images/dorm/choose/orange.png"
		end

		local var_85_23 = xyd.AssetLoader.get():loadSprite(var_85_22)

		var_85_23:setAnchorPoint(cc.p(1, 1))
		arg_85_1:addChild(var_85_23)
		var_85_23:setName("house")
		var_85_23:setPosition(cc.p(var_85_17.width + 2, var_85_17.height + 2))
		var_85_23:setLocalZOrder(100)
	end

	if var_85_10 and var_85_10 ~= 0 then
		local var_85_24 = "windows/common/hero_common/small_element_" .. var_85_10

		if var_85_11 then
			var_85_24 = var_85_24 .. "sp"
		end

		local var_85_25 = xyd.AssetLoader.get():loadSprite(var_85_24 .. ".png")

		var_85_25:setAnchorPoint(0, 1)
		var_85_25:addTo(var_85_20)
		var_85_25:setPosition(0, var_85_20:getContentSize().height)

		if var_85_11 then
			local var_85_26 = "skeletons/ui_effect/element_equip/element_" .. var_85_10 .. "xiao"
			local var_85_27 = xyd.createEffect(var_85_26)
			local var_85_28 = var_85_25:getContentSize()

			var_85_27:addTo(var_85_25)
			var_85_27:setPosition(var_85_28.width / 2, var_85_28.height / 2)
			var_85_27:play(nil, true)
		end
	end

	local var_85_29 = var_85_4

	if var_85_29 > xyd.MAX_STAR_LEVEL then
		var_85_29 = var_85_29 - xyd.MAX_STAR_LEVEL
	end

	local var_85_30 = var_85_0(arg_85_0, var_85_4):getContentSize().width - 3
	local var_85_31 = (var_85_21.width - var_85_29 * var_85_30) / 2
	local var_85_32 = display.newNode()

	var_85_32:setName("view")
	var_85_32:setContentSize(var_85_21)
	var_85_32:setAnchorPoint(cc.p(0, 0))
	var_85_32:setPosition(cc.p(0, 0))

	for iter_85_0 = 1, var_85_29 do
		local var_85_33 = var_85_0(arg_85_0, var_85_4)

		var_85_32:addChild(var_85_33)
		var_85_33:x(var_85_31 + (iter_85_0 - 1) * var_85_30):y(5)
		var_85_33:setAnchorPoint(cc.p(0, 0))
	end

	var_85_32:setScale(var_85_17.width / var_85_21.width, var_85_17.height / var_85_21.height)
	arg_85_1:addChild(var_85_32)

	if var_85_2 then
		local var_85_34 = xyd.getItemEffect(5)

		if not var_85_34 then
			return
		end

		arg_85_1:addChild(var_85_34)
		var_85_34:setLocalZOrder(-100)
		var_85_34:setPosition(var_85_17.width / 2, var_85_17.height / 2)
		var_85_34:play(nil, true)
	end

	if arg_85_8 then
		local var_85_35 = xyd.tables.hero:name(var_85_5)
		local var_85_36 = display.newScale9Sprite("windows/common/name_label_bg.png", 0, 0, cc.size(119, 25), cc.rect(5, 5, 5, 5))

		var_85_36:setAnchorPoint(cc.p(0.5, 1))

		local var_85_37 = xyd.createLabel(20, cc.c3b(255, 255, 255))

		var_85_37:setAnchorPoint(cc.p(0.5, 0.5))
		var_85_37:setString(var_85_35)
		var_85_37:addTo(var_85_36)
		var_85_37:setPosition(cc.p(var_85_36:getContentSize().width / 2, var_85_36:getContentSize().height / 2))
		var_85_36:addTo(arg_85_1)
		var_85_36:setPosition(cc.p(arg_85_1:getContentSize().width / 2, -2))
		var_85_36:setScale(var_85_17.width / var_85_21.width, var_85_17.height / var_85_21.height)
	end
end

function xyd.setTeamBorder(arg_87_0, arg_87_1)
	local var_87_0 = "images/icon/skill_icon/" .. arg_87_0 .. "_icon.png"
	local var_87_1 = xyd.SpriteLoader.new(var_87_0, nil, extra_params, xyd.DefaultImageType.SKILL_ICON)
	local var_87_2 = arg_87_1:getContentSize()

	var_87_1 = var_87_1 or xyd.AssetLoader.get():loadSprite("windows/common/common_avatar.png")

	local var_87_3 = xyd.AssetLoader:get():loadSprite("windows/common/avatar_mask.png")
	local var_87_4 = cc.ClippingNode:create()

	var_87_4:setStencil(var_87_3)
	var_87_4:setInverted(false)
	var_87_4:setAlphaThreshold(0)
	var_87_4:addChild(var_87_1)
	var_87_1:align(display.CENTER, var_87_2.width / 2, var_87_2.height / 2)
	var_87_1:scale(var_87_2.width / var_87_1:getWidth())
	var_87_3:addTo(arg_87_1, -1)
	var_87_3:align(display.CENTER, var_87_2.width / 2, var_87_2.height / 2)
	var_87_3:scale((var_87_2.width - 3) / var_87_3:getWidth())
	arg_87_1:addChild(var_87_4)

	local var_87_5 = xyd.getAvatarBorder(nil)
	local var_87_6 = clone(var_87_5:getContentSize())

	xyd.displaySpriteOnContainer(var_87_5, arg_87_1, true)

	local var_87_7 = display.newNode()

	var_87_7:setName("view")
	var_87_7:setContentSize(var_87_6)
	var_87_7:setAnchorPoint(cc.p(0, 0))
	var_87_7:setPosition(cc.p(0, 0))
	var_87_7:setScale(var_87_2.width / var_87_6.width, var_87_2.height / var_87_6.height)
	arg_87_1:addChild(var_87_7)
end

function xyd.setAvatarBorderWithLevelAndHp(arg_88_0, arg_88_1, arg_88_2, arg_88_3, arg_88_4, arg_88_5)
	local function var_88_0(arg_89_0, arg_89_1)
		local var_89_0
		local var_89_1 = xyd.isSuperHero(arg_89_0) and arg_89_1 > xyd.MAX_STAR_LEVEL and "windows/common/small_pink_star.png" or "windows/common/small_yellow_star.png"

		return xyd.AssetLoader.get():loadSprite(var_89_1)
	end

	local var_88_1
	local var_88_2
	local var_88_3 = arg_88_2
	local var_88_4 = arg_88_3
	local var_88_5 = arg_88_4
	local var_88_6 = false
	local var_88_7 = false
	local var_88_8 = false
	local var_88_9

	if type(arg_88_0) == "number" or type(arg_88_0) == "string" then
		local var_88_10 = tonumber(arg_88_0)
		local var_88_11 = xyd.tables.hero:modelID(var_88_10)

		var_88_1 = xyd.tables.model:avatar(var_88_11)
	else
		var_88_2 = type(arg_88_2) == "boolean" and arg_88_2 == true
		var_88_1 = arg_88_0:getAvatar()
		var_88_3 = arg_88_0:getColor()
		var_88_4 = arg_88_0:getStar()
		var_88_5 = arg_88_0:getLevel()
		var_88_6 = arg_88_0:isAwaken()
		var_88_7 = arg_88_0:isAwakeTwice()

		if arg_88_0.getInscriptionKuangLevel then
			var_88_8 = arg_88_0:getInscriptionKuangLevel()
		end

		local var_88_12 = arg_88_0.houseTableId

		if var_88_12 and var_88_12 > 0 then
			var_88_9 = xyd.tables.dormHouse:maintype(var_88_12)

			if var_88_9 <= 1 then
				var_88_9 = nil
			end
		end
	end

	local var_88_13 = xyd.SpriteLoader.new(var_88_1, nil, nil, xyd.DefaultImageType.AVATAR)
	local var_88_14 = arg_88_1:getContentSize()

	var_88_13 = var_88_13 or xyd.AssetLoader.get():loadSprite("windows/common/hero_avatar3.png")

	local var_88_15 = xyd.AssetLoader:get():loadSprite("windows/common/avatar_mask.png")
	local var_88_16 = cc.ClippingNode:create()

	var_88_16:setStencil(var_88_15)
	var_88_16:setInverted(false)
	var_88_16:setAlphaThreshold(0)
	var_88_16:addChild(var_88_13)
	var_88_13:align(display.CENTER, var_88_14.width / 2, var_88_14.height / 2)
	var_88_13:scale(var_88_14.width / var_88_13:getWidth())

	if var_88_5 then
		local var_88_17 = xyd.AssetLoader.get():loadSprite("windows/common/lv_di.png")

		var_88_16:addChild(var_88_17)
		var_88_17:setPosition(var_88_14.width * 27 / 120, var_88_14.height * 49 / 120)
		var_88_17:scale(var_88_14.width / var_88_13:getWidth())

		local var_88_18 = xyd.AssetLoader.get():loadLabel()

		var_88_18:setString(var_88_5)
		var_88_17:addChild(var_88_18)
		var_88_18:align(display.CENTER, var_88_17:getContentSize().width / 2, var_88_17:getContentSize().height / 2)
		var_88_18:scale(var_88_14.width / var_88_13:getWidth())
	end

	var_88_15:addTo(arg_88_1, -1)
	var_88_15:align(display.CENTER, var_88_14.width / 2, var_88_14.height / 2)
	var_88_15:scale((var_88_14.width - 3) / var_88_15:getWidth())
	arg_88_1:addChild(var_88_16)

	local var_88_19 = xyd.isSuperHero(arg_88_0)
	local var_88_20 = xyd.getAvatarBorder(var_88_3, var_88_6, var_88_7, var_88_8, var_88_19)
	local var_88_21 = clone(var_88_20:getContentSize())

	xyd.displaySpriteOnContainer(var_88_20, arg_88_1, true)

	if var_88_9 then
		local var_88_22 = xyd.tables.dormHouseType:icon(var_88_9)
		local var_88_23 = xyd.AssetLoader.get():loadSprite(var_88_22)

		var_88_23:setAnchorPoint(cc.p(1, 1))
		arg_88_1:addChild(var_88_23)
		var_88_23:setName("house")
		var_88_23:setPosition(cc.p(var_88_14.width + 2, var_88_14.height + 2))
		var_88_23:setLocalZOrder(100)
	end

	local var_88_24 = var_88_4

	if var_88_24 > xyd.MAX_STAR_LEVEL then
		var_88_24 = var_88_24 - xyd.MAX_STAR_LEVEL
	end

	local var_88_25 = var_88_0(arg_88_0, var_88_4):getContentSize().width - 3
	local var_88_26 = (var_88_21.width - var_88_24 * var_88_25) / 2
	local var_88_27 = display.newNode()

	var_88_27:setName("view")
	var_88_27:setContentSize(var_88_21)
	var_88_27:setAnchorPoint(cc.p(0, 0))
	var_88_27:setPosition(cc.p(0, 0))

	for iter_88_0 = 1, var_88_24 do
		local var_88_28 = var_88_0(arg_88_0, var_88_4)

		var_88_27:addChild(var_88_28)
		var_88_28:x(var_88_26 + (iter_88_0 - 1) * var_88_25):y(5)
		var_88_28:setAnchorPoint(cc.p(0, 0))
	end

	var_88_27:setScale(var_88_14.width / var_88_21.width, var_88_14.height / var_88_21.height)
	arg_88_1:addChild(var_88_27)

	if var_88_2 then
		local var_88_29 = xyd.getItemEffect(5)

		if not var_88_29 then
			return
		end

		arg_88_1:addChild(var_88_29)
		var_88_29:setLocalZOrder(-100)
		var_88_29:setPosition(var_88_14.width / 2, var_88_14.height / 2)
		var_88_29:play(nil, true)
	end
end

function xyd.setPetAvatarCard(arg_90_0, arg_90_1, arg_90_2)
	local function var_90_0()
		local var_91_0 = "windows/common/small_yellow_star.png"

		return xyd.AssetLoader.get():loadSprite(var_91_0)
	end

	local var_90_1 = arg_90_0:getAvatar(2)
	local var_90_2 = arg_90_0:getColor()
	local var_90_3 = arg_90_0:getStar()
	local var_90_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/battle/select_team/pet_avatar.csb")

	var_90_4:getChildByName("avatar_mask"):hide()
	var_90_4:getChildByName("chosen"):hide()
	var_90_4:getChildByName("name"):setVisible(false)
	var_90_4:getChildByName("name_label_bg"):setVisible(false)

	local var_90_5 = var_90_4:getChildByName("background"):getWidth()

	var_90_4:size(var_90_5, var_90_5)
	var_90_4:setName("layout")
	var_90_4:align(display.CENTER, arg_90_1:getWidth() / 2, arg_90_1:getHeight() / 2 + 5)
	var_90_4:setScale(0.85, 0.85)

	local var_90_6 = var_90_4:getChildByName("avatar")
	local var_90_7

	if arg_90_0:isAwaken() then
		var_90_7 = xyd.AssetLoader.get():loadSprite("images/battle/b_pet_awake_avatar_border_" .. var_90_2 .. ".png")
	else
		var_90_7 = xyd.AssetLoader.get():loadSprite("images/battle/b_pet_avatar_border_" .. var_90_2 .. ".png")
	end

	var_90_6:addChild(var_90_7)
	var_90_7:align(display.CENTER, 50, 50)

	local var_90_8 = xyd.AssetLoader.get():loadSprite(var_90_1)

	var_90_6:addChild(var_90_8)
	var_90_8:align(display.CENTER_BOTTOM, 50, 0)

	local var_90_9 = arg_90_1:getChildByName("card")
	local var_90_10

	if arg_90_2 then
		var_90_10 = xyd.AssetLoader:get():loadSprite("images/blank_pet_big.png")
	else
		var_90_10 = xyd.AssetLoader:get():loadSprite("images/blank_pet.png")

		var_90_10:setScale(0.94, 0.94)
	end

	var_90_10:setAnchorPoint(cc.p(0, 0))
	var_90_10:setPosition(-1, 0)
	var_90_9:addChild(var_90_10)
	var_90_9:addChild(var_90_4)

	local var_90_11 = var_90_9:getContentSize()
	local var_90_12 = arg_90_1:getContentSize().height
	local var_90_13 = arg_90_1:getContentSize().width
	local var_90_14 = xyd.AssetLoader.get():loadSprite("windows/arena/bottom.png")
	local var_90_15

	if arg_90_2 then
		var_90_15 = xyd.AssetLoader:get():loadSprite("images/card_mask.png")
	else
		var_90_15 = xyd.AssetLoader:get():loadSprite("images/small_card_mask.png")
	end

	var_90_15:setPosition(var_90_13 / 2, var_90_12 / 2)
	var_90_15:setAnchorPoint(cc.p(0.5, 0.5))
	var_90_15:setScale(var_90_12 / var_90_15:getHeight())

	local var_90_16 = cc.ClippingNode:create()

	var_90_16:setStencil(var_90_15)
	var_90_16:setInverted(true)
	var_90_16:setAlphaThreshold(0)
	arg_90_1:addChild(var_90_16)

	local var_90_17 = var_90_11.width / var_90_14:getWidth()

	var_90_14:setScale(var_90_17, 1)
	var_90_14:setPosition(var_90_11.width / 2, var_90_14:getHeight() / 2)
	var_90_16:addChild(var_90_14)
	var_90_16:setLocalZOrder(-1)

	local var_90_18 = xyd.AssetLoader.get():loadSprite("windows/common/border" .. arg_90_0:getColor() .. ".png")

	xyd.displaySpriteOnContainer(var_90_18, arg_90_1, true)

	local var_90_19 = display.newNode()

	var_90_19:setContentSize(var_90_11)
	var_90_19:setAnchorPoint(cc.p(0.5, 0.5))
	var_90_19:setPosition(cc.p(0.5 * var_90_11.width, 0.5 * var_90_11.height))

	local var_90_20 = var_90_0():getContentSize().width - 3
	local var_90_21 = (var_90_11.width - var_90_3 * var_90_20) / 2

	var_90_19:setName("view")
	var_90_19:setAnchorPoint(cc.p(0, 0))
	var_90_19:setPosition(cc.p(0, 0))

	for iter_90_0 = 1, var_90_3 do
		local var_90_22 = var_90_0()

		var_90_19:addChild(var_90_22)
		var_90_22:x(var_90_21 + (iter_90_0 - 1) * var_90_20):y(5)
		var_90_22:setAnchorPoint(cc.p(0, 0))
	end

	arg_90_1:addChild(var_90_19)
end

function xyd.setAvatarCard(arg_92_0, arg_92_1, arg_92_2, arg_92_3, arg_92_4)
	local function var_92_0(arg_93_0, arg_93_1)
		local var_93_0
		local var_93_1 = xyd.isSuperHero(arg_93_0) and arg_93_1 > xyd.MAX_STAR_LEVEL and "windows/common/small_pink_star.png" or "windows/common/small_yellow_star.png"

		return xyd.AssetLoader.get():loadSprite(var_93_1)
	end

	local var_92_1 = xyd.tables.model:smallCard(arg_92_0:getModelID())
	local var_92_2 = arg_92_0:getColor()
	local var_92_3 = arg_92_0:getStar()
	local var_92_4 = xyd.getSmallCard(arg_92_0, xyd.SkinDynamicPosType.PERSON_DISPLAY)
	local var_92_5 = arg_92_1:getChildByName("card"):getContentSize()
	local var_92_6 = arg_92_1:getContentSize().height
	local var_92_7 = arg_92_1:getContentSize().width

	var_92_4 = var_92_4 or xyd.AssetLoader.get():loadSprite("images/cards/10001001.png")

	local var_92_8 = xyd.AssetLoader.get():loadSprite("windows/arena/bottom.png")
	local var_92_9

	if arg_92_4 then
		var_92_9 = xyd.AssetLoader:get():loadSprite("images/small_card_mask.png")

		arg_92_1:getChildByName("rare_lev"):setScale(0.5)
	else
		var_92_9 = xyd.AssetLoader:get():loadSprite("images/card_mask.png")
	end

	local var_92_10 = arg_92_0:getSkinDatas()

	for iter_92_0 = 1, #var_92_10 do
		if arg_92_1:getChildByName("rare_lev") and var_92_10[iter_92_0].modelID == arg_92_0:getModelID() then
			if var_92_10[iter_92_0].cardState == 2 then
				arg_92_1:getChildByName("rare_lev"):setVisible(true)
				xyd.setCardRare(arg_92_0, arg_92_0:getModelID(), arg_92_1, 2, 1)

				break
			end

			arg_92_1:getChildByName("rare_lev"):setVisible(false)

			break
		end
	end

	var_92_9:setPosition(var_92_7 / 2, var_92_6 / 2)
	var_92_9:setAnchorPoint(cc.p(0.5, 0.5))
	var_92_9:setScale(var_92_6 / var_92_9:getHeight() * 1.01)

	local var_92_11 = cc.ClippingNode:create()

	var_92_11:setStencil(var_92_9)
	var_92_11:setInverted(true)
	var_92_11:setAlphaThreshold(0)
	arg_92_1:addChild(var_92_11)
	var_92_11:addChild(var_92_4)

	local var_92_12 = var_92_5.width / var_92_8:getWidth()

	var_92_8:setScale(var_92_12, 1)
	var_92_8:setPosition(var_92_5.width / 2, var_92_8:getHeight() / 2)
	var_92_11:addChild(var_92_8)
	var_92_4:setPosition(var_92_7 / 2, var_92_6 / 2)
	var_92_4:setAnchorPoint(cc.p(0.5, 0.5))

	local var_92_13 = var_92_6 / var_92_4:getHeight()

	var_92_4:setScale(var_92_6 / var_92_4:getHeight(), var_92_6 / var_92_4:getHeight())
	var_92_11:setLocalZOrder(-1)

	if arg_92_0:isHeroMarried() then
		local var_92_14 = xyd.AssetLoader.get():loadSprite("windows/hero_list/married_icon.png")

		var_92_14:addTo(var_92_11)
		var_92_14:setPosition(var_92_7 * 0.75, var_92_6 * 0.2)
		var_92_14:setScale(var_92_6 / var_92_4:getHeight())
	end

	local var_92_15

	if xyd.isSuperHero(arg_92_0) then
		var_92_15 = xyd.AssetLoader.get():loadSprite("windows/common/border_super.png")
	elseif arg_92_0:getInscriptionKuangLevel() then
		var_92_15 = xyd.AssetLoader.get():loadSprite("windows/common/border_suit" .. arg_92_0:getInscriptionKuangLevel() .. ".png")
	elseif arg_92_0:isAwakeTwice() then
		var_92_15 = xyd.AssetLoader.get():loadSprite("windows/common/border_awake_twice" .. arg_92_0:getColor() .. ".png")
	elseif arg_92_0:isAwaken() then
		var_92_15 = xyd.AssetLoader.get():loadSprite("windows/common/border_awake" .. arg_92_0:getColor() .. ".png")
	else
		var_92_15 = xyd.AssetLoader.get():loadSprite("windows/common/border" .. arg_92_0:getColor() .. ".png")
	end

	xyd.displaySpriteOnContainer(var_92_15, arg_92_1, true)

	local var_92_16 = display.newNode()

	var_92_16:setContentSize(var_92_5)
	var_92_16:setAnchorPoint(cc.p(0.5, 0.5))
	var_92_16:setPosition(cc.p(0.5 * var_92_5.width, 0.5 * var_92_5.height))

	local var_92_17 = var_92_3

	if var_92_17 > xyd.MAX_STAR_LEVEL then
		var_92_17 = var_92_17 - xyd.MAX_STAR_LEVEL
	end

	local var_92_18 = var_92_0(arg_92_0, var_92_3):getContentSize().width - 3
	local var_92_19 = (var_92_5.width - var_92_17 * var_92_18) / 2

	var_92_16:setName("view")
	var_92_16:setAnchorPoint(cc.p(0, 0))
	var_92_16:setPosition(cc.p(0, 0))

	for iter_92_1 = 1, var_92_17 do
		local var_92_20 = var_92_0(arg_92_0, var_92_3)

		var_92_16:addChild(var_92_20)
		var_92_20:x(var_92_19 + (iter_92_1 - 1) * var_92_18):y(5)
		var_92_20:setAnchorPoint(cc.p(0, 0))
	end

	arg_92_1:addChild(var_92_16)
end

function xyd.getAvatarBorder(arg_94_0, arg_94_1, arg_94_2, arg_94_3, arg_94_4)
	local var_94_0 = "windows/common/"

	if arg_94_4 then
		var_94_0 = var_94_0 .. "avatar_super.png"
	elseif arg_94_3 then
		var_94_0 = var_94_0 .. "avatar_suit" .. arg_94_3 .. ".png"
	elseif arg_94_2 then
		var_94_0 = var_94_0 .. "avatar_awake_twice" .. arg_94_0 .. ".png"
	elseif arg_94_1 then
		var_94_0 = var_94_0 .. "avatar_awake" .. arg_94_0 .. ".png"
	elseif type(arg_94_0) ~= "number" then
		var_94_0 = var_94_0 .. "avatar1.png"
	elseif arg_94_0 == 0 then
		var_94_0 = var_94_0 .. "avatar_awake.png"
	elseif arg_94_0 and arg_94_0 <= xyd.MAX_HERO_COLOR then
		var_94_0 = var_94_0 .. "avatar" .. arg_94_0 .. ".png"
	else
		var_94_0 = var_94_0 .. "avatar1.png"
	end

	return xyd.AssetLoader:get():loadSprite(var_94_0)
end

function xyd.getAvatarBorder2(arg_95_0)
	local var_95_0 = "windows/common/"

	if arg_95_0 == 0 then
		var_95_0 = var_95_0 .. "avatar_awake.png"
	elseif arg_95_0 <= xyd.MAX_HERO_COLOR then
		var_95_0 = var_95_0 .. "avatar" .. arg_95_0 .. ".png"
	else
		var_95_0 = var_95_0 .. "avatar1.png"
	end

	return xyd.AssetLoader:get():loadSprite(var_95_0)
end

function xyd.setSkillBorder(arg_96_0, arg_96_1, arg_96_2, arg_96_3)
	local var_96_0 = xyd.tables.skill:icon(arg_96_1)

	xyd.setSpriteBorder(arg_96_0, var_96_0, arg_96_2, nil, arg_96_3)
end

function xyd.setSpriteBorder(arg_97_0, arg_97_1, arg_97_2, arg_97_3, arg_97_4)
	local var_97_0

	if arg_97_3 then
		local var_97_1 = {
			filter = {}
		}

		var_97_1.filter.name = "GRAY"
		var_97_1.filter.value = {
			0.2,
			0.3,
			0.5,
			0.1
		}
		var_97_0 = xyd.SpriteLoader.new(arg_97_1, nil, var_97_1, xyd.DefaultImageType.SKILL_ICON, arg_97_0)
	else
		var_97_0 = xyd.SpriteLoader.new(arg_97_1, nil, nil, xyd.DefaultImageType.SKILL_ICON, arg_97_0)
	end

	local var_97_2 = arg_97_0:getContentSize().width
	local var_97_3 = arg_97_0:getContentSize().height
	local var_97_4 = xyd.AssetLoader:get():loadSprite("images/icon_mask2.png")

	var_97_4:setPosition(var_97_2 / 2, var_97_3 / 2)
	var_97_4:setAnchorPoint(cc.p(0.5, 0.5))
	var_97_4:setScale(var_97_3 / var_97_4:getHeight())

	local var_97_5 = var_97_3 / var_97_4:getHeight()
	local var_97_6 = cc.ClippingNode:create()

	var_97_6:setStencil(var_97_4)
	var_97_6:setInverted(true)
	var_97_6:setAlphaThreshold(0)
	arg_97_0:addChild(var_97_6)
	var_97_6:addChild(var_97_0)
	var_97_0:setPosition(var_97_2 / 2, var_97_3 / 2)
	var_97_0:setAnchorPoint(cc.p(0.5, 0.5))

	local var_97_7 = var_97_3 / var_97_0:getHeight()

	var_97_0:setScale(var_97_7)
	var_97_6:setLocalZOrder(-1)

	if arg_97_2 then
		local var_97_8 = xyd.getBorder(arg_97_2, nil, arg_97_4)

		xyd.displaySpriteOnContainer(var_97_8, arg_97_0, true)

		local var_97_9 = xyd.getItemBg(arg_97_2)
		local var_97_10 = var_97_9:getContentSize().height

		var_97_9:addTo(var_97_6, -100)
		var_97_9:setAnchorPoint(0.5, 0.5)
		var_97_9:setPosition(var_97_2 / 2, var_97_3 / 2)
		var_97_9:setScale(var_97_3 / var_97_10)
	end
end

function xyd.setItemWithTextNode(arg_98_0, arg_98_1, arg_98_2, arg_98_3, arg_98_4, arg_98_5)
	local var_98_0 = arg_98_3 or 50
	local var_98_1 = arg_98_2 or xyd.color.WHITE
	local var_98_2 = display.newNode()
	local var_98_3 = display.newNode()

	var_98_3:setContentSize(var_98_0, var_98_0)

	if arg_98_0 < 0 then
		local var_98_4
		local var_98_5

		if arg_98_0 == -1 or arg_98_0 == "-1" then
			var_98_4 = "images/icon/eco/yuanbao.png"
		elseif arg_98_0 == -2 or arg_98_0 == "-2" then
			var_98_4 = "images/icon/eco/jinbi.png"
		elseif arg_98_0 == -3 or arg_98_0 == "-3" then
			var_98_4 = "windows/treasure/sp_icon.png"
		elseif arg_98_0 == -4 or arg_98_0 == "-4" then
			var_98_4 = "images/icon/eco/stone.png"
		elseif arg_98_0 == -5 or arg_98_0 == "-5" then
			var_98_4 = "windows/treasure/drink_mini.png"
		elseif arg_98_0 == -11 or arg_98_0 == "-11" then
			var_98_4 = "images/icon/eco/magic_dust_small.png"
		elseif arg_98_0 == -12 or arg_98_0 == "-12" then
			var_98_4 = "images/icon/eco/magic_liquid_small.png"
		elseif arg_98_0 == -21 or arg_98_0 == "-21" then
			var_98_4 = "images/icon/eco/erudition_star.png"
		elseif arg_98_0 == -22 or arg_98_0 == "-22" then
			var_98_4 = "images/icon/eco/model_star.png"
		elseif arg_98_0 == -23 or arg_98_0 == "-23" then
			var_98_4 = "images/icon/eco/green_star.png"
		end

		if not var_98_4 then
			return var_98_2
		end

		local var_98_6 = xyd.AssetLoader:get():loadSprite(var_98_4)

		var_98_3:addChild(var_98_6)
		var_98_6:setPosition(var_98_0 / 2, var_98_0 / 2)
		var_98_6:setAnchorPoint(cc.p(0.5, 0.5))

		local var_98_7 = var_98_0 / var_98_6:getHeight()

		var_98_6:setScale(var_98_7)
	else
		xyd.setItemBorder(var_98_3, arg_98_0)
	end

	var_98_3:setPosition(0, 0)
	var_98_2:addChild(var_98_3)

	local var_98_8 = arg_98_5 or 28
	local var_98_9 = var_98_0 * 2

	if arg_98_1 then
		local var_98_10 = {
			text = arg_98_1,
			size = var_98_8,
			color = var_98_1,
			align = cc.ui.TEXT_ALIGN_CENTER,
			valign = cc.ui.TEXT_VALIGN_TOP,
			x = var_98_0 / 4 * 5,
			y = var_98_0 / 2
		}
		local var_98_11 = xyd.AssetLoader.get():loadLabel(var_98_10)

		var_98_11:addTo(var_98_2)
		var_98_11:setAnchorPoint(0, 0.5)

		var_98_9 = var_98_9 + var_98_11:getBoundingBox().width
	end

	if not arg_98_4 and arg_98_0 > 0 then
		var_98_3:setTouchEnabled(true)

		local var_98_12 = {
			id = arg_98_0,
			hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(arg_98_0)
		}

		xyd.addTips(var_98_3, var_98_12)
	end

	var_98_2:setContentSize(var_98_9, var_98_0)

	return var_98_2
end

function xyd.getFormatItemsByGiftId(arg_99_0)
	local var_99_0 = xyd.tables.gift:items(arg_99_0)
	local var_99_1 = xyd.tables.gift:itemNum(arg_99_0)
	local var_99_2 = xyd.getFormatItemsByIdNums(var_99_0, var_99_1)
	local var_99_3 = xyd.tables.gift:crystal(arg_99_0)

	if var_99_3 and var_99_3 > 0 then
		local var_99_4 = {
			item_id = xyd.tables.asset:getIdByBackendName("crystal"),
			item_num = var_99_3
		}

		table.insert(var_99_2, var_99_4)
	end

	local var_99_5 = xyd.tables.gift:mana(arg_99_0)

	if var_99_5 and var_99_5 > 0 then
		local var_99_6 = {
			item_id = xyd.tables.asset:getIdByBackendName("mana"),
			item_num = var_99_5
		}

		table.insert(var_99_2, var_99_6)
	end

	local var_99_7 = xyd.tables.gift:badge(arg_99_0)

	if var_99_7 and var_99_7 > 0 then
		local var_99_8 = {
			item_id = xyd.tables.asset:getIdByBackendName("guild_coin"),
			item_num = var_99_7
		}

		table.insert(var_99_2, var_99_8)
	end

	local var_99_9 = xyd.tables.gift:spiritStone(arg_99_0)

	if var_99_9 and var_99_9 > 0 then
		local var_99_10 = {
			item_id = xyd.tables.asset:getIdByBackendName("spirit_stone"),
			item_num = var_99_9
		}

		table.insert(var_99_2, var_99_10)
	end

	return var_99_2
end

function xyd.getFormatItemsByMissionId(arg_100_0)
	local var_100_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	local var_100_1 = {}
	local var_100_2 = xyd.tables.mission:exp(arg_100_0)

	if var_100_2 > 0 then
		local var_100_3 = {}

		if var_100_0.lev < var_100_0.maxTeamLev then
			var_100_3.item_id = xyd.tables.asset:getIdByBackendName("exp")
			var_100_3.item_num = var_100_2
		else
			local var_100_4 = {
				item_id = xyd.tables.asset:getIdByBackendName("march_coin"),
				item_num = var_100_2
			}
		end

		table.insert(var_100_1, var_100_3)
	end

	local var_100_5 = xyd.tables.mission:guildCoin(arg_100_0)

	if var_100_0.vip >= xyd.tables.mission:vip(arg_100_0) then
		var_100_5 = var_100_5 + xyd.tables.mission:exCoin(arg_100_0)
	end

	if var_100_5 > 0 then
		local var_100_6 = {
			item_id = xyd.tables.asset:getIdByBackendName("guild_coin"),
			item_num = var_100_5
		}

		table.insert(var_100_1, var_100_6)
	end

	local var_100_7 = xyd.tables.mission:crystal(arg_100_0)

	if var_100_7 > 0 then
		local var_100_8 = {
			item_id = xyd.tables.asset:getIdByBackendName("crystal"),
			item_num = var_100_7
		}

		table.insert(var_100_1, var_100_8)
	end

	local var_100_9 = xyd.tables.mission:gold(arg_100_0)

	if var_100_9 and var_100_9 > 0 then
		local var_100_10 = {
			item_id = xyd.tables.asset:getIdByBackendName("mana"),
			item_num = var_100_9
		}

		table.insert(var_100_1, var_100_10)
	end

	local var_100_11 = xyd.tables.mission:spiritStone(arg_100_0)

	if var_100_11 and var_100_11 > 0 then
		local var_100_12 = {
			item_id = xyd.tables.asset:getIdByBackendName("spirit_stone"),
			item_num = var_100_11
		}

		table.insert(var_100_1, var_100_12)
	end

	local var_100_13 = xyd.tables.mission:award(arg_100_0)

	if var_100_13 ~= "" and var_100_13 ~= "0" and var_100_13 ~= "0.0" then
		local var_100_14 = xyd.splitToNumber(var_100_13, "|")
		local var_100_15 = var_100_14[1]

		if #var_100_14 > 1 then
			if var_100_15 == 1 then
				local var_100_16 = {
					item_id = xyd.tables.asset:getIdByBackendName("energy"),
					item_num = var_100_14[2]
				}

				table.insert(var_100_1, var_100_16)
			end
		else
			local var_100_17 = xyd.tables.mission:award_num(arg_100_0)

			if var_100_17 > 0 then
				local var_100_18 = {
					item_id = var_100_15,
					item_num = var_100_17
				}

				table.insert(var_100_1, var_100_18)
			end
		end
	end

	return var_100_1
end

function xyd.getFormatItemsByIdNums(arg_101_0, arg_101_1)
	local var_101_0 = {}

	for iter_101_0 = 1, #arg_101_0 do
		local var_101_1 = {
			item_id = arg_101_0[iter_101_0],
			item_num = arg_101_1[iter_101_0] or 0
		}

		if var_101_1.item_id > 0 and var_101_1.item_num > 0 then
			table.insert(var_101_0, var_101_1)
		end
	end

	return var_101_0
end

function xyd.getItemsWithNum(arg_102_0, arg_102_1, arg_102_2, arg_102_3, arg_102_4, arg_102_5)
	local var_102_0 = display.newNode()

	var_102_0:setAnchorPoint(cc.p(0, 0))

	local var_102_1 = 0

	for iter_102_0 = 1, #arg_102_0 do
		local var_102_2 = arg_102_0[iter_102_0]
		local var_102_3 = xyd.getItemWithNumBorder(var_102_2, arg_102_2, arg_102_3, arg_102_4, arg_102_5)

		var_102_3:setAnchorPoint(cc.p(0, 0))
		var_102_3:addTo(var_102_0)
		var_102_3:setPosition(cc.p(var_102_1, 0))

		if arg_102_1 and arg_102_1 >= var_102_3:getContentSize().width and iter_102_0 < #arg_102_0 then
			var_102_1 = var_102_1 + arg_102_1
		elseif arg_102_1 and iter_102_0 < #arg_102_0 then
			var_102_1 = var_102_1 + var_102_3:getContentSize().width + arg_102_1
		end
	end

	var_102_0:setContentSize(var_102_1, arg_102_3 or 50)

	return var_102_0
end

function xyd.getItemWithNumBorder(arg_103_0, arg_103_1, arg_103_2, arg_103_3, arg_103_4)
	local var_103_0 = arg_103_2 or 50
	local var_103_1 = arg_103_1 or xyd.color.WHITE
	local var_103_2 = display.newNode()
	local var_103_3 = display.newNode()

	var_103_3:setContentSize(var_103_0, var_103_0)

	if arg_103_0.item_id < 0 then
		local var_103_4 = xyd.tables.asset:transparentIcon(arg_103_0.item_id)

		icon = xyd.AssetLoader:get():loadSprite(var_103_4)

		var_103_3:addChild(icon)
		icon:setPosition(var_103_0 / 2, var_103_0 / 2)
		icon:setAnchorPoint(cc.p(0.5, 0.5))

		local var_103_5 = var_103_0 / icon:getHeight()

		icon:setScale(var_103_5)
	else
		xyd.setItemBorder(var_103_3, arg_103_0.item_id)
	end

	var_103_3:setPosition(0, 0)
	var_103_2:addChild(var_103_3)

	local var_103_6 = arg_103_4 or 28
	local var_103_7 = var_103_0 * 2

	if arg_103_0.item_num and arg_103_0.item_num > 0 then
		local var_103_8 = {
			text = "x" .. tostring(arg_103_0.item_num),
			size = var_103_6,
			color = var_103_1,
			align = cc.ui.TEXT_ALIGN_CENTER,
			valign = cc.ui.TEXT_VALIGN_TOP,
			x = var_103_0 / 4 * 5,
			y = var_103_0 / 2
		}
		local var_103_9 = xyd.AssetLoader.get():loadLabel(var_103_8)

		var_103_9:addTo(var_103_2)
		var_103_9:setAnchorPoint(0, 0.5)

		var_103_7 = var_103_7 + var_103_9:getBoundingBox().width
	end

	if not arg_103_3 and arg_103_0.item_id > 0 then
		var_103_3:setTouchEnabled(true)

		local var_103_10 = {
			id = arg_103_0.item_id,
			hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(arg_103_0.item_id)
		}

		xyd.addTips(var_103_3, var_103_10)
	end

	var_103_2:setContentSize(var_103_7, var_103_0)

	return var_103_2
end

function xyd.getHouseAttrsAndComforts(arg_104_0, arg_104_1)
	local var_104_0 = xyd.tables.dormHouse
	local var_104_1 = xyd.tables.dormHouseType
	local var_104_2 = xyd.tables.dormExpand
	local var_104_3 = var_104_0:maintype(arg_104_0)
	local var_104_4 = var_104_0:type(arg_104_0)
	local var_104_5 = clone(var_104_0:attr(arg_104_0))
	local var_104_6 = clone(var_104_0:comfort(arg_104_0))

	arg_104_1 = arg_104_1 or 0

	if var_104_3 == xyd.DormType.VILLA then
		local var_104_7 = var_104_2:getAttrsByType(var_104_4)
		local var_104_8 = var_104_2:getComforts()

		for iter_104_0 = 1, arg_104_1 do
			table.insert(var_104_5, var_104_7[iter_104_0])
			table.insert(var_104_6, var_104_8[iter_104_0])
		end
	end

	return var_104_5, var_104_6
end

function xyd.getHouseCurrentAttrs(arg_105_0, arg_105_1, arg_105_2)
	local var_105_0, var_105_1 = xyd.getHouseAttrsAndComforts(arg_105_0, arg_105_2)
	local var_105_2 = xyd.linearSearch(var_105_1, arg_105_1)

	return xyd.getAttrsGrowByLev(var_105_0, var_105_2)
end

function xyd.linearSearch(arg_106_0, arg_106_1)
	for iter_106_0 = #arg_106_0, 1, -1 do
		if arg_106_1 >= arg_106_0[iter_106_0] then
			return iter_106_0
		end
	end
end

function xyd.getAttrsGrowByLev(arg_107_0, arg_107_1)
	return xyd.splitToNumber(arg_107_0[arg_107_1], ",")
end

function xyd.setItemBorder(arg_108_0, arg_108_1, arg_108_2, arg_108_3, arg_108_4, arg_108_5, arg_108_6, arg_108_7, arg_108_8)
	local var_108_0
	local var_108_1
	local var_108_2
	local var_108_3
	local var_108_4 = arg_108_0:getContentSize().width
	local var_108_5 = arg_108_0:getContentSize().height

	if arg_108_1 == -1 or arg_108_1 == "-1" then
		var_108_0 = "images/icon/zuanshi3.png"
		var_108_2 = false
	elseif arg_108_1 == -2 or arg_108_1 == "-2" then
		var_108_0 = "images/icon/mana_icon.png"
		var_108_2 = false
	elseif arg_108_1 == -3 or arg_108_1 == "-3" then
		var_108_0 = "images/icon/arena_coin.png"
		var_108_2 = false
	elseif arg_108_1 == -4 or arg_108_1 == "-4" then
		var_108_0 = "images/icon/march_coin.png"
		var_108_2 = false
	elseif arg_108_1 == -5 or arg_108_1 == "-5" then
		var_108_0 = "images/icon/lucky_coin.png"
	elseif arg_108_1 == -6 or arg_108_1 == "-6" then
		var_108_0 = "images/icon/war_coin.png"
	elseif arg_108_1 == -7 or arg_108_1 == "-7" then
		var_108_0 = "images/icon/exp_icon.png"
	elseif arg_108_1 == -8 or arg_108_1 == "-8" then
		var_108_0 = "images/icon/vip_exp.png"
	elseif arg_108_1 == -11 or arg_108_1 == "-11" then
		var_108_0 = "images/icon/magic_dust.png"
	elseif arg_108_1 == -12 or arg_108_1 == "-12" then
		var_108_0 = "images/icon/magic_liquid.png"
	elseif arg_108_1 == -13 or arg_108_1 == "-13" then
		var_108_0 = "images/icon/energy.png"
	elseif arg_108_1 == -17 or arg_108_1 == "-17" then
		var_108_0 = "images/icon/zaoxingquan.png"
	elseif arg_108_1 == -100 or arg_108_1 == "-100" then
		var_108_0 = "images/icon/lucky_star_icon.png"
	elseif arg_108_1 == -101 or arg_108_1 == "-101" then
		var_108_0 = "images/icon/skin_fragment.png"
	elseif arg_108_1 == -102 or arg_108_1 == "-102" then
		var_108_0 = "windows/activities/1156/blank_icon.png"
	elseif xyd.tables.ecoType:getEcoPathByID(arg_108_1) then
		var_108_0 = xyd.tables.ecoType:getEcoPathByID(arg_108_1)
	else
		var_108_0 = xyd.tables.item:icon(arg_108_1)
		var_108_3 = xyd.tables.item:type(arg_108_1)
		var_108_2 = var_108_3 == xyd.ItemType.EQUIPMENT_FRAGMENT or var_108_3 == xyd.ItemType.REEL_FRAGMENT or var_108_3 == xyd.ItemType.STONE or var_108_3 == xyd.ItemType.PET_STONE or var_108_3 == xyd.ItemType.BOOK_FRAGMENT
	end

	if var_108_3 == xyd.ItemType.AVATAR and xyd.tables.avatar:isActive(arg_108_1) then
		var_108_1 = xyd.createEffect(xyd.tables.avatar:iconJson(arg_108_1))

		var_108_1:play(nil, true)
	elseif var_108_3 == xyd.ItemType.HUNQI then
		xyd.setHunqiBorder({
			container = arg_108_0,
			tableID = arg_108_1
		})

		return
	elseif not arg_108_3 then
		var_108_1 = xyd.SpriteLoader.new(var_108_0, nil, nil, xyd.DefaultImageType.ITEM_ICON, arg_108_0)
	else
		local var_108_6 = {
			filter = {}
		}

		var_108_6.filter.name = "GRAY"
		var_108_6.filter.value = {
			0.2,
			0.3,
			0.5,
			0.1
		}
		var_108_1 = xyd.SpriteLoader.new(var_108_0, nil, var_108_6, xyd.DefaultImageType.ITEM_ICON, arg_108_0)
	end

	if not var_108_1 then
		print("Wrong item, can not be displayed. Item ID is ", arg_108_1)
	end

	local var_108_7

	if var_108_2 then
		var_108_7 = xyd.AssetLoader:get():loadSprite("images/icon_mask.png")
	else
		var_108_7 = xyd.AssetLoader:get():loadSprite("images/icon_mask2.png")
	end

	if var_108_3 == xyd.ItemType.AVATAR and xyd.tables.avatar:isActive(arg_108_1) then
		var_108_7 = xyd.AssetLoader:get():loadSprite("images/icon_mask_active.png")
	end

	var_108_7:setPosition(var_108_4 / 2, var_108_5 / 2)
	var_108_7:setAnchorPoint(cc.p(0.5, 0.5))

	local var_108_8 = var_108_5 / var_108_7:getHeight()
	local var_108_9 = cc.ClippingNode:create()

	var_108_9:setStencil(var_108_7)
	var_108_9:setName("clipper")
	var_108_9:setInverted(true)
	var_108_9:setAlphaThreshold(0)
	arg_108_0:addChild(var_108_9)
	var_108_9:addChild(var_108_1)
	var_108_1:setPosition(var_108_4 / 2, var_108_5 / 2)
	var_108_1:setAnchorPoint(cc.p(0.5, 0.5))

	local var_108_10 = var_108_5 / var_108_1:getHeight()

	if var_108_3 == xyd.ItemType.AVATAR and xyd.tables.avatar:isActive(arg_108_1) then
		var_108_1:setScale(var_108_5 / (xyd.AvatarWidth + 3))
		var_108_7:setScale(var_108_5 / (var_108_7:getHeight() - 192))
	else
		var_108_1:setScale(var_108_10)
		var_108_7:setScale(var_108_5 / var_108_7:getHeight())
	end

	var_108_9:setLocalZOrder(-1)

	local var_108_11 = xyd.tables.item:quality(arg_108_1)

	if arg_108_1 == -102 then
		var_108_11 = 3
	end

	local var_108_12 = xyd.getItemBg(var_108_11)
	local var_108_13 = var_108_12:getContentSize().height

	var_108_12:addTo(var_108_9, -100)
	var_108_12:setAnchorPoint(0.5, 0.5)
	var_108_12:setPosition(var_108_4 / 2, var_108_5 / 2)
	var_108_12:setScale(var_108_5 / var_108_13)

	if arg_108_8 then
		var_108_12:setVisible(false)
	else
		local var_108_14 = xyd.getBorder(var_108_11, var_108_2)

		xyd.displaySpriteOnContainer(var_108_14, arg_108_0, true)
	end

	if var_108_3 == xyd.ItemType.EQUIPMENT_FRAGMENT or var_108_3 == xyd.ItemType.REEL_FRAGMENT or var_108_3 == xyd.ItemType.BOOK_FRAGMENT then
		local var_108_15 = xyd.AssetLoader:get():loadSprite("images/f-equip.png")

		var_108_15:setPosition(25 * var_108_8, var_108_5 - 25 * var_108_8)
		var_108_15:setScale(var_108_8)
		arg_108_0:addChild(var_108_15)
	elseif var_108_3 == xyd.ItemType.STONE then
		local var_108_16 = xyd.AssetLoader:get():loadSprite("images/f-stone.png")

		var_108_16:setPosition(25 * var_108_8, var_108_5 - 25 * var_108_8)
		var_108_16:setScale(var_108_8)
		arg_108_0:addChild(var_108_16)
	elseif var_108_3 == xyd.ItemType.PET_STONE then
		local var_108_17 = xyd.AssetLoader:get():loadSprite("images/f-pet.png")

		var_108_17:setPosition(25 * var_108_8, var_108_5 - 25 * var_108_8)
		var_108_17:setScale(var_108_8)
		arg_108_0:addChild(var_108_17)
	end

	if arg_108_2 then
		local var_108_18 = xyd.getItemEffect(var_108_11, 0.5 * var_108_5 / var_108_1:getHeight())

		if not var_108_18 then
			return
		end

		arg_108_0:addChild(var_108_18)
		var_108_18:setLocalZOrder(-100)
		var_108_18:setPosition(var_108_4 / 2, var_108_5 / 2)
		var_108_18:play(nil, true)
	end

	if arg_108_4 and arg_108_4 > 1 or arg_108_6 and arg_108_4 >= 0 then
		local var_108_19 = xyd.AssetLoader:get():loadSprite("images/bg_num.png")
		local var_108_20 = var_108_19:getContentSize().width
		local var_108_21 = 12 * var_108_4 / 108

		var_108_9:addChild(var_108_19)
		var_108_19:setAnchorPoint(cc.p(1, 0))
		var_108_19:setPosition(var_108_1:getContentSize().width * var_108_10, var_108_21 / 2)
		var_108_19:setName("digit_bg")

		if var_108_4 < var_108_20 then
			var_108_19:setScale(var_108_4 / var_108_20)
		end

		local var_108_22 = {
			size = 20,
			y = 2,
			text = arg_108_4,
			color = cc.c3b(255, 255, 255),
			align = cc.ui.TEXT_ALIGN_CENTER,
			valign = cc.ui.TEXT_VALIGN_TOP,
			x = var_108_20 - var_108_21
		}
		local var_108_23 = xyd.AssetLoader.get():loadLabel(var_108_22)

		var_108_23:addTo(var_108_19)
		var_108_23:setAnchorPoint(1, 0)
		var_108_23:setName("num_label")

		local var_108_24 = var_108_23:getContentSize().width

		if var_108_24 > var_108_20 - var_108_21 * 1.5 and var_108_24 > var_108_4 - var_108_21 * 1.5 then
			var_108_19:setScale((var_108_4 - var_108_21 * 1.5) / var_108_24)
		end
	end

	if arg_108_7 and arg_108_7 >= 0 then
		local var_108_25 = {
			size = 18,
			x = 17,
			text = arg_108_7,
			color = cc.c3b(255, 255, 255),
			align = cc.ui.TEXT_ALIGN_CENTER,
			valign = cc.ui.TEXT_VALIGN_TOP,
			y = arg_108_0:getWidth() - 17
		}
		local var_108_26 = xyd.AssetLoader.get():loadLabel(var_108_25)
		local var_108_27 = xyd.AssetLoader:get():loadSprite("images/super_equip_tip.png")

		arg_108_0:addChild(var_108_27)
		var_108_27:setAnchorPoint(cc.p(0, 1))
		var_108_27:setPosition(1, arg_108_0:getWidth() - 1)
		var_108_26:addTo(arg_108_0)
		var_108_26:enableOutline(cc.c4b(0, 0, 0, 255), 1)
		var_108_26:setAnchorPoint(0.5, 0.5)
	end

	if arg_108_5 and arg_108_5 == true then
		local var_108_28 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
		local var_108_29 = false

		if var_108_28.heros_ and next(var_108_28.heros_) then
			for iter_108_0, iter_108_1 in pairs(var_108_28.heros_) do
				if iter_108_1:getItemHeroHasNotEquip(arg_108_1) then
					var_108_29 = true

					break
				end
			end
		end

		if var_108_29 == true then
			local var_108_30 = xyd.AssetLoader:get():loadSprite("images/green_point.png")

			var_108_30:setPosition(var_108_4 / 14 * 13, var_108_5 / 14 * 13)
			arg_108_0:addChild(var_108_30)
		end
	end

	if var_108_3 == xyd.ItemType.ELEMENT_EQUIP then
		local var_108_31 = xyd.tables.elementEquip:element(arg_108_1)
		local var_108_32 = xyd.tables.elementEquip:equipType(arg_108_1)
		local var_108_33 = "windows/common/hero_common/small_element_" .. var_108_31

		if var_108_32 == xyd.ElementEquipType.SP_CORE then
			var_108_33 = var_108_33 .. "sp"
		end

		local var_108_34 = var_108_33 .. ".png"
		local var_108_35 = xyd.AssetLoader:get():loadSprite(var_108_34)

		var_108_35:addTo(arg_108_0)
		var_108_35:setAnchorPoint(0, 1)
		var_108_35:setPosition(0, var_108_5)
		var_108_35:setScale(var_108_10)
		var_108_35:setName("element_icon")
	end
end

function xyd.setRankLabel(arg_109_0, arg_109_1, arg_109_2)
	local var_109_0

	if arg_109_1 <= 3 then
		var_109_0 = xyd.AssetLoader.get():loadSprite("windows/common/rank/" .. arg_109_1 .. ".png")
	else
		var_109_0 = xyd.AssetLoader.get():loadLabel(nil, "rankFonts")

		var_109_0:setString(tostring(arg_109_1))
	end

	var_109_0:setAnchorPoint(cc.p(0, 0.5))

	if arg_109_2 == "left" then
		var_109_0:setAnchorPoint(cc.p(0, 0.5))
	elseif arg_109_2 == "middle" then
		var_109_0:setAnchorPoint(cc.p(0.5, 0.5))
	elseif arg_109_2 == "right" then
		var_109_0:setAnchorPoint(cc.p(1, 0.5))
	end

	var_109_0:addTo(arg_109_0)
end

function xyd.getBorder(arg_110_0, arg_110_1, arg_110_2)
	local var_110_0

	if arg_110_1 then
		var_110_0 = "border-white.png"

		if arg_110_0 == 1 then
			-- block empty
		elseif arg_110_0 == 2 then
			var_110_0 = "border-green.png"
		elseif arg_110_0 == 3 then
			var_110_0 = "border-blue.png"
		elseif arg_110_0 == 4 then
			var_110_0 = "border-purple.png"
		elseif arg_110_0 == 5 then
			var_110_0 = "border-orange.png"
		elseif arg_110_0 == 6 then
			var_110_0 = "border-red.png"
		end

		var_110_0 = "images/f" .. var_110_0
	else
		var_110_0 = "item_border_white.png"

		if arg_110_0 == 1 then
			-- block empty
		elseif arg_110_0 == 2 then
			var_110_0 = "item_border_green.png"
		elseif arg_110_0 == 3 then
			var_110_0 = "item_border_blue.png"
		elseif arg_110_0 == 4 then
			var_110_0 = "item_border_purple.png"
		elseif arg_110_0 == 5 then
			var_110_0 = "item_border_orange.png"
		elseif arg_110_0 == 6 then
			var_110_0 = "item_border_red.png"
		end

		var_110_0 = "images/common/" .. var_110_0
	end

	if arg_110_2 and not arg_110_1 then
		var_110_0 = "images/common/skill_common_border.png"
	end

	return xyd.AssetLoader:get():loadSprite(var_110_0)
end

function xyd.getItemBg(arg_111_0)
	local var_111_0 = "images/common/"
	local var_111_1 = "item_bg_white.png"

	if arg_111_0 == 1 then
		-- block empty
	elseif arg_111_0 == 2 then
		var_111_1 = "item_bg_green.png"
	elseif arg_111_0 == 3 then
		var_111_1 = "item_bg_blue.png"
	elseif arg_111_0 == 4 then
		var_111_1 = "item_bg_purple.png"
	elseif arg_111_0 == 5 then
		var_111_1 = "item_bg_orange.png"
	elseif arg_111_0 == 6 then
		var_111_1 = "item_bg_red.png"
	end

	return xyd.AssetLoader:get():loadSprite(var_111_0 .. var_111_1)
end

function xyd.getSmallCardBorder(arg_112_0, arg_112_1)
	local var_112_0 = "windows/common/hero_common/"
	local var_112_1
	local var_112_2 = (arg_112_1 or xyd.Color2Level[arg_112_0:getColor()] == "") and "equip" or "hero"
	local var_112_3

	if xyd.isSuperHero(arg_112_0) then
		var_112_3 = xyd.NewQuality.UR
	else
		local var_112_4 = arg_112_0:getInscriptionKuangLevel()

		if var_112_4 and var_112_4 > 0 then
			if var_112_4 == 1 then
				var_112_2 = "equip"
			end

			var_112_3 = xyd.NewQuality.PSS
		else
			var_112_3 = xyd.Color2NewQuality[arg_112_0:getColor()]
		end
	end

	local var_112_5 = var_112_0 .. "border_" .. var_112_2 .. "_" .. var_112_3 .. ".png"

	return xyd.AssetLoader.get():loadSprite(var_112_5)
end

function xyd.getItemEffect(arg_113_0, arg_113_1)
	local var_113_0 = "skeletons/ui_effect/common_effect_summon"
	local var_113_1

	if arg_113_0 == 3 then
		var_113_1 = var_113_0 .. "4/common_effect_summon4"
	elseif arg_113_0 == 4 then
		var_113_1 = var_113_0 .. "5/common_effect_summon5"
	elseif arg_113_0 == 5 then
		var_113_1 = var_113_0 .. "6/common_effect_summon6"
	else
		return
	end

	arg_113_1 = arg_113_1 or 0.5

	if arg_113_0 ~= 3 then
		arg_113_1 = arg_113_1 * 2
	end

	local var_113_2 = var_113_1 .. ".json"
	local var_113_3 = var_113_1 .. ".atlas"

	return (import("app.common.ui.SpineEffect").new(var_113_2, var_113_3, arg_113_1))
end

function xyd.setSpecialItemBorder(arg_114_0, arg_114_1, arg_114_2, arg_114_3)
	local var_114_0 = xyd.tables.item:icon(arg_114_1)

	if arg_114_1 > 60000000 and arg_114_1 < 80000000 then
		var_114_0 = xyd.tables.item:icon(arg_114_1 - 40000000)
	end

	local var_114_1 = xyd.tables.item:type(arg_114_1)
	local var_114_2

	if var_114_1 == xyd.ItemType.AVATAR and xyd.tables.avatar:isActive(arg_114_1) then
		var_114_2 = xyd.createEffect(xyd.tables.avatar:iconJson(arg_114_1))

		var_114_2:play(nil, true)
	elseif not arg_114_2 then
		var_114_2 = xyd.SpriteLoader.new(var_114_0, nil, nil, xyd.DefaultImageType.ITEM_ICON)
	else
		local var_114_3 = {
			filter = {}
		}

		var_114_3.filter.name = "GRAY"
		var_114_3.filter.value = {
			0.2,
			0.3,
			0.5,
			0.1
		}
		var_114_2 = xyd.SpriteLoader.new(var_114_0, nil, var_114_3, xyd.DefaultImageType.ITEM_ICON)
	end

	local var_114_4 = arg_114_0:getContentSize().width
	local var_114_5 = arg_114_0:getContentSize().height
	local var_114_6 = xyd.AssetLoader:get():loadSprite("images/icon_mask3.png")

	var_114_6:setPosition(var_114_4 / 2, var_114_5 / 2)
	var_114_6:setAnchorPoint(cc.p(0.5, 0.5))
	var_114_6:setScale(var_114_5 / var_114_6:getHeight())

	local var_114_7 = cc.ClippingNode:create()

	var_114_7:setStencil(var_114_6)
	var_114_7:setInverted(true)
	var_114_7:setAlphaThreshold(0)
	arg_114_0:addChild(var_114_7)
	var_114_7:addChild(var_114_2)
	var_114_2:setPosition(var_114_4 / 2, var_114_5 / 2)
	var_114_2:setAnchorPoint(cc.p(0.5, 0.5))

	if var_114_1 == xyd.ItemType.AVATAR and xyd.tables.avatar:isActive(arg_114_1) then
		var_114_2:setScale(var_114_5 / xyd.AvatarWidth)
	else
		var_114_2:setScale(var_114_5 / var_114_2:getHeight())
	end

	var_114_7:setLocalZOrder(-1)

	local var_114_8 = xyd.tables.item:quality(arg_114_1)
	local var_114_9 = xyd.getItemBg(var_114_8)
	local var_114_10 = var_114_9:getContentSize().height

	var_114_9:addTo(var_114_7, -100)
	var_114_9:setAnchorPoint(0.5, 0.5)
	var_114_9:setPosition(var_114_4 / 2, var_114_5 / 2)
	var_114_9:setScale(var_114_5 / var_114_10)

	local var_114_11 = "sborder-white.png"

	if var_114_8 == 1 then
		-- block empty
	elseif var_114_8 == 2 then
		var_114_11 = "sborder-green.png"
	elseif var_114_8 == 3 then
		var_114_11 = "sborder-blue.png"
	elseif var_114_8 == 4 then
		var_114_11 = "sborder-purple.png"
	elseif var_114_8 == 5 then
		var_114_11 = "sborder-orange.png"
	elseif var_114_8 == 6 then
		var_114_11 = "sborder-red.png"
	end

	local var_114_12 = "images/" .. var_114_11
	local var_114_13 = xyd.AssetLoader:get():loadSprite(var_114_12)

	if arg_114_3 and arg_114_3 >= 0 then
		local var_114_14 = {
			size = 20,
			x = 40,
			text = arg_114_3,
			color = cc.c3b(255, 255, 255),
			align = cc.ui.TEXT_ALIGN_CENTER,
			valign = cc.ui.TEXT_VALIGN_TOP,
			y = var_114_4 / 10 * 8 + 3
		}
		local var_114_15 = xyd.AssetLoader.get():loadLabel(var_114_14)

		var_114_15:addTo(arg_114_0)
		var_114_15:setAnchorPoint(0.5, 1)

		local var_114_16 = xyd.AssetLoader:get():loadSprite("images/super_equip_tip.png")

		var_114_7:addChild(var_114_16)
		var_114_16:setAnchorPoint(cc.p(0, 0))
		var_114_16:setPosition(15, var_114_2:getContentSize().width - var_114_16:getContentSize().width + 12)
	end

	xyd.displaySpriteOnContainer(var_114_13, arg_114_0, true)
end

function xyd.setSpecialItemBorderNewUI(arg_115_0, arg_115_1, arg_115_2, arg_115_3, arg_115_4)
	local var_115_0 = xyd.tables.item:icon(arg_115_1)

	if arg_115_1 > 61000000 and arg_115_1 < 80000000 then
		var_115_0 = xyd.tables.item:icon(arg_115_1 - 40000000)
	end

	local var_115_1 = xyd.tables.item:type(arg_115_1)
	local var_115_2

	if var_115_1 == xyd.ItemType.AVATAR and xyd.tables.avatar:isActive(arg_115_1) then
		var_115_2 = xyd.createEffect(xyd.tables.avatar:iconJson(arg_115_1))

		var_115_2:play(nil, true)
	elseif not arg_115_2 then
		var_115_2 = xyd.SpriteLoader.new(var_115_0, nil, nil, xyd.DefaultImageType.ITEM_ICON)
	else
		local var_115_3 = {
			filter = {}
		}

		var_115_3.filter.name = "GRAY"
		var_115_3.filter.value = {
			0.2,
			0.3,
			0.5,
			0.1
		}
		var_115_2 = xyd.SpriteLoader.new(var_115_0, nil, var_115_3, xyd.DefaultImageType.ITEM_ICON)
	end

	local var_115_4 = arg_115_0:getContentSize().width
	local var_115_5 = arg_115_0:getContentSize().height
	local var_115_6 = xyd.AssetLoader:get():loadSprite("images/icon_mask2.png")

	var_115_6:setPosition(var_115_4 / 2, var_115_5 / 2)
	var_115_6:setAnchorPoint(cc.p(0.5, 0.5))
	var_115_6:setScale(var_115_5 / var_115_6:getHeight())

	local var_115_7 = cc.ClippingNode:create()

	var_115_7:setStencil(var_115_6)
	var_115_7:setInverted(true)
	var_115_7:setAlphaThreshold(0)
	arg_115_0:addChild(var_115_7)
	var_115_7:addChild(var_115_2)
	var_115_2:setPosition(var_115_4 / 2, var_115_5 / 2)
	var_115_2:setAnchorPoint(cc.p(0.5, 0.5))

	if var_115_1 == xyd.ItemType.AVATAR and xyd.tables.avatar:isActive(arg_115_1) then
		var_115_2:setScale(var_115_5 / xyd.AvatarWidth)
	else
		var_115_2:setScale(var_115_5 / var_115_2:getHeight())
	end

	var_115_7:setLocalZOrder(-1)

	local var_115_8 = xyd.tables.item:quality(arg_115_1)
	local var_115_9 = "item_border_white.png"

	if var_115_8 == 1 then
		-- block empty
	elseif var_115_8 == 2 then
		var_115_9 = "item_border_green.png"
	elseif var_115_8 == 3 then
		var_115_9 = "item_border_blue.png"
	elseif var_115_8 == 4 then
		var_115_9 = "item_border_purple.png"
	elseif var_115_8 == 5 then
		var_115_9 = "item_border_orange.png"
	elseif var_115_8 == 6 then
		var_115_9 = "item_border_red.png"
	end

	local var_115_10 = "images/common/" .. var_115_9
	local var_115_11

	if arg_115_2 then
		var_115_11 = xyd.getItemBg(1)
		var_115_10 = "images/common/item_border_white.png"
	else
		var_115_11 = xyd.getItemBg(var_115_8)
	end

	local var_115_12 = var_115_11:getContentSize().height

	var_115_11:addTo(var_115_7, -100)
	var_115_11:setAnchorPoint(0.5, 0.5)
	var_115_11:setPosition(var_115_4 / 2, var_115_5 / 2)
	var_115_11:setScale(var_115_5 / var_115_12)

	local var_115_13 = xyd.AssetLoader:get():loadSprite(var_115_10)

	xyd.displaySpriteOnContainer(var_115_13, arg_115_0, true)

	if arg_115_4 and arg_115_4 > 1 then
		local var_115_14 = {
			size = 20,
			y = 6,
			text = arg_115_4,
			color = cc.c3b(255, 255, 255),
			align = cc.ui.TEXT_ALIGN_CENTER,
			valign = cc.ui.TEXT_VALIGN_TOP,
			x = var_115_4 / 10 * 9
		}
		local var_115_15 = xyd.AssetLoader.get():loadLabel(var_115_14)

		var_115_15:addTo(arg_115_0)
		var_115_15:setAnchorPoint(1, 0)

		local var_115_16 = xyd.AssetLoader:get():loadSprite("images/bg_num.png")
		local var_115_17 = var_115_5 / var_115_2:getHeight()

		var_115_7:addChild(var_115_16)
		var_115_16:setAnchorPoint(cc.p(0, 0))
		var_115_16:setPosition(var_115_2:getContentSize().width * var_115_17 - var_115_16:getContentSize().width, 5)
	end

	if arg_115_3 and arg_115_3 >= 0 then
		local var_115_18 = {
			size = 18,
			y = 93,
			x = 17,
			text = arg_115_3,
			color = cc.c3b(255, 255, 255),
			align = cc.ui.TEXT_ALIGN_CENTER,
			valign = cc.ui.TEXT_VALIGN_TOP
		}
		local var_115_19 = xyd.AssetLoader:get():loadSprite("images/super_equip_tip.png")

		arg_115_0:addChild(var_115_19)
		var_115_19:setAnchorPoint(cc.p(0, 1))
		var_115_19:setPosition(1, var_115_4 - 1)

		local var_115_20 = xyd.AssetLoader.get():loadLabel(var_115_18)

		var_115_20:addTo(arg_115_0)
		var_115_20:enableOutline(cc.c4b(0, 0, 0, 255), 1)
		var_115_20:setAnchorPoint(0.5, 0.5)
	end
end

function xyd.getHeroCard(arg_116_0, arg_116_1, arg_116_2, arg_116_3, arg_116_4)
	local var_116_0 = arg_116_1 or 1
	local var_116_1 = arg_116_2 or 0
	local var_116_2 = "windows/hero/card.csb"
	local var_116_3 = xyd.AssetLoader.get():loadNodeFromJson(var_116_2)
	local var_116_4

	if arg_116_4 then
		var_116_4 = 1
	elseif arg_116_0:getStar() > xyd.MAX_STAR_LEVEL then
		var_116_4 = arg_116_0:getStar() - xyd.MAX_STAR_LEVEL + 1
	else
		var_116_4 = arg_116_0:getStar() + 1
	end

	if arg_116_0:isSuper() and arg_116_0:getStar() > xyd.MAX_STAR_LEVEL then
		for iter_116_0 = 1, xyd.MAX_STAR_LEVEL do
			local var_116_5 = xyd.AssetLoader.get():loadSprite("windows/common/star_pink.png")

			var_116_5:setAnchorPoint(0.5, 0.5)
			var_116_5:addTo(var_116_3)
			var_116_5:setPosition(var_116_3:getChildByName("card_star" .. iter_116_0):getPosition())
			var_116_5:setName("card_star_pink" .. iter_116_0)
			var_116_3:getChildByName("card_star" .. iter_116_0):setVisible(false)
		end
	end

	for iter_116_1 = xyd.MAX_STAR_LEVEL, var_116_4, -1 do
		var_116_3:getChildByName("card_star" .. iter_116_1):setVisible(false)

		if not tolua.isnull(var_116_3:getChildByName("card_star_pink" .. iter_116_1)) then
			var_116_3:getChildByName("card_star_pink" .. iter_116_1):setVisible(false)
		end
	end

	var_116_3:setContentSize(var_116_3:getChildByName("background"):getContentSize())
	var_116_3:setAnchorPoint(cc.p(0.5, 0.5))

	if arg_116_0:isHeroMarried() then
		var_116_3:getChildByName("card_border"):setVisible(false)
		var_116_3:getChildByName("card_board_married"):setVisible(true)
	else
		var_116_3:getChildByName("card_border"):setVisible(true)
		var_116_3:getChildByName("card_board_married"):setVisible(false)
	end

	local var_116_6
	local var_116_7
	local var_116_8 = false
	local var_116_9

	if var_116_0 == 1 then
		if arg_116_0:isAwaken() then
			local var_116_10 = xyd.tables.hero:beforeAwaken(arg_116_0:getTableID())

			var_116_9 = var_116_10
			var_116_6 = xyd.getNormalCard(arg_116_0, xyd.SkinDynamicPosType.HERO_MAIN, var_116_10)
		else
			var_116_6 = nil
			var_116_9 = arg_116_0:getTableID()
		end
	elseif var_116_0 == 2 then
		var_116_9 = arg_116_0:getModelID()

		if arg_116_0.isSkinOn_ == 1 then
			var_116_6 = xyd.getNormalCard(arg_116_0, xyd.SkinDynamicPosType.HERO_MAIN)

			local var_116_11

			var_116_11 = xyd.tables.model:dynamicType(arg_116_0:getModelID()) == 2
		else
			var_116_6 = nil
		end
	elseif var_116_0 == 3 then
		var_116_6 = xyd.getNormalCard(arg_116_0, xyd.SkinDynamicPosType.HERO_MAIN, arg_116_0:getTableID())

		local var_116_12

		var_116_12 = xyd.tables.model:dynamicType(arg_116_0:getTableID()) == 2
		var_116_9 = arg_116_0:getTableID()
	end

	local var_116_13 = xyd.tables.model:dynamicType(var_116_9) == 2

	if var_116_1 == 1 then
		if arg_116_0:isAwaken() then
			local var_116_14 = xyd.tables.hero:beforeAwaken(arg_116_0:getTableID())

			var_116_7 = xyd.getNormalCard(arg_116_0, xyd.SkinDynamicPosType.HERO_MAIN, var_116_14)
		else
			var_116_7 = nil
		end
	elseif var_116_1 == 2 then
		if arg_116_0.isSkinOn_ == 1 then
			var_116_7 = xyd.getNormalCard(arg_116_0, xyd.SkinDynamicPosType.HERO_MAIN)
		else
			var_116_7 = nil
		end
	elseif var_116_1 == 3 then
		var_116_7 = xyd.getNormalCard(arg_116_0, xyd.SkinDynamicPosType.HERO_MAIN, heroID)
	end

	var_116_6 = var_116_6 or xyd.getNormalCard(arg_116_0, xyd.SkinDynamicPosType.HERO_MAIN, var_116_9)
	var_116_7 = var_116_7 or xyd.getNormalCard(arg_116_0, xyd.SkinDynamicPosType.HERO_MAIN, var_116_9)

	local var_116_15 = var_116_3:getChildByName("container")

	xyd.displaySpriteOnContainer(var_116_6, var_116_15)

	if var_116_7 then
		xyd.displaySpriteOnContainer(var_116_7, var_116_15)
		var_116_7:setName("cardBack")
		var_116_7:setVisible(false)
	end

	var_116_6:setName("cardFront")

	local var_116_16 = arg_116_0:getHeroType()

	var_116_3:getChildByName("agile"):setVisible(var_116_16 == xyd.HeroType.AGILE)
	var_116_3:getChildByName("strength"):setVisible(var_116_16 == xyd.HeroType.STRENGTH)
	var_116_3:getChildByName("wise"):setVisible(var_116_16 == xyd.HeroType.WISE)

	for iter_116_2 = 1, 4 do
		var_116_3:getChildByName("party_" .. iter_116_2):setVisible(arg_116_0:getFromType() == iter_116_2)
	end

	var_116_3:getChildByName("label_name"):setString(arg_116_0:getName())
	var_116_3:getChildByName("label_name"):enableOutline(cc.c4b(0, 0, 0, 188), 2)

	local var_116_17 = var_116_3:getChildByName("live")

	var_116_17:setVisible(var_116_13 and arg_116_3)

	if xyd.isShowDynamicCard(arg_116_0, var_116_9) and arg_116_0:getDynamicCardState(var_116_9) == 1 then
		var_116_17:setBrightStyle(ccui.BrightStyle.highlight)
	else
		var_116_17:setBrightStyle(ccui.BrightStyle.normal)
	end

	return var_116_3
end

function xyd.getNewHeroCard(arg_117_0, arg_117_1, arg_117_2, arg_117_3, arg_117_4)
	local var_117_0 = arg_117_1 or 1
	local var_117_1 = arg_117_2 or 0
	local var_117_2 = "windows/hero_card/card.csb"
	local var_117_3 = xyd.AssetLoader.get():loadNodeFromJson(var_117_2)
	local var_117_4

	if arg_117_4 then
		var_117_4 = 1
	elseif arg_117_0:getStar() > xyd.MAX_STAR_LEVEL then
		var_117_4 = arg_117_0:getStar() - xyd.MAX_STAR_LEVEL + 1
	else
		var_117_4 = arg_117_0:getStar() + 1
	end

	if arg_117_0:isSuper() and arg_117_0:getStar() > xyd.MAX_STAR_LEVEL then
		for iter_117_0 = 1, xyd.MAX_STAR_LEVEL do
			local var_117_5 = xyd.AssetLoader.get():loadSprite("windows/common/star_pink.png")

			var_117_5:setAnchorPoint(0.5, 0.5)
			var_117_5:addTo(var_117_3)
			var_117_5:setPosition(var_117_3:getChildByName("card_star" .. iter_117_0):getPosition())
			var_117_5:setName("card_star_pink" .. iter_117_0)
			var_117_3:getChildByName("card_star" .. iter_117_0):setVisible(false)
		end
	end

	for iter_117_1 = xyd.MAX_STAR_LEVEL, var_117_4, -1 do
		var_117_3:getChildByName("card_star" .. iter_117_1):setVisible(false)

		if not tolua.isnull(var_117_3:getChildByName("card_star_pink" .. iter_117_1)) then
			var_117_3:getChildByName("card_star_pink" .. iter_117_1):setVisible(false)
		end
	end

	var_117_3:setContentSize(var_117_3:getChildByName("background"):getContentSize())
	var_117_3:setAnchorPoint(cc.p(0.5, 0.5))

	if arg_117_0:isHeroMarried() then
		var_117_3:getChildByName("card_border"):setVisible(false)
		var_117_3:getChildByName("card_board_married"):setVisible(true)
	else
		var_117_3:getChildByName("card_border"):setVisible(true)
		var_117_3:getChildByName("card_board_married"):setVisible(false)
	end

	local var_117_6
	local var_117_7
	local var_117_8 = false
	local var_117_9

	if var_117_0 == 1 then
		if arg_117_0:isAwaken() then
			local var_117_10 = xyd.tables.hero:beforeAwaken(arg_117_0:getTableID())

			var_117_9 = var_117_10
			var_117_6 = xyd.getNormalCard(arg_117_0, xyd.SkinDynamicPosType.HERO_MAIN, var_117_10)
		else
			var_117_6 = nil
			var_117_9 = arg_117_0:getTableID()
		end
	elseif var_117_0 == 2 then
		var_117_9 = arg_117_0:getModelID()

		if arg_117_0.isSkinOn_ == 1 then
			var_117_6 = xyd.getNormalCard(arg_117_0, xyd.SkinDynamicPosType.HERO_MAIN)

			local var_117_11

			var_117_11 = xyd.tables.model:dynamicType(arg_117_0:getModelID()) == 2
		else
			var_117_6 = nil
		end
	elseif var_117_0 == 3 then
		var_117_6 = xyd.getNormalCard(arg_117_0, xyd.SkinDynamicPosType.HERO_MAIN, arg_117_0:getTableID())

		local var_117_12

		var_117_12 = xyd.tables.model:dynamicType(arg_117_0:getTableID()) == 2
		var_117_9 = arg_117_0:getTableID()
	end

	local var_117_13 = xyd.tables.model:dynamicType(var_117_9) == 2

	if var_117_1 == 1 then
		if arg_117_0:isAwaken() then
			local var_117_14 = xyd.tables.hero:beforeAwaken(arg_117_0:getTableID())

			var_117_7 = xyd.getNormalCard(arg_117_0, xyd.SkinDynamicPosType.HERO_MAIN, var_117_14)
		else
			var_117_7 = nil
		end
	elseif var_117_1 == 2 then
		if arg_117_0.isSkinOn_ == 1 then
			var_117_7 = xyd.getNormalCard(arg_117_0, xyd.SkinDynamicPosType.HERO_MAIN)
		else
			var_117_7 = nil
		end
	elseif var_117_1 == 3 then
		var_117_7 = xyd.getNormalCard(arg_117_0, xyd.SkinDynamicPosType.HERO_MAIN, heroID)
	end

	var_117_6 = var_117_6 or xyd.getNormalCard(arg_117_0, xyd.SkinDynamicPosType.HERO_MAIN, var_117_9)
	var_117_7 = var_117_7 or xyd.getNormalCard(arg_117_0, xyd.SkinDynamicPosType.HERO_MAIN, var_117_9)

	local var_117_15 = var_117_3:getChildByName("container")

	xyd.displaySpriteOnContainer(var_117_6, var_117_15)

	if var_117_7 then
		xyd.displaySpriteOnContainer(var_117_7, var_117_15)
		var_117_7:setName("cardBack")
		var_117_7:setVisible(false)
	end

	var_117_6:setName("cardFront")

	local var_117_16 = arg_117_0:getHeroType()

	var_117_3:getChildByName("agile"):setVisible(not arg_117_0:isHeroMarried() and var_117_16 == xyd.HeroType.AGILE)
	var_117_3:getChildByName("strength"):setVisible(not arg_117_0:isHeroMarried() and var_117_16 == xyd.HeroType.STRENGTH)
	var_117_3:getChildByName("wise"):setVisible(not arg_117_0:isHeroMarried() and var_117_16 == xyd.HeroType.WISE)
	var_117_3:getChildByName("agile_pink"):setVisible(arg_117_0:isHeroMarried() and var_117_16 == xyd.HeroType.AGILE)
	var_117_3:getChildByName("strength_pink"):setVisible(arg_117_0:isHeroMarried() and var_117_16 == xyd.HeroType.STRENGTH)
	var_117_3:getChildByName("wise_pink"):setVisible(arg_117_0:isHeroMarried() and var_117_16 == xyd.HeroType.WISE)

	for iter_117_2 = 1, 4 do
		var_117_3:getChildByName("party_" .. iter_117_2):setVisible(arg_117_0:getFromType() == iter_117_2)
	end

	var_117_3:getChildByName("label_name"):setString(arg_117_0:getName())
	var_117_3:getChildByName("label_name"):enableOutline(cc.c4b(0, 0, 0, 188), 2)

	if arg_117_0.isSkinOn_ == 1 then
		xyd.setCardRare(arg_117_0, arg_117_0:getModelID(), var_117_3, var_117_0, 1)
	end

	local var_117_17 = var_117_3:getChildByName("live")

	var_117_17:setVisible(var_117_13 and arg_117_3)

	if xyd.isShowDynamicCard(arg_117_0, var_117_9) and arg_117_0:getDynamicCardState(var_117_9) == 1 then
		var_117_17:setBrightStyle(ccui.BrightStyle.highlight)
	else
		var_117_17:setBrightStyle(ccui.BrightStyle.normal)
	end

	return var_117_3
end

function xyd.getSuperHeroCard(arg_118_0, arg_118_1, arg_118_2, arg_118_3, arg_118_4, arg_118_5)
	local var_118_0 = arg_118_1 or 1
	local var_118_1 = arg_118_2 or 0
	local var_118_2 = "windows/hero/card.csb"
	local var_118_3 = xyd.AssetLoader.get():loadNodeFromJson(var_118_2)
	local var_118_4

	if arg_118_4 then
		var_118_4 = 1
	elseif arg_118_0:getStar() > xyd.MAX_STAR_LEVEL then
		var_118_4 = arg_118_0:getStar() - xyd.MAX_STAR_LEVEL + 1
	else
		var_118_4 = arg_118_0:getStar() + 1
	end

	if arg_118_0:isSuper() and arg_118_0:getStar() > xyd.MAX_STAR_LEVEL then
		for iter_118_0 = 1, xyd.MAX_STAR_LEVEL do
			local var_118_5 = xyd.AssetLoader.get():loadSprite("windows/common/star_pink.png")

			var_118_5:setAnchorPoint(0.5, 0.5)
			var_118_5:addTo(var_118_3)
			var_118_5:setPosition(var_118_3:getChildByName("card_star" .. iter_118_0):getPosition())
			var_118_5:setName("card_star_pink" .. iter_118_0)
			var_118_3:getChildByName("card_star" .. iter_118_0):setVisible(false)
		end
	end

	for iter_118_1 = xyd.MAX_STAR_LEVEL, var_118_4, -1 do
		var_118_3:getChildByName("card_star" .. iter_118_1):setVisible(false)

		if not tolua.isnull(var_118_3:getChildByName("card_star_pink" .. iter_118_1)) then
			var_118_3:getChildByName("card_star_pink" .. iter_118_1):setVisible(false)
		end
	end

	var_118_3:setContentSize(var_118_3:getChildByName("background"):getContentSize())
	var_118_3:setAnchorPoint(cc.p(0.5, 0.5))

	if arg_118_0:isHeroMarried() then
		var_118_3:getChildByName("card_border"):setVisible(false)
		var_118_3:getChildByName("card_board_married"):setVisible(true)
	else
		var_118_3:getChildByName("card_border"):setVisible(true)
		var_118_3:getChildByName("card_board_married"):setVisible(false)
	end

	local var_118_6
	local var_118_7
	local var_118_8 = false
	local var_118_9

	if var_118_0 == 1 then
		if arg_118_0:isAwaken() then
			local var_118_10 = xyd.tables.hero:beforeAwaken(arg_118_0:getTableID())

			var_118_9 = var_118_10
			var_118_6 = xyd.getNormalCard(arg_118_0, xyd.SkinDynamicPosType.HERO_MAIN, var_118_10)
		else
			var_118_6 = nil
			var_118_9 = arg_118_0:getTableID()
		end
	elseif var_118_0 == 2 then
		var_118_9 = arg_118_0:getModelID()

		if arg_118_0.isSkinOn_ == 1 then
			var_118_6 = xyd.getNormalCard(arg_118_0, xyd.SkinDynamicPosType.HERO_MAIN)

			local var_118_11

			var_118_11 = xyd.tables.model:dynamicType(arg_118_0:getModelID()) == 2
		else
			var_118_6 = nil
		end
	elseif var_118_0 == 3 then
		var_118_6 = xyd.getNormalCard(arg_118_0, xyd.SkinDynamicPosType.HERO_MAIN, arg_118_0:getTableID())

		local var_118_12

		var_118_12 = xyd.tables.model:dynamicType(arg_118_0:getTableID()) == 2
		var_118_9 = arg_118_0:getTableID()
	end

	local var_118_13 = xyd.tables.model:dynamicType(var_118_9) == 2

	if var_118_1 == 1 then
		if arg_118_0:isAwaken() then
			local var_118_14 = xyd.tables.hero:beforeAwaken(arg_118_0:getTableID())

			var_118_7 = xyd.getNormalCard(arg_118_0, xyd.SkinDynamicPosType.HERO_MAIN, var_118_14)
		else
			var_118_7 = nil
		end
	elseif var_118_1 == 2 then
		if arg_118_0.isSkinOn_ == 1 then
			var_118_7 = xyd.getNormalCard(arg_118_0, xyd.SkinDynamicPosType.HERO_MAIN)
		else
			var_118_7 = nil
		end
	elseif var_118_1 == 3 then
		var_118_7 = xyd.getNormalCard(arg_118_0, xyd.SkinDynamicPosType.HERO_MAIN, heroID)
	end

	var_118_6 = var_118_6 or xyd.getNormalCard(arg_118_0, xyd.SkinDynamicPosType.HERO_MAIN, var_118_9)
	var_118_7 = var_118_7 or xyd.getNormalCard(arg_118_0, xyd.SkinDynamicPosType.HERO_MAIN, var_118_9)

	local var_118_15 = var_118_3:getChildByName("container")

	xyd.displaySpriteOnContainer(var_118_6, var_118_15)

	if var_118_7 then
		xyd.displaySpriteOnContainer(var_118_7, var_118_15)
		var_118_7:setName("cardBack")
		var_118_7:setVisible(false)
	end

	var_118_6:setName("cardFront")

	local var_118_16 = arg_118_0:getHeroType()

	var_118_3:getChildByName("agile"):setVisible(var_118_16 == xyd.HeroType.AGILE)
	var_118_3:getChildByName("strength"):setVisible(var_118_16 == xyd.HeroType.STRENGTH)
	var_118_3:getChildByName("wise"):setVisible(var_118_16 == xyd.HeroType.WISE)

	for iter_118_2 = 1, 4 do
		var_118_3:getChildByName("party_" .. iter_118_2):setVisible(arg_118_0:getFromType() == iter_118_2)
	end

	var_118_3:getChildByName("label_name"):setString(arg_118_0:getName())
	var_118_3:getChildByName("label_name"):enableOutline(cc.c4b(0, 0, 0, 188), 2)

	if arg_118_0.isSkinOn_ == 1 then
		xyd.setCardRare(arg_118_0, arg_118_0:getModelID(), var_118_3, var_118_0, 1)
	end

	local var_118_17 = var_118_3:getChildByName("live")

	var_118_17:setVisible(var_118_13 and arg_118_3)

	if xyd.isShowDynamicCard(arg_118_0, var_118_9) and arg_118_0:getDynamicCardState(var_118_9) == 1 then
		var_118_17:setBrightStyle(ccui.BrightStyle.highlight)
	else
		var_118_17:setBrightStyle(ccui.BrightStyle.normal)
	end

	return var_118_3
end

function xyd.setCardRare(arg_119_0, arg_119_1, arg_119_2, arg_119_3, arg_119_4)
	local var_119_0 = xyd.tables.skinSkill
	local var_119_1 = xyd.tables.hero:skinItem(arg_119_0:getTableID())

	if arg_119_3 == 2 then
		local var_119_2
		local var_119_3

		for iter_119_0 = 1, #var_119_1 do
			local var_119_4 = var_119_1[iter_119_0]
			local var_119_5 = var_119_0:getModelID(var_119_4)

			if var_119_5 and var_119_5 == arg_119_1 then
				var_119_3 = var_119_0:getRareLev(var_119_1[iter_119_0])

				break
			end
		end

		if var_119_3 and var_119_3 ~= 1 then
			if not arg_119_4 then
				arg_119_2:getChildByName("rare_lev"):loadTexture("images/icon/rare" .. var_119_3 .. "_2.png")
			else
				arg_119_2:getChildByName("rare_lev"):loadTexture("images/icon/rare" .. var_119_3 .. ".png")
			end

			arg_119_2:getChildByName("rare_lev"):setVisible(true)
		else
			arg_119_2:getChildByName("rare_lev"):setVisible(false)
		end
	else
		arg_119_2:getChildByName("rare_lev"):setVisible(false)
	end
end

function xyd.getPetCard(arg_120_0, arg_120_1, arg_120_2)
	local var_120_0 = arg_120_1 or 1
	local var_120_1 = arg_120_2 or 0
	local var_120_2 = "windows/pet/petMainWindow/card.csb"
	local var_120_3 = xyd.AssetLoader.get():loadNodeFromJson(var_120_2)

	for iter_120_0 = xyd.MAX_STAR_LEVEL, arg_120_0:getStar() + 1, -1 do
		var_120_3:getChildByName("card_star" .. iter_120_0):setVisible(false)
	end

	var_120_3:setContentSize(var_120_3:getChildByName("background"):getContentSize())
	var_120_3:setAnchorPoint(cc.p(0.5, 0.5))

	local var_120_4
	local var_120_5

	if var_120_0 == 1 then
		if arg_120_0:isAwaken() then
			local var_120_6 = xyd.tables.hero:beforeAwaken(arg_120_0:getTableID())

			var_120_4 = xyd.SpriteLoader.new(xyd.tables.model:card(var_120_6), nil, nil, xyd.DefaultImageType.HERO_CARD)
		else
			var_120_4 = nil
		end
	elseif var_120_0 == 2 then
		if arg_120_0.isSkinOn_ == 1 then
			var_120_4 = xyd.SpriteLoader.new(arg_120_0:getCard(), nil, nil, xyd.DefaultImageType.HERO_CARD)
		else
			var_120_4 = nil
		end
	elseif var_120_0 == 3 then
		var_120_4 = xyd.SpriteLoader.new(xyd.tables.model:card(arg_120_0:getTableID()), nil, nil, xyd.DefaultImageType.HERO_CARD)
	end

	if var_120_1 == 1 then
		if arg_120_0:isAwaken() then
			local var_120_7 = xyd.tables.hero:beforeAwaken(arg_120_0:getTableID())

			var_120_5 = xyd.SpriteLoader.new(xyd.tables.model:card(var_120_7), nil, nil, xyd.DefaultImageType.HERO_CARD)
		else
			var_120_5 = nil
		end
	elseif var_120_1 == 2 then
		if arg_120_0.isSkinOn_ == 1 then
			var_120_5 = xyd.SpriteLoader.new(arg_120_0:getCard(), nil, nil, xyd.DefaultImageType.HERO_CARD)
		else
			var_120_5 = nil
		end
	elseif var_120_1 == 3 then
		var_120_5 = xyd.SpriteLoader.new(xyd.tables.model:card(arg_120_0:getTableID()), nil, nil, xyd.DefaultImageType.HERO_CARD)
	end

	var_120_4 = var_120_4 or xyd.SpriteLoader.new(xyd.tables.model:card(arg_120_0:getTableID()), nil, nil, xyd.DefaultImageType.HERO_CARD)
	var_120_5 = var_120_5 or xyd.SpriteLoader.new(xyd.tables.model:card(arg_120_0:getTableID()), nil, nil, xyd.DefaultImageType.HERO_CARD)

	local var_120_8 = var_120_3:getChildByName("container")

	xyd.displaySpriteOnContainer(var_120_4, var_120_8)

	if var_120_5 then
		xyd.displaySpriteOnContainer(var_120_5, var_120_8)
		var_120_5:setName("cardBack")
		var_120_5:setVisible(false)
	end

	var_120_4:setName("cardFront")
	var_120_3:getChildByName("label_name"):setString(arg_120_0:getName())
	var_120_3:getChildByName("label_name"):enableOutline(cc.c4b(0, 0, 0, 188), 2)

	return var_120_3
end

function xyd.setPlayerTitle(arg_121_0, arg_121_1, arg_121_2)
	local var_121_0 = import("app.common.ui.SpineEffect")

	if arg_121_1 and arg_121_1.title_id and arg_121_1.title_id ~= 0 then
		local var_121_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/person_display/person_main/title.csb")
		local var_121_2

		if xyd.tables.titleSystemTable:isDynamic(arg_121_1.title_id) ~= 1 then
			local var_121_3 = xyd.tables.titleSystemTable:bg(arg_121_1.title_id)

			var_121_2 = xyd.AssetLoader:get():loadSprite(var_121_3)

			var_121_2:setAnchorPoint(0, 0)
			var_121_2:addTo(var_121_1:getChildByName("container"):getChildByName("bg"))
		else
			local var_121_4 = xyd.tables.titleSystemTable:dynamicPath(arg_121_1.title_id)
			local var_121_5 = xyd.EffectLoader.new(var_121_4, 6)

			var_121_5:addTo(var_121_1:getChildByName("container"):getChildByName("bg"), -1)

			local var_121_6 = var_121_1:getChildByName("container"):getChildByName("bg"):getContentSize()

			var_121_5:pos(var_121_6.width / 2, var_121_6.height / 2)

			var_121_2 = display.newNode()

			var_121_2:setContentSize(var_121_6)
			var_121_2:setAnchorPoint(0, 0)
			var_121_2:addTo(var_121_1:getChildByName("container"):getChildByName("bg"), -1)
		end

		local var_121_7 = var_121_2:getContentSize()

		if arg_121_1.unique_id ~= 0 then
			var_121_1:getChildByName("container"):getChildByName("txt_img"):setVisible(true)

			local var_121_8 = xyd.tables.titleSystemTable:textImg(arg_121_1.title_id)
			local var_121_9 = xyd.AssetLoader:get():loadSprite(var_121_8 .. arg_121_1.unique_id .. ".png")

			var_121_9:setAnchorPoint(0.5, 0.5)
			var_121_9:addTo(var_121_1:getChildByName("container"):getChildByName("txt_img"))
		else
			var_121_1:getChildByName("container"):getChildByName("txt_img"):setVisible(false)
		end

		local var_121_10 = arg_121_0:getContentSize().height / var_121_7.height

		var_121_1:getChildByName("container"):setScale(var_121_10)
		var_121_1:setName("node")
		var_121_1:addTo(arg_121_0)

		if arg_121_2 then
			return {
				width = var_121_7.width * var_121_10,
				height = var_121_7.height * var_121_10
			}
		end
	end
end

function xyd.setNameLabel(arg_122_0, arg_122_1, arg_122_2, arg_122_3)
	local var_122_0 = cc.Node:create()
	local var_122_1 = arg_122_1:getName()
	local var_122_2 = arg_122_1:getColor()
	local var_122_3 = {
		color = arg_122_3 or cc.c3b(71, 56, 31),
		text = var_122_1
	}
	local var_122_4 = xyd.AssetLoader:get():loadLabel(var_122_3)

	var_122_0:addChild(var_122_4)
	var_122_4:setAnchorPoint(cc.p(0, 0))

	if arg_122_2 then
		var_122_4:enableOutline(cc.c4b(255, 255, 255, 255), 2)
	end

	local var_122_5 = {
		color = xyd.color.HERO_QUALITY[var_122_2],
		text = xyd.Color2Level[arg_122_1:getColor()]
	}
	local var_122_6 = xyd.AssetLoader:get():loadLabel(var_122_5)

	var_122_0:addChild(var_122_6)
	var_122_6:setPosition(var_122_4:getContentSize().width + 5, -3)
	var_122_6:setAnchorPoint(cc.p(0, 0))
	var_122_6:enableOutline(cc.c4b(255, 255, 255, 255), 2)

	local var_122_7 = arg_122_0:getContentSize().width - var_122_4:getContentSize().width - var_122_6:getContentSize().width - 5

	var_122_0:setPosition(var_122_7 / 2, 2)
	var_122_0:setAnchorPoint(cc.p(0, 0))
	arg_122_0:addChild(var_122_0)
end

function xyd.setPlayerAvatar(arg_123_0, arg_123_1)
	if not arg_123_1 then
		return nil
	end

	local var_123_0 = arg_123_1.avatar_path

	if arg_123_1.avatar_path then
		var_123_0 = arg_123_1.avatar_path
	elseif arg_123_1.avatar_id then
		var_123_0 = "images/avatars/" .. arg_123_1.avatar_id .. ".png"
	end

	var_123_0 = var_123_0 or "images/avatars/" .. xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarId] .. ".png"

	local var_123_1 = true

	if xyd.tables.avatar:isActive(arg_123_1.avatar_id) then
		var_123_0 = xyd.tables.avatar:iconJson(arg_123_1.avatar_id)
		var_123_1 = false
	end

	local var_123_2 = "windows/arena/avatar.csb"

	if arg_123_1.is_new then
		var_123_2 = "windows/arena/avatar_new.csb"
	end

	local var_123_3 = xyd.AssetLoader.get():loadNodeFromJson(var_123_2)
	local var_123_4 = var_123_3:getChildByName("container")

	var_123_3:setName("avatar")

	framePath = "images/avatar_frames/" .. xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarFrameId] .. ".png"

	if arg_123_1.avatar_frame_id and arg_123_1.avatar_frame_id ~= 0 and xyd.tables.avatar.icon_[arg_123_1.avatar_frame_id] then
		framePath = "images/avatar_frames/" .. xyd.tables.avatar:icon(arg_123_1.avatar_frame_id) .. ".png"
	end

	local var_123_5

	if arg_123_1.isGray == true then
		local var_123_6 = {
			filter = {}
		}

		var_123_6.filter.name = "GRAY"
		var_123_6.filter.value = {
			0.2,
			0.3,
			0.5,
			0.1
		}
		var_123_5 = xyd.SpriteLoader.new(framePath, nil, var_123_6, xyd.DefaultImageType.AVATAR_FRAME)
	else
		var_123_5 = xyd.SpriteLoader.new(framePath, nil, nil, xyd.DefaultImageType.AVATAR_FRAME)
	end

	var_123_4:getChildByName("circle"):addChild(var_123_5)
	var_123_5:setPosition(var_123_4:getChildByName("circle"):getWidth() / 2, var_123_4:getChildByName("circle"):getHeight() / 2)

	if arg_123_1.is_new then
		var_123_5:setScale(var_123_4:getWidth() / 112)
	end

	local var_123_7
	local var_123_8

	if xyd.tables.avatar:isActive(arg_123_1.avatar_id) and not var_123_1 then
		local var_123_9 = xyd.createEffect(var_123_0)
	end

	if xyd.tables.avatar:isActive(arg_123_1.avatar_id) and not var_123_1 then
		var_123_7 = xyd.createEffect(var_123_0)

		var_123_7:play(nil, true)
		var_123_7:setFlipX(arg_123_1.isFlipX and not xyd.tables.avatar:noTurn(arg_123_1.avatar_id))
	elseif arg_123_1.isGray == true then
		local var_123_10 = {
			filter = {}
		}

		var_123_10.filter.name = "GRAY"
		var_123_10.filter.value = {
			0.2,
			0.3,
			0.5,
			0.1
		}
		var_123_7 = xyd.SpriteLoader.new(var_123_0, nil, var_123_10, xyd.DefaultImageType.AVATAR)

		var_123_7:setFlippedX(arg_123_1.isFlipX and not xyd.tables.avatar:noTurn(arg_123_1.avatar_id))
	else
		var_123_7 = xyd.SpriteLoader.new(var_123_0, nil, nil, xyd.DefaultImageType.AVATAR)

		var_123_7:setFlippedX(arg_123_1.isFlipX and not xyd.tables.avatar:noTurn(arg_123_1.avatar_id))
	end

	var_123_4:setAnchorPoint(0.5, 0.5)
	var_123_4:setPosition(arg_123_0:getContentSize().width / 2, arg_123_0:getContentSize().height / 2)

	local var_123_11 = var_123_4:getContentSize()

	var_123_4:setScale(arg_123_0:getContentSize().height / var_123_11.height)

	local var_123_12 = {
		lev = arg_123_1.level,
		conquerLev = arg_123_1.conquerLev,
		loopID = arg_123_1.conquerLoopID
	}

	if arg_123_1.is_new then
		var_123_12.fontColor = cc.c3b(102, 30, 30)
	end

	if arg_123_1.conquerLev and arg_123_1.conquerLev > 0 then
		xyd.setLev(var_123_4:getChildByName("level_container"), var_123_12)
	elseif arg_123_1.showLevel and arg_123_1.showLevel == true and arg_123_1.level then
		xyd.setLev(var_123_4:getChildByName("level_container"), var_123_12)
	end

	local var_123_13 = var_123_4:getContentSize().width
	local var_123_14 = var_123_4:getContentSize().height
	local var_123_15

	if xyd.tables.avatar:isActive(arg_123_1.avatar_id) then
		var_123_15 = xyd.AssetLoader:get():loadSprite("images/avatars/touxiang_clip.png")

		var_123_15:setScale(var_123_14 / (var_123_15:getHeight() - 196))
		var_123_7:setScale(var_123_14 / xyd.AvatarWidth)
	else
		var_123_15 = xyd.AssetLoader:get():loadSprite("images/avatars/mask1.png")

		var_123_15:setScale(var_123_14 / var_123_15:getHeight())
		var_123_7:setScale(var_123_14 / var_123_7:getHeight())
	end

	var_123_15:setPosition(var_123_13 / 2, var_123_14 / 2)
	var_123_15:setAnchorPoint(cc.p(0.5, 0.5))

	local var_123_16 = cc.ClippingNode:create()

	var_123_16:setStencil(var_123_15)
	var_123_16:setInverted(true)
	var_123_16:setAlphaThreshold(0)
	var_123_4:addChild(var_123_16)
	var_123_16:addChild(var_123_7)
	var_123_7:setPosition(var_123_13 / 2, var_123_14 / 2)
	var_123_7:setAnchorPoint(cc.p(0.5, 0.5))
	var_123_16:setLocalZOrder(-1)

	if arg_123_1.callback then
		var_123_3:setTouchSwallowEnabled(false)
		var_123_3:setTouchEnabled(true)
		var_123_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, arg_123_1.callback)
	elseif arg_123_1.playerInfo and arg_123_1.playerInfo.player_id then
		xyd.setPlayerAvatarTouch(var_123_3, arg_123_1.playerInfo, arg_123_0:getContentSize())
	end

	arg_123_0:addChild(var_123_3, 1, 1)
end

function xyd.drawColorPentagon(arg_124_0, arg_124_1)
	local var_124_0 = arg_124_1.values
	local var_124_1 = arg_124_1.center
	local var_124_2 = arg_124_1.radius
	local var_124_3 = arg_124_1.alpha or 0.6
	local var_124_4 = {
		cc.c4fFromc4b(cc.c4b(255, 244, 125, var_124_3 * 255)),
		cc.c4fFromc4b(cc.c4b(255, 244, 125, var_124_3 * 255)),
		cc.c4fFromc4b(cc.c4b(255, 244, 125, var_124_3 * 255)),
		cc.c4fFromc4b(cc.c4b(255, 244, 125, var_124_3 * 255)),
		cc.c4fFromc4b(cc.c4b(255, 244, 125, var_124_3 * 255)),
		cc.c4fFromc4b(cc.c4b(255, 244, 125, var_124_3 * 255))
	}
	local var_124_5 = cc.c4fFromc4b(cc.c4b(255, 244, 125, var_124_3 * 255))
	local var_124_6 = {}

	for iter_124_0 = 1, #var_124_0 do
		local var_124_7 = var_124_0[iter_124_0] / 100
		local var_124_8 = var_124_4[iter_124_0]
		local var_124_9 = cc.c4f(var_124_8.r * var_124_7 + var_124_5.r * (1 - var_124_7), var_124_8.g * var_124_7 + var_124_5.g * (1 - var_124_7), var_124_8.b * var_124_7 + var_124_5.b * (1 - var_124_7), var_124_3)

		table.insert(var_124_6, var_124_9)
	end

	xyd.drawCyclicPolygonWithColor(arg_124_0, {
		values = var_124_0,
		colors = var_124_6,
		center = var_124_1,
		centerColor = var_124_5,
		radius = var_124_2
	})
end

function xyd.drawCyclicPolygonWithColor(arg_125_0, arg_125_1)
	arg_125_0:removeAllChildren()

	local var_125_0 = arg_125_0:getContentSize()
	local var_125_1 = arg_125_0:getPosition()
	local var_125_2 = arg_125_1.values
	local var_125_3 = arg_125_1.colors
	local var_125_4 = arg_125_1.centerColor
	local var_125_5 = arg_125_1.center or cc.p(120, 120)
	local var_125_6 = arg_125_1.valueLimit or 100
	local var_125_7 = arg_125_1.radius or 110
	local var_125_8 = #var_125_2
	local var_125_9 = 2 * math.pi / var_125_8
	local var_125_10 = 2 * math.pi / 3
	local var_125_11 = var_125_7 / var_125_6
	local var_125_12 = {}
	local var_125_13 = var_125_10

	for iter_125_0, iter_125_1 in ipairs(var_125_2) do
		local var_125_14 = math.cos(var_125_13) * iter_125_1 * var_125_11 + var_125_5.x
		local var_125_15 = math.sin(var_125_13) * iter_125_1 * var_125_11 + var_125_5.y

		table.insert(var_125_12, {
			var_125_14,
			var_125_15
		})

		var_125_13 = var_125_13 + var_125_9
	end

	display.newConvexPolygon(var_125_12, {
		borderWidth = 2,
		center = var_125_5,
		centerColor = var_125_4,
		borderColor = cc.c4f(1, 0.969, 0.808, 1),
		vertColors = var_125_3
	}):addTo(arg_125_0)
end

function xyd.luaStringSplit(arg_126_0, arg_126_1)
	if not arg_126_0 then
		return nil
	end

	local var_126_0 = {}

	while true do
		local var_126_1 = string.find(arg_126_0, arg_126_1)

		if not var_126_1 then
			var_126_0[#var_126_0 + 1] = arg_126_0

			break
		end

		local var_126_2 = string.sub(arg_126_0, 1, var_126_1 - 1)

		var_126_0[#var_126_0 + 1] = var_126_2
		arg_126_0 = string.sub(arg_126_0, var_126_1 + 1, #arg_126_0)
	end

	return var_126_0
end

function xyd.secondsToString(arg_127_0, arg_127_1)
	local var_127_0 = math.floor(arg_127_0 / 86400)
	local var_127_1 = math.floor(arg_127_0 % 86400 / 3600)
	local var_127_2 = math.floor(arg_127_0 % 3600 / 60)
	local var_127_3 = math.floor(arg_127_0 % 60)
	local var_127_4 = ""

	if arg_127_1 and arg_127_1.toText == true then
		if var_127_0 > 0 then
			var_127_4 = var_127_0 .. xyd.tables.translation:translation("UNIT_DAY")

			if arg_127_1.short == true then
				return var_127_4
			end
		end

		if var_127_1 > 0 then
			if var_127_1 < 10 then
				var_127_4 = var_127_4 .. "0"
			end

			var_127_4 = var_127_4 .. tostring(var_127_1) .. xyd.tables.translation:translation("UNIT_HOUR")

			if arg_127_1.short == true then
				return var_127_4
			end
		end

		if var_127_2 < 10 then
			var_127_4 = var_127_4 .. "0"
		end

		var_127_4 = var_127_4 .. tostring(var_127_2) .. xyd.tables.translation:translation("UNIT_MINUTE")

		if var_127_3 < 10 then
			var_127_4 = var_127_4 .. "0" .. xyd.tables.translation:translation("UNIT_SECOND")
		end
	else
		if var_127_0 > 0 then
			var_127_4 = var_127_0 .. "d "
		end

		if var_127_1 > 0 then
			if var_127_1 < 10 then
				var_127_4 = var_127_4 .. "0"
			end

			var_127_4 = var_127_4 .. tostring(var_127_1) .. ":"
		end

		if var_127_2 < 10 then
			var_127_4 = var_127_4 .. "0"
		end

		var_127_4 = var_127_4 .. tostring(var_127_2) .. ":"

		if var_127_3 < 10 then
			var_127_4 = var_127_4 .. "0"
		end

		var_127_4 = var_127_4 .. tostring(var_127_3)
	end

	return var_127_4
end

function xyd.secondsToString1(arg_128_0, arg_128_1)
	local var_128_0 = math.floor(arg_128_0 / 86400)
	local var_128_1 = math.floor(arg_128_0 % 86400 / 3600)
	local var_128_2 = math.floor(arg_128_0 % 3600 / 60)
	local var_128_3 = math.floor(arg_128_0 % 60)
	local var_128_4 = ""

	arg_128_1 = arg_128_1 or 2

	local var_128_5 = 0

	if var_128_0 > 0 then
		var_128_4 = var_128_0 .. xyd.tables.translation:translation("UNIT_DAY")
		var_128_5 = var_128_5 + 1
	end

	if var_128_1 > 0 then
		var_128_4 = var_128_4 .. tostring(var_128_1) .. xyd.tables.translation:translation("UNIT_HOUR")
		var_128_5 = var_128_5 + 1

		if arg_128_1 <= var_128_5 then
			return var_128_4
		end
	end

	if var_128_2 > 0 then
		var_128_4 = var_128_4 .. tostring(var_128_2) .. xyd.tables.translation:translation("UNIT_MINUTE")
		var_128_5 = var_128_5 + 1

		if arg_128_1 <= var_128_5 then
			return var_128_4
		end
	end

	if var_128_3 > 0 then
		var_128_4 = var_128_4 .. var_128_3 .. xyd.tables.translation:translation("UNIT_SECOND")

		if arg_128_1 <= var_128_5 + 1 then
			return var_128_4
		end
	end

	return var_128_4
end

function xyd.addCampaignStar(arg_129_0, arg_129_1)
	local function var_129_0()
		local var_130_0 = "images/star.png"

		return xyd.AssetLoader.get():loadSprite(var_130_0)
	end

	local var_129_1 = xyd.AssetLoader.get():loadSprite("images/star_bg.png")

	arg_129_0:addChild(var_129_1)
	var_129_1:setAnchorPoint(cc.p(0, 0))

	for iter_129_0 = 1, arg_129_1 do
		local var_129_2 = var_129_0()

		arg_129_0:addChild(var_129_2)
		var_129_2:x((iter_129_0 - 1) * 30 + 4):y(5)
		var_129_2:setAnchorPoint(cc.p(0, 0))
	end

	arg_129_0:setContentSize(var_129_1:getContentSize())
end

function xyd.tableMerge(arg_131_0, arg_131_1)
	if not arg_131_1 or not next(arg_131_1) then
		return arg_131_0
	end

	for iter_131_0, iter_131_1 in pairs(arg_131_1) do
		if type(iter_131_1) == "table" then
			if type(arg_131_0[iter_131_0] or false) == "table" then
				xyd.tableMerge(arg_131_0[iter_131_0] or {}, arg_131_1[iter_131_0] or {})
			else
				arg_131_0[iter_131_0] = iter_131_1
			end
		else
			arg_131_0[iter_131_0] = iter_131_1
		end
	end
end

function xyd.tableHaveElement(arg_132_0, arg_132_1)
	for iter_132_0 = 1, #arg_132_0 do
		if arg_132_0[iter_132_0] == arg_132_1 then
			return true
		end
	end

	return false
end

function xyd.setAvatarClip(arg_133_0, arg_133_1, arg_133_2)
	local var_133_0

	if arg_133_1 then
		var_133_0 = "images/avatars/" .. arg_133_1 .. ".png"
	else
		var_133_0 = "images/avatars/" .. xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarId] .. ".png"
	end

	local var_133_1 = true

	if xyd.tables.avatar:isActive(arg_133_1) then
		var_133_0 = xyd.tables.avatar:iconJson(arg_133_1)

		local var_133_2 = false
	end

	local var_133_3

	if xyd.tables.avatar:isActive(arg_133_1) then
		var_133_3 = xyd.createEffect(var_133_0)

		var_133_3:play(nil, true)
	elseif arg_133_2 == 6 then
		local var_133_4 = {
			filter = {}
		}

		var_133_4.filter.name = "GRAY"
		var_133_4.filter.value = {
			0.2,
			0.3,
			0.5,
			0.1
		}
		var_133_3 = xyd.SpriteLoader.new(var_133_0, nil, var_133_4, xyd.DefaultImageType.AVATAR)
	else
		var_133_3 = xyd.SpriteLoader.new(var_133_0, nil, nil, xyd.DefaultImageType.AVATAR)
	end

	local var_133_5 = arg_133_0:getContentSize().width
	local var_133_6 = arg_133_0:getContentSize().height
	local var_133_7 = xyd.AssetLoader.get():loadSprite("images/avatars/touxiang_clip.png")

	var_133_7:setPosition(var_133_5 / 2, var_133_6 / 2)
	var_133_7:setAnchorPoint(cc.p(0.5, 0.5))

	if xyd.tables.avatar:isActive(arg_133_1) then
		var_133_3:setScale(var_133_6 / xyd.AvatarWidth)
	else
		var_133_3:setScale(var_133_6 / var_133_3:getHeight())
	end

	var_133_7:setScale(var_133_6 / (var_133_7:getHeight() - 196))

	local var_133_8 = cc.ClippingNode:create()

	var_133_8:setStencil(var_133_7)
	var_133_8:setInverted(true)
	var_133_8:setAlphaThreshold(0)
	arg_133_0:addChild(var_133_8)
	var_133_8:addChild(var_133_3)
	var_133_3:setPosition(var_133_5 / 2, var_133_6 / 2)
	var_133_3:setAnchorPoint(cc.p(0.5, 0.5))
	var_133_8:setLocalZOrder(-1)

	return arg_133_0
end

function xyd.setCircleClip(arg_134_0, arg_134_1, arg_134_2)
	local var_134_0 = arg_134_1

	if not var_134_0 then
		return
	end

	local var_134_1 = cc.FileUtils:getInstance():fullPathForFilename(var_134_0)

	if io.exists(var_134_1) ~= true then
		return false
	end

	local var_134_2

	if arg_134_2 == 6 then
		var_134_2 = xyd.GrayedSprite.new(var_134_0)
	else
		var_134_2 = xyd.AssetLoader.get():loadSprite(var_134_0)
	end

	local var_134_3 = arg_134_0:getContentSize().width
	local var_134_4 = arg_134_0:getContentSize().height
	local var_134_5 = xyd.AssetLoader.get():loadSprite("images/avatars/touxiang_clip.png")

	var_134_5:setPosition(var_134_3 / 2, var_134_4 / 2)
	var_134_5:setAnchorPoint(cc.p(0.5, 0.5))
	var_134_5:setScale(var_134_4 / (var_134_5:getHeight() - 196))

	local var_134_6 = cc.ClippingNode:create()

	var_134_6:setStencil(var_134_5)
	var_134_6:setInverted(true)
	var_134_6:setAlphaThreshold(0)
	arg_134_0:addChild(var_134_6)
	var_134_6:addChild(var_134_2)
	var_134_2:setPosition(var_134_3 / 2, var_134_4 / 2)
	var_134_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_134_2:setScale(var_134_4 / var_134_2:getHeight())
	var_134_6:setLocalZOrder(-1)

	return arg_134_0
end

function xyd.justSetAvatar(arg_135_0, arg_135_1)
	local var_135_0
	local var_135_1

	if type(arg_135_0) == "number" or type(arg_135_0) == "string" then
		local var_135_2 = tonumber(arg_135_0)
		local var_135_3 = xyd.tables.hero:modelID(var_135_2)

		var_135_0 = xyd.tables.model:avatar(var_135_3)
	else
		local var_135_4

		var_135_4 = type(color) == "boolean" and color == true
		var_135_0 = arg_135_0:getAvatar()
		heroColor = arg_135_0:getColor()
		heroStar = arg_135_0:getStar()
	end

	local var_135_5 = xyd.SpriteLoader.new(var_135_0, nil, nil, xyd.DefaultImageType.AVATAR)
	local var_135_6 = arg_135_1:getContentSize()

	var_135_5 = var_135_5 or xyd.AssetLoader.get():loadSprite("windows/common/common_avatar.png")

	local var_135_7 = xyd.AssetLoader:get():loadSprite("windows/common/avatar_mask.png")
	local var_135_8 = cc.ClippingNode:create()

	var_135_8:setStencil(var_135_7)
	var_135_8:setInverted(false)
	var_135_8:setAlphaThreshold(0)
	var_135_8:addChild(var_135_5)
	var_135_5:align(display.CENTER, var_135_6.width / 2, var_135_6.height / 2)
	var_135_5:scale(var_135_6.width / var_135_5:getWidth())
	var_135_7:addTo(arg_135_1, -1)
	var_135_7:align(display.CENTER, var_135_6.width / 2, var_135_6.height / 2)
	var_135_7:scale((var_135_6.width - 3) / var_135_7:getWidth())
	arg_135_1:addChild(var_135_8)
end

function xyd.setItemStarOnTop(arg_136_0, arg_136_1)
	local function var_136_0()
		local var_137_0 = "windows/common/small_yellow_star.png"

		return xyd.AssetLoader.get():loadSprite(var_137_0)
	end

	local var_136_1 = arg_136_0:getContentSize()
	local var_136_2 = var_136_0():getContentSize().width - 3
	local var_136_3 = (var_136_1.width - arg_136_1 * var_136_2) / 2

	for iter_136_0 = 1, arg_136_1 do
		local var_136_4 = var_136_0()

		arg_136_0:addChild(var_136_4)
		var_136_4:setAnchorPoint(cc.p(0, 1))
		var_136_4:x(var_136_3 + (iter_136_0 - 1) * var_136_2):y(var_136_1.height - 5)
	end
end

function xyd.justSetAvatarBorderAndStar(arg_138_0, arg_138_1, arg_138_2)
	local function var_138_0()
		local var_139_0 = "windows/common/small_yellow_star.png"

		return xyd.AssetLoader.get():loadSprite(var_139_0)
	end

	local var_138_1 = arg_138_1
	local var_138_2 = arg_138_2
	local var_138_3 = xyd.getAvatarBorder(var_138_1)
	local var_138_4 = clone(var_138_3:getContentSize())

	xyd.displaySpriteOnContainer(var_138_3, arg_138_0, true)
	var_138_3:setName("border")

	local var_138_5 = arg_138_0:getContentSize()
	local var_138_6 = var_138_0():getContentSize().width - 3
	local var_138_7 = (var_138_4.width - var_138_2 * var_138_6) / 2
	local var_138_8 = display.newNode()

	var_138_8:setName("view")
	var_138_8:setContentSize(var_138_4)
	var_138_8:setAnchorPoint(cc.p(0, 0))
	var_138_8:setPosition(cc.p(0, 0))

	for iter_138_0 = 1, var_138_2 do
		local var_138_9 = var_138_0()

		var_138_8:addChild(var_138_9)
		var_138_9:x(var_138_7 + (iter_138_0 - 1) * var_138_6):y(5)
		var_138_9:setAnchorPoint(cc.p(0, 0))
	end

	var_138_8:setScale(var_138_5.width / var_138_4.width, var_138_5.height / var_138_4.height)
	arg_138_0:addChild(var_138_8)
end

function xyd.getWeekDay()
	local var_140_0 = xyd.ServerTime.get():getServerTime()

	return (os.date("%A", var_140_0))
end

function xyd.addRollingWorld(arg_141_0, arg_141_1, arg_141_2, arg_141_3, arg_141_4, arg_141_5)
	local var_141_0 = xyd.rollingWidthPerWorld(arg_141_1, arg_141_3, arg_141_4)
	local var_141_1 = cc.rect(0, 0, arg_141_0:getWidth(), arg_141_0:getHeight())
	local var_141_2 = display.newClippingRegionNode(var_141_1)
	local var_141_3 = cc.ui.UILabel.new({
		text = arg_141_1,
		font = arg_141_3,
		size = arg_141_4,
		color = cc.c3b(255, 255, 255),
		align = cc.ui.TEXT_ALIGN_CENTER,
		valign = cc.ui.TEXT_VALIGN_CENTER
	}):align(display.CENTER_LEFT, var_141_1.width + var_141_1.x, var_141_1.y + arg_141_0:getHeight() / 2):addTo(var_141_2)
	local var_141_4 = math.round(var_141_3:getContentSize().width)

	local function var_141_5()
		if var_141_3 ~= nil then
			var_141_3:removeSelf()

			var_141_3 = nil
		end
	end

	local var_141_6 = cc.MoveBy:create(arg_141_2, cc.p(-(var_141_1.width + var_141_4), 0))
	local var_141_7 = cc.CallFunc:create(var_141_5)
	local var_141_8 = cc.Sequence:create(var_141_6, var_141_7)

	arg_141_0:addChild(var_141_2)
	var_141_3:runAction(var_141_8)
end

xyd.mWideWordWidth = {}

function xyd.rollingWidthPerWorld(arg_143_0, arg_143_1, arg_143_2)
	local var_143_0 = string.format("%s%d", arg_143_1, arg_143_2)

	if xyd.mWideWordWidth[var_143_0] == nil then
		local var_143_1 = "ABCDEFGHIJKLMNopqrstuvwxyz1234567890"

		xyd.mWideWordWidth[var_143_0] = cc.Label:createWithTTF(var_143_1, arg_143_1, arg_143_2):getContentSize().width / (string.len(var_143_1) / 3)
	end

	return xyd.mWideWordWidth[var_143_0]
end

function xyd.randomIndex(arg_144_0, arg_144_1)
	if arg_144_1 <= 1 then
		return arg_144_0
	end

	local var_144_0 = math.random(arg_144_1)

	if var_144_0 ~= arg_144_0 then
		return var_144_0
	end

	if var_144_0 > 1 then
		return var_144_0 - 1
	end

	if var_144_0 < arg_144_1 then
		return var_144_0 + 1
	end

	return var_144_0
end

function xyd.luaStringMerge(arg_145_0, arg_145_1)
	local var_145_0 = arg_145_0[1]

	for iter_145_0 = 2, #arg_145_0 do
		var_145_0 = var_145_0 .. arg_145_1 .. arg_145_0[iter_145_0]
	end

	return var_145_0
end

function xyd.sleep(arg_146_0)
	socket.select(nil, nil, arg_146_0)
end

function xyd.FBDianZan()
	if device.platform == "android" then
		local var_147_0 = "org/cocos2dx/lua/AppActivity"
		local var_147_1 = "fbPraise"
		local var_147_2 = {
			xyd.tables.misc.fb_link,
			"586658441487615"
		}
		local var_147_3 = "(Ljava/lang/String;Ljava/lang/String;)V"
		local var_147_4, var_147_5 = luaj.callStaticMethod(var_147_0, var_147_1, var_147_2, var_147_3)
	elseif device.platform == "ios" then
		luaoc.callStaticMethod("SdkIOS", "initZanView", {})
	end
end

function xyd.generateUUID()
	local var_148_0 = math.random
	local var_148_1 = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"

	return string.gsub(var_148_1, "[xy]", function(arg_149_0)
		local var_149_0 = arg_149_0 == "x" and var_148_0(0, 15) or var_148_0(8, 11)

		return string.format("%x", var_149_0)
	end)
end

function xyd.playSceneShaking(arg_150_0, arg_150_1)
	local var_150_0 = cc.Director:getInstance():getRunningScene()
	local var_150_1 = cc.Director:getInstance():getWinSize()

	var_150_0:setPosition(0, 0)

	local var_150_2 = xyd.Shake:create(arg_150_0, arg_150_1)

	var_150_0:runAction(var_150_2)
end

function xyd.createMultiColorTxt(arg_151_0, arg_151_1, arg_151_2, arg_151_3, arg_151_4)
	local function var_151_0(arg_152_0)
		if string.len(arg_152_0) ~= 6 then
			print("Wrong color params.")

			return
		end

		return cc.c3b(tonumber(string.sub(arg_152_0, 1, 2), 16), tonumber(string.sub(arg_152_0, 3, 4), 16), tonumber(string.sub(arg_152_0, 5, 6), 16))
	end

	local function var_151_1(arg_153_0)
		if string.sub(arg_153_0, 1, 1) == "#" then
			local var_153_0 = string.sub(arg_153_0, 2, string.find(string.sub(arg_153_0, 2), "#"))
			local var_153_1 = string.sub(arg_153_0, string.find(string.sub(arg_153_0, 2), "#") + 2)

			return var_151_0(var_153_0), var_153_1
		else
			return arg_151_1, arg_153_0
		end
	end

	local var_151_2 = display.newNode()
	local var_151_3 = {}
	local var_151_4 = string.len(arg_151_0)
	local var_151_5 = 1
	local var_151_6 = var_151_4

	for iter_151_0 = 1, var_151_4 do
		local var_151_7 = string.sub(arg_151_0, iter_151_0, iter_151_0)

		if var_151_7 == "{" and iter_151_0 == var_151_5 then
			var_151_5 = var_151_5 + 1
		end

		if var_151_7 == "{" then
			local var_151_8 = string.sub(arg_151_0, var_151_5, iter_151_0 - 1)
			local var_151_9, var_151_10 = var_151_1(var_151_8)
			local var_151_11 = {
				text = var_151_10,
				color = var_151_9
			}

			table.insert(var_151_3, var_151_11)

			var_151_5 = iter_151_0 + 1
		elseif var_151_7 == "}" then
			local var_151_12 = string.sub(arg_151_0, var_151_5, iter_151_0 - 1)
			local var_151_13, var_151_14 = var_151_1(var_151_12)
			local var_151_15 = {
				text = var_151_14,
				color = var_151_13
			}

			table.insert(var_151_3, var_151_15)

			var_151_5 = iter_151_0 + 1
		elseif iter_151_0 == var_151_6 then
			local var_151_16 = string.sub(arg_151_0, var_151_5, iter_151_0)
			local var_151_17, var_151_18 = var_151_1(var_151_16)
			local var_151_19 = {
				text = var_151_18,
				color = var_151_17
			}

			table.insert(var_151_3, var_151_19)

			var_151_5 = iter_151_0 + 1
		end

		if var_151_6 < var_151_5 then
			break
		end
	end

	local var_151_20 = 0
	local var_151_21 = 0

	for iter_151_1, iter_151_2 in ipairs(var_151_3) do
		local var_151_22 = display.newTTFLabel({
			font = "fonts/main_font.ttf",
			text = iter_151_2.text,
			size = arg_151_2,
			color = iter_151_2.color,
			align = cc.TEXT_ALIGNMENT_LEFT
		})

		if arg_151_3 then
			var_151_22:enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
		end

		if arg_151_4 then
			var_151_22:enableOutline(arg_151_4, 2)
		end

		var_151_22:addTo(var_151_2)
		var_151_22:setPosition(var_151_20, 0)
		var_151_22:setAnchorPoint(cc.p(0, 0))

		var_151_20 = var_151_20 + var_151_22:getContentSize().width + 2
		var_151_21 = var_151_22:getContentSize().height + 1
	end

	var_151_2:setContentSize(var_151_20, var_151_21)

	return var_151_2
end

function xyd.createMultiLineMultiColorTxt(arg_154_0, arg_154_1, arg_154_2, arg_154_3)
	local var_154_0 = xyd.split(arg_154_0, "\n")
	local var_154_1 = display.newNode()
	local var_154_2 = 0
	local var_154_3 = 0

	for iter_154_0 = #var_154_0, 1, -1 do
		local var_154_4 = xyd.createMultiColorTxt(var_154_0[iter_154_0], arg_154_1, arg_154_2, arg_154_3)

		var_154_4:setAnchorPoint(cc.p(0, 0))
		var_154_4:addTo(var_154_1)
		var_154_4:setPositionY(var_154_2)

		var_154_2 = var_154_2 + var_154_4:getContentSize().height + 1

		if var_154_3 < var_154_4:getContentSize().width then
			var_154_3 = var_154_4:getContentSize().width
		end
	end

	var_154_1:setContentSize(var_154_3, var_154_2)

	return var_154_1
end

function xyd.createUrlAndColorTxt(arg_155_0, arg_155_1, arg_155_2, arg_155_3)
	local function var_155_0(arg_156_0)
		if string.len(arg_156_0) ~= 6 then
			print("Wrong color params.")

			return
		end

		return cc.c3b(tonumber(string.sub(arg_156_0, 1, 2), 16), tonumber(string.sub(arg_156_0, 3, 4), 16), tonumber(string.sub(arg_156_0, 5, 6), 16))
	end

	local function var_155_1(arg_157_0)
		if string.sub(arg_157_0, 1, 1) == "#" then
			local var_157_0 = string.sub(arg_157_0, 2, string.find(string.sub(arg_157_0, 2), "#"))
			local var_157_1 = string.sub(arg_157_0, string.find(string.sub(arg_157_0, 2), "#") + 2)

			if var_157_0 == "u" or var_157_0 == "t" then
				return var_157_0, var_157_1
			else
				return var_155_0(var_157_0) or arg_155_1, var_157_1
			end
		else
			return arg_155_1, arg_157_0
		end
	end

	local var_155_2 = display.newNode()
	local var_155_3 = {}
	local var_155_4 = string.len(arg_155_0)
	local var_155_5 = 1

	for iter_155_0 = 1, var_155_4 do
		local var_155_6 = string.sub(arg_155_0, iter_155_0, iter_155_0)

		if var_155_6 == "{" and iter_155_0 == var_155_5 then
			var_155_5 = var_155_5 + 1
		end

		if var_155_6 == "{" then
			local var_155_7 = string.sub(arg_155_0, var_155_5, iter_155_0 - 1)
			local var_155_8, var_155_9 = var_155_1(var_155_7)
			local var_155_10 = {
				text = var_155_9,
				color = var_155_8
			}

			table.insert(var_155_3, var_155_10)

			var_155_5 = iter_155_0 + 1
		elseif var_155_6 == "}" then
			local var_155_11 = string.sub(arg_155_0, var_155_5, iter_155_0 - 1)
			local var_155_12, var_155_13 = var_155_1(var_155_11)
			local var_155_14 = {
				text = var_155_13,
				color = var_155_12
			}

			table.insert(var_155_3, var_155_14)

			var_155_5 = iter_155_0 + 1
		elseif iter_155_0 == var_155_4 then
			local var_155_15 = string.sub(arg_155_0, var_155_5, iter_155_0)
			local var_155_16, var_155_17 = var_155_1(var_155_15)
			local var_155_18 = {
				text = var_155_17,
				color = var_155_16
			}

			table.insert(var_155_3, var_155_18)

			var_155_5 = iter_155_0 + 1
		end

		if var_155_4 < var_155_5 then
			break
		end
	end

	local var_155_19 = 0
	local var_155_20 = 0

	for iter_155_1, iter_155_2 in ipairs(var_155_3) do
		local var_155_21

		if iter_155_2.color == "t" then
			var_155_21 = xyd.AssetLoader.get():loadLabel({
				font = "fonts/main_font.ttf",
				color = arg_155_1,
				size = arg_155_2
			})

			var_155_21:setWidth(arg_155_3)
			var_155_21:setMaxLineWidth(arg_155_3)
			var_155_21:setLineBreakWithoutSpace(true)
			var_155_21:setString(iter_155_2.text)
		elseif iter_155_2.color == "u" then
			var_155_21 = xyd.createLinkLabel(iter_155_2.text, arg_155_2, cc.c3b(0, 73, 255), cc.c4f(0, 0.28627450980392155, 1, 1), 3, function(arg_158_0)
				cc.Application:getInstance():openURL(iter_155_2.text)
			end)
		else
			var_155_21 = display.newTTFLabel({
				font = "fonts/main_font.ttf",
				text = iter_155_2.text,
				size = arg_155_2,
				color = iter_155_2.color,
				align = cc.TEXT_ALIGNMENT_LEFT
			})

			var_155_21:setMaxLineWidth(arg_155_3)
		end

		var_155_21:addTo(var_155_2)
		var_155_21:setPosition(var_155_19, 0)
		var_155_21:setAnchorPoint(cc.p(0, 0))

		var_155_19 = var_155_19 + var_155_21:getContentSize().width
		var_155_20 = var_155_21:getContentSize().height
	end

	var_155_2:setContentSize(var_155_19, var_155_20)

	return var_155_2
end

function xyd.getTimeZoneDiff()
	local var_159_0 = os.time()

	return os.difftime(var_159_0, os.time(os.date("!*t", os.time())))
end

function xyd.date(arg_160_0, arg_160_1)
	local var_160_0 = xyd.getTimeZoneDiff()
	local var_160_1 = arg_160_1 - xyd.timeZone * 3600 + var_160_0

	return os.date(arg_160_0, var_160_1)
end

function xyd.timeFormatAsHMS(arg_161_0)
	return string.format("%.2d:%.2d:%.2d", arg_161_0 / 3600, arg_161_0 / 60 % 60, arg_161_0 % 60)
end

function xyd.getSplitUtf8Str(arg_162_0, arg_162_1, arg_162_2)
	local var_162_0 = string.byte(arg_162_0, arg_162_2 + 1)

	if not var_162_0 then
		return arg_162_0
	end

	if var_162_0 >= 128 and var_162_0 < 192 then
		return xyd.getSplitUtf8Str(arg_162_0, 1, arg_162_2 - 1)
	end

	return string.sub(arg_162_0, 1, arg_162_2), string.sub(arg_162_0, arg_162_2 + 1, #arg_162_0)
end

function xyd.createLinkLabel(arg_163_0, arg_163_1, arg_163_2, arg_163_3, arg_163_4, arg_163_5)
	local var_163_0 = display.newNode()

	var_163_0:setAnchorPoint(cc.p(0, 0))

	local var_163_1 = {
		color = arg_163_2,
		size = arg_163_1
	}
	local var_163_2 = xyd.AssetLoader.get():loadLabel(var_163_1)

	var_163_2:setAnchorPoint(cc.p(0, 0))
	var_163_2:setString(arg_163_0)

	local var_163_3 = var_163_2:getContentSize().width
	local var_163_4 = var_163_2:getContentSize().height

	var_163_0:setContentSize(var_163_3, var_163_4)
	var_163_2:addTo(var_163_0)

	local var_163_5 = display.newLine({
		{
			0,
			0
		},
		{
			var_163_3,
			0
		}
	}, {
		borderColor = arg_163_3,
		borderWidth = arg_163_4
	})

	var_163_5:setAnchorPoint(cc.p(0, 0))
	var_163_5:addTo(var_163_0)
	var_163_5:setPosition(0, 0)
	var_163_5:setLocalZOrder(100)

	var_163_0.str = arg_163_0

	if arg_163_5 then
		var_163_0:setTouchEnabled(true)
		var_163_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_164_0)
			if arg_164_0.name == "ended" then
				arg_163_5(var_163_0.str)
			end

			return true
		end)
	end

	return var_163_0
end

function xyd.splitStrByPairTag(arg_165_0, arg_165_1, arg_165_2)
	local function var_165_0(arg_166_0, arg_166_1)
		return {
			str = arg_166_0,
			type = arg_166_1
		}
	end

	if arg_165_0 == "" or arg_165_0 == nil then
		return nil
	end

	local var_165_1 = 0
	local var_165_2 = 0
	local var_165_3 = string.len(arg_165_1)
	local var_165_4 = string.len(arg_165_2)
	local var_165_5 = {}

	repeat
		local var_165_6 = string.find(arg_165_0, arg_165_1)
		local var_165_7 = string.find(arg_165_0, arg_165_2)

		if not var_165_6 or not var_165_7 then
			table.insert(var_165_5, var_165_0(arg_165_0, xyd.ParseStrType.TEXT))

			return var_165_5
		end

		if var_165_7 < var_165_6 + var_165_3 then
			return nil
		end

		if not var_165_6 then
			table.insert(var_165_5, var_165_0(arg_165_0, xyd.ParseStrType.TEXT))

			break
		end

		local var_165_8 = string.sub(arg_165_0, 1, var_165_6 - 1)

		if var_165_8 and var_165_8 ~= "" then
			table.insert(var_165_5, var_165_0(string.sub(arg_165_0, 1, var_165_6 - 1), xyd.ParseStrType.TEXT))
		end

		local var_165_9 = string.sub(arg_165_0, var_165_6 + var_165_3, var_165_7)

		if var_165_9 and var_165_9 ~= "" then
			table.insert(var_165_5, var_165_0(string.sub(arg_165_0, var_165_6 + var_165_3, var_165_7 - 1), xyd.ParseStrType.MARK))
		end

		arg_165_0 = string.sub(arg_165_0, var_165_7 + var_165_4, #arg_165_0)
	until not arg_165_0 or arg_165_0 == ""

	return var_165_5
end

function xyd.setPetAvatar(arg_167_0, arg_167_1, arg_167_2, arg_167_3, arg_167_4, arg_167_5, arg_167_6)
	if not arg_167_1 then
		return
	end

	local var_167_0 = {
		{
			50,
			10
		},
		{
			34,
			16,
			66,
			16
		},
		{
			50,
			10,
			18,
			24,
			82,
			24
		},
		{
			38,
			12,
			62,
			12,
			18,
			24,
			82,
			24
		},
		{
			50,
			10,
			34,
			16,
			66,
			16,
			18,
			24,
			82,
			24
		}
	}

	local function var_167_1()
		local var_168_0 = "images/battle/star_small2.png"

		return xyd.AssetLoader.get():loadSprite(var_168_0)
	end

	if not arg_167_0 or tolua.isnull(arg_167_0) then
		return
	end

	local var_167_2 = arg_167_1:getAvatar(2)
	local var_167_3 = arg_167_1:getColor()
	local var_167_4 = arg_167_1:getStar()
	local var_167_5 = xyd.AssetLoader.get():loadNodeFromJson("windows/battle/select_team/pet_avatar.csb")

	var_167_5:getChildByName("avatar_mask"):hide()
	var_167_5:getChildByName("chosen"):hide()
	var_167_5:getChildByName("name"):setString(arg_167_1:getName())

	if arg_167_3 then
		var_167_5:getChildByName("name_label_bg"):setVisible(false)
		var_167_5:getChildByName("name"):setString("")
	end

	local var_167_6 = var_167_5:getChildByName("background"):getWidth()

	var_167_5:size(var_167_6, var_167_6)
	arg_167_0:addChild(var_167_5)
	var_167_5:setName("layout")
	var_167_5:align(display.CENTER, arg_167_0:getWidth() / 2, arg_167_0:getHeight() / 2)

	local var_167_7 = var_167_5:getChildByName("avatar")
	local var_167_8

	if arg_167_1:isAwaken() and not arg_167_4 then
		var_167_8 = xyd.AssetLoader.get():loadSprite("images/battle/b_pet_awake_avatar_border_" .. var_167_3 .. ".png")
	else
		var_167_8 = xyd.AssetLoader.get():loadSprite("images/battle/b_pet_avatar_border_" .. var_167_3 .. ".png")
	end

	var_167_7:addChild(var_167_8)
	var_167_8:align(display.CENTER, 50, 50)

	local var_167_9 = xyd.AssetLoader.get():loadSprite(var_167_2)

	var_167_7:addChild(var_167_9)
	var_167_9:align(display.CENTER_BOTTOM, 50, 0)

	if var_167_4 and var_167_4 > 0 then
		local var_167_10 = var_167_1():getWidth()
		local var_167_11 = var_167_0[var_167_4]

		for iter_167_0 = var_167_4, 1, -1 do
			local var_167_12 = var_167_1()

			var_167_7:addChild(var_167_12)
			var_167_12:align(display.CENTER, var_167_11[2 * iter_167_0 - 1], var_167_11[2 * iter_167_0])
		end
	end

	if arg_167_5 then
		local var_167_13 = arg_167_0:getContentSize()

		var_167_5:scale(var_167_13.width / var_167_5:getWidth() * 1.3)
	end

	if arg_167_6 then
		local var_167_14 = arg_167_1:getName()
		local var_167_15 = display.newScale9Sprite("windows/common/name_label_bg.png", 0, 0, cc.size(119, 25), cc.rect(5, 5, 5, 5))

		var_167_15:setAnchorPoint(cc.p(0.5, 1))

		local var_167_16 = xyd.createLabel(20, cc.c3b(255, 255, 255))

		var_167_16:setAnchorPoint(cc.p(0.5, 0.5))
		var_167_16:setString(var_167_14)
		var_167_16:addTo(var_167_15)
		var_167_16:setPosition(cc.p(var_167_15:getContentSize().width / 2, var_167_15:getContentSize().height / 2))
		var_167_15:addTo(arg_167_0)
		var_167_15:setPosition(cc.p(arg_167_0:getContentSize().width / 2, -4))
		var_167_15:setScale(arg_167_0:getContentSize().width / var_167_5:getWidth() * 1.2, arg_167_0:getContentSize().height / var_167_5:getHeight() * 1.2)
		var_167_15:setName("name_bg")
	end
end

function xyd.getPlayerRegion(arg_169_0)
	local var_169_0 = 100000

	return math.floor(tonumber(arg_169_0) / var_169_0)
end

function xyd.getGuildRegion(arg_170_0)
	local var_170_0 = 1000000

	return math.floor(tonumber(arg_170_0) / var_170_0)
end

function xyd.getChannel()
	local var_171_0 = 0

	if device.platform == "android" then
		local var_171_1 = "org/cocos2dx/lua/AppActivity"
		local var_171_2 = "getChannel"
		local var_171_3 = {}
		local var_171_4 = "()I"
		local var_171_5, var_171_6 = luaj.callStaticMethod(var_171_1, var_171_2, var_171_3, var_171_4)

		if var_171_5 then
			var_171_0 = var_171_6
		end
	end

	return var_171_0
end

function xyd.tracking(arg_172_0, arg_172_1)
	print("tracking " .. arg_172_0)

	local var_172_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if device.platform == "android" then
		local var_172_1 = "org/cocos2dx/lua/AppActivity"
		local var_172_2 = "tracking"
		local var_172_3 = {
			arg_172_0,
			tostring(var_172_0.uid),
			tostring(var_172_0.region),
			tostring(var_172_0.playerID),
			tostring(var_172_0.playerName),
			tostring(var_172_0.lev),
			arg_172_1 or ""
		}
		local var_172_4 = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"
		local var_172_5, var_172_6 = luaj.callStaticMethod(var_172_1, var_172_2, var_172_3, var_172_4)
	elseif device.platform == "ios" then
		local var_172_7 = {
			user_id = tostring(var_172_0.uid),
			server_id = tostring(var_172_0.region),
			player_id = tostring(var_172_0.playerID),
			player_name = tostring(var_172_0.playerName),
			player_lev = tostring(var_172_0.lev),
			trackName = arg_172_0
		}

		luaoc.callStaticMethod("SdkIOS", "startCustomTrack", var_172_7)
	end
end

function xyd.fbTracking(arg_173_0)
	print("tracking " .. arg_173_0)

	if device.platform == "android" then
		xyd.tracking(arg_173_0, "")

		local var_173_0 = "org/cocos2dx/lua/AppActivity"
		local var_173_1 = "fbTracking"
		local var_173_2 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
		local var_173_3 = {
			arg_173_0,
			tostring(var_173_2.uid),
			tostring(var_173_2.region),
			tostring(var_173_2.playerID),
			tostring(var_173_2.playerName),
			tostring(var_173_2.lev)
		}
		local var_173_4 = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"
		local var_173_5, var_173_6 = luaj.callStaticMethod(var_173_0, var_173_1, var_173_3, var_173_4)
	elseif device.platform == "ios" then
		if arg_173_0 == xyd.FBInAppEventName.LEVEL_ACHIEVED then
			luaoc.callStaticMethod("SdkIOS", "sendAchievedLevel", {
				level = 10
			})
		elseif arg_173_0 == xyd.FBInAppEventName.TUTORIAL_COMPLETION then
			luaoc.callStaticMethod("SdkIOS", "sendFinishTutorialMsg", {})
		else
			luaoc.callStaticMethod("SdkIOS", "startFBTrack", {
				eventName = arg_173_0
			})
		end
	end
end

function xyd.printOnScreen(arg_174_0)
	if not display.getRunningScene() then
		return
	end

	local var_174_0 = {}

	if type(arg_174_0) == "table" then
		var_174_0 = arg_174_0
	else
		table.insert(var_174_0, arg_174_0)
	end

	local var_174_1 = display.newRect({
		width = 1000,
		height = 500
	}, {
		fillColor = cc.c4b(0, 0, 0, 160)
	})

	var_174_1:addTo(display.getRunningScene(), 90000)
	var_174_1:align(display.LEFT_BOTTOM, 140, 110)

	local var_174_2 = {
		size = 18,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		color = cc.c4b(255, 255, 255, 255)
	}

	for iter_174_0, iter_174_1 in ipairs(var_174_0) do
		var_174_2.text = iter_174_1

		local var_174_3 = xyd.AssetLoader.get():loadLabel(var_174_2)

		var_174_3:addTo(var_174_1)
		var_174_3:align(display.LEFT_BOTTOM, 0, 30 * iter_174_0 - 30)
	end

	var_174_1:performWithDelay(function()
		var_174_1:removeSelf()
	end, 5)

	local var_174_4 = cc.FileUtils:getInstance():fullPathForFilename("/res/battle_report/log.txt")
	local var_174_5 = ""

	for iter_174_2, iter_174_3 in ipairs(var_174_0) do
		var_174_5 = var_174_5 .. iter_174_3 .. "\n"
	end

	io.writefile(var_174_4, var_174_5, "w+")
end

function xyd.formatAcademyArenaHero(arg_176_0)
	if xyd.isSuperHero(arg_176_0) then
		if arg_176_0:isCanAwaken() and not arg_176_0:isAwaken() then
			arg_176_0:setTableID(arg_176_0:afterAwakenID())
		end

		arg_176_0.level_ = 100
		arg_176_0.color_ = 1
		arg_176_0.star_ = math.max(arg_176_0.star_, 8)
	else
		if arg_176_0:isCanAwaken() and not arg_176_0:isAwaken() then
			arg_176_0:setTableID(arg_176_0:afterAwakenID())
		end

		arg_176_0.level_ = 100
		arg_176_0.color_ = 16
		arg_176_0.star_ = math.max(arg_176_0.star_, 3)
	end
end

function xyd.formatRegionArenaHeros(arg_177_0)
	local var_177_0 = {
		100,
		100,
		80,
		60,
		0,
		0
	}
	local var_177_1 = {
		0,
		0,
		0,
		0,
		0,
		0
	}
	local var_177_2 = {
		0,
		0,
		0,
		0,
		0,
		0
	}
	local var_177_3 = {
		0,
		0,
		0,
		0,
		0,
		0
	}

	for iter_177_0, iter_177_1 in ipairs(arg_177_0) do
		if xyd.isSuperHero(iter_177_1) then
			var_177_0 = {
				100,
				100,
				80,
				60,
				0,
				0
			}
			var_177_1 = {
				0,
				0,
				0,
				0,
				0,
				0
			}
			var_177_2 = {
				0,
				0,
				0,
				0,
				0,
				0
			}
			var_177_3 = {
				31,
				31,
				31,
				31,
				31,
				31
			}

			xyd.renewSuperHeroInfo(iter_177_1, var_177_0, var_177_1, var_177_3, var_177_2)
		else
			xyd.renewHeroInfo(iter_177_1, var_177_0, var_177_1, var_177_3, var_177_2)
		end

		iter_177_1.inscriptItems_ = {}
	end
end

function xyd.formatRegionArenaHerosAwake(arg_178_0)
	local var_178_0 = {
		100,
		100,
		80,
		60,
		0,
		0
	}
	local var_178_1 = {
		0,
		1,
		1,
		1,
		1,
		1
	}
	local var_178_2 = {
		0,
		1,
		1,
		1,
		1,
		1
	}

	for iter_178_0, iter_178_1 in pairs(arg_178_0) do
		xyd.renewHeroInfoAwake(iter_178_1, var_178_0, var_178_1, var_178_2)

		iter_178_1.inscriptItems_ = {}
	end
end

function xyd.renewHeroInfoAwake(arg_179_0, arg_179_1, arg_179_2, arg_179_3)
	local var_179_0 = xyd.tables.misc.regionHeroColor
	local var_179_1 = xyd.tables.misc.regionHeroLevel

	if arg_179_0:isCanAwaken() and not arg_179_0:isAwaken() then
		arg_179_0:setTableID(arg_179_0:afterAwakenID())
	end

	if arg_179_0:isCanAwakeTwice() then
		arg_179_0.awakeTwiceStage_ = xyd.AwakeTwiceStage.COMPLETE
		arg_179_1 = {
			100,
			100,
			80,
			60,
			40,
			40
		}
	end

	arg_179_0.color_ = var_179_0
	arg_179_0.level_ = var_179_1
end

function xyd.formatRegionArenaPets(arg_180_0)
	local var_180_0 = {
		100,
		100,
		80,
		60,
		0
	}
	local var_180_1 = {
		0,
		0,
		0
	}

	for iter_180_0, iter_180_1 in pairs(arg_180_0) do
		xyd.renewPetInfo(iter_180_1, var_180_0, var_180_1)
	end
end

function xyd.formatRegionArenaPetsAwake(arg_181_0)
	local var_181_0 = {
		100,
		100,
		80,
		60,
		0
	}
	local var_181_1 = {
		0,
		1,
		1
	}

	for iter_181_0, iter_181_1 in pairs(arg_181_0) do
		xyd.renewPetInfoAwake(iter_181_1, var_181_0, var_181_1)
	end
end

function xyd.renewPetInfoAwake(arg_182_0, arg_182_1, arg_182_2)
	local var_182_0 = xyd.tables.misc.regionHeroColor
	local var_182_1 = xyd.tables.misc.regionHeroLevel

	if arg_182_0:isCanAwaken() and not arg_182_0:isAwaken() then
		arg_182_0:setTableID(arg_182_0:afterAwakenID())
	end

	arg_182_0.color_ = var_182_0
	arg_182_0.level_ = var_182_1
end

function xyd.renewHeroInfo(arg_183_0, arg_183_1, arg_183_2, arg_183_3, arg_183_4)
	local var_183_0 = xyd.tables.misc.regionHeroColor

	arg_183_0.level_, arg_183_0.color_ = xyd.tables.misc.regionHeroLevel, var_183_0
	arg_183_0.fumoLev_ = arg_183_4
end

function xyd.renewSuperHeroInfo(arg_184_0, arg_184_1, arg_184_2, arg_184_3, arg_184_4)
	arg_184_0.color_ = 1
	arg_184_0.fumoLev_ = arg_184_4
end

function xyd.renewPetInfo(arg_185_0, arg_185_1, arg_185_2)
	local var_185_0 = xyd.tables.misc.regionHeroColor

	arg_185_0.level_, arg_185_0.color_ = xyd.tables.misc.regionHeroLevel, var_185_0
end

function xyd.setItemAndAddTips(arg_186_0, arg_186_1, arg_186_2)
	local var_186_0 = arg_186_0:getContentSize().height
	local var_186_1 = display.newNode()

	var_186_1:setContentSize(var_186_0, var_186_0)

	local var_186_2 = xyd.tables.item:type(arg_186_1)

	xyd.setItemBorder(var_186_1, arg_186_1, nil, nil, arg_186_2)
	var_186_1:addTo(arg_186_0)
	var_186_1:setAnchorPoint(cc.p(0, 0))

	local var_186_3 = {
		id = arg_186_1,
		hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(arg_186_1)
	}

	xyd.addTips(var_186_1, var_186_3)
end

function xyd.setItemWithoutBg(arg_187_0, arg_187_1, arg_187_2)
	local var_187_0 = arg_187_0:getContentSize().height
	local var_187_1 = display.newNode()

	var_187_1:setContentSize(var_187_0, var_187_0)

	local var_187_2 = xyd.tables.item:type(arg_187_1)

	xyd.setItemBorder(var_187_1, arg_187_1, nil, nil, arg_187_2, nil, nil, nil, true)
	var_187_1:addTo(arg_187_0)
	var_187_1:setAnchorPoint(cc.p(0, 0))
end

function xyd.addTips(arg_188_0, arg_188_1)
	if not arg_188_0 then
		return
	end

	arg_188_0:setTouchEnabled(true)
	arg_188_0:setTouchSwallowEnabled(false)

	local var_188_0

	arg_188_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_189_0)
		if arg_189_0.name == "began" then
			var_188_0 = arg_189_0.y

			if not xyd.WindowManager.get():getWindow("new_item_tips") then
				local var_189_0 = xyd.WindowManager.get():openWindow("new_item_tips", arg_188_1)

				xyd.adaptToWorldPosition(arg_188_0, var_189_0)
			end

			return true
		elseif arg_189_0.name == "moved" then
			local var_189_1 = arg_189_0.y

			if math.abs(var_189_1 - var_188_0) > 30 then
				xyd.WindowManager.get():closeWindow("new_item_tips")
			end
		elseif arg_189_0.name == "ended" then
			xyd.WindowManager.get():closeWindow("new_item_tips")
		end
	end)
end

function xyd.addGiftTips(arg_190_0, arg_190_1, arg_190_2)
	if not arg_190_0 then
		return
	end

	arg_190_0:setTouchEnabled(true)
	arg_190_0:setTouchSwallowEnabled(false)

	local var_190_0
	local var_190_1 = arg_190_0:getContentSize()

	arg_190_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_191_0)
		if arg_191_0.name == "began" then
			var_190_0 = arg_191_0.y

			if not xyd.WindowManager.get():getWindow("gift_tips") then
				local var_191_0 = xyd.WindowManager.get():openWindow("gift_tips", arg_190_1)

				xyd.adaptToWorldPosition(arg_190_0, var_191_0)
			end

			return true
		elseif arg_191_0.name == "moved" then
			local var_191_1 = arg_191_0.y

			if math.abs(var_191_1 - var_190_0) > 30 then
				xyd.WindowManager.get():closeWindow("gift_tips")
			end
		elseif arg_191_0.name == "ended" then
			xyd.WindowManager.get():closeWindow("gift_tips")

			local var_191_2 = arg_190_0:convertToNodeSpace(cc.p(arg_191_0.x, arg_191_0.y))

			if var_191_2.x < 0 or var_191_2.x > var_190_1.width or var_191_2.y < 0 or var_191_2.y > var_190_1.height then
				return
			end

			if arg_190_2 then
				arg_190_2()
			end
		end
	end)
end

function xyd.showGuideWnd(arg_192_0, arg_192_1, arg_192_2, arg_192_3, arg_192_4, arg_192_5, arg_192_6)
	if GUIDE_WINDOW_NOT_SHOW then
		return
	end

	arg_192_4 = arg_192_4 or nil
	arg_192_5 = arg_192_5 or false

	local var_192_0 = arg_192_2 or arg_192_0:getContentSize()

	if xyd.WindowManager.get():isWindowOpen("sign_in") then
		xyd.WindowManager.get():closeWindow("sign_in")
	end

	if xyd.WindowManager.get():isWindowOpen("guide") then
		xyd.WindowManager.get():closeWindow("guide")
	end

	local var_192_1 = xyd.WindowManager.get():openWindow("guide")

	if not arg_192_1 then
		local var_192_2 = cc.p(arg_192_0:getPosition())
		local var_192_3 = arg_192_0:getAnchorPoint()
		local var_192_4 = var_192_2.x + var_192_0.width * (0.5 - var_192_3.x)
		local var_192_5 = var_192_2.y + var_192_0.height * (0.5 - var_192_3.y)

		arg_192_1 = var_192_1:convertToNodeSpace(arg_192_0:getParent():convertToWorldSpace(cc.p(var_192_4, var_192_5)))
	end

	var_192_1:addNode()
	var_192_1:setStencil(var_192_0.width, var_192_0.height, arg_192_1.x, arg_192_1.y, arg_192_3, {
		position = arg_192_4,
		right = arg_192_5,
		rect = arg_192_6
	})
end

function xyd.getMissionGoIDs(arg_193_0)
	local var_193_0 = xyd.tables.mission:goIDs(arg_193_0)
	local var_193_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	local var_193_2

	if type(var_193_0) == "table" then
		local var_193_3 = var_193_0[1]

		for iter_193_0 = 1, #var_193_0 do
			local var_193_4 = 0

			if var_193_1.worldMaps_[var_193_0[iter_193_0]] then
				var_193_4 = var_193_1.worldMaps_[var_193_0[iter_193_0]].star or 0
			end

			if var_193_3 <= var_193_0[iter_193_0] and var_193_4 == 3 then
				var_193_3 = var_193_0[iter_193_0]
			end
		end

		var_193_2 = var_193_3
	else
		var_193_2 = var_193_0
	end

	return var_193_2
end

function xyd.getStudentExp(arg_194_0, arg_194_1)
	local var_194_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	local var_194_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	local var_194_2 = arg_194_0
	local var_194_3 = 0

	if var_194_0.teacherInfo and type(var_194_0.teacherInfo.idInfo) == "table" and var_194_0.teacherInfo.idInfo.player_id and var_194_0.teacherInfo.intimacy and var_194_1.lev < 91 then
		local var_194_4 = 1

		for iter_194_0 = xyd.tables.teacherExp.maxId, 1, -1 do
			if var_194_0.teacherInfo.intimacy >= xyd.tables.teacherExp:relation(iter_194_0) then
				var_194_4 = xyd.tables.teacherExp:exp(iter_194_0)

				break
			end
		end

		var_194_2 = math.floor(var_194_1.exp) - math.floor(var_194_1.exp - arg_194_0 * (arg_194_1 + var_194_4 - 1))
		var_194_3 = arg_194_0 * (var_194_4 - 1)
	else
		var_194_2 = var_194_2 * arg_194_1
	end

	return var_194_2, var_194_3
end

function xyd.getLoopBy(arg_195_0, arg_195_1)
	local var_195_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	local var_195_1 = arg_195_1 or var_195_0.conquerLoopID

	if arg_195_0 == 56 then
		var_195_1 = math.max(1, var_195_1 - 1)
	end

	if arg_195_0 > 0 then
		var_195_1 = math.max(1, var_195_1)
	end

	return (math.min(xyd.tables.misc.conquerSchoolMaxLoop, var_195_1))
end

function xyd.setLev(arg_196_0, arg_196_1)
	arg_196_0:removeAllChildren()

	local var_196_0 = arg_196_0:getContentSize()
	local var_196_1 = 0
	local var_196_2
	local var_196_3
	local var_196_4
	local var_196_5

	if arg_196_1.conquerLev and arg_196_1.conquerLev > 0 then
		var_196_1 = xyd.getLoopBy(arg_196_1.conquerLev, arg_196_1.loopID)
		var_196_3 = arg_196_1.conquerLev
		var_196_2 = var_196_1 <= 1 and "images/conquer_lev.png" or "images/conquer_lev" .. var_196_1 .. ".png"
		var_196_4 = var_196_0.width / 2
		posY = var_196_0.height / 2 + 1
	else
		var_196_2 = "images/level_bg.png"
		var_196_3 = arg_196_1.lev
		var_196_4 = var_196_0.width / 2 - 1
		posY = var_196_0.height / 2 + 3
	end

	local var_196_6 = xyd.AssetLoader.get():loadSprite(var_196_2)

	var_196_6:setPosition(var_196_0.width / 2, var_196_0.height / 2)
	arg_196_0:addChild(var_196_6)

	local var_196_7 = {
		text = var_196_3,
		color = arg_196_1.fontColor or cc.c3b(0, 0, 0),
		size = arg_196_1.fontSize or 20
	}
	local var_196_8 = xyd.AssetLoader.get():loadLabel(var_196_7)

	var_196_8:setAnchorPoint(0.5, 0.5)

	if arg_196_1.outlineColor and arg_196_1.outlineSize then
		var_196_8:enableOutline(arg_196_1.outlineColor, arg_196_1.outlineSize)

		var_196_4 = var_196_4 + 1.5
	end

	if var_196_1 == 8 then
		posY = posY + 2
	end

	var_196_8:setPosition(var_196_4, posY)
	arg_196_0:addChild(var_196_8)
end

function xyd.setConquerLev(arg_197_0, arg_197_1, arg_197_2, arg_197_3, arg_197_4, arg_197_5, arg_197_6, arg_197_7)
	if not arg_197_0 or not arg_197_1 or not arg_197_2 then
		return
	end

	local var_197_0

	arg_197_6 = arg_197_6 or "conquer_lev_bg"

	local var_197_1 = xyd.getLoopBy(arg_197_0, arg_197_7)

	if arg_197_2:getParent():getChildByName(arg_197_6) then
		arg_197_2:getParent():getChildByName(arg_197_6):setVisible(false)
	end

	if var_197_1 <= 1 then
		var_197_0 = xyd.AssetLoader.get():loadSprite("images/conquer_lev.png")
	else
		var_197_0 = xyd.AssetLoader.get():loadSprite("images/conquer_lev" .. var_197_1 .. ".png")
	end

	var_197_0:addTo(arg_197_2:getParent())

	local var_197_2 = cc.p(arg_197_2:getPosition())

	var_197_0:setName(arg_197_6)
	var_197_0:setAnchorPoint(cc.p(0.5, 0.5))

	if arg_197_3 then
		var_197_0:setPosition(cc.p(var_197_2.x + arg_197_3.x, var_197_2.y + arg_197_3.y))
	else
		var_197_0:setPosition(cc.p(var_197_2))
	end

	arg_197_2:setVisible(false)
	arg_197_1:setVisible(true)
	var_197_0:setLocalZOrder(9)
	arg_197_1:setLocalZOrder(10)
	arg_197_1:setString(arg_197_0)

	if arg_197_4 then
		arg_197_1:setPosition(cc.p(var_197_2.x + arg_197_3.x, var_197_2.y + arg_197_3.y))
	end

	if arg_197_5 and arg_197_5 > 0 then
		var_197_0:setScale(arg_197_5)
	end
end

function xyd.setPlayerAvatarTouch(arg_198_0, arg_198_1, arg_198_2)
	local var_198_0 = display.newNode()

	var_198_0:addTo(arg_198_0)
	var_198_0:setContentSize(arg_198_2.width, arg_198_2.height)
	var_198_0:setTouchSwallowEnabled(false)
	var_198_0:setTouchEnabled(true)

	local var_198_1
	local var_198_2
	local var_198_3 = 5

	var_198_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_199_0)
		if arg_199_0.name == "began" then
			var_198_1 = arg_199_0.prevX
			var_198_2 = arg_199_0.prevY

			return true
		elseif arg_199_0.name == "ended" then
			if math.abs(arg_199_0.x - var_198_1) > var_198_3 or math.abs(arg_199_0.y - var_198_2) > var_198_3 then
				return
			end

			xyd.openPersonDisplayWindow(arg_198_1)
		end
	end)
end

function xyd.openPersonDisplayWindow(arg_200_0)
	local var_200_0 = {
		to_player_id = arg_200_0.player_id,
		sub_type = xyd.PlayerCardButtonStyle.MAIN,
		isRobot = xyd.checkPlayerIsRobot(arg_200_0.player_id),
		player_info = arg_200_0
	}
	local var_200_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.PERSON_DISPLAY)

	if var_200_1:checkCanTouch() then
		var_200_1:getPlayerInfo(var_200_0, function(arg_201_0, arg_201_1)
			if arg_201_0 == xyd.error.OK then
				var_200_1:updateTouchCount(true)

				if xyd.WindowManager.get():isWindowOpen("person_praise") then
					xyd.WindowManager.get():closeWindow("person_praise")
				end

				if xyd.WindowManager.get():isWindowOpen("person_display") then
					xyd.WindowManager.get():closeWindow("person_display")
				end

				xyd.WindowManager.get():openWindow("person_display")
			end
		end, true)
	else
		xyd.WindowManager.get():openWindow("toast", {
			message = xyd.tables.translation:translation("PERSON_NOT_TOUCH_MORE")
		})
	end
end

function xyd.playerAvatarTouchEvent(arg_202_0)
	local var_202_0 = {
		to_player_id = arg_202_0.player_id,
		sub_type = xyd.PlayerCardButtonStyle.MAIN,
		isRobot = xyd.checkPlayerIsRobot(arg_202_0.player_id),
		player_info = arg_202_0
	}
	local var_202_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.PERSON_DISPLAY)
	local var_202_2 = xyd.ModelManager.get():loadModel(xyd.ModelType.MESSAGE_MANAGER)

	if var_202_1:checkCanTouch() then
		var_202_1:getPlayerInfo(var_202_0, function(arg_203_0, arg_203_1)
			if arg_203_0 == xyd.error.OK then
				var_202_1:updateTouchCount(true)

				if xyd.WindowManager.get():isWindowOpen("person_display") then
					xyd.WindowManager.get():closeWindow("person_display")
				end

				xyd.WindowManager.get():openWindow("person_display")

				if var_202_2.loadOnce then
					var_202_2.loadOnce = false
				end
			end
		end, true)
	else
		if var_202_2.loadOnce then
			var_202_2.loadOnce = false
		end

		xyd.WindowManager.get():openWindow("toast", {
			message = xyd.tables.translation:translation("PERSON_NOT_TOUCH_MORE")
		})
	end
end

function xyd.checkPlayerIsRobot(arg_204_0)
	if not arg_204_0 then
		return false
	end

	local var_204_0 = arg_204_0

	if arg_204_0 > 100000 then
		var_204_0 = var_204_0 - math.floor(arg_204_0 / 100000) * 100000
	end

	if var_204_0 < 25000 then
		return true
	end

	return false
end

function xyd.num2ThousandsStr(arg_205_0)
	local var_205_0 = ""

	if arg_205_0 < 0 then
		arg_205_0 = -arg_205_0
		var_205_0 = "-"
	end

	local var_205_1 = {}
	local var_205_2 = 1

	while arg_205_0 >= 1000 do
		var_205_1[var_205_2] = arg_205_0 % 1000
		arg_205_0 = math.floor(arg_205_0 / 1000)
		var_205_2 = var_205_2 + 1
	end

	var_205_1[var_205_2] = arg_205_0 % 1000

	for iter_205_0 = #var_205_1, 1, -1 do
		if iter_205_0 ~= #var_205_1 then
			if var_205_1[iter_205_0] < 100 then
				var_205_0 = var_205_0 .. "0"
			end

			if var_205_1[iter_205_0] < 10 then
				var_205_0 = var_205_0 .. "0"
			end
		end

		var_205_0 = var_205_0 .. var_205_1[iter_205_0]

		if iter_205_0 ~= 1 then
			var_205_0 = var_205_0 .. ","
		end
	end

	return var_205_0
end

function xyd.isInTable(arg_206_0, arg_206_1)
	if not arg_206_0 then
		return false
	end

	for iter_206_0, iter_206_1 in pairs(arg_206_0) do
		if iter_206_1 == arg_206_1 then
			return true
		end
	end

	return false
end

function xyd.getKeyByValue(arg_207_0, arg_207_1)
	if not arg_207_0 then
		return
	end

	for iter_207_0, iter_207_1 in pairs(arg_207_0) do
		if iter_207_1 == arg_207_1 then
			return iter_207_0
		end
	end
end

function xyd.navigateToHeroGetWay(arg_208_0)
	local var_208_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	local var_208_1 = xyd.tables.heroGetWayTable
	local var_208_2 = xyd.tables.translation
	local var_208_3 = var_208_1:getFuncId(arg_208_0)

	if var_208_3 and var_208_0:isFuncOpen(var_208_3) ~= true then
		if xyd.WindowManager.get():isWindowOpen("toast") then
			xyd.WindowManager.get():closeWindow("toast")
		end

		xyd.WindowManager.get():openWindow("toast", {
			message = var_208_2:translation("FUNCTION_OPEN_TIP_OTHER")
		})

		return
	end

	if var_208_1:getWindow(arg_208_0) == "shop" then
		xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP):loadShopList({}, function()
			xyd.WindowManager.get():openWindow("shop", {
				shop_type = var_208_1:shopType(arg_208_0)
			})
		end)
	elseif var_208_1:getWindow(arg_208_0) == "treasure_window" then
		xyd.ModelManager.get():loadModel(xyd.ModelType.TREASURE):loadTreasureInfo(function(arg_210_0, arg_210_1)
			if arg_210_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("treasure_window")
			end
		end)
	elseif var_208_1:getWindow(arg_208_0) == "pet_campaign" then
		xyd.ModelManager.get():loadModel(xyd.ModelType.PET_COMPAIGN):getCampaignInfo(function(arg_211_0)
			if arg_211_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("pet_campaign")
			end
		end)
	elseif var_208_1:getWindow(arg_208_0) == "march" then
		local var_208_4 = xyd.ModelManager.get():loadModel(xyd.ModelType.MARCH)

		if var_208_4.mapInfo == nil then
			var_208_4:loadMarchInfo({}, function(arg_212_0)
				if arg_212_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("march")
				end
			end)
		else
			xyd.WindowManager.get():openWindow("march")
		end
	elseif var_208_1:getWindow(arg_208_0) == "summon" then
		var_208_0:loadSummonInfo(nil, function()
			xyd.WindowManager.get():openWindow("summon")

			if xyd.StoryData.get():getGuideID() <= xyd.GuideStoryType.GUIDE_SUMMON_FREE_TWO then
				var_208_0:sendOperationLog(xyd.StatID.ID_CLICK_SUMMON)
			end
		end, true)
	elseif var_208_1:getWindow(arg_208_0) == "occult" then
		xyd.ModelManager.get():loadModel(xyd.ModelType.OCCULT):openOccultWindow()
	elseif var_208_1:getWindow(arg_208_0) == "conquer_school" then
		xyd.ModelManager.get():loadModel(xyd.ModelType.CONQUER_SCHOOL):loadConquerSchoolInfo(function(arg_214_0)
			if arg_214_0 then
				xyd.WindowManager.get():openWindow("conquer_school", response)
			end
		end, true)
	elseif var_208_1:getWindow(arg_208_0) == "super_partner" then
		if xyd.WindowManager.get():isWindowOpen("super_partner") then
			xyd.WindowManager.get():closeWindow("super_partner")
		end

		xyd.WindowManager.get():openWindow("super_partner")
	elseif var_208_1:getWindow(arg_208_0) ~= "" then
		xyd.WindowManager.get():openWindow(var_208_1:getWindow(arg_208_0))
	else
		xyd.WindowManager.get():openWindow("toast", {
			message = xyd.tables.translation:translation("GET_WAY_NOT_OPEN_TIP")
		})
	end
end

function xyd.getTreasureItem(arg_215_0, arg_215_1)
	local var_215_0 = xyd.tables.misc
	local var_215_1 = {}

	if arg_215_0 == xyd.TreasureProductType.MANA then
		var_215_1.item_id = -2
		var_215_1.item_num = arg_215_1
	elseif arg_215_0 == xyd.TreasureProductType.DRINK then
		var_215_1.item_id = -5
		var_215_1.item_num = math.floor(arg_215_1 * var_215_0.treasureExpParam)
	elseif arg_215_0 == xyd.TreasureProductType.STONE then
		var_215_1.item_id = -4
		var_215_1.item_num = math.floor(arg_215_1 * var_215_0.treasureScrollParam)
	elseif arg_215_0 == xyd.TreasureProductType.DUST then
		var_215_1.item_id = -11
		var_215_1.item_num = math.floor(arg_215_1 * var_215_0.treasureMagicDustParam)
	elseif arg_215_0 == xyd.TreasureProductType.LIQUID then
		var_215_1.item_id = -12
		var_215_1.item_num = math.floor(arg_215_1 * var_215_0.treasureMagicLiquidParam)
	elseif arg_215_0 == xyd.TreasureProductType.GLUE then
		var_215_1.item_id = var_215_0.eventCentreAccelerateItem
		var_215_1.item_num = math.floor(arg_215_1 * var_215_0.treasureGlueParam)
	elseif arg_215_0 == xyd.TreasureProductType.RED_STAR then
		var_215_1.item_id = var_215_0.treasureInscriptItem1
		var_215_1.item_num = math.floor(arg_215_1 * var_215_0.treasureInscriptParam)
	elseif arg_215_0 == xyd.TreasureProductType.BLUE_STAR then
		var_215_1.item_id = var_215_0.treasureInscriptItem2
		var_215_1.item_num = math.floor(arg_215_1 * var_215_0.treasureInscriptParam)
	elseif arg_215_0 == xyd.TreasureProductType.GREEN_STAR then
		var_215_1.item_id = var_215_0.treasureInscriptItem3
		var_215_1.item_num = math.floor(arg_215_1 * var_215_0.treasureInscriptParam)
	end

	return var_215_1
end

function xyd.getFormationStr(arg_216_0)
	local var_216_0 = ""

	for iter_216_0, iter_216_1 in ipairs(arg_216_0) do
		var_216_0 = var_216_0 .. string.format("%d", iter_216_1:getHeroID())

		if iter_216_0 < #arg_216_0 then
			var_216_0 = var_216_0 .. "|"
		end
	end

	return var_216_0
end

function xyd.setPlayerInfoContainer(arg_217_0, arg_217_1)
	xyd.setPlayerAvatar(arg_217_0:getChildByName("avtar_container"), arg_217_1)

	if arg_217_1.conquer_lev > 0 then
		arg_217_0:getChildByName("conquer_lev"):setVisible(true)
		arg_217_0:getChildByName("level_bg"):setVisible(false)
		arg_217_0:getChildByName("lev_txt"):setString(arg_217_1.conquer_lev)

		local var_217_0 = xyd.getLoopBy(arg_217_1.conquer_lev, arg_217_1.conquer_loop_id)

		if var_217_0 < 2 then
			var_217_0 = ""
		end

		arg_217_0:getChildByName("conquer_lev"):setTexture("images/conquer_lev" .. var_217_0 .. ".png")
	else
		arg_217_0:getChildByName("conquer_lev"):setVisible(false)
		arg_217_0:getChildByName("level_bg"):setVisible(true)
		arg_217_0:getChildByName("lev_txt"):setString(arg_217_1.lev)
	end

	arg_217_0:getChildByName("name_txt"):setString(arg_217_1.player_name)
end

function xyd.createEffect(arg_218_0, arg_218_1)
	local var_218_0 = import("app.common.ui.SpineEffect")
	local var_218_1 = arg_218_0 .. ".json"
	local var_218_2 = arg_218_0 .. ".atlas"
	local var_218_3 = var_218_0.new(var_218_1, var_218_2, arg_218_1 or 1)

	var_218_3:setAnchorPoint(cc.p(0.5, 0.5))

	return var_218_3
end

function xyd.reverseTable(arg_219_0)
	local var_219_0 = {}

	for iter_219_0 = #arg_219_0, 1, -1 do
		table.insert(var_219_0, arg_219_0[iter_219_0])
	end

	return var_219_0
end

function xyd.mergeTable(arg_220_0, arg_220_1, arg_220_2)
	local var_220_0

	if arg_220_2 then
		var_220_0 = arg_220_0
	else
		var_220_0 = clone(arg_220_0)
	end

	for iter_220_0 = 1, #arg_220_1 do
		table.insert(var_220_0, arg_220_1[iter_220_0])
	end

	return var_220_0
end

function xyd.joinTable(arg_221_0, arg_221_1)
	local var_221_0

	for iter_221_0 = 1, #arg_221_0 do
		if not var_221_0 then
			var_221_0 = tostring(arg_221_0[iter_221_0])
		else
			var_221_0 = var_221_0 .. arg_221_1 .. tostring(arg_221_0[iter_221_0])
		end
	end

	return var_221_0 or ""
end

function xyd.removeByValues(arg_222_0, arg_222_1)
	local var_222_0 = {}

	for iter_222_0 = 1, #arg_222_0 do
		if not xyd.isInTable(arg_222_1, arg_222_0[iter_222_0]) then
			table.insert(var_222_0, arg_222_0[iter_222_0])
		end
	end

	return var_222_0
end

function xyd.closeWindows(arg_223_0)
	local var_223_0 = xyd.WindowManager.get()

	for iter_223_0, iter_223_1 in pairs(arg_223_0) do
		var_223_0:closeWindow(iter_223_1)
	end
end

function xyd.addPosition(arg_224_0, arg_224_1)
	return cc.p(arg_224_0.x + arg_224_1.x, arg_224_0.y + arg_224_1.y)
end

function xyd.subPosition(arg_225_0, arg_225_1)
	return cc.p(arg_225_0.x - arg_225_1.x, arg_225_0.y - arg_225_1.y)
end

function xyd.getPositionLen(arg_226_0)
	return math.sqrt(arg_226_0.x * arg_226_0.x + arg_226_0.y * arg_226_0.y)
end

function xyd.mulPosition(arg_227_0, arg_227_1)
	return cc.p(arg_227_0.x * arg_227_1, arg_227_0.y * arg_227_1)
end

function xyd.findValue(arg_228_0, arg_228_1)
	for iter_228_0 = 1, #arg_228_0 do
		if arg_228_1 <= arg_228_0[iter_228_0] then
			return iter_228_0
		end
	end
end

function xyd.convertWorldPos(arg_229_0, arg_229_1)
	local var_229_0 = cc.Director:getInstance():getVisibleSize()

	if var_229_0.width > xyd.STAGE_WIDTH then
		arg_229_0 = arg_229_0 - (var_229_0.width - xyd.STAGE_WIDTH) / 2
	elseif var_229_0.height > xyd.STAGE_HEIGHT then
		arg_229_1 = arg_229_1 - (var_229_0.height - xyd.STAGE_HEIGHT) / 2
	end

	return arg_229_0, arg_229_1
end

function xyd.convertNodePos(arg_230_0, arg_230_1)
	local var_230_0 = cc.Director:getInstance():getVisibleSize()

	if var_230_0.width > xyd.STAGE_WIDTH then
		arg_230_0 = arg_230_0 + (var_230_0.width - xyd.STAGE_WIDTH) / 2
	elseif var_230_0.height > xyd.STAGE_HEIGHT then
		arg_230_1 = arg_230_1 + (var_230_0.height - xyd.STAGE_HEIGHT) / 2
	end

	return arg_230_0, arg_230_1
end

function xyd.imgEvent(arg_231_0, arg_231_1)
	local var_231_0
	local var_231_1
	local var_231_2

	arg_231_0:setTouchEnabled(true)
	arg_231_0:setTouchSwallowEnabled(true)

	local var_231_3 = arg_231_0:getScale()

	arg_231_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_232_0)
		if arg_232_0.name == "began" then
			arg_231_0:setScale(0.9 * var_231_3)

			var_231_0 = arg_232_0.x
			var_231_1 = arg_232_0.y
			var_231_2 = false
		elseif arg_232_0.name == "moved" then
			local var_232_0 = 10

			if var_232_0 < math.abs(arg_232_0.x - var_231_0) or var_232_0 < math.abs(arg_232_0.y - var_231_1) then
				arg_231_0:setScale(var_231_3)

				var_231_2 = true
			end
		elseif arg_232_0.name == "ended" and not var_231_2 then
			arg_231_0:setScale(var_231_3)

			if arg_231_1 then
				arg_231_1()
			end
		end

		return true
	end)
end

function xyd.fbShare(arg_233_0, arg_233_1, arg_233_2, arg_233_3, arg_233_4)
	local var_233_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if device.platform == "android" then
		local function var_233_1(arg_234_0)
			dump(arg_234_0)
		end

		local var_233_2 = "org/cocos2dx/lua/AppActivity"
		local var_233_3 = "fbShare"
		local var_233_4 = {
			var_233_1,
			arg_233_2,
			arg_233_3,
			arg_233_1,
			arg_233_4,
			tostring(var_233_0.playerID),
			arg_233_0
		}
		local var_233_5 = "(ILjava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"
		local var_233_6, var_233_7 = luaj.callStaticMethod(var_233_2, var_233_3, var_233_4, var_233_5)
	elseif device.platform == "ios" then
		local var_233_8 = {
			player_id = tostring(var_233_0.playerID),
			type = arg_233_0,
			link = arg_233_3,
			imgurl = arg_233_4,
			title = arg_233_1,
			desc = arg_233_2
		}

		luaoc.callStaticMethod("SdkIOS", "startFBShareWithPlayerID", var_233_8)
	end
end

function xyd.buttonLongTouch(arg_235_0, arg_235_1, arg_235_2)
	local var_235_0 = require("framework.scheduler")
	local var_235_1
	local var_235_2 = false

	arg_235_0:addTouchEventListener(function(arg_236_0, arg_236_1)
		if arg_236_1 == ccui.TouchEventType.began then
			local var_236_0 = 0

			local function var_236_1()
				var_236_0 = var_236_0 + 0.1

				if var_236_0 > 0.5 then
					var_235_2 = true

					if arg_235_1 then
						arg_235_1(var_235_1)
					end
				else
					var_235_2 = false
				end
			end

			var_235_2 = false
			var_235_1 = var_235_0.scheduleGlobal(var_236_1, 0.1)
		elseif arg_236_1 == ccui.TouchEventType.ended or arg_236_1 == ccui.TouchEventType.canceled then
			if var_235_1 then
				var_235_0.unscheduleGlobal(var_235_1)

				var_235_1 = nil
			end

			if not var_235_2 and arg_235_2 then
				arg_235_2()
			end
		end
	end)
end

function xyd.fbShare(arg_238_0, arg_238_1, arg_238_2, arg_238_3, arg_238_4)
	local var_238_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if device.platform == "android" then
		local function var_238_1(arg_239_0)
			return
		end

		local var_238_2 = "org/cocos2dx/lua/AppActivity"
		local var_238_3 = "fbShare"
		local var_238_4 = {
			var_238_1,
			arg_238_2,
			arg_238_3,
			arg_238_1,
			arg_238_4
		}
		local var_238_5 = "(ILjava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"
		local var_238_6, var_238_7 = luaj.callStaticMethod(var_238_2, var_238_3, var_238_4, var_238_5)
	elseif device.platform == "ios" then
		local var_238_8 = {
			player_id = tostring(var_238_0.playerID),
			type = arg_238_0,
			link = arg_238_3,
			imgurl = arg_238_4,
			title = arg_238_1,
			desc = arg_238_2
		}

		luaoc.callStaticMethod("SdkIOS", "startFBShareWithPlayerID", var_238_8)
	end
end

function xyd.GrayNode(arg_240_0, arg_240_1)
	if not arg_240_1 then
		local var_240_0 = cc.GLProgram:createWithByteArrays(xyd.shader.NO_MVP_VERT_STRING, xyd.shader.GRAY_FRAG_STRING)

		arg_240_1 = cc.GLProgramState:create(var_240_0)
	end

	arg_240_0:setGLProgramState(arg_240_1)

	for iter_240_0, iter_240_1 in pairs(arg_240_0:getChildren()) do
		if iter_240_1:isVisible() then
			xyd.GrayNode(iter_240_1, arg_240_1)
		end
	end
end

function xyd.unGrayNode(arg_241_0, arg_241_1)
	if not arg_241_1 then
		local var_241_0 = cc.GLProgram:createWithByteArrays(xyd.shader.NO_MVP_VERT_STRING, xyd.shader.NO_MVP_FRAG_STRING)

		arg_241_1 = cc.GLProgramState:create(var_241_0)
	end

	arg_241_0:setGLProgramState(arg_241_1)

	for iter_241_0, iter_241_1 in pairs(arg_241_0:getChildren()) do
		if iter_241_1:isVisible() then
			xyd.GrayNode(iter_241_1, arg_241_1)
		end
	end
end

function xyd.splitTextByLen(arg_242_0, arg_242_1)
	local var_242_0 = {}
	local var_242_1
	local var_242_2

	while var_242_2 do
		local var_242_3

		var_242_3, var_242_2 = xyd.getSplitByTextLen(var_242_2, arg_242_1)

		if var_242_3 then
			table.insert(var_242_0, var_242_3)
		end
	end
end

function xyd.getDistance(arg_243_0, arg_243_1)
	return math.sqrt(math.pow(arg_243_0.x - arg_243_1.x, 2), math.pow(arg_243_0.y - arg_243_1.y, 2))
end

function xyd.isMapWindowCampaignType(arg_244_0)
	if arg_244_0 == xyd.CampaignType.NORMAL or arg_244_0 == xyd.CampaignType.SUPER or arg_244_0 == xyd.CampaignType.GUILD or arg_244_0 == xyd.CampaignType.CHALLENGE then
		return true
	end

	return false
end

function xyd.getColorlabel(arg_245_0, arg_245_1)
	local var_245_0 = clone(arg_245_0)
	local var_245_1 = cc.c3b(255, 255, 255)

	var_245_0.color = var_245_1

	if arg_245_0.color then
		var_245_1 = arg_245_0.color
	end

	local var_245_2 = xyd.AssetLoader.get():loadLabel(var_245_0)
	local var_245_3 = clone(arg_245_1)
	local var_245_4, var_245_5 = string.find(var_245_3, "{#%w*#.+}")

	local function var_245_6(arg_246_0)
		if string.len(arg_246_0) ~= 6 then
			print("Wrong color params.")

			return
		end

		return cc.c3b(tonumber(string.sub(arg_246_0, 1, 2), 16), tonumber(string.sub(arg_246_0, 3, 4), 16), tonumber(string.sub(arg_246_0, 5, 6), 16))
	end

	local function var_245_7(arg_247_0)
		if string.sub(arg_247_0, 1, 1) == "#" then
			local var_247_0 = string.find(arg_247_0, "#", 2)
			local var_247_1 = string.sub(arg_247_0, 2, var_247_0 - 1)

			return var_245_6(var_247_1), var_247_0
		else
			return var_245_1, 0
		end
	end

	if not var_245_4 or not var_245_5 then
		var_245_2:setString(var_245_3)
		var_245_2:setColor(var_245_1)
	else
		local var_245_8 = {}
		local var_245_9 = {}
		local var_245_10 = 1
		local var_245_11 = ""
		local var_245_12 = 1
		local var_245_13 = string.len(var_245_3)

		for iter_245_0 = 1, var_245_13 do
			local var_245_14 = string.sub(var_245_3, iter_245_0, iter_245_0)

			if var_245_14 == "{" then
				if iter_245_0 > 1 then
					local var_245_15 = string.sub(var_245_3, var_245_10, iter_245_0 - 1)
					local var_245_16 = #var_245_9 > 0 and var_245_9[#var_245_9] or var_245_1
					local var_245_17 = var_245_12 + xyd.utf8len(var_245_15) - 1

					table.insert(var_245_8, {
						color = var_245_16,
						began = var_245_12,
						ended = var_245_17
					})

					var_245_11 = var_245_11 .. var_245_15
					var_245_12 = var_245_17 + 1
				end

				local var_245_18, var_245_19 = var_245_7(string.sub(var_245_3, iter_245_0 + 1))

				table.insert(var_245_9, var_245_18)

				var_245_10 = iter_245_0 + var_245_19 + 1
			elseif var_245_14 == "}" then
				local var_245_20 = string.sub(var_245_3, var_245_10, iter_245_0 - 1)
				local var_245_21 = var_245_1

				if #var_245_9 > 0 then
					var_245_21 = var_245_9[#var_245_9]

					table.remove(var_245_9, #var_245_9)
				end

				local var_245_22 = var_245_12 + xyd.utf8len(var_245_20) - 1

				table.insert(var_245_8, {
					color = var_245_21,
					began = var_245_12,
					ended = var_245_22
				})

				var_245_11 = var_245_11 .. var_245_20
				var_245_10 = iter_245_0 + 1
				var_245_12 = var_245_22 + 1
			elseif iter_245_0 == var_245_13 then
				local var_245_23 = string.sub(var_245_3, var_245_10, iter_245_0)
				local var_245_24 = var_245_1

				if #var_245_9 > 0 then
					var_245_24 = var_245_9[#var_245_9]

					table.remove(var_245_9, #var_245_9)
				end

				local var_245_25 = var_245_12 + xyd.utf8len(var_245_23) - 1

				table.insert(var_245_8, {
					color = var_245_24,
					began = var_245_12,
					ended = var_245_25
				})

				var_245_11 = var_245_11 .. var_245_23
				var_245_10 = iter_245_0 + 1
				var_245_12 = var_245_25 + 1
			end
		end

		var_245_2:setString(var_245_11)

		local var_245_26 = 0

		for iter_245_1, iter_245_2 in ipairs(var_245_8) do
			for iter_245_3 = iter_245_2.began, iter_245_2.ended do
				if not var_245_2:getLetter(var_245_26 + iter_245_3 - 1) then
					var_245_26 = var_245_26 + 1
				end

				var_245_2:getLetter(var_245_26 + iter_245_3 - 1):setColor(iter_245_2.color)
			end
		end
	end

	return var_245_2
end

function xyd.newLive2d(arg_248_0, arg_248_1, arg_248_2, arg_248_3, arg_248_4)
	if not arg_248_0 or not arg_248_1 or tolua.isnull(arg_248_0) then
		return
	end

	local var_248_0 = arg_248_2 or 1
	local var_248_1 = arg_248_3 or 1
	local var_248_2 = arg_248_4 or cc.p(xyd.STAGE_WIDTH / 2, xyd.STAGE_HEIGHT / 2)
	local var_248_3 = xyd.LAppView:createDrawNode(arg_248_1)

	var_248_3:addTo(arg_248_0)
	var_248_3:changePosition(var_248_2.x, var_248_2.y)
	var_248_3:changeScale(var_248_0, var_248_1)

	return var_248_3
end

function xyd.isLive2dCanUse()
	return false
end

function xyd.randomlySelectElement(arg_250_0)
	return arg_250_0[math.random(1, #arg_250_0)]
end

function xyd.getFilteredHeros(arg_251_0, arg_251_1)
	local var_251_0 = {}

	arg_251_1 = arg_251_1 or xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER).sortType

	local var_251_1 = {
		0,
		0,
		0
	}
	local var_251_2 = {
		0,
		0,
		0
	}
	local var_251_3 = {
		0,
		0,
		0,
		0
	}
	local var_251_4 = {
		0,
		0,
		0
	}

	if arg_251_1 and arg_251_1 > 0 then
		local var_251_5 = {}
		local var_251_6 = 1

		while arg_251_1 > 0 do
			var_251_5[var_251_6] = arg_251_1 % 2
			var_251_6 = var_251_6 + 1
			arg_251_1 = math.floor(arg_251_1 / 2)
		end

		local var_251_7 = 1

		for iter_251_0 = 13, 1, -1 do
			if iter_251_0 <= 4 then
				if iter_251_0 == 4 then
					var_251_7 = 1
				end

				var_251_3[var_251_7] = var_251_5[iter_251_0]
			elseif iter_251_0 <= 7 then
				if iter_251_0 == 7 then
					var_251_7 = 1
				end

				var_251_2[var_251_7] = var_251_5[iter_251_0]
			elseif iter_251_0 <= 10 then
				if iter_251_0 == 10 then
					var_251_7 = 1
				end

				var_251_1[var_251_7] = var_251_5[iter_251_0]
			elseif iter_251_0 <= 13 then
				if iter_251_0 == 13 then
					var_251_7 = 1
				end

				if var_251_5[iter_251_0] then
					var_251_4[var_251_7] = var_251_5[iter_251_0]
				end
			end

			var_251_7 = var_251_7 + 1
		end
	else
		var_251_1 = {
			1,
			1,
			1
		}
		var_251_2 = {
			1,
			1,
			1
		}
		var_251_3 = {
			1,
			1,
			1,
			1
		}
		var_251_4 = {
			1,
			1,
			1
		}
	end

	for iter_251_1, iter_251_2 in pairs(arg_251_0) do
		if var_251_1[iter_251_2:getDistanceType() - 1] == 1 and var_251_2[iter_251_2:getHeroType()] == 1 and var_251_3[iter_251_2:getFromType()] == 1 and var_251_4[iter_251_2:getAwakenType()] == 1 then
			table.insert(var_251_0, iter_251_2)
		end
	end

	return var_251_0
end

function xyd.createLabel(arg_252_0, arg_252_1)
	local var_252_0 = {
		color = arg_252_1 or cc.c3b(255, 255, 255),
		size = arg_252_0 or 24
	}
	local var_252_1 = xyd.AssetLoader.get():loadLabel(var_252_0)

	var_252_1:setAnchorPoint(cc.p(0, 0.5))

	return var_252_1
end

function xyd.searchHeroByName(arg_253_0, arg_253_1)
	if not arg_253_0 or arg_253_0 == "" then
		return true
	end

	arg_253_0 = string.lower(arg_253_0)

	local var_253_0 = arg_253_1:getSearchName() or {
		arg_253_1:getName()
	}

	for iter_253_0, iter_253_1 in pairs(var_253_0) do
		if string.match(string.lower(iter_253_1), arg_253_0) then
			return true
		end
	end

	return false
end

function xyd.shuffle(arg_254_0)
	local var_254_0 = clone(arg_254_0)
	local var_254_1 = {}

	while var_254_0 and next(var_254_0) do
		local var_254_2 = math.random(#var_254_0)

		table.insert(var_254_1, var_254_0[var_254_2])
		table.remove(var_254_0, var_254_2)
	end

	return var_254_1
end

function xyd.getVipLev(arg_255_0)
	local var_255_0 = xyd.tables.vip
	local var_255_1 = 0
	local var_255_2 = 0

	if not arg_255_0 then
		return 0
	end

	while var_255_2 < arg_255_0 and var_255_1 < 15 do
		var_255_2 = var_255_0:chargeReq(var_255_1 + 1)

		if var_255_2 <= arg_255_0 then
			var_255_1 = var_255_1 + 1
		end
	end

	return var_255_1
end

function xyd.getItemDesc(arg_256_0)
	local var_256_0 = {
		10,
		30,
		80
	}
	local var_256_1 = ""
	local var_256_2 = xyd.tables.item:desc1(arg_256_0)
	local var_256_3 = xyd.tables.item:desc2(arg_256_0)

	if var_256_2 ~= "" then
		return var_256_2
	elseif var_256_3 ~= "" then
		return var_256_3
	end

	local var_256_4 = xyd.tables.item:type(arg_256_0)

	if var_256_4 == xyd.ItemType.EQUIPMENT or var_256_4 == xyd.ItemType.PET_EQUIP then
		local var_256_5 = xyd.tables.item:attrs(arg_256_0)
		local var_256_6 = {}

		for iter_256_0, iter_256_1 in pairs(var_256_5) do
			local var_256_7 = {
				name = xyd.tables.attr:name(iter_256_0),
				value = iter_256_1
			}

			table.insert(var_256_6, var_256_7)
		end

		local var_256_8 = ""

		for iter_256_2 = 1, #var_256_6 do
			var_256_8 = var_256_8 .. var_256_6[iter_256_2].name .. "+" .. var_256_6[iter_256_2].value .. "\n"
		end

		var_256_1 = var_256_8
	elseif var_256_4 == xyd.ItemType.STONE then
		local var_256_9 = xyd.tables.item:heroID(arg_256_0)
		local var_256_10 = xyd.tables.hero:name(var_256_9)
		local var_256_11 = var_256_0[xyd.tables.hero:initialStar(var_256_9)]
		local var_256_12

		if xyd.isSuperHero(var_256_9) then
			var_256_12 = string.format(xyd.tables.translation:translation("BACKPACK_SUPER_STONE_DESC"), var_256_10)
		else
			var_256_12 = string.format(xyd.tables.translation:translation("BACKPACK_STONE_DESC"), var_256_11, var_256_10, var_256_10)
		end

		local var_256_13 = {}

		if var_256_3 and var_256_3 ~= "" then
			var_256_13 = var_256_12 .. "\n" .. "\n" .. var_256_3
		else
			var_256_13 = var_256_12
		end

		var_256_1 = var_256_13
	elseif var_256_4 == xyd.ItemType.EQUIPMENT_FRAGMENT or var_256_4 == xyd.ItemType.REEL_FRAGMENT or var_256_4 == xyd.ItemType.BOOK_FRAGMENT then
		local var_256_14 = xyd.tables.item:itemNum(arg_256_0)
		local var_256_15 = xyd.tables.item:composeItem(arg_256_0)
		local var_256_16 = xyd.tables.item:name(var_256_15)

		var_256_1 = string.format(stringLocalizer:translation("FRAGMENT_DESC1"), var_256_14, var_256_16)
	elseif var_256_4 == xyd.ItemType.BOOK then
		var_256_1 = stringLocalizer:translation("EFFECT_HERO") .. stringLocalizer:translation("COLON")
	end

	return var_256_1
end

function xyd.pushBattleScene(arg_257_0)
	local function var_257_0(arg_258_0, arg_258_1)
		if arg_258_0:getModelID() == arg_258_1 or arg_258_0:beforeAwakenID() == arg_258_1 then
			return true
		end

		local var_258_0 = xyd.tables.hero:skinItem(arg_258_1)

		if var_258_0 and next(var_258_0) then
			for iter_258_0 = 1, #var_258_0 do
				local var_258_1 = var_258_0[iter_258_0]
				local var_258_2 = xyd.tables.skinSkill:getModelID(var_258_1)

				if arg_258_0:getModelID() == var_258_2 then
					return true
				end
			end
		end

		return false
	end

	local var_257_1 = {}
	local var_257_2 = {}
	local var_257_3 = false
	local var_257_4 = false

	if arg_257_0.herosA and next(arg_257_0.herosA) then
		for iter_257_0, iter_257_1 in ipairs(arg_257_0.herosA) do
			if not var_257_2[iter_257_1:getModelID()] then
				var_257_2[iter_257_1:getModelID()] = true

				table.insert(var_257_1, iter_257_1:getModelID())
			end

			if not var_257_2[iter_257_1:getOldModelID()] then
				var_257_2[iter_257_1:getOldModelID()] = true

				table.insert(var_257_1, iter_257_1:getOldModelID())
			end

			var_257_3 = var_257_3 or var_257_0(iter_257_1, 10001069)
			var_257_4 = var_257_4 or var_257_0(iter_257_1, 11004)
		end
	end

	if arg_257_0.herosB and next(arg_257_0.herosB) then
		for iter_257_2, iter_257_3 in ipairs(arg_257_0.herosB) do
			if iter_257_3 and type(iter_257_3) == "table" and next(iter_257_3) then
				for iter_257_4, iter_257_5 in ipairs(iter_257_3) do
					if not var_257_2[iter_257_5:getModelID()] then
						var_257_2[iter_257_5:getModelID()] = true

						table.insert(var_257_1, iter_257_5:getModelID())
					end

					if not var_257_2[iter_257_5:getOldModelID()] then
						var_257_2[iter_257_5:getOldModelID()] = true

						table.insert(var_257_1, iter_257_5:getOldModelID())
					end

					var_257_3 = var_257_3 or var_257_0(iter_257_5, 10001069)
					var_257_4 = var_257_4 or var_257_0(iter_257_5, 11004)
				end
			end
		end
	end

	if arg_257_0.petsA and next(arg_257_0.petsA) then
		for iter_257_6, iter_257_7 in ipairs(arg_257_0.petsA) do
			if not var_257_2[iter_257_7:getModelID()] then
				var_257_2[iter_257_7:getModelID()] = true

				table.insert(var_257_1, iter_257_7:getModelID())
			end
		end
	end

	if arg_257_0.petsB and next(arg_257_0.petsB) then
		for iter_257_8, iter_257_9 in ipairs(arg_257_0.petsB) do
			if not var_257_2[iter_257_9:getModelID()] then
				var_257_2[iter_257_9:getModelID()] = true

				table.insert(var_257_1, iter_257_9:getModelID())
			end
		end
	end

	local var_257_5
	local var_257_6 = {}

	if arg_257_0.campaignType and arg_257_0.campaignType == xyd.CampaignType.TREASURE and arg_257_0.treasureAwardType then
		var_257_5 = xyd.tables.treasure:map(arg_257_0.treasureAwardType)
	elseif arg_257_0.battleID then
		var_257_5 = xyd.tables.battle:maps(arg_257_0.battleID)
	end

	local var_257_7 = "images/maps/map_images/"

	if type(var_257_5) == "number" then
		var_257_6 = {
			var_257_7 .. tostring(var_257_5) .. ".png"
		}
	elseif type(var_257_5) == "string" then
		var_257_6 = {
			var_257_7 .. tostring(var_257_5) .. ".png"
		}
	elseif type(var_257_5) == "table" then
		for iter_257_10, iter_257_11 in ipairs(var_257_5) do
			table.insert(var_257_6, var_257_7 .. tostring(iter_257_11) .. ".png")
		end
	end

	if var_257_3 then
		local var_257_8 = var_257_7 .. "yxt2.png"
		local var_257_9 = var_257_7 .. "yxt.png"

		table.insert(var_257_6, var_257_8)
		table.insert(var_257_6, var_257_9)
	end

	if var_257_4 then
		local var_257_10 = var_257_7 .. "zqsj.png"

		table.insert(var_257_6, var_257_10)
	end

	local var_257_11

	if arg_257_0.battleID then
		var_257_11 = xyd.tables.battle:sounds(arg_257_0.battleID)
	end

	local var_257_12

	if arg_257_0.battleID == 939020 then
		var_257_12 = import("app.scenes.BattleChocolate")
	else
		var_257_12 = xyd.BattleCreate
	end

	xyd.AssetDownload.get():preloadBattleInfos({
		var_257_11
	}, var_257_6, var_257_1, function()
		cc.Director:getInstance():pushScene(var_257_12.new(arg_257_0))
	end)
end

function xyd.setPositionBy(arg_260_0, arg_260_1)
	local var_260_0 = cc.p(arg_260_0:getPosition())
	local var_260_1 = xyd.addPosition(var_260_0, arg_260_1)

	arg_260_0:setPosition(var_260_1)
end

function xyd.getTransparentCard(arg_261_0, arg_261_1, arg_261_2, arg_261_3)
	local var_261_0 = xyd.tables.skinDynamic
	local var_261_1 = arg_261_2 or arg_261_0:getModelID()

	arg_261_3 = arg_261_3 or 1

	if xyd.isShowDynamicCard(arg_261_0, var_261_1) then
		local var_261_2 = var_261_0:path(var_261_1)
		local var_261_3 = var_261_0:homeCardScale(var_261_1) * arg_261_3
		local var_261_4 = var_261_0:pos(var_261_1, arg_261_1)

		return xyd.EffectLoader.new(var_261_2, 3, var_261_3, var_261_4), var_261_1
	else
		card = xyd.SpriteLoader.new(xyd.tables.model:transparentCard(var_261_1), nil, nil, xyd.DefaultImageType.HOME_CARD)

		card:setScale(arg_261_3)

		return card, var_261_1
	end
end

function xyd.getSmallCard(arg_262_0, arg_262_1)
	local var_262_0 = xyd.tables.skinDynamic
	local var_262_1 = arg_262_0:getModelID()

	if xyd.isShowDynamicCard(arg_262_0) then
		local var_262_2 = var_262_0:path(var_262_1)
		local var_262_3 = var_262_0:oldSmallCardScale(var_262_1)
		local var_262_4 = var_262_0:pos(var_262_1, arg_262_1)

		return xyd.EffectLoader.new(var_262_2, 4, var_262_3, var_262_4)
	else
		return xyd.SpriteLoader.new(xyd.tables.model:smallCard(var_262_1), nil, nil, xyd.DefaultImageType.SMALL_CARD)
	end
end

function xyd.getNewSmallCard(arg_263_0)
	local var_263_0 = xyd.tables.skinDynamic
	local var_263_1 = arg_263_0:getModelID()

	if xyd.isShowDynamicCard(arg_263_0) then
		local var_263_2 = var_263_0:path(var_263_1)
		local var_263_3 = var_263_0:smallCardScale(var_263_1)
		local var_263_4 = var_263_0:pos(var_263_1, xyd.SkinDynamicPosType.NEW_SMALLCARD)

		return xyd.EffectLoader.new(var_263_2, 2, var_263_3, var_263_4)
	else
		return xyd.SpriteLoader.new(xyd.tables.model:newSmallCard(var_263_1), nil, nil, xyd.DefaultImageType.S_CARD)
	end
end

function xyd.getNormalCard(arg_264_0, arg_264_1, arg_264_2)
	local var_264_0 = xyd.tables.skinDynamic
	local var_264_1 = arg_264_2 or arg_264_0:getModelID()

	if xyd.isShowDynamicCard(arg_264_0, var_264_1) then
		local var_264_2 = var_264_0:path(var_264_1)
		local var_264_3 = var_264_0:cardScale(var_264_1, arg_264_1)
		local var_264_4 = var_264_0:pos(var_264_1, arg_264_1)

		return xyd.EffectLoader.new(var_264_2, 1, var_264_3, var_264_4)
	else
		return xyd.SpriteLoader.new(xyd.tables.model:card(var_264_1), nil, nil, xyd.DefaultImageType.HERO_CARD)
	end
end

function xyd.isShowDynamicCard(arg_265_0, arg_265_1)
	local var_265_0 = xyd.tables.model
	local var_265_1 = arg_265_1 or arg_265_0:getModelID()
	local var_265_2 = var_265_0:dynamicType(var_265_1)

	if var_265_2 == 0 then
		return false
	end

	if var_265_2 == 1 then
		return true
	end

	return arg_265_0:isUnlockDynamicCard(var_265_1) and arg_265_0:getDynamicCardState(var_265_1) == 1
end

function xyd.catToString(arg_266_0, arg_266_1)
	local var_266_0 = ""

	if arg_266_0 == nil then
		return var_266_0
	end

	local var_266_1 = false

	for iter_266_0, iter_266_1 in ipairs(arg_266_0) do
		if var_266_1 == true then
			var_266_0 = var_266_0 .. arg_266_1
		end

		var_266_1 = true
		var_266_0 = var_266_0 .. iter_266_1
	end

	return var_266_0
end

function xyd.getPartnerTypeByTableID(arg_267_0)
	if not arg_267_0 or arg_267_0 <= 0 then
		return
	end

	if arg_267_0 / xyd.tables.misc.partnerTableInitID > 1 then
		return xyd.PartnerType.NORMAL
	else
		return xyd.PartnerType.SUPER
	end
end

function xyd.getPartnerTypeByPartnerID(arg_268_0)
	if not arg_268_0 or arg_268_0 <= 0 then
		return
	end

	if arg_268_0 >= xyd.tables.misc.superPartnerInitID then
		return xyd.PartnerType.SUPER
	else
		return xyd.PartnerType.NORMAL
	end
end

function xyd.isSuperHero(arg_269_0)
	local var_269_0

	if type(arg_269_0) == "number" or type(arg_269_0) == "string" then
		var_269_0 = tonumber(arg_269_0)
	else
		var_269_0 = arg_269_0:getTableID()
	end

	if not var_269_0 or var_269_0 <= 0 then
		return
	end

	if var_269_0 / xyd.tables.misc.partnerTableInitID > 1 then
		return false
	else
		return true
	end
end

function xyd.getOriginHeroIds(arg_270_0)
	local var_270_0 = xyd.splitToNumber(arg_270_0, "|")

	for iter_270_0 = 1, #var_270_0 do
		var_270_0[iter_270_0] = xyd.getOriginHeroId(var_270_0[iter_270_0])
	end

	return xyd.joinTable(var_270_0, "|")
end

function xyd.getOriginHeroId(arg_271_0)
	if xyd.getPartnerTypeByTableID(arg_271_0) == xyd.PartnerType.NORMAL and arg_271_0 > xyd.AWAKEN_HERO_START_ID then
		return arg_271_0 - xyd.AWAKEN_HERO_DIFF
	end

	return arg_271_0
end

function xyd.buttonScaleAnim(arg_272_0, arg_272_1, arg_272_2, arg_272_3)
	arg_272_2 = arg_272_2 or 0.9
	arg_272_3 = arg_272_3 or 1

	if arg_272_1 == ccui.TouchEventType.began then
		arg_272_0:setScale(arg_272_2 * arg_272_3)
	elseif arg_272_1 == ccui.TouchEventType.canceled then
		arg_272_0:setScale(arg_272_3)
	elseif arg_272_1 == ccui.TouchEventType.ended then
		arg_272_0:setScale(arg_272_3)
	end
end

function xyd.addTouchEvent(arg_273_0, arg_273_1)
	local var_273_0 = arg_273_0:getContentSize()
	local var_273_1 = display.newNode()

	var_273_1:setContentSize(var_273_0.width, var_273_0.height)
	var_273_1:setAnchorPoint(0, 0)
	var_273_1:addTo(arg_273_0)
	var_273_1:setName("touch_node")
	var_273_1:setTouchEnabled(true)
	var_273_1:setTouchSwallowEnabled(false)
	var_273_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_274_0)
		if arg_274_0.name == "began" then
			arg_273_0:setScale(0.9)

			return true
		elseif arg_274_0.name == "canceled" then
			arg_273_0:setScale(1)
		elseif arg_274_0.name == "ended" then
			arg_273_0:setScale(1)

			local var_274_0 = var_273_1:convertToNodeSpace(cc.p(arg_274_0.x, arg_274_0.y))

			if var_274_0.x < 0 or var_274_0.x > var_273_0.width or var_274_0.y < 0 or var_274_0.y > var_273_0.height then
				return
			end

			xyd.playButtonSound()
			arg_273_1()
		end
	end)
end

function xyd.addTouchEvent2(arg_275_0, arg_275_1)
	local var_275_0 = arg_275_0:getContentSize()
	local var_275_1 = display.newNode()

	var_275_1:setContentSize(var_275_0.width, var_275_0.height)
	var_275_1:setAnchorPoint(0, 0)
	var_275_1:addTo(arg_275_0)
	var_275_1:setName("touch_node")
	var_275_1:setTouchEnabled(true)
	var_275_1:setTouchSwallowEnabled(false)
	var_275_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_276_0)
		return arg_275_1(arg_276_0)
	end)
end

function xyd.nodeEventSample(arg_277_0, arg_277_1, arg_277_2)
	arg_277_1 = arg_277_1 or {}
	arg_277_1.scale = arg_277_1.scale or 0.9

	local var_277_0 = arg_277_0:getScaleX()
	local var_277_1 = arg_277_0:getScaleY()
	local var_277_2 = arg_277_0:getContentSize()

	arg_277_0:setTouchEnabled(true)
	arg_277_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_278_0)
		if not arg_277_0 or tolua.isnull(arg_277_0) then
			return
		end

		if arg_278_0.name == "began" then
			arg_277_0:setScaleX(arg_277_1.scale * var_277_0)
			arg_277_0:setScaleY(arg_277_1.scale * var_277_1)

			return true
		elseif arg_278_0.name == "ended" then
			arg_277_0:setScaleX(var_277_0)
			arg_277_0:setScaleY(var_277_1)

			if not arg_277_1.force then
				local var_278_0 = arg_277_0:convertToNodeSpace(cc.p(arg_278_0.x, arg_278_0.y))

				if var_278_0.x < 0 or var_278_0.x > var_277_2.width or var_278_0.y < 0 or var_278_0.y > var_277_2.height then
					return
				end
			end

			arg_277_2(arg_278_0)
		end
	end)
end

function xyd.createAutoFixLabel(arg_279_0)
	local var_279_0 = arg_279_0.width
	local var_279_1 = arg_279_0.height
	local var_279_2 = arg_279_0.txtColor

	if not var_279_0 or not var_279_1 or not var_279_2 then
		return nil
	end

	local var_279_3 = xyd.convertHex2RGB(var_279_2)
	local var_279_4 = 64
	local var_279_5 = 2
	local var_279_6 = arg_279_0.outlineColor
	local var_279_7 = arg_279_0.outlineSize
	local var_279_8 = arg_279_0.align
	local var_279_9 = arg_279_0.valign
	local var_279_10 = arg_279_0.text or ""
	local var_279_11 = arg_279_0.fontSize

	var_279_6 = var_279_6 and xyd.convertHex2RGB(var_279_6)

	local var_279_12

	local function var_279_13(arg_280_0)
		if var_279_12 then
			local var_280_0 = var_279_12:getTTFConfig()

			var_280_0.fontSize = arg_280_0

			var_279_12:setTTFConfig(var_280_0)

			return
		end

		local var_280_1 = {
			color = var_279_3,
			size = arg_280_0,
			align = var_279_8,
			valign = var_279_9,
			text = var_279_10,
			dimensions = cc.size(var_279_0, 0)
		}

		var_279_12 = xyd.AssetLoader.get():loadLabel(var_280_1)

		if not var_279_12 then
			return
		end

		var_279_12:setLineBreakWithoutSpace(true)

		if var_279_6 then
			var_279_12:enableOutline(var_279_6, var_279_7 or 1)
		end
	end

	if var_279_11 and var_279_11 > 0 then
		var_279_13(var_279_11)

		if var_279_12 and var_279_1 >= var_279_12:getContentSize().height then
			return var_279_12
		end
	end

	var_279_13(var_279_4)

	if var_279_1 >= var_279_12:getContentSize().height then
		return var_279_12
	end

	var_279_13(var_279_5)

	if var_279_1 <= var_279_12:getContentSize().height then
		return nil
	end

	local var_279_14
	local var_279_15

	while var_279_4 - var_279_5 >= 2 do
		local var_279_16 = math.floor((var_279_4 + var_279_5) / 2)

		var_279_13(var_279_16)

		if not var_279_12 then
			return
		end

		var_279_15 = var_279_12:getContentSize().height

		if var_279_15 < var_279_1 then
			var_279_5 = var_279_16
		elseif var_279_1 < var_279_15 then
			var_279_4 = var_279_16
		else
			break
		end
	end

	if var_279_15 == var_279_1 then
		return var_279_12
	end

	if var_279_4 % 2 ~= 0 then
		var_279_4 = var_279_4 + 1
	end

	local var_279_17 = var_279_4

	while var_279_15 - var_279_1 > 0 do
		var_279_17 = var_279_17 - 2

		var_279_13(var_279_17)

		if not var_279_12 then
			return
		end

		var_279_15 = var_279_12:getContentSize().height
	end

	return var_279_12
end

function xyd.createSpriteFromPlist(arg_281_0, arg_281_1)
	if not arg_281_0 or not arg_281_1 then
		return
	end

	if not cc.SpriteFrameCache:getInstance():getSpriteFrame(arg_281_0) and arg_281_1 then
		cc.SpriteFrameCache:getInstance():addSpriteFrames(arg_281_1)
	end

	return cc.Sprite:createWithSpriteFrameName(arg_281_0)
end

function xyd.changeAnchorPoint(arg_282_0, arg_282_1, arg_282_2)
	local var_282_0 = arg_282_0:getAnchorPoint()
	local var_282_1 = arg_282_0:getContentSize()
	local var_282_2, var_282_3 = arg_282_0:getPosition()
	local var_282_4 = var_282_2 + (arg_282_1 - var_282_0.x) * var_282_1.width
	local var_282_5 = var_282_3 + (arg_282_2 - var_282_0.y) * var_282_1.height

	arg_282_0:setPosition(var_282_4, var_282_5)
	arg_282_0:setAnchorPoint(arg_282_1, arg_282_2)
end

function xyd.changeAnchorPointByWorldSpacePoint(arg_283_0, arg_283_1)
	local var_283_0 = arg_283_0:convertToNodeSpace(cc.p(arg_283_1.x, arg_283_1.y))
	local var_283_1, var_283_2 = arg_283_0:getPosition()
	local var_283_3 = arg_283_0:getContentSize()
	local var_283_4 = var_283_0.x / var_283_3.width
	local var_283_5 = var_283_0.y / var_283_3.height

	xyd.changeAnchorPoint(arg_283_0, var_283_4, var_283_5)
end

function xyd.getTextAlign(arg_284_0)
	if arg_284_0 == xyd.ui_align.LEFT then
		return cc.ui.TEXT_ALIGN_LEFT
	elseif arg_284_0 == xyd.ui_align.RIGHT then
		return cc.ui.TEXT_ALIGN_RIGHT
	elseif arg_284_0 == xyd.ui_align.CENTER then
		return cc.ui.TEXT_ALIGN_CENTER
	end
end

function xyd.getTextValign(arg_285_0)
	if arg_285_0 == xyd.ui_valign.TOP then
		return cc.ui.TEXT_VALIGN_TOP
	elseif arg_285_0 == xyd.ui_valign.BOTTOM then
		return cc.ui.TEXT_VALIGN_BOTTOM
	elseif arg_285_0 == xyd.ui_valign.CENTER then
		return cc.ui.TEXT_VALIGN_CENTER
	end
end

function xyd.getHeroAttrIcon(arg_286_0)
	local var_286_0
	local var_286_1 = xyd.tables.hero:heroType(arg_286_0)

	if var_286_1 == xyd.AttrType.LI then
		var_286_0 = "windows/common/hero_common/icon_attr_li.png"
	elseif var_286_1 == xyd.AttrType.ZHI then
		var_286_0 = "windows/common/hero_common/icon_attr_zhi.png"
	elseif var_286_1 == xyd.AttrType.MIN then
		var_286_0 = "windows/common/hero_common/icon_attr_min.png"
	end

	return xyd.AssetLoader.get():loadSprite(var_286_0)
end

function xyd.createHeroSmallCard(arg_287_0, arg_287_1)
	if not arg_287_0 or not next(arg_287_0) then
		return
	end

	local var_287_0 = import("app.windows.HeroListCell").new({
		hero = arg_287_0
	})

	var_287_0:layout()

	if arg_287_1 and arg_287_1 > 0 then
		local var_287_1 = arg_287_1 / var_287_0:getWidth()

		var_287_0:setScale(var_287_1)
	end

	return var_287_0
end

function xyd.createHeroStars(arg_288_0)
	local var_288_0 = 20
	local var_288_1 = 10
	local var_288_2 = arg_288_0:getStar()

	local function var_288_3(arg_289_0)
		local var_289_0

		if not arg_289_0 then
			var_289_0 = xyd.AssetLoader.get():loadSprite("windows/common/hero_common/icon_hero_star.png")
		else
			var_289_0 = xyd.AssetLoader.get():loadSprite("windows/common/hero_common/icon_pink_star.png")
		end

		return var_289_0
	end

	local var_288_4 = false

	if xyd.isSuperHero(arg_288_0) and var_288_2 > xyd.HERO_TOTAL_STARS then
		var_288_4 = true
		var_288_2 = var_288_2 - xyd.HERO_TOTAL_STARS
	end

	local var_288_5 = var_288_3(var_288_4)
	local var_288_6 = var_288_5:getWidth()
	local var_288_7 = var_288_6 + (var_288_2 - 1) * var_288_0
	local var_288_8 = var_288_5:getHeight()
	local var_288_9 = display.newNode()

	var_288_9:setContentSize(var_288_7, var_288_8)
	var_288_9:setAnchorPoint(0.5, 0.5)
	var_288_5:addTo(var_288_9, var_288_1)
	var_288_5:setAnchorPoint(0.5, 0.5)
	var_288_5:setPosition(var_288_6 / 2, var_288_8 / 2)

	for iter_288_0 = 1, var_288_2 - 1 do
		local var_288_10 = var_288_3(var_288_4)

		var_288_10:addTo(var_288_9, var_288_1 - iter_288_0)
		var_288_10:setAnchorPoint(0.5, 0.5)
		var_288_10:setPosition(var_288_6 / 2 + iter_288_0 * var_288_0, var_288_8 / 2)
	end

	return var_288_9
end

function xyd.getItemBorder(arg_290_0)
	local var_290_0

	if arg_290_0 <= 1 then
		var_290_0 = "item_border_white.png"
	elseif arg_290_0 == 2 then
		var_290_0 = "item_border_green.png"
	elseif arg_290_0 == 3 then
		var_290_0 = "item_border_blue.png"
	elseif arg_290_0 == 4 then
		var_290_0 = "item_border_purple.png"
	elseif arg_290_0 == 5 then
		var_290_0 = "item_border_orange.png"
	elseif arg_290_0 == 6 then
		var_290_0 = "item_border_red.png"
	end

	return "images/common/" .. var_290_0
end

function xyd.colorNumLabel(arg_291_0, arg_291_1, arg_291_2)
	if type(arg_291_0) ~= "number" or not arg_291_1 then
		return
	end

	local var_291_0 = display.newNode()
	local var_291_1 = "images/color_num/" .. arg_291_1 .. "_"
	local var_291_2 = arg_291_2 and arg_291_2.dis or 0
	local var_291_3 = math.floor(arg_291_0)
	local var_291_4 = arg_291_0 - var_291_3
	local var_291_5 = -var_291_2
	local var_291_6 = 0
	local var_291_7 = xyd.AssetLoader.get():loadSprite(var_291_1 .. "0.png"):getHeight()
	local var_291_8 = {}

	if var_291_3 == 0 then
		table.insert(var_291_8, 0)
	end

	while var_291_3 > 0 do
		table.insert(var_291_8, var_291_3 % 10)

		var_291_3 = math.floor(var_291_3 / 10)
	end

	for iter_291_0 = 1, #var_291_8 do
		local var_291_9 = xyd.AssetLoader.get():loadSprite(var_291_1 .. var_291_8[#var_291_8 - iter_291_0 + 1] .. ".png")

		var_291_9:setAnchorPoint(0, 0)
		var_291_9:addTo(var_291_0)

		var_291_5 = var_291_5 + var_291_2

		var_291_9:pos(var_291_5, 0)

		var_291_5 = var_291_5 + var_291_9:getWidth()
	end

	if var_291_4 > 0 then
		local var_291_10 = xyd.AssetLoader.get():loadSprite(var_291_1 .. "p.png")

		var_291_10:setAnchorPoint(0, 0)
		var_291_10:addTo(var_291_0)

		var_291_5 = var_291_5 + var_291_2

		var_291_10:pos(var_291_5, 0)

		var_291_5 = var_291_5 + var_291_10:getWidth()

		while var_291_4 > 0 do
			var_291_4 = var_291_4 * 10

			local var_291_11 = math.floor(var_291_4)

			var_291_4 = remian - var_291_11

			local var_291_12 = xyd.AssetLoader.get():loadSprite(var_291_1 .. var_291_11 .. ".png")

			var_291_12:setAnchorPoint(0, 0)
			var_291_12:addTo(var_291_0)

			var_291_5 = var_291_5 + var_291_2

			var_291_12:pos(var_291_5, 0)

			var_291_5 = var_291_5 + var_291_12:getWidth()
		end
	end

	if arg_291_2 and arg_291_2.percent then
		local var_291_13 = xyd.AssetLoader.get():loadSprite(var_291_1 .. "per.png")

		var_291_13:setAnchorPoint(0, 0)
		var_291_13:addTo(var_291_0)

		var_291_5 = var_291_5 + var_291_2

		var_291_13:pos(var_291_5, 0)

		var_291_5 = var_291_5 + var_291_13:getWidth()
	end

	var_291_0:setContentSize(var_291_5, var_291_7)

	return var_291_0
end

function xyd.setAvatarBorderNewUI(arg_292_0, arg_292_1, arg_292_2, arg_292_3, arg_292_4, arg_292_5, arg_292_6, arg_292_7, arg_292_8, arg_292_9, arg_292_10)
	local function var_292_0(arg_293_0, arg_293_1)
		local var_293_0
		local var_293_1 = xyd.isSuperHero(arg_293_0) and arg_293_1 > xyd.MAX_STAR_LEVEL and "windows/common/hero_common/icon_pink_star_small.png" or "windows/common/hero_common/icon_hero_star_small.png"

		return xyd.AssetLoader.get():loadSprite(var_293_1)
	end

	local var_292_1
	local var_292_2
	local var_292_3 = arg_292_2
	local var_292_4 = arg_292_3
	local var_292_5
	local var_292_6
	local var_292_7 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	local var_292_8
	local var_292_9 = false
	local var_292_10
	local var_292_11
	local var_292_12

	if type(arg_292_0) == "number" or type(arg_292_0) == "string" then
		var_292_5 = tonumber(arg_292_0)

		local var_292_13 = xyd.tables.hero:modelID(var_292_5)

		if arg_292_6 and arg_292_6 ~= 0 then
			var_292_13 = arg_292_6
		end

		var_292_1 = xyd.tables.model:avatar(var_292_13)

		if var_292_7:getHeroByTableID(var_292_5) and not arg_292_7 then
			var_292_6 = var_292_7:getHeroByTableID(var_292_5):getInscriptionKuangLevel()
		end

		if arg_292_10 then
			var_292_10 = arg_292_10
		end
	else
		if not arg_292_0 then
			return
		end

		var_292_2 = type(arg_292_2) == "boolean" and arg_292_2 == true

		local var_292_14 = arg_292_0:getModelID()

		var_292_1 = xyd.tables.model:avatar(var_292_14)
		var_292_3 = var_292_3 or arg_292_0:getColor()
		var_292_4 = var_292_4 or arg_292_0:getStar()
		arg_292_4 = arg_292_4 or arg_292_0:isAwakeTwice()
		var_292_5 = arg_292_0:getTableID()

		if arg_292_0.getInscriptionKuangLevel then
			var_292_6 = arg_292_0:getInscriptionKuangLevel()
		end

		if arg_292_0.houseExpandLev and arg_292_0.houseExpandLev > 0 then
			var_292_9 = true
		end

		local var_292_15 = arg_292_0.houseTableId

		if var_292_15 and var_292_15 > 0 then
			var_292_8 = xyd.tables.dormHouse:maintype(var_292_15)

			if var_292_8 <= 1 then
				var_292_8 = nil
			end
		end

		if not arg_292_10 then
			var_292_10 = arg_292_0:getElementType()
		else
			var_292_10 = arg_292_10
		end

		var_292_11 = arg_292_0:isActiveSP()

		if arg_292_0.isSkinOn_ == 1 then
			local var_292_16 = arg_292_0:getSkinDatas()

			for iter_292_0, iter_292_1 in ipairs(var_292_16) do
				if iter_292_1.skinItem and xyd.tables.item:skinModel(iter_292_1.skinItem) == arg_292_0.skinId_ then
					var_292_12 = iter_292_1.skinItem

					break
				end
			end
		end
	end

	local var_292_17

	if arg_292_5 then
		local var_292_18 = {
			filter = {}
		}

		var_292_18.filter.name = "GRAY"
		var_292_18.filter.value = {
			0.2,
			0.3,
			0.5,
			0.1
		}
		var_292_17 = xyd.SpriteLoader.new(var_292_1, nil, var_292_18, xyd.DefaultImageType.SKILL_ICON)
	else
		var_292_17 = xyd.SpriteLoader.new(var_292_1, nil, nil, xyd.DefaultImageType.SKILL_ICON)
	end

	local var_292_19 = arg_292_1:getContentSize()

	var_292_17 = var_292_17 or xyd.AssetLoader.get():loadSprite("windows/common/common_avatar.png")

	local var_292_20 = xyd.AssetLoader:get():loadSprite("windows/common/hero_common/avatar_mask.png")
	local var_292_21 = cc.ClippingNode:create()

	var_292_21:setStencil(var_292_20)
	var_292_21:setInverted(false)
	var_292_21:setAlphaThreshold(0)
	var_292_21:addChild(var_292_17)
	var_292_17:align(display.CENTER, var_292_19.width / 2, var_292_19.height / 2)
	var_292_17:scale(var_292_19.width / var_292_17:getWidth())
	var_292_20:addTo(arg_292_1, -1)
	var_292_20:align(display.CENTER, var_292_19.width / 2, var_292_19.height / 2)
	var_292_20:scale((var_292_19.width - 3) / var_292_20:getWidth())
	arg_292_1:addChild(var_292_21)

	local var_292_22
	local var_292_23 = xyd.tables.hero:beforeAwaken(var_292_5) > 0 and true or false
	local var_292_24 = xyd.getAvatarBorderNewUI(var_292_3, var_292_23, arg_292_4, var_292_6, xyd.isSuperHero(arg_292_0))
	local var_292_25 = clone(var_292_24:getContentSize())
	local var_292_26

	if var_292_23 then
		if arg_292_4 then
			var_292_26 = xyd.AssetLoader.get():loadSprite("windows/common/hero_common/bg_hero_border_awake_twice.png")
		else
			var_292_26 = xyd.AssetLoader.get():loadSprite("windows/common/hero_common/bg_hero_border_awake.png")
		end

		var_292_26:addTo(var_292_24)
		var_292_26:setAnchorPoint(0, 0)
	end

	if var_292_3 and type(var_292_3) == "number" and var_292_3 > 0 then
		local var_292_27

		if xyd.Color2Level[var_292_3] ~= "" then
			var_292_27 = xyd.AssetLoader.get():loadSprite("windows/common/hero_common/border_quality_" .. var_292_3 .. ".png")
		end

		if xyd.isSuperHero(arg_292_0) then
			var_292_27 = nil
		end

		if var_292_10 and var_292_10 ~= 0 then
			local var_292_28 = "windows/common/hero_common/small_element_" .. var_292_10

			if var_292_11 then
				var_292_28 = var_292_28 .. "sp"
			end

			var_292_27 = xyd.AssetLoader.get():loadSprite(var_292_28 .. ".png")

			var_292_27:setAnchorPoint(0, 1)
			var_292_27:addTo(var_292_24)
			var_292_27:setPosition(0, var_292_24:getContentSize().height)

			if var_292_11 then
				local var_292_29 = "skeletons/ui_effect/element_equip/element_" .. var_292_10 .. "xiao"
				local var_292_30 = xyd.createEffect(var_292_29)
				local var_292_31 = var_292_27:getContentSize()

				var_292_30:addTo(var_292_27)
				var_292_30:setPosition(var_292_31.width / 2, var_292_31.height / 2)
				var_292_30:play(nil, true)
			end
		elseif var_292_27 then
			var_292_27:setAnchorPoint(0, 1)
			var_292_27:addTo(var_292_24)
			var_292_27:setPosition(-10, var_292_24:getContentSize().height + 11)
		end
	end

	xyd.displaySpriteOnContainer(var_292_24, arg_292_1, true)
	var_292_24:setName("border")

	if var_292_12 then
		local var_292_32 = xyd.AssetLoader.get():loadSprite("images/skin_bg.png")
		local var_292_33 = var_292_32:getContentSize()
		local var_292_34 = xyd.SpriteLoader.new(xyd.tables.item:icon(var_292_12), nil, nil, xyd.DefaultImageType.ITEM_ICON, var_292_32)

		var_292_34:setScale(0.4)
		var_292_34:setPosition(var_292_33.width / 2 + 1, var_292_33.height / 2 + 1)
		var_292_32:addChild(var_292_34)
		var_292_32:setAnchorPoint(1, 1)
		var_292_32:setPosition(var_292_19.width + 2, var_292_19.width + 2)
		var_292_32:setScale(var_292_19.width / 86)
		arg_292_1:addChild(var_292_32)
	end

	if var_292_8 and not arg_292_9 then
		local var_292_35 = xyd.tables.dormHouseType:newIcon(var_292_8)

		if var_292_9 then
			var_292_35 = "images/dorm/choose/new_orange.png"
		end

		local var_292_36 = xyd.AssetLoader.get():loadSprite(var_292_35)

		var_292_36:setAnchorPoint(cc.p(0.5, 0))
		arg_292_1:addChild(var_292_36)
		var_292_36:setName("house")
		var_292_36:setPosition(cc.p(var_292_19.width - 3, 0))
		var_292_36:setLocalZOrder(100)
	end

	local var_292_37 = var_292_4

	if var_292_37 > xyd.MAX_STAR_LEVEL then
		var_292_37 = var_292_37 - xyd.MAX_STAR_LEVEL
	end

	local var_292_38 = var_292_0(arg_292_0, var_292_4):getContentSize().width - 8
	local var_292_39 = (var_292_25.width - var_292_37 * var_292_38 - 8) / 2
	local var_292_40 = display.newNode()

	var_292_40:setName("view")
	var_292_40:setContentSize(var_292_25)
	var_292_40:setAnchorPoint(cc.p(0, 0))
	var_292_40:setPosition(cc.p(0, 0))

	for iter_292_2 = 1, var_292_37 do
		local var_292_41 = var_292_0(arg_292_0, var_292_4)

		var_292_40:addChild(var_292_41)
		var_292_41:x(var_292_39 + (iter_292_2 - 1) * var_292_38):y(5)
		var_292_41:setAnchorPoint(cc.p(0, 0))
	end

	var_292_40:setScale(var_292_19.width / var_292_25.width, var_292_19.height / var_292_25.height)
	arg_292_1:addChild(var_292_40)

	if var_292_2 then
		local var_292_42 = xyd.getItemEffect(5)

		if not var_292_42 then
			return
		end

		arg_292_1:addChild(var_292_42)
		var_292_42:setLocalZOrder(-100)
		var_292_42:setPosition(var_292_19.width / 2, var_292_19.height / 2)
		var_292_42:play(nil, true)
	end

	if arg_292_8 then
		local var_292_43 = xyd.tables.hero:name(var_292_5)
		local var_292_44 = display.newScale9Sprite("windows/common/name_label_bg.png", 0, 0, cc.size(119, 25), cc.rect(5, 5, 5, 5))

		var_292_44:setAnchorPoint(cc.p(0.5, 1))

		local var_292_45 = xyd.createLabel(20, cc.c3b(255, 255, 255))

		var_292_45:setAnchorPoint(cc.p(0.5, 0.5))
		var_292_45:setString(var_292_43)
		var_292_45:addTo(var_292_44)
		var_292_45:setPosition(cc.p(var_292_44:getContentSize().width / 2, var_292_44:getContentSize().height / 2))
		var_292_44:addTo(arg_292_1)
		var_292_44:setPosition(cc.p(arg_292_1:getContentSize().width / 2, -2))
		var_292_44:setScale(var_292_19.width / var_292_25.width, var_292_19.height / var_292_25.height)
	end
end

function xyd.setAvatarBorderWithLevelAndHpNewUI(arg_294_0, arg_294_1, arg_294_2, arg_294_3, arg_294_4, arg_294_5, arg_294_6)
	local function var_294_0(arg_295_0, arg_295_1)
		local var_295_0
		local var_295_1 = xyd.isSuperHero(arg_295_0) and arg_295_1 > xyd.MAX_STAR_LEVEL and "windows/common/hero_common/icon_pink_star_small.png" or "windows/common/hero_common/icon_hero_star_small.png"

		return xyd.AssetLoader.get():loadSprite(var_295_1)
	end

	local var_294_1
	local var_294_2
	local var_294_3 = arg_294_2
	local var_294_4 = arg_294_3
	local var_294_5 = arg_294_4
	local var_294_6 = false
	local var_294_7 = false
	local var_294_8 = false
	local var_294_9
	local var_294_10
	local var_294_11

	if type(arg_294_0) == "number" or type(arg_294_0) == "string" then
		local var_294_12 = tonumber(arg_294_0)
		local var_294_13 = xyd.tables.hero:modelID(var_294_12)

		var_294_1 = xyd.tables.model:avatar(var_294_13)

		if arg_294_6 then
			var_294_10 = arg_294_6
		end
	else
		var_294_2 = type(arg_294_2) == "boolean" and arg_294_2 == true
		var_294_1 = arg_294_0:getAvatar()
		var_294_3 = arg_294_0:getColor()
		var_294_4 = arg_294_0:getStar()
		var_294_5 = arg_294_0:getLevel()
		heroId = arg_294_0:getTableID()

		local var_294_14 = arg_294_0:isAwaken()

		var_294_7 = arg_294_0:isAwakeTwice()

		if arg_294_0.getInscriptionKuangLevel then
			var_294_8 = arg_294_0:getInscriptionKuangLevel()
		end

		local var_294_15 = arg_294_0.houseTableId

		if var_294_15 and var_294_15 > 0 then
			var_294_9 = xyd.tables.dormHouse:maintype(var_294_15)

			if var_294_9 <= 1 then
				var_294_9 = nil
			end
		end

		if not arg_294_6 then
			var_294_10 = arg_294_0:getElementType()
		else
			var_294_10 = arg_294_6
		end

		var_294_11 = arg_294_0:isActiveSP()
	end

	local var_294_16 = xyd.SpriteLoader.new(var_294_1, nil, nil, xyd.DefaultImageType.AVATAR)
	local var_294_17 = arg_294_1:getContentSize()

	var_294_16 = var_294_16 or xyd.AssetLoader.get():loadSprite("windows/common/hero_avatar3.png")

	local var_294_18 = xyd.AssetLoader:get():loadSprite("windows/common/hero_common/avatar_mask.png")
	local var_294_19 = cc.ClippingNode:create()

	var_294_19:setStencil(var_294_18)
	var_294_19:setInverted(false)
	var_294_19:setAlphaThreshold(0)
	var_294_19:addChild(var_294_16)
	var_294_16:align(display.CENTER, var_294_17.width / 2, var_294_17.height / 2)
	var_294_16:scale(var_294_17.width / var_294_16:getWidth())

	if var_294_5 then
		local var_294_20 = xyd.AssetLoader.get():loadSprite("windows/common/lv_di.png")

		var_294_19:addChild(var_294_20)
		var_294_20:setPosition(var_294_17.width * 27 / 120, var_294_17.height * 49 / 120)
		var_294_20:scale(var_294_17.width / var_294_16:getWidth())

		local var_294_21 = xyd.AssetLoader.get():loadLabel()

		var_294_21:setString(var_294_5)
		var_294_20:addChild(var_294_21)
		var_294_21:align(display.CENTER, var_294_20:getContentSize().width / 2, var_294_20:getContentSize().height / 2)
		var_294_21:scale(var_294_17.width / var_294_16:getWidth())
	end

	var_294_18:addTo(arg_294_1, -1)
	var_294_18:align(display.CENTER, var_294_17.width / 2, var_294_17.height / 2)
	var_294_18:scale((var_294_17.width - 3) / var_294_18:getWidth())
	arg_294_1:addChild(var_294_19)

	local var_294_22 = xyd.isSuperHero(arg_294_0)
	local var_294_23
	local var_294_24 = xyd.tables.hero:beforeAwaken(heroId) > 0 and true or false
	local var_294_25 = xyd.getAvatarBorderNewUI(var_294_3, var_294_24, var_294_7, var_294_8, xyd.isSuperHero(arg_294_0))
	local var_294_26 = clone(var_294_25:getContentSize())
	local var_294_27

	if var_294_24 then
		if var_294_7 then
			var_294_27 = xyd.AssetLoader.get():loadSprite("windows/common/hero_common/bg_hero_border_awake_twice.png")
		else
			var_294_27 = xyd.AssetLoader.get():loadSprite("windows/common/hero_common/bg_hero_border_awake.png")
		end

		var_294_27:addTo(var_294_25)
		var_294_27:setAnchorPoint(0, 0)
	end

	if var_294_3 and type(var_294_3) == "number" and var_294_3 > 0 then
		local var_294_28

		if xyd.Color2Level[var_294_3] ~= "" then
			var_294_28 = xyd.AssetLoader.get():loadSprite("windows/common/hero_common/border_quality_" .. var_294_3 .. ".png")
		end

		if xyd.isSuperHero(arg_294_0) then
			var_294_28 = nil
		end

		if var_294_10 and var_294_10 ~= 0 then
			local var_294_29 = "windows/common/hero_common/small_element_" .. var_294_10

			if var_294_11 then
				var_294_29 = var_294_29 .. "sp"
			end

			var_294_28 = xyd.AssetLoader.get():loadSprite(var_294_29 .. ".png")
		end

		if var_294_28 then
			var_294_28:setAnchorPoint(0, 1)
			var_294_28:addTo(var_294_25)
			var_294_28:setPosition(-10, var_294_25:getContentSize().height + 11)
		end
	end

	xyd.displaySpriteOnContainer(var_294_25, arg_294_1, true)

	if var_294_9 then
		local var_294_30 = xyd.tables.dormHouseType:icon(var_294_9)
		local var_294_31 = xyd.AssetLoader.get():loadSprite(var_294_30)

		var_294_31:setAnchorPoint(cc.p(1, 1))
		arg_294_1:addChild(var_294_31)
		var_294_31:setName("house")
		var_294_31:setPosition(cc.p(var_294_17.width + 2, var_294_17.height + 2))
		var_294_31:setLocalZOrder(100)
	end

	local var_294_32 = var_294_4

	if var_294_32 > xyd.MAX_STAR_LEVEL then
		var_294_32 = var_294_32 - xyd.MAX_STAR_LEVEL
	end

	local var_294_33 = var_294_0(arg_294_0, var_294_4):getContentSize().width - 8
	local var_294_34 = (var_294_26.width - var_294_32 * var_294_33 - 8) / 2
	local var_294_35 = display.newNode()

	var_294_35:setName("view")
	var_294_35:setContentSize(var_294_26)
	var_294_35:setAnchorPoint(cc.p(0, 0))
	var_294_35:setPosition(cc.p(0, 0))

	for iter_294_0 = 1, var_294_32 do
		local var_294_36 = var_294_0(arg_294_0, var_294_4)

		var_294_35:addChild(var_294_36)
		var_294_36:x(var_294_34 + (iter_294_0 - 1) * var_294_33):y(5)
		var_294_36:setAnchorPoint(cc.p(0, 0))
	end

	var_294_35:setScale(var_294_17.width / var_294_26.width, var_294_17.height / var_294_26.height)
	arg_294_1:addChild(var_294_35)

	if var_294_2 then
		local var_294_37 = xyd.getItemEffect(5)

		if not var_294_37 then
			return
		end

		arg_294_1:addChild(var_294_37)
		var_294_37:setLocalZOrder(-100)
		var_294_37:setPosition(var_294_17.width / 2, var_294_17.height / 2)
		var_294_37:play(nil, true)
	end
end

function xyd.getAvatarBorderNewUI(arg_296_0, arg_296_1, arg_296_2, arg_296_3, arg_296_4)
	local var_296_0 = "windows/common/hero_common/"

	if arg_296_4 then
		var_296_0 = var_296_0 .. "bg_hero_border2_super.png"
	elseif type(arg_296_0) ~= "number" then
		var_296_0 = var_296_0 .. "bg_hero_border2_1.png"
	elseif arg_296_0 == 0 then
		var_296_0 = "windows/common/avatar_awake.png"
	elseif arg_296_0 and arg_296_0 <= xyd.MAX_HERO_COLOR then
		if xyd.Color2Level[arg_296_0] == "" then
			var_296_0 = var_296_0 .. "bg_hero_border2_" .. xyd.Color2Quality[arg_296_0] .. ".png"
		else
			var_296_0 = var_296_0 .. "bg_hero_border_" .. xyd.Color2Quality[arg_296_0] .. ".png"
		end
	end

	return xyd.AssetLoader:get():loadSprite(var_296_0)
end

function xyd.setPetAvatarNewUI(arg_297_0, arg_297_1, arg_297_2, arg_297_3, arg_297_4, arg_297_5, arg_297_6)
	if not arg_297_1 then
		return
	end

	local var_297_0 = {
		{
			50,
			10
		},
		{
			34,
			16,
			66,
			16
		},
		{
			50,
			10,
			18,
			24,
			82,
			24
		},
		{
			38,
			12,
			62,
			12,
			18,
			24,
			82,
			24
		},
		{
			50,
			10,
			34,
			16,
			66,
			16,
			18,
			24,
			82,
			24
		}
	}

	local function var_297_1()
		local var_298_0 = "images/battle/star_small2.png"

		return xyd.AssetLoader.get():loadSprite(var_298_0)
	end

	if not arg_297_0 or tolua.isnull(arg_297_0) then
		return
	end

	local var_297_2 = arg_297_1:getAvatar(2)
	local var_297_3 = arg_297_1:getColor()
	local var_297_4 = arg_297_1:getStar()
	local var_297_5 = xyd.AssetLoader.get():loadNodeFromJson("windows/battle/select_team_new/pet_avatar.csb")

	var_297_5:getChildByName("avatar_mask"):hide()
	var_297_5:getChildByName("chosen"):hide()
	var_297_5:getChildByName("name"):setString(arg_297_1:getName())

	if arg_297_3 then
		var_297_5:getChildByName("name_label_bg"):setVisible(false)
		var_297_5:getChildByName("name"):setString("")
	end

	local var_297_6 = var_297_5:getChildByName("background"):getWidth()

	var_297_5:size(var_297_6, var_297_6)
	arg_297_0:addChild(var_297_5)
	var_297_5:setName("layout")
	var_297_5:align(display.CENTER, arg_297_0:getWidth() / 2, arg_297_0:getHeight() / 2)

	local var_297_7 = var_297_5:getChildByName("avatar")
	local var_297_8

	if arg_297_1:isAwaken() and not arg_297_4 then
		var_297_8 = xyd.AssetLoader.get():loadSprite("images/battle/b_pet_awake_avatar_border_" .. var_297_3 .. ".png")
	else
		var_297_8 = xyd.AssetLoader.get():loadSprite("images/battle/b_pet_avatar_border_" .. var_297_3 .. ".png")
	end

	var_297_7:addChild(var_297_8)
	var_297_8:align(display.CENTER, 50, 50)

	local var_297_9 = xyd.AssetLoader.get():loadSprite(var_297_2)

	var_297_7:addChild(var_297_9)
	var_297_9:align(display.CENTER_BOTTOM, 50, 0)

	if var_297_4 and var_297_4 > 0 then
		local var_297_10 = var_297_1():getWidth()
		local var_297_11 = var_297_0[var_297_4]

		for iter_297_0 = var_297_4, 1, -1 do
			local var_297_12 = var_297_1()

			var_297_7:addChild(var_297_12)
			var_297_12:align(display.CENTER, var_297_11[2 * iter_297_0 - 1], var_297_11[2 * iter_297_0])
		end
	end

	if arg_297_5 then
		local var_297_13 = arg_297_0:getContentSize()

		var_297_5:scale(var_297_13.width / var_297_5:getWidth() * 1.3)
	end

	if arg_297_6 then
		local var_297_14 = arg_297_1:getName()
		local var_297_15 = display.newScale9Sprite("windows/common/bg_pet_name.png", 0, 0, cc.size(119, 25), cc.rect(5, 5, 5, 5))

		var_297_15:setAnchorPoint(cc.p(0.5, 1))

		local var_297_16 = xyd.createLabel(20, cc.c3b(255, 255, 255))

		var_297_16:setAnchorPoint(cc.p(0.5, 0.5))
		var_297_16:setString(var_297_14)
		var_297_16:addTo(var_297_15)
		var_297_16:setPosition(cc.p(var_297_15:getContentSize().width / 2, var_297_15:getContentSize().height / 2))
		var_297_15:addTo(arg_297_0)
		var_297_15:setPosition(cc.p(arg_297_0:getContentSize().width / 2, -4))
		var_297_15:setScale(arg_297_0:getContentSize().width / var_297_5:getWidth() * 1.2, arg_297_0:getContentSize().height / var_297_5:getHeight() * 1.2)
		var_297_15:setName("name_bg")
	end
end

function xyd.setItemAnimation(arg_299_0, arg_299_1, arg_299_2)
	if not arg_299_0 or not arg_299_1 then
		return
	end

	local var_299_0 = arg_299_2 or 0.04

	xyd.setCascadeOpacityEnabled(arg_299_0, true)
	arg_299_0:setVisible(false)
	arg_299_0:setOpacity(100)
	arg_299_0:performWithDelay(function()
		if not arg_299_0 or tolua.isnull(arg_299_0) then
			return
		end

		arg_299_0:setVisible(true)
		arg_299_0:runActionOnce(cc.FadeIn:create(0.04))
	end, arg_299_1 * var_299_0)
end

function xyd.assetDownloadErrorLog(arg_301_0)
	if cc.FileUtils:getInstance():isFileExist(arg_301_0) then
		return true
	else
		local var_301_0 = "assetDownloadErrorLog Error! path:" .. arg_301_0

		xyd.db.errorLog:add(var_301_0)

		return false
	end
end

function xyd.checkFirstInGuide(arg_302_0)
	local var_302_0 = xyd.tables.guideFunction
	local var_302_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	local var_302_2 = xyd.tables.abtest:uniqueKey(xyd.Abtests.MTSPY)

	if not var_302_1.abtestGroup then
		var_302_1:initABtest()
	end

	if not var_302_1.abtestGroup[var_302_2] then
		var_302_1:getAbtestGroupByKey(var_302_2)
	end

	local var_302_3 = var_302_1.abtestGroup[var_302_2]

	if var_302_3 and var_302_3 ~= "A" then
		return
	end

	local var_302_4 = var_302_0:checkGuide(arg_302_0)
	local var_302_5 = false

	if not var_302_4 or var_302_4 == 0 then
		return
	else
		if xyd.WindowManager.get():isWindowOpen("guide") or xyd.WindowManager.get():isWindowOpen("guide_new") then
			return
		end

		local var_302_6 = var_302_0:getGuideWnd()
		local var_302_7 = var_302_0:getGuideWndIDs(arg_302_0)
		local var_302_8 = var_302_1.guideFuncList
		local var_302_9 = var_302_1.reloadGuideID
		local var_302_10 = {}

		for iter_302_0 = 1, #var_302_7 do
			local var_302_11 = tostring(var_302_7[iter_302_0])

			if not var_302_8[var_302_11] or var_302_8[var_302_11] == 0 then
				table.insert(var_302_10, var_302_7[iter_302_0])
			end
		end

		if var_302_10 == {} then
			return
		end

		local var_302_12 = var_302_1.lev

		for iter_302_1 = 1, #var_302_10 do
			local var_302_13 = var_302_0:para(var_302_10[iter_302_1])

			dump(var_302_10[iter_302_1])

			local var_302_14 = var_302_0:stype(var_302_10[iter_302_1])

			if xyd.WindowManager.get():isWindowOpen(arg_302_0) then
				var_302_5 = xyd.WindowManager.get():getWindow(arg_302_0):checkIfSatisfyGuide(var_302_14)
			end

			if var_302_14 ~= 1 then
				if not var_302_5 then
					dump("return")
				end
			elseif var_302_12 >= var_302_13[1] and var_302_12 <= var_302_13[2] then
				local var_302_15 = {
					nowGuideID = var_302_0:guideNewId(var_302_10[iter_302_1])
				}

				if var_302_9 and var_302_9 ~= 0 then
					var_302_15.nowGuideID = var_302_9
				end

				dump(var_302_10[iter_302_1])

				var_302_15.nowFuncID = var_302_10[iter_302_1]

				local var_302_16 = xyd.WindowManager.get():openWindow("guide_new", var_302_15)
				local var_302_17 = tostring(var_302_10[iter_302_1])

				return
			end
		end
	end
end

function xyd.goNextGuideNewWnd(arg_303_0, arg_303_1)
	local var_303_0 = {
		nowGuideID = arg_303_0,
		nowFuncID = arg_303_1
	}

	if xyd.WindowManager.get():isWindowOpen("guide_new") then
		xyd.WindowManager.get():closeWindow("guide_new")
	end

	local var_303_1 = xyd.WindowManager.get():openWindow("guide_new", var_303_0)
end

function xyd.sendGudieBtnClick(arg_304_0)
	if xyd.WindowManager.get():isWindowOpen("guide_new") then
		local var_304_0 = xyd.WindowManager.get():getWindow("guide_new")

		var_304_0:getBtnClick(arg_304_0)
		var_304_0:goToNextGuide(arg_304_0)
	end
end

function xyd.checkReload(arg_305_0)
	if xyd.WindowManager.get():isWindowOpen("guide_new") then
		local var_305_0 = xyd.WindowManager.get():getWindow("guide_new")

		var_305_0:getBtnClick(arg_305_0)
		var_305_0:goToNextGuide(arg_305_0)
	end
end

function xyd.adaptToWorldPosition(arg_306_0, arg_306_1)
	local var_306_0 = 20
	local var_306_1 = 1260
	local var_306_2 = 20
	local var_306_3 = 700
	local var_306_4, var_306_5 = arg_306_0:getPosition()
	local var_306_6 = arg_306_1:getParent():convertToWorldSpace(cc.p(0, 0))
	local var_306_7 = arg_306_0:getParent():convertToWorldSpace(cc.p(var_306_4, var_306_5))

	var_306_7.x = var_306_7.x - var_306_6.x
	var_306_7.y = var_306_7.y - var_306_6.y

	local var_306_8 = arg_306_0:getContentSize()
	local var_306_9 = arg_306_1:getTipHeight()
	local var_306_10 = arg_306_1:getTipWidth()
	local var_306_11 = var_306_7.x
	local var_306_12 = var_306_7.y

	if var_306_7.x <= 640 and var_306_7.y >= 320 then
		var_306_11 = var_306_7.x + var_306_8.width
		var_306_12 = var_306_7.y - var_306_9 + var_306_8.height
	elseif var_306_7.x > 640 and var_306_7.y >= 320 then
		var_306_11 = var_306_7.x - var_306_10
		var_306_12 = var_306_7.y - var_306_9 + var_306_8.height
	elseif var_306_7.x <= 640 and var_306_7.y < 320 then
		var_306_11 = var_306_7.x + var_306_8.width
	elseif var_306_7.x > 640 and var_306_7.y < 320 then
		var_306_11 = var_306_7.x - var_306_10
	end

	if var_306_11 < var_306_0 then
		var_306_11 = var_306_0
	elseif var_306_1 < var_306_11 + var_306_10 then
		var_306_11 = var_306_1 - var_306_10
	end

	if var_306_12 < var_306_2 then
		var_306_12 = var_306_2
	elseif var_306_3 < var_306_12 + var_306_9 then
		var_306_12 = var_306_3 - var_306_9
	end

	arg_306_1:setPosition(var_306_11, var_306_12)

	if arg_306_1.name == "skill_tips" then
		arg_306_1:setPosition(var_306_11, var_306_12 + var_306_9 - 185)
	end
end

function xyd.heroNormalSort(arg_307_0, arg_307_1)
	if not arg_307_0.isPet and not arg_307_1.isPet then
		if xyd.isSuperHero(arg_307_0) ~= xyd.isSuperHero(arg_307_1) then
			return xyd.isSuperHero(arg_307_0)
		elseif arg_307_0.level_ ~= arg_307_1.level_ then
			return arg_307_0.level_ > arg_307_1.level_
		elseif arg_307_0.star_ ~= arg_307_1.star_ then
			return arg_307_0.star_ > arg_307_1.star_
		elseif arg_307_0.color_ ~= arg_307_1.color_ then
			return arg_307_0.color_ > arg_307_1.color_
		elseif arg_307_0.awakeTwiceStage_ and arg_307_1.awakeTwiceStage_ and arg_307_0.awakeTwiceStage_ ~= arg_307_1.awakeTwiceStage_ then
			return arg_307_0.awakeTwiceStage_ > arg_307_1.awakeTwiceStage_
		elseif arg_307_0:isAwaken() ~= arg_307_1:isAwaken() then
			return arg_307_0:isAwaken()
		else
			return arg_307_0.tableID_ < arg_307_1.tableID_
		end
	else
		xyd.petNormalSort(arg_307_0, arg_307_1)
	end
end

function xyd.petNormalSort(arg_308_0, arg_308_1)
	if arg_308_0.level_ ~= arg_308_1.level_ then
		return arg_308_0.level_ > arg_308_1.level_
	elseif arg_308_0.star_ ~= arg_308_1.star_ then
		return arg_308_0.star_ > arg_308_1.star_
	elseif arg_308_0.color_ ~= arg_308_1.color_ then
		return arg_308_0.color_ > arg_308_1.color_
	else
		return arg_308_0.tableID_ < arg_308_1.tableID_
	end
end

function xyd.isSystemFuncOpen(arg_309_0)
	local var_309_0 = xyd.ServerTime.get():getServerTime()
	local var_309_1 = tonumber(xyd.date("%m", var_309_0))
	local var_309_2 = tonumber(xyd.date("%d", var_309_0))
	local var_309_3 = tonumber(xyd.date("%w", var_309_0))

	if var_309_3 == 0 then
		var_309_3 = 7
	end

	local var_309_4 = xyd.tables.systemOpen
	local var_309_5 = var_309_4:week(arg_309_0)

	if var_309_5 and next(var_309_5) then
		local var_309_6 = false

		for iter_309_0 = 1, #var_309_5 do
			if var_309_3 == var_309_5[iter_309_0] then
				var_309_6 = true

				break
			end
		end

		if not var_309_6 then
			return false
		end
	end

	local var_309_7 = var_309_4:day(arg_309_0)

	if var_309_7 and next(var_309_7) then
		local var_309_8 = false

		for iter_309_1 = 1, #var_309_7 do
			if var_309_2 == var_309_7[iter_309_1] then
				var_309_8 = true

				break
			end
		end

		if not var_309_8 then
			return false
		end
	end

	local var_309_9 = var_309_4:month(arg_309_0)

	if var_309_9 and next(var_309_9) then
		local var_309_10 = false

		for iter_309_2 = 1, #var_309_9 do
			if var_309_1 == var_309_9[iter_309_2] then
				var_309_10 = true

				break
			end
		end

		if not var_309_10 then
			return false
		end
	end

	local var_309_11 = var_309_4:time(arg_309_0)
	local var_309_12 = xyd.ServerTime.get():getSecondsOfDay()

	if var_309_11 and next(var_309_11) then
		local var_309_13 = false

		for iter_309_3 = 1, #var_309_11 / 2 do
			local var_309_14 = (iter_309_3 - 1) * 2 + 1

			if var_309_12 >= var_309_11[var_309_14] and var_309_12 <= var_309_11[var_309_14 + 1] then
				var_309_13 = true

				break
			end
		end

		if not var_309_13 then
			return false
		end
	end

	return true
end

function xyd.showAiHelp()
	local var_310_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	local var_310_1 = {
		tostring(var_310_0.playerID),
		var_310_0.playerName,
		tostring(var_310_0.region)
	}
	local var_310_2 = "setUserInfo"
	local var_310_3 = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"
	local var_310_4 = "1"
	local var_310_5 = ""
	local var_310_6 = "org/cocos2dx/lua/AppActivity"
	local var_310_7 = "showAiView"
	local var_310_8 = {
		var_310_4,
		var_310_5
	}
	local var_310_9 = "(Ljava/lang/String;Ljava/lang/String;)V"

	luaj.callStaticMethod(var_310_6, var_310_2, var_310_1, var_310_3)

	local var_310_10, var_310_11 = luaj.callStaticMethod(var_310_6, var_310_7, var_310_8, var_310_9)
end

function xyd.showAiHelpFAQ()
	local var_311_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	local var_311_1 = {
		tostring(var_311_0.playerID),
		var_311_0.playerName,
		tostring(var_311_0.region)
	}
	local var_311_2 = "setUserInfo"
	local var_311_3 = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"
	local var_311_4 = "org/cocos2dx/lua/AppActivity"
	local var_311_5 = "showFAQs"
	local var_311_6 = {}
	local var_311_7 = "()V"

	luaj.callStaticMethod(var_311_4, var_311_2, var_311_1, var_311_3)

	local var_311_8, var_311_9 = luaj.callStaticMethod(var_311_4, var_311_5, var_311_6, var_311_7)
end

function xyd.showAiHelpActivity()
	local var_312_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	local var_312_1 = {
		tostring(var_312_0.playerID),
		var_312_0.playerName,
		tostring(var_312_0.region)
	}
	local var_312_2 = "setUserInfo"
	local var_312_3 = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"
	local var_312_4 = "1"
	local var_312_5 = "org/cocos2dx/lua/AppActivity"
	local var_312_6 = "showOP"
	local var_312_7 = {
		var_312_4
	}
	local var_312_8 = "(Ljava/lang/String;)V"

	luaj.callStaticMethod(var_312_5, var_312_2, var_312_1, var_312_3)

	local var_312_9, var_312_10 = luaj.callStaticMethod(var_312_5, var_312_6, var_312_7, var_312_8)
end

function xyd.showAiHelpQuery()
	local var_313_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	local var_313_1 = {
		tostring(var_313_0.playerID),
		var_313_0.playerName,
		tostring(var_313_0.region)
	}
	local var_313_2 = "setUserInfo"
	local var_313_3 = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"
	local var_313_4 = "1"
	local var_313_5 = "hihi"
	local var_313_6 = "org/cocos2dx/lua/AppActivity"
	local var_313_7 = "showAiView"
	local var_313_8 = {
		var_313_4,
		var_313_5
	}
	local var_313_9 = "(Ljava/lang/String;Ljava/lang/String;)V"

	luaj.callStaticMethod(var_313_6, var_313_2, var_313_1, var_313_3)

	local var_313_10, var_313_11 = luaj.callStaticMethod(var_313_6, var_313_7, var_313_8, var_313_9)
end

function xyd.setBubble(arg_314_0, arg_314_1)
	if arg_314_1 > 0 then
		local var_314_0 = arg_314_0:getContentSize()
		local var_314_1 = xyd.tables.chatBubble:capInsets(arg_314_1)
		local var_314_2 = {
			41,
			-37
		}
		local var_314_3 = {
			37,
			25,
			37,
			24
		}
		local var_314_4 = cc.size(var_314_0.width + var_314_3[1] + var_314_3[3], var_314_0.height + var_314_3[2] + var_314_3[4])
		local var_314_5 = xyd.SpriteLoader.new("images/bubble/arrow/" .. arg_314_1 .. ".png", nil, nil, xyd.DefaultImageType.BUBBLE_ARROW)
		local var_314_6 = xyd.SpriteLoader.new("images/bubble/bg/" .. arg_314_1 .. ".png", cc.rect(var_314_1[1], var_314_1[2], var_314_1[3], var_314_1[4]), {
			size = var_314_4
		}, xyd.DefaultImageType.BUBBLE_BG)

		var_314_6:setAnchorPoint(0, 0)
		var_314_6:setPosition(-var_314_3[1], -var_314_3[2])
		var_314_5:setAnchorPoint(1, 1)
		var_314_5:setPosition(var_314_2[1] - var_314_3[1], var_314_0.height + var_314_3[4] + var_314_2[2])
		arg_314_0:addChild(var_314_6)
		arg_314_0:addChild(var_314_5)

		local var_314_7 = {
			size = 22,
			color = cc.c3b(96, 99, 131),
			text = xyd.tables.translation:translation("CHAT_BUBBLE_TEXT_4"),
			x = var_314_0.width / 2,
			y = var_314_0.height / 2
		}
		local var_314_8 = xyd.AssetLoader.get():loadLabel(var_314_7)

		var_314_8:setAnchorPoint(0.5, 0.5)
		arg_314_0:addChild(var_314_8)
	end
end

function xyd.setHunqiBorder(arg_315_0)
	local var_315_0 = arg_315_0.container

	if var_315_0:getChildByName("spirit") then
		var_315_0:removeChildByName("spirit")
	end

	local var_315_1 = arg_315_0.item
	local var_315_2

	if var_315_1 then
		var_315_2 = var_315_1.table_id
	else
		var_315_2 = arg_315_0.tableID
	end

	local var_315_3 = xyd.tables.spiritEquip:modelId(var_315_2)
	local var_315_4 = xyd.tables.spiritEquip:from(var_315_2)
	local var_315_5 = xyd.tables.spirit:pos(var_315_3)
	local var_315_6 = xyd.tables.spirit:star(var_315_3)
	local var_315_7 = display.newNode()
	local var_315_8 = xyd.HunqiDefualtSize

	var_315_7:setContentSize(var_315_8, var_315_8)
	var_315_7:setName("spirit")

	local var_315_9 = 0
	local var_315_10 = 0
	local var_315_11 = false
	local var_315_12
	local var_315_13

	if var_315_5 > 3 then
		var_315_13 = var_315_5 - 3
		var_315_11 = true
	else
		var_315_13 = var_315_5
	end

	if var_315_5 == 1 then
		var_315_12 = 1
	elseif var_315_5 == 2 then
		var_315_12 = 2
	elseif var_315_5 == 3 then
		var_315_12 = 3
	elseif var_315_5 == 4 then
		var_315_12 = 3
	elseif var_315_5 == 5 then
		var_315_9 = -9
		var_315_10 = 0
		var_315_12 = 2
	elseif var_315_5 == 6 then
		var_315_12 = 1
	end

	if not arg_315_0.noBorder then
		local var_315_14 = xyd.getItemBg(var_315_6)

		xyd.displaySpriteOnContainer(var_315_14, var_315_7)
	end

	local var_315_15 = xyd.AssetLoader.get():loadSprite("images/hunqi_border/border_bg_" .. var_315_12 .. ".png")

	if var_315_11 then
		var_315_15:setFlippedX(var_315_11)
	end

	var_315_15:addTo(var_315_7)
	var_315_15:setPosition(var_315_8 / 2, var_315_8 / 2)

	local var_315_16 = xyd.SpriteLoader.new("images/hunqi/" .. var_315_4 .. "_" .. var_315_13 .. ".png", nil, nil, xyd.DefaultImageType.QUESTION_MARK2)

	var_315_16:addTo(var_315_7)
	var_315_16:setPosition(var_315_9 + var_315_8 / 2, var_315_10 + var_315_8 / 2)

	local var_315_17 = "images/hunqi_border/border_"

	if var_315_6 <= 1 then
		var_315_17 = var_315_17 .. "white"
	elseif var_315_6 == 2 then
		var_315_17 = var_315_17 .. "green"
	elseif var_315_6 == 3 then
		var_315_17 = var_315_17 .. "blue"
	elseif var_315_6 == 4 then
		var_315_17 = var_315_17 .. "purple"
	elseif var_315_6 == 5 then
		var_315_17 = var_315_17 .. "orange"
	elseif var_315_6 == 6 then
		var_315_17 = var_315_17 .. "red"
	end

	local var_315_18 = xyd.AssetLoader.get():loadSprite(var_315_17 .. "_" .. var_315_12 .. ".png")

	if var_315_11 then
		var_315_18:setFlippedX(var_315_11)
	end

	var_315_18:addTo(var_315_7)
	var_315_18:setPosition(var_315_8 / 2, var_315_8 / 2)

	if not arg_315_0.noBorder and var_315_1 and var_315_1.is_lock ~= 0 then
		local var_315_19 = xyd.AssetLoader.get():loadSprite("windows/hunqi/detail/lock.png")

		var_315_19:setAnchorPoint(cc.p(0, 1))
		var_315_19:addTo(var_315_7)
		var_315_19:setPosition(6, var_315_8 - 4)
	end

	if not arg_315_0.noLev and var_315_1 then
		local var_315_20 = {
			size = 22,
			align = cc.ui.TEXT_ALIGN_CENTER,
			font = xyd.AssetLoader.FONT_NAME,
			color = cc.c3b(255, 255, 255)
		}
		local var_315_21 = xyd.AssetLoader.get():loadLabel(var_315_20)

		var_315_21:setString("+" .. var_315_1.lev)
		var_315_21:addTo(var_315_7)
		var_315_21:enableOutline(cc.c4b(59, 59, 94, 255), 2)

		if not arg_315_0.levShowTop then
			var_315_21:setAnchorPoint(cc.p(1, 1))
			var_315_21:setPosition(var_315_8 - 4, var_315_8 - 4)
		else
			var_315_21:setAnchorPoint(cc.p(0.5, 1))

			if var_315_5 == 5 then
				var_315_21:setPosition(var_315_8 / 2 - 9, var_315_8 - 4)
			else
				var_315_21:setPosition(var_315_8 / 2, var_315_8 - 4)
			end
		end
	end

	xyd.displaySpriteOnContainer(var_315_7, var_315_0)
end

function xyd.setHunqiAndAddTips(arg_316_0)
	local var_316_0 = arg_316_0.container
	local var_316_1 = var_316_0:getContentSize().height
	local var_316_2 = display.newNode()

	var_316_2:setContentSize(var_316_1, var_316_1)

	arg_316_0.container = var_316_2

	xyd.setHunqiBorder(arg_316_0)
	var_316_2:addTo(var_316_0)
	var_316_2:setAnchorPoint(cc.p(0, 0))
	var_316_2:setTouchEnabled(true)
	var_316_2:setTouchSwallowEnabled(false)

	local var_316_3
	local var_316_4

	var_316_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_317_0)
		if arg_317_0.name == "began" then
			var_316_3 = arg_317_0.x
			var_316_4 = arg_317_0.y

			return true
		elseif arg_317_0.name == "ended" then
			local var_317_0 = arg_317_0.x
			local var_317_1 = arg_317_0.y
			local var_317_2 = var_316_2:convertToNodeSpace(cc.p(arg_317_0.x, arg_317_0.y))

			if var_317_2.x < 0 or var_317_2.x > var_316_1 or var_317_2.y < 0 or var_317_2.y > var_316_1 or math.abs(var_317_0 - var_316_3) > 30 or math.abs(var_317_1 - var_316_4) > 30 then
				return
			end

			if xyd.WindowManager.get():getWindow("hunqi_detail") then
				xyd.WindowManager.get():closeWindow("hunqi_detail")
			end

			local var_317_3 = xyd.WindowManager.get():openWindow("hunqi_detail", {
				item1 = arg_316_0.item
			})

			xyd.adaptToWorldPosition(var_316_2, var_317_3)
		end

		return true
	end)
end
