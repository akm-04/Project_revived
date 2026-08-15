local var_0_0 = {
	isLocalWiFiAvailable = function()
		return cc.Network:isLocalWiFiAvailable()
	end,
	isInternetConnectionAvailable = function()
		return cc.Network:isInternetConnectionAvailable()
	end,
	isHostNameReachable = function(arg_3_0)
		if type(arg_3_0) ~= "string" then
			printError("network.isHostNameReachable() - invalid hostname %s", tostring(arg_3_0))

			return false
		end

		return cc.Network:isHostNameReachable(arg_3_0)
	end,
	getInternetConnectionStatus = function()
		return cc.Network:getInternetConnectionStatus()
	end,
	createHTTPRequest = function(arg_5_0, arg_5_1, arg_5_2)
		arg_5_2 = arg_5_2 or "GET"

		if string.upper(tostring(arg_5_2)) == "GET" then
			arg_5_2 = cc.kCCHTTPRequestMethodGET
		elseif string.upper(tostring(arg_5_2)) == "PUT" then
			arg_5_2 = cc.kCCHTTPRequestMethodPUT
		elseif string.upper(tostring(arg_5_2)) == "DELETE" then
			arg_5_2 = cc.kCCHTTPRequestMethodDELETE
		else
			arg_5_2 = cc.kCCHTTPRequestMethodPOST
		end

		return cc.HTTPRequest:createWithUrl(arg_5_0, arg_5_1, arg_5_2)
	end
}

function var_0_0.uploadFile(arg_6_0, arg_6_1, arg_6_2)
	assert(arg_6_2 or arg_6_2.fileFieldName or arg_6_2.filePath, "Need file datas!")

	local var_6_0 = var_0_0.createHTTPRequest(arg_6_0, arg_6_1, "POST")
	local var_6_1 = arg_6_2.fileFieldName
	local var_6_2 = arg_6_2.filePath
	local var_6_3 = arg_6_2.contentType

	if var_6_3 then
		var_6_0:addFormFile(var_6_1, var_6_2, var_6_3)
	else
		var_6_0:addFormFile(var_6_1, var_6_2)
	end

	if arg_6_2.extra then
		for iter_6_0 in ipairs(arg_6_2.extra) do
			local var_6_4 = arg_6_2.extra[iter_6_0]

			var_6_0:addFormContents(var_6_4[1], var_6_4[2])
		end
	end

	var_6_0:start()

	return var_6_0
end

local function var_0_1(arg_7_0)
	arg_7_0 = string.lower(tostring(arg_7_0))

	if arg_7_0 == "yes" or arg_7_0 == "true" then
		return true
	end

	return false
end

function var_0_0.makeCookieString(arg_8_0)
	local var_8_0 = {}

	for iter_8_0, iter_8_1 in pairs(arg_8_0) do
		if type(iter_8_1) == "table" then
			iter_8_1 = tostring(iter_8_1.value)
		else
			iter_8_1 = tostring(iter_8_1)
		end

		var_8_0[#var_8_0 + 1] = tostring(iter_8_0) .. "=" .. string.urlencode(iter_8_1)
	end

	return table.concat(var_8_0, "; ")
end

function var_0_0.parseCookie(arg_9_0)
	local var_9_0 = {}
	local var_9_1 = string.split(arg_9_0, "\n")

	for iter_9_0, iter_9_1 in ipairs(var_9_1) do
		iter_9_1 = string.trim(iter_9_1)

		if iter_9_1 ~= "" then
			local var_9_2 = string.split(iter_9_1, "\t")
			local var_9_3 = {
				domain = var_9_2[1],
				access = var_0_1(var_9_2[2]),
				path = var_9_2[3],
				secure = var_0_1(var_9_2[4]),
				expire = checkint(var_9_2[5]),
				name = var_9_2[6],
				value = string.urldecode(var_9_2[7])
			}

			var_9_0[var_9_3.name] = var_9_3
		end
	end

	return var_9_0
end

return var_0_0
