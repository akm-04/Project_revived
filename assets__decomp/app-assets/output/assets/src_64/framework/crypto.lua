return {
	encryptAES256 = function(arg_1_0, arg_1_1)
		arg_1_0 = tostring(arg_1_0)
		arg_1_1 = tostring(arg_1_1)

		return cc.Crypto:encryptAES256(arg_1_0, string.len(arg_1_0), arg_1_1, string.len(arg_1_1))
	end,
	decryptAES256 = function(arg_2_0, arg_2_1)
		arg_2_0 = tostring(arg_2_0)
		arg_2_1 = tostring(arg_2_1)

		return cc.Crypto:decryptAES256(arg_2_0, string.len(arg_2_0), arg_2_1, string.len(arg_2_1))
	end,
	encryptXXTEA = function(arg_3_0, arg_3_1)
		arg_3_0 = tostring(arg_3_0)
		arg_3_1 = tostring(arg_3_1)

		return cc.Crypto:encryptXXTEA(arg_3_0, string.len(arg_3_0), arg_3_1, string.len(arg_3_1))
	end,
	decryptXXTEA = function(arg_4_0, arg_4_1)
		arg_4_0 = tostring(arg_4_0)
		arg_4_1 = tostring(arg_4_1)

		return cc.Crypto:decryptXXTEA(arg_4_0, string.len(arg_4_0), arg_4_1, string.len(arg_4_1))
	end,
	encodeBase64 = function(arg_5_0)
		arg_5_0 = tostring(arg_5_0)

		return cc.Crypto:encodeBase64(arg_5_0, string.len(arg_5_0))
	end,
	decodeBase64 = function(arg_6_0)
		arg_6_0 = tostring(arg_6_0)

		return cc.Crypto:decodeBase64(arg_6_0)
	end,
	md5 = function(arg_7_0, arg_7_1)
		arg_7_0 = tostring(arg_7_0)

		if type(arg_7_1) ~= "boolean" then
			arg_7_1 = false
		end

		return cc.Crypto:MD5(arg_7_0, arg_7_1)
	end,
	md5file = function(arg_8_0)
		if not arg_8_0 then
			printError("crypto.md5file() - invalid filename")

			return nil
		end

		arg_8_0 = tostring(arg_8_0)

		if DEBUG > 1 then
			printInfo("crypto.md5file() - filename: %s", arg_8_0)
		end

		return cc.Crypto:MD5File(arg_8_0)
	end
}
