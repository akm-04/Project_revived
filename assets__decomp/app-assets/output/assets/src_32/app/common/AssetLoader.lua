local var_0_0 = class("AssetLoader")
local var_0_1 = import("framework.scheduler")

function var_0_0.get()
	if var_0_0.INSTANCE == nil then
		var_0_0.INSTANCE = var_0_0.new()
	end

	return var_0_0.INSTANCE
end

var_0_0.FONT_NAME = "fonts/main_font.ttf"

function var_0_0.ctor(arg_2_0)
	arg_2_0:loadAtlasInfo_()
end

function var_0_0.newSprite_(arg_3_0, arg_3_1, arg_3_2)
	if arg_3_2.filter and next(arg_3_2.filter) then
		return display.newFilteredSprite(arg_3_1, arg_3_2.filter.name, arg_3_2.filter.value)
	elseif arg_3_2.filters and next(arg_3_2.filters) then
		return display.newFilteredSprite(arg_3_1, arg_3_2.filters, arg_3_2.filterVals)
	else
		return display.newSprite(arg_3_1, 0, 0, arg_3_2)
	end
end

function var_0_0.loadSprite(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	if arg_4_1 == nil then
		return nil
	end

	local var_4_0 = arg_4_3 or {}

	var_4_0.capInsets = arg_4_2

	if arg_4_2 ~= nil then
		var_4_0.class = ccui.Scale9Sprite
	end

	local var_4_1 = "#" .. arg_4_1

	if cc.SpriteFrameCache:getInstance():getSpriteFrame(arg_4_1) ~= nil then
		return arg_4_0:newSprite_(var_4_1, var_4_0)
	end

	local var_4_2 = arg_4_0.frameInfos_[arg_4_1]

	if var_4_2 == nil then
		return arg_4_0:newSprite_(arg_4_1, var_4_0)
	else
		display.addSpriteFrames(var_4_2.plist, var_4_2.image)

		return arg_4_0:newSprite_(var_4_1, var_4_0)
	end
end

function var_0_0.loadFrame(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	if arg_5_1 == nil then
		return nil
	end

	local var_5_0 = arg_5_3 or {}

	var_5_0.capInsets = arg_5_2

	if arg_5_2 ~= nil then
		var_5_0.class = ccui.Scale9Sprite
	end

	local var_5_1 = "#" .. arg_5_1

	return (cc.SpriteFrameCache:getInstance():getSpriteFrame(arg_5_1))
end

function var_0_0.loadLabel(arg_6_0, arg_6_1, arg_6_2)
	arg_6_1 = arg_6_1 or {}

	if arg_6_2 == nil then
		arg_6_1.UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF
		arg_6_1.font = arg_6_1.font or var_0_0.FONT_NAME

		return cc.ui.UILabel.new(arg_6_1)
	else
		arg_6_1.UILabelType = cc.ui.UILabel.LABEL_TYPE_BM
		arg_6_1.font = xyd.tables.bmfont:resource(arg_6_2).font
	end

	return cc.ui.UILabel.new(arg_6_1)
end

function var_0_0.loadButton(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	local var_7_0

	if arg_7_2 then
		var_7_0 = arg_7_2
	end

	var_7_0 = var_7_0 or cc.ui.UIPushButton

	local var_7_1

	if type(arg_7_1) == "table" then
		if #arg_7_1 >= 3 then
			var_7_1 = {
				normal = arg_7_1[1] .. ".png",
				pressed = arg_7_1[2] .. ".png",
				disabled = arg_7_1[3] .. ".png"
			}
		else
			var_7_1 = {
				normal = arg_7_1[1] .. ".png",
				pressed = arg_7_1[1] .. ".png",
				disabled = arg_7_1[1] .. ".png"
			}
		end
	else
		var_7_1 = {
			normal = arg_7_1 .. "-normal.png",
			pressed = arg_7_1 .. "-selected.png",
			disabled = arg_7_1 .. "-disabled.png"
		}
	end

	local function var_7_2(arg_8_0, arg_8_1)
		if string.byte(var_7_1[arg_8_0]) == 35 then
			local var_8_0 = string.sub(var_7_1[arg_8_0], 2)

			if arg_7_0.frameInfos_[var_8_0] == nil then
				var_7_1[arg_8_0] = arg_8_1
			else
				local var_8_1 = arg_7_0.frameInfos_[var_8_0]

				display.addSpriteFrames(var_8_1.plist, var_8_1.image)
			end
		elseif not cc.FileUtils:getInstance():isFileExist(var_7_1[arg_8_0]) then
			var_7_1[arg_8_0] = arg_8_1
		end
	end

	var_7_2("normal", var_7_1.normal)
	var_7_2("pressed", var_7_1.normal)
	var_7_2("disabled", nil)

	if var_7_0 == xyd.IrregularButton or var_7_0 == ccui.Button then
		local var_7_3 = 0

		local function var_7_4(arg_9_0)
			if var_7_1[arg_9_0] then
				var_7_1[arg_9_0] = string.gsub(var_7_1[arg_9_0], "#", "")
			end
		end

		if string.byte(var_7_1.normal) == 35 then
			var_7_3 = 1

			var_7_4("normal")
			var_7_4("pressed")
			var_7_4("disabled")
		end

		return var_7_0:create(var_7_1.normal, var_7_1.pressed, var_7_1.disabled, var_7_3)
	else
		local var_7_5 = var_7_0.new(var_7_1, arg_7_3)

		if arg_7_3 and arg_7_3.size then
			local var_7_6 = arg_7_3.size

			var_7_5:setButtonSize(var_7_6.width, var_7_6.height)
			var_7_5:setContentSize(var_7_6)
		end

		return var_7_5
	end
end

function var_0_0.loadNodeFromJson(arg_10_0, arg_10_1)
	if not xyd.assetDownloadErrorLog(arg_10_1) then
		return
	end

	return cc.CSLoader:createNode(arg_10_1)
end

function var_0_0.loadAnimation(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = cc.AnimationCache:getInstance():getAnimation(arg_11_1)

	if var_11_0 == nil then
		local var_11_1 = xyd.tables.animation:plist(arg_11_1)
		local var_11_2 = xyd.tables.animation:image(arg_11_1)

		display.addSpriteFrames(var_11_1, var_11_2)

		local var_11_3 = xyd.tables.animation:numberOfFrames(arg_11_1)
		local var_11_4 = xyd.tables.animation:begin(arg_11_1)
		local var_11_5 = arg_11_1 .. "%04d"

		if arg_11_2 then
			var_11_5 = var_11_5 .. ".png"
		end

		local var_11_6 = display.newFrames(var_11_5, var_11_4, var_11_3)

		var_11_0 = display.newAnimation(var_11_6, xyd.tables.animation:delay(arg_11_1))
	end

	return var_11_0
end

function var_0_0.loadSkeletonAnimation(arg_12_0, arg_12_1, arg_12_2)
	xyd.AssetDownload.get():preloadCharacterModelWithPath(arg_12_1, arg_12_2, function()
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.PRELOAD_MODEL_SUCCESS,
			modelID = arg_12_2
		})
	end)
end

function var_0_0.loadAtlasInfo_(arg_14_0)
	local function var_14_0(arg_15_0, arg_15_1)
		local var_15_0 = cc.FileUtils:getInstance():getDataFromFile(arg_15_0)
		local var_15_1 = -1

		for iter_15_0 in var_15_0:gmatch("([^\n]+)\n") do
			if iter_15_0:match("<key>frames</key>") then
				var_15_1 = 0
			elseif var_15_1 < 0 then
				-- block empty
			elseif iter_15_0:match("<dict>") then
				var_15_1 = var_15_1 + 1
			elseif iter_15_0:match("</dict>") then
				var_15_1 = var_15_1 - 1

				if var_15_1 <= 0 then
					break
				end
			elseif var_15_1 == 1 then
				local var_15_2 = iter_15_0:match("<key>(.*)</key>")

				if var_15_2 ~= nil then
					arg_14_0.frameInfos_[var_15_2] = {
						plist = arg_15_0,
						image = arg_15_1
					}
				end
			end
		end
	end

	arg_14_0.frameInfos_ = {}

	for iter_14_0, iter_14_1 in ipairs(xyd.tables.atlas:allAtlas()) do
		var_14_0(unpack(iter_14_1))
	end
end

return var_0_0
