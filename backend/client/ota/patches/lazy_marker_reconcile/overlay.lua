		arg_1_0.changeCount = 0

		local stampKey = "__lazy_marker_reconcile__"
		local lazyPrefix = "__lazy__"
		local defaults = cc.UserDefault:getInstance()
		local appliedVersion = defaults:getStringForKey(xyd.USER_DEFAULTS_VERSION_KEY) or ""

		if appliedVersion ~= "" and defaults:getStringForKey(stampKey) ~= appliedVersion then
			local lazyPrefixLength = string.len(lazyPrefix)

			for key, payload in pairs(arg_1_0.maps) do
				if type(key) == "string" and string.sub(key, 1, lazyPrefixLength) == lazyPrefix then
					local decodeOk, marker = pcall(var_0_0.decode, payload)

					if decodeOk and type(marker) == "table" and marker.path and marker.md5 then
						local filePath = xyd.versionUpdatePath .. string.gsub(marker.path, "/web/", "/")

						if arg_1_0.fileUtilsIns:isFileExist(filePath) and cc.Crypto:MD5File(filePath) == marker.md5 then
							arg_1_0.maps[key] = nil
						end
					end
				end
			end

			arg_1_0:flush()
			defaults:setStringForKey(stampKey, appliedVersion)
		end
	end,
