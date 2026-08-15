local var_0_0 = class("OnlineImageSprite", function(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4)
	return display.newSprite(arg_1_0, arg_1_2, arg_1_3, arg_1_4)
end)

function var_0_0.ctor(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5)
	arg_2_0.url = arg_2_2
	arg_2_0.baseInfo = arg_2_5

	if arg_2_0.url ~= "" and arg_2_0.url ~= nil then
		if not arg_2_0:isExist() then
			local var_2_0 = arg_2_2

			if string.sub(var_2_0, 1, 7) ~= "http://" then
				var_2_0 = "http://" .. var_2_0
			end

			arg_2_0:downloadImage(var_2_0)
		else
			local var_2_1 = cc.Director:getInstance():getTextureCache():addImage(arg_2_0:getImagePath())

			if var_2_1 then
				arg_2_0:setTexture(var_2_1)
			end
		end
	end
end

function var_0_0.isExist(arg_3_0)
	local var_3_0 = arg_3_0:getImagePath()

	if cc.FileUtils:getInstance():isFileExist(var_3_0) then
		if arg_3_0.baseInfo.md5_code == 1 and cc.FileUtils:getInstance():getFileSize(var_3_0) ~= 0 then
			return true
		end

		if cc.Crypto:MD5File(var_3_0) ~= arg_3_0.baseInfo.md5_code then
			return false
		else
			return true
		end
	end

	return false
end

function var_0_0.getImagePath(arg_4_0)
	if arg_4_0.baseInfo.file_name and arg_4_0.baseInfo.file_path then
		return arg_4_0.baseInfo.file_path .. arg_4_0.baseInfo.file_name
	else
		local var_4_0 = arg_4_0.url
		local var_4_1 = string.gsub(var_4_0, "/", "")
		local var_4_2 = string.gsub(var_4_1, "\\", "")

		return cc.FileUtils:getInstance():getWritablePath() .. var_4_2
	end
end

function var_0_0.downloadImage(arg_5_0, arg_5_1)
	local var_5_0, var_5_1 = string.find(arg_5_1, "/")
	local var_5_2 = string.sub(arg_5_1, var_5_1 + 1)
	local var_5_3 = string.sub(arg_5_1, 1, var_5_1 - 1)

	xyd.FileDownloader:download(arg_5_1, arg_5_0:getImagePath(), 0, 10, function(arg_6_0, arg_6_1, arg_6_2)
		return
	end, handler(arg_5_0, arg_5_0.onDownloadCompleted))
end

function var_0_0.onDownloadCompleted(arg_7_0, arg_7_1)
	if tolua.isnull(arg_7_0) then
		return
	end

	if arg_7_1 == xyd.FileDownloader.RESULT_SUCCESS then
		cc.Director:getInstance():getTextureCache():removeTextureForKey(arg_7_0:getImagePath())

		local var_7_0 = cc.Director:getInstance():getTextureCache():addImage(arg_7_0:getImagePath())

		if var_7_0 then
			arg_7_0:setTexture(var_7_0)
		end
	end
end

return var_0_0
