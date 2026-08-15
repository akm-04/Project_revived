local var_0_0 = {}
local var_0_1 = cc.Director:getInstance()
local var_0_2 = cc.Director:getInstance():getTextureCache()
local var_0_3 = cc.SpriteFrameCache:getInstance()
local var_0_4 = cc.AnimationCache:getInstance()
local var_0_5 = var_0_1:getOpenGLView()

if var_0_5 == nil then
	var_0_5 = cc.GLViewImpl:createWithRect("QuickCocos", cc.rect(0, 0, CONFIG_SCREEN_WIDTH or 900, CONFIG_SCREEN_HEIGHT or 640))

	var_0_1:setOpenGLView(var_0_5)
end

local var_0_6 = var_0_5:getFrameSize()

var_0_0.sizeInPixels = {
	width = var_0_6.width,
	height = var_0_6.height
}

local var_0_7 = var_0_0.sizeInPixels.width
local var_0_8 = var_0_0.sizeInPixels.height

if CONFIG_SCREEN_WIDTH == nil or CONFIG_SCREEN_HEIGHT == nil then
	CONFIG_SCREEN_WIDTH = var_0_7
	CONFIG_SCREEN_HEIGHT = var_0_8
end

if not CONFIG_SCREEN_AUTOSCALE then
	if var_0_8 < var_0_7 then
		CONFIG_SCREEN_AUTOSCALE = "FIXED_HEIGHT"
	else
		CONFIG_SCREEN_AUTOSCALE = "FIXED_WIDTH"
	end
else
	CONFIG_SCREEN_AUTOSCALE = string.upper(CONFIG_SCREEN_AUTOSCALE)
end

local var_0_9
local var_0_10
local var_0_11

if CONFIG_SCREEN_AUTOSCALE and CONFIG_SCREEN_AUTOSCALE ~= "NONE" then
	if type(CONFIG_SCREEN_AUTOSCALE_CALLBACK) == "function" then
		var_0_10, var_0_11 = CONFIG_SCREEN_AUTOSCALE_CALLBACK(var_0_7, var_0_8, device.model)
	end

	if CONFIG_SCREEN_AUTOSCALE == "EXACT_FIT" then
		var_0_9 = 1

		var_0_5:setDesignResolutionSize(CONFIG_SCREEN_WIDTH, CONFIG_SCREEN_HEIGHT, cc.ResolutionPolicy.EXACT_FIT)
	elseif CONFIG_SCREEN_AUTOSCALE == "FILL_ALL" then
		CONFIG_SCREEN_WIDTH = var_0_7
		CONFIG_SCREEN_HEIGHT = var_0_8
		var_0_9 = 1

		var_0_5:setDesignResolutionSize(CONFIG_SCREEN_WIDTH, CONFIG_SCREEN_HEIGHT, cc.ResolutionPolicy.SHOW_ALL)
	else
		if not var_0_10 or not var_0_11 then
			var_0_10, var_0_11 = var_0_7 / CONFIG_SCREEN_WIDTH, var_0_8 / CONFIG_SCREEN_HEIGHT
		end

		if CONFIG_SCREEN_AUTOSCALE == "FIXED_WIDTH" then
			var_0_9 = var_0_10
			CONFIG_SCREEN_HEIGHT = var_0_8 / var_0_9
		elseif CONFIG_SCREEN_AUTOSCALE == "FIXED_HEIGHT" then
			var_0_9 = var_0_11
			CONFIG_SCREEN_WIDTH = var_0_7 / var_0_9
		elseif CONFIG_SCREEN_AUTOSCALE == "FIXED_AUTO" then
			if var_0_10 < var_0_11 then
				var_0_9 = var_0_10
				CONFIG_SCREEN_HEIGHT = var_0_8 / var_0_9
			else
				var_0_9 = var_0_11
				CONFIG_SCREEN_WIDTH = var_0_7 / var_0_9
			end
		else
			var_0_9 = 1

			printError(string.format("display - invalid CONFIG_SCREEN_AUTOSCALE \"%s\"", CONFIG_SCREEN_AUTOSCALE))
		end

		var_0_5:setDesignResolutionSize(CONFIG_SCREEN_WIDTH, CONFIG_SCREEN_HEIGHT, cc.ResolutionPolicy.NO_BORDER)
	end
else
	CONFIG_SCREEN_WIDTH = var_0_7
	CONFIG_SCREEN_HEIGHT = var_0_8
	var_0_9 = 1
end

local var_0_12 = var_0_1:getWinSize()

var_0_0.screenScale = 2
var_0_0.contentScaleFactor = var_0_9
var_0_0.size = {
	width = var_0_12.width,
	height = var_0_12.height
}
var_0_0.width = var_0_0.size.width
var_0_0.height = var_0_0.size.height
var_0_0.cx = var_0_0.width / 2
var_0_0.cy = var_0_0.height / 2
var_0_0.c_left = -var_0_0.width / 2
var_0_0.c_right = var_0_0.width / 2
var_0_0.c_top = var_0_0.height / 2
var_0_0.c_bottom = -var_0_0.height / 2
var_0_0.left = 0
var_0_0.right = var_0_0.width
var_0_0.top = var_0_0.height
var_0_0.bottom = 0
var_0_0.widthInPixels = var_0_0.sizeInPixels.width
var_0_0.heightInPixels = var_0_0.sizeInPixels.height

printInfo(string.format("# CONFIG_SCREEN_AUTOSCALE      = %s", CONFIG_SCREEN_AUTOSCALE))
printInfo(string.format("# CONFIG_SCREEN_WIDTH          = %0.2f", CONFIG_SCREEN_WIDTH))
printInfo(string.format("# CONFIG_SCREEN_HEIGHT         = %0.2f", CONFIG_SCREEN_HEIGHT))
printInfo(string.format("# display.widthInPixels        = %0.2f", var_0_0.widthInPixels))
printInfo(string.format("# display.heightInPixels       = %0.2f", var_0_0.heightInPixels))
printInfo(string.format("# display.contentScaleFactor   = %0.2f", var_0_0.contentScaleFactor))
printInfo(string.format("# display.width                = %0.2f", var_0_0.width))
printInfo(string.format("# display.height               = %0.2f", var_0_0.height))
printInfo(string.format("# display.cx                   = %0.2f", var_0_0.cx))
printInfo(string.format("# display.cy                   = %0.2f", var_0_0.cy))
printInfo(string.format("# display.left                 = %0.2f", var_0_0.left))
printInfo(string.format("# display.right                = %0.2f", var_0_0.right))
printInfo(string.format("# display.top                  = %0.2f", var_0_0.top))
printInfo(string.format("# display.bottom               = %0.2f", var_0_0.bottom))
printInfo(string.format("# display.c_left               = %0.2f", var_0_0.c_left))
printInfo(string.format("# display.c_right              = %0.2f", var_0_0.c_right))
printInfo(string.format("# display.c_top                = %0.2f", var_0_0.c_top))
printInfo(string.format("# display.c_bottom             = %0.2f", var_0_0.c_bottom))
printInfo("#")

var_0_0.COLOR_WHITE = cc.c3b(255, 255, 255)
var_0_0.COLOR_BLACK = cc.c3b(0, 0, 0)
var_0_0.COLOR_RED = cc.c3b(255, 0, 0)
var_0_0.COLOR_GREEN = cc.c3b(0, 255, 0)
var_0_0.COLOR_BLUE = cc.c3b(0, 0, 255)
var_0_0.AUTO_SIZE = 0
var_0_0.FIXED_SIZE = 1
var_0_0.LEFT_TO_RIGHT = 0
var_0_0.RIGHT_TO_LEFT = 1
var_0_0.TOP_TO_BOTTOM = 2
var_0_0.BOTTOM_TO_TOP = 3
var_0_0.CENTER = 1
var_0_0.LEFT_TOP = 2
var_0_0.TOP_LEFT = 2
var_0_0.CENTER_TOP = 3
var_0_0.TOP_CENTER = 3
var_0_0.RIGHT_TOP = 4
var_0_0.TOP_RIGHT = 4
var_0_0.CENTER_LEFT = 5
var_0_0.LEFT_CENTER = 5
var_0_0.CENTER_RIGHT = 6
var_0_0.RIGHT_CENTER = 6
var_0_0.BOTTOM_LEFT = 7
var_0_0.LEFT_BOTTOM = 7
var_0_0.BOTTOM_RIGHT = 8
var_0_0.RIGHT_BOTTOM = 8
var_0_0.BOTTOM_CENTER = 9
var_0_0.CENTER_BOTTOM = 9
var_0_0.ANCHOR_POINTS = {
	cc.p(0.5, 0.5),
	cc.p(0, 1),
	cc.p(0.5, 1),
	cc.p(1, 1),
	cc.p(0, 0.5),
	cc.p(1, 0.5),
	cc.p(0, 0),
	cc.p(1, 0),
	cc.p(0.5, 0)
}
var_0_0.SCENE_TRANSITIONS = {
	CROSSFADE = {
		cc.TransitionCrossFade,
		2
	},
	FADE = {
		cc.TransitionFade,
		3,
		cc.c3b(0, 0, 0)
	},
	FADEBL = {
		cc.TransitionFadeBL,
		2
	},
	FADEDOWN = {
		cc.TransitionFadeDown,
		2
	},
	FADETR = {
		cc.TransitionFadeTR,
		2
	},
	FADEUP = {
		cc.TransitionFadeUp,
		2
	},
	FLIPANGULAR = {
		cc.TransitionFlipAngular,
		3,
		cc.TRANSITION_ORIENTATION_LEFT_OVER
	},
	FLIPX = {
		cc.TransitionFlipX,
		3,
		cc.TRANSITION_ORIENTATION_LEFT_OVER
	},
	FLIPY = {
		cc.TransitionFlipY,
		3,
		cc.TRANSITION_ORIENTATION_UP_OVER
	},
	JUMPZOOM = {
		cc.TransitionJumpZoom,
		2
	},
	MOVEINB = {
		cc.TransitionMoveInB,
		2
	},
	MOVEINL = {
		cc.TransitionMoveInL,
		2
	},
	MOVEINR = {
		cc.TransitionMoveInR,
		2
	},
	MOVEINT = {
		cc.TransitionMoveInT,
		2
	},
	PAGETURN = {
		cc.TransitionPageTurn,
		3,
		false
	},
	ROTOZOOM = {
		cc.TransitionRotoZoom,
		2
	},
	SHRINKGROW = {
		cc.TransitionShrinkGrow,
		2
	},
	SLIDEINB = {
		cc.TransitionSlideInB,
		2
	},
	SLIDEINL = {
		cc.TransitionSlideInL,
		2
	},
	SLIDEINR = {
		cc.TransitionSlideInR,
		2
	},
	SLIDEINT = {
		cc.TransitionSlideInT,
		2
	},
	SPLITCOLS = {
		cc.TransitionSplitCols,
		2
	},
	SPLITROWS = {
		cc.TransitionSplitRows,
		2
	},
	TURNOFFTILES = {
		cc.TransitionTurnOffTiles,
		2
	},
	ZOOMFLIPANGULAR = {
		cc.TransitionZoomFlipAngular,
		2
	},
	ZOOMFLIPX = {
		cc.TransitionZoomFlipX,
		3,
		cc.TRANSITION_ORIENTATION_LEFT_OVER
	},
	ZOOMFLIPY = {
		cc.TransitionZoomFlipY,
		3,
		cc.TRANSITION_ORIENTATION_UP_OVER
	}
}
var_0_0.TEXTURES_PIXEL_FORMAT = {}
var_0_0.DEFAULT_TTF_FONT = "Arial"
var_0_0.DEFAULT_TTF_FONT_SIZE = 24

function var_0_0.newScene(arg_1_0)
	local var_1_0 = cc.Scene:create()

	var_1_0.name = arg_1_0 or "<unknown-scene>"

	var_1_0:setNodeEventEnabled(true)

	return var_1_0
end

function var_0_0.newPhysicsScene(arg_2_0)
	local var_2_0 = cc.Scene:createWithPhysics()

	var_2_0.name = arg_2_0 or "<unknown-scene>"

	var_2_0:setNodeEventEnabled(true)

	return var_2_0
end

function var_0_0.wrapSceneWithTransition(arg_3_0, arg_3_1, arg_3_2, arg_3_3)
	local var_3_0 = string.upper(tostring(arg_3_1))

	if string.sub(var_3_0, 1, 12) == "CCTRANSITION" then
		var_3_0 = string.sub(var_3_0, 13)
	end

	if var_3_0 == "RANDOM" then
		local var_3_1 = table.keys(var_0_0.SCENE_TRANSITIONS)

		var_3_0 = var_3_1[math.random(1, #var_3_1)]
	end

	if var_0_0.SCENE_TRANSITIONS[var_3_0] then
		local var_3_2, var_3_3, var_3_4 = unpack(var_0_0.SCENE_TRANSITIONS[var_3_0])

		arg_3_2 = arg_3_2 or 0.2

		if var_3_3 == 3 then
			arg_3_0 = var_3_2:create(arg_3_2, arg_3_0, arg_3_3 or var_3_4)
		else
			arg_3_0 = var_3_2:create(arg_3_2, arg_3_0)
		end
	else
		printError("display.wrapSceneWithTransition() - invalid transitionType %s", tostring(arg_3_1))
	end

	return arg_3_0
end

function var_0_0.replaceScene(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	if var_0_1:getRunningScene() then
		if arg_4_1 then
			arg_4_0 = var_0_0.wrapSceneWithTransition(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
		end

		var_0_1:replaceScene(arg_4_0)
	else
		var_0_1:runWithScene(arg_4_0)
	end
end

function var_0_0.getRunningScene()
	return var_0_1:getRunningScene()
end

function var_0_0.pause()
	var_0_1:pause()
end

function var_0_0.resume()
	var_0_1:resume()
end

function var_0_0.newLayer()
	local var_8_0 = cc.Node:create()

	var_8_0:setContentSize(cc.size(var_0_0.width, var_0_0.height))

	return var_8_0
end

function var_0_0.newColorLayer(arg_9_0)
	local var_9_0 = cc.LayerColor:create(arg_9_0)

	var_9_0:setTouchEnabled(true)
	var_9_0:setTouchSwallowEnabled(true)

	return var_9_0
end

function var_0_0.newNode()
	return cc.Node:create()
end

if cc.ClippingRectangleNode then
	cc.ClippingRegionNode = cc.ClippingRectangleNode
else
	cc.ClippingRectangleNode = cc.ClippingRegionNode
end

function var_0_0.newClippingRectangleNode(arg_11_0)
	if arg_11_0 then
		return cc.ClippingRegionNode:create(arg_11_0)
	else
		return cc.ClippingRegionNode:create()
	end
end

var_0_0.newClippingRegionNode = var_0_0.newClippingRectangleNode

function var_0_0.newSprite(arg_12_0, arg_12_1, arg_12_2, arg_12_3)
	local var_12_0
	local var_12_1

	if arg_12_3 then
		var_12_0 = arg_12_3.class
		var_12_1 = arg_12_3.size
	end

	var_12_0 = var_12_0 or cc.Sprite

	local var_12_2 = type(arg_12_0)

	if var_12_2 == "userdata" then
		var_12_2 = tolua.type(arg_12_0)
	end

	local var_12_3

	if not arg_12_0 then
		var_12_3 = var_12_0:create()
	elseif var_12_2 == "string" then
		if string.byte(arg_12_0) == 35 then
			local var_12_4 = var_0_0.newSpriteFrame(string.sub(arg_12_0, 2))

			if var_12_4 then
				if arg_12_3 and arg_12_3.capInsets then
					var_12_3 = var_12_0:createWithSpriteFrame(var_12_4, arg_12_3.capInsets)
				else
					var_12_3 = var_12_0:createWithSpriteFrame(var_12_4)
				end
			end
		elseif var_0_0.TEXTURES_PIXEL_FORMAT[arg_12_0] then
			cc.Texture2D:setDefaultAlphaPixelFormat(var_0_0.TEXTURES_PIXEL_FORMAT[arg_12_0])

			var_12_3 = var_12_0:create(arg_12_0)

			cc.Texture2D:setDefaultAlphaPixelFormat(cc.TEXTURE2D_PIXEL_FORMAT_RGBA8888)
		elseif arg_12_3 and arg_12_3.capInsets then
			var_12_3 = var_12_0:create(arg_12_3.capInsets, arg_12_0)
		else
			var_12_3 = var_12_0:create(arg_12_0)
		end
	elseif var_12_2 == "cc.SpriteFrame" then
		var_12_3 = var_12_0:createWithSpriteFrame(arg_12_0)
	elseif var_12_2 == "cc.Texture2D" then
		var_12_3 = var_12_0:createWithTexture(arg_12_0)
	else
		printError("display.newSprite() - invalid filename value type")

		var_12_3 = var_12_0:create()
	end

	if var_12_3 then
		if arg_12_1 and arg_12_2 then
			var_12_3:setPosition(arg_12_1, arg_12_2)
		end

		if var_12_1 then
			var_12_3:setContentSize(var_12_1)
		end
	else
		printError("display.newSprite() - create sprite failure, filename %s", tostring(arg_12_0))

		var_12_3 = var_12_0:create()
	end

	return var_12_3
end

function var_0_0.newScale9Sprite(arg_13_0, arg_13_1, arg_13_2, arg_13_3, arg_13_4)
	local var_13_0 = ccui.Scale9Sprite or cc.Scale9Sprite

	return var_0_0.newSprite(arg_13_0, arg_13_1, arg_13_2, {
		class = var_13_0,
		size = arg_13_3,
		capInsets = arg_13_4
	})
end

function var_0_0.newTilesSprite(arg_14_0, arg_14_1)
	arg_14_1 = arg_14_1 or cc.rect(0, 0, var_0_0.width, var_0_0.height)

	local var_14_0 = cc.Sprite:create(arg_14_0, arg_14_1)

	if not var_14_0 then
		printError("display.newTilesSprite() - create sprite failure, filename %s", tostring(arg_14_0))

		return
	end

	var_14_0:getTexture():setTexParameters(gl.LINEAR, gl.LINEAR, gl.REPEAT, gl.REPEAT)
	var_0_0.align(var_14_0, var_0_0.LEFT_BOTTOM, 0, 0)

	return var_14_0
end

function var_0_0.newTiledBatchNode(arg_15_0, arg_15_1, arg_15_2, arg_15_3, arg_15_4)
	arg_15_2 = arg_15_2 or cc.size(var_0_0.width, var_0_0.height)
	arg_15_3 = arg_15_3 or 0
	arg_15_4 = arg_15_4 or 0

	local var_15_0 = var_0_0.newSprite(arg_15_0):getContentSize()

	var_15_0.width = var_15_0.width - arg_15_3
	var_15_0.height = var_15_0.height - arg_15_4

	local var_15_1 = math.ceil(arg_15_2.width / var_15_0.width)
	local var_15_2 = math.ceil(arg_15_2.height / var_15_0.height)
	local var_15_3 = var_15_1 * var_15_2
	local var_15_4 = var_0_0.newBatchNode(arg_15_1, var_15_3)
	local var_15_5 = cc.size(0, 0)

	for iter_15_0 = 0, var_15_2 - 1 do
		for iter_15_1 = 0, var_15_1 - 1 do
			var_15_5.width = var_15_5.width + var_15_0.width

			local var_15_6 = var_0_0.newSprite(arg_15_0):align(var_0_0.LEFT_BOTTOM, iter_15_1 * var_15_0.width, iter_15_0 * var_15_0.height):addTo(var_15_4)
		end

		var_15_5.height = var_15_5.height + var_15_0.height
	end

	var_15_4:setContentSize(var_15_5)

	return var_15_4, var_15_5.width, var_15_5.height
end

function var_0_0.newFilteredSprite(arg_16_0, arg_16_1, arg_16_2)
	local var_16_0 = {
		class = cc.FilteredSpriteWithOne
	}
	local var_16_1 = {
		class = cc.FilteredSpriteWithMulti
	}

	if not arg_16_1 then
		return var_0_0.newSprite(arg_16_0, nil, nil, var_16_0)
	end

	local var_16_2
	local var_16_3 = type(arg_16_1)

	if var_16_3 == "userdata" then
		var_16_3 = tolua.type(arg_16_1)
	end

	if var_16_3 == "string" then
		var_16_2 = var_0_0.newSprite(arg_16_0, nil, nil, var_16_0)
		arg_16_1 = filter.newFilter(arg_16_1, arg_16_2)

		var_16_2:setFilter(arg_16_1)
	elseif var_16_3 == "table" then
		assert(#arg_16_1 > 1, "display.newFilteredSprite() - Please give me 2 or more filters!")

		var_16_2 = var_0_0.newSprite(arg_16_0, nil, nil, var_16_1)

		if type(arg_16_1[1]) == "string" then
			var_16_2:setFilters(filter.newFilters(arg_16_1, arg_16_2))
		else
			local var_16_4 = cc.Array:create()

			for iter_16_0 in ipairs(arg_16_1) do
				var_16_4:addObject(arg_16_1[iter_16_0])
			end

			var_16_2:setFilters(var_16_4)
		end
	elseif var_16_3 == "Array" then
		var_16_2 = var_0_0.newSprite(arg_16_0, nil, nil, var_16_1)

		var_16_2:setFilters(arg_16_1)
	else
		var_16_2 = var_0_0.newSprite(arg_16_0, nil, nil, var_16_0)

		var_16_2:setFilter(arg_16_1)
	end

	return var_16_2
end

function var_0_0.newGraySprite(arg_17_0, arg_17_1)
	return var_0_0.newFilteredSprite(arg_17_0, "GRAY", arg_17_1)
end

function var_0_0.newDrawNode()
	return cc.DrawNode:create()
end

function var_0_0.newSolidCircle(arg_19_0, arg_19_1)
	local var_19_0 = var_0_0.newDrawNode()

	var_19_0:drawSolidCircle(cc.p(arg_19_1.x or 0, arg_19_1.y or 0), arg_19_0 or 0, arg_19_1.angle or 0, arg_19_1.segments or 50, arg_19_1.scaleX or 1, arg_19_1.scaleY or 1, arg_19_1.color or cc.c4f(0, 0, 0, 1))

	return var_19_0
end

function var_0_0.newCircle(arg_20_0, arg_20_1)
	arg_20_1 = checktable(arg_20_1)

	local function var_20_0(arg_21_0)
		local var_21_0 = arg_20_1.segments or 32
		local var_21_1 = 0
		local var_21_2 = math.pi * 2
		local var_21_3 = arg_20_1.x or 0
		local var_21_4 = arg_20_1.y or 0

		if arg_20_1.startAngle then
			var_21_1 = math.angle2radian(arg_20_1.startAngle)
		end

		if arg_20_1.endAngle then
			var_21_2 = var_21_1 + math.angle2radian(arg_20_1.endAngle)
		end

		local var_21_5 = 2 * math.pi / var_21_0
		local var_21_6 = {}

		for iter_21_0 = 1, var_21_0 do
			local var_21_7 = var_21_1 + iter_21_0 * var_21_5

			if var_21_2 < var_21_7 then
				break
			end

			var_21_6[#var_21_6 + 1] = {
				var_21_3 + arg_21_0 * math.cos(var_21_7),
				var_21_4 + arg_21_0 * math.sin(var_21_7)
			}
		end

		return var_21_6
	end

	local var_20_1 = var_20_0(arg_20_0)
	local var_20_2 = var_0_0.newPolygon(var_20_1, arg_20_1)

	if var_20_2 then
		var_20_2.radius = arg_20_0
		var_20_2.params = arg_20_1

		function var_20_2.setRadius(arg_22_0, arg_22_1)
			arg_22_0:clear()

			local var_22_0 = var_20_0(arg_22_1)

			var_0_0.newPolygon(var_22_0, arg_20_1, arg_22_0)
		end

		function var_20_2.setLineColor(arg_23_0, arg_23_1)
			arg_23_0:clear()

			local var_23_0 = var_20_0(arg_20_0)

			arg_20_1.borderColor = arg_23_1

			var_0_0.newPolygon(var_23_0, arg_20_1, arg_23_0)
		end
	end

	return var_20_2
end

function var_0_0.newRect(arg_24_0, arg_24_1)
	local var_24_0 = 0
	local var_24_1 = 0
	local var_24_2
	local var_24_3
	local var_24_4 = arg_24_0.x or 0
	local var_24_5 = arg_24_0.y or 0
	local var_24_6 = arg_24_0.height
	local var_24_7 = arg_24_0.width
	local var_24_8 = {
		{
			var_24_4,
			var_24_5
		},
		{
			var_24_4 + var_24_7,
			var_24_5
		},
		{
			var_24_4 + var_24_7,
			var_24_5 + var_24_6
		},
		{
			var_24_4,
			var_24_5 + var_24_6
		}
	}

	return var_0_0.newPolygon(var_24_8, arg_24_1)
end

function var_0_0.newRoundedRect(arg_25_0, arg_25_1, arg_25_2)
	local var_25_0 = arg_25_1 or 1
	local var_25_1 = math.ceil(var_25_0)
	local var_25_2 = math.pi * 0.5 / var_25_1
	local var_25_3 = {}

	for iter_25_0 = 0, var_25_1 do
		local var_25_4 = iter_25_0 * var_25_2

		var_25_3[iter_25_0] = cc.p(math.round(math.cos(var_25_4) * var_25_0 * 10) / 10, math.round(math.sin(var_25_4) * var_25_0 * 10) / 10)
	end

	local var_25_5 = {}
	local var_25_6 = cc.p(0, 0)
	local var_25_7 = cc.p(var_25_0, arg_25_0.height - var_25_0)

	for iter_25_1 = 0, var_25_1 do
		local var_25_8 = iter_25_1

		var_25_5[#var_25_5 + 1] = cc.p(var_25_7.x - var_25_3[var_25_8].x, var_25_7.y + var_25_3[var_25_8].y)
	end

	local var_25_9 = cc.p(arg_25_0.width - var_25_0, arg_25_0.height - var_25_0)

	for iter_25_2 = 0, var_25_1 do
		local var_25_10 = var_25_1 - iter_25_2

		var_25_5[#var_25_5 + 1] = cc.p(var_25_9.x + var_25_3[var_25_10].x, var_25_9.y + var_25_3[var_25_10].y)
	end

	local var_25_11 = cc.p(arg_25_0.width - var_25_0, var_25_0)

	for iter_25_3 = 0, var_25_1 do
		local var_25_12 = iter_25_3

		var_25_5[#var_25_5 + 1] = cc.p(var_25_11.x + var_25_3[var_25_12].x, var_25_11.y - var_25_3[var_25_12].y)
	end

	local var_25_13 = cc.p(var_25_0, var_25_0)

	for iter_25_4 = 0, var_25_1 do
		local var_25_14 = var_25_1 - iter_25_4

		var_25_5[#var_25_5 + 1] = cc.p(var_25_13.x - var_25_3[var_25_14].x, var_25_13.y - var_25_3[var_25_14].y)
	end

	var_25_5[#var_25_5 + 1] = cc.p(var_25_5[1].x, var_25_5[1].y)
	arg_25_2 = checktable(arg_25_2)

	local var_25_15 = arg_25_2.borderWidth or 0.5
	local var_25_16 = arg_25_2.fillColor or cc.c4f(1, 1, 1, 1)
	local var_25_17 = arg_25_2.borderColor or cc.c4f(1, 1, 1, 1)
	local var_25_18 = cc.DrawNode:create()

	var_25_18:drawPolygon(var_25_5, #var_25_5, var_25_16, var_25_15, var_25_17)
	var_25_18:setContentSize(arg_25_0)
	var_25_18:setAnchorPoint(cc.p(0.5, 0.5))

	return var_25_18
end

function var_0_0.newLine(arg_26_0, arg_26_1)
	local var_26_0
	local var_26_1
	local var_26_2
	local var_26_3

	if not arg_26_1 then
		var_26_1 = cc.c4f(0, 0, 0, 1)
		var_26_0 = 0.5
		var_26_3 = 1
	else
		var_26_1 = arg_26_1.borderColor or cc.c4f(0, 0, 0, 1)
		var_26_0 = arg_26_1.borderWidth and arg_26_1.borderWidth / 2 or 0.5
		var_26_3 = checknumber(arg_26_1.scale or 1)
	end

	for iter_26_0, iter_26_1 in ipairs(arg_26_0) do
		iter_26_1 = cc.p(iter_26_1[1] * var_26_3, iter_26_1[2] * var_26_3)
		arg_26_0[iter_26_0] = iter_26_1
	end

	local var_26_4 = cc.DrawNode:create()

	var_26_4:drawSegment(arg_26_0[1], arg_26_0[2], var_26_0, var_26_1)

	return var_26_4
end

function var_0_0.newPolygon(arg_27_0, arg_27_1, arg_27_2)
	arg_27_1 = checktable(arg_27_1)

	local var_27_0 = checknumber(arg_27_1.scale or 1)
	local var_27_1 = checknumber(arg_27_1.borderWidth or 0.5)
	local var_27_2 = arg_27_1.fillColor or cc.c4f(1, 1, 1, 0)
	local var_27_3 = arg_27_1.borderColor or cc.c4f(0, 0, 0, 1)
	local var_27_4 = {}

	for iter_27_0, iter_27_1 in ipairs(arg_27_0) do
		var_27_4[iter_27_0] = {
			x = iter_27_1[1] * var_27_0,
			y = iter_27_1[2] * var_27_0
		}
	end

	arg_27_2 = arg_27_2 or cc.DrawNode:create()

	arg_27_2:drawPolygon(var_27_4, {
		fillColor = var_27_2,
		borderWidth = var_27_1,
		borderColor = var_27_3
	})

	if arg_27_2 then
		function arg_27_2.setLineStipple(arg_28_0)
			return
		end

		function arg_27_2.setLineStippleEnabled(arg_29_0)
			return
		end

		function arg_27_2.setLineColor(arg_30_0, arg_30_1)
			return
		end
	end

	return arg_27_2
end

function var_0_0.newConvexPolygon(arg_31_0, arg_31_1, arg_31_2)
	arg_31_1 = checktable(arg_31_1)

	local var_31_0 = checknumber(arg_31_1.scale or 1)
	local var_31_1 = checknumber(arg_31_1.borderWidth or 0.5)
	local var_31_2 = arg_31_1.center
	local var_31_3 = arg_31_1.borderColor or cc.c4f(0, 0, 0, 1)
	local var_31_4 = arg_31_1.vertColors
	local var_31_5 = arg_31_1.centerColor

	if arg_31_0 == nil or var_31_2 == nil or var_31_4 == nil or var_31_5 == nil then
		return nil
	end

	local var_31_6 = {}

	for iter_31_0, iter_31_1 in ipairs(arg_31_0) do
		var_31_6[iter_31_0] = {
			x = iter_31_1[1] * var_31_0,
			y = iter_31_1[2] * var_31_0
		}
	end

	arg_31_2 = arg_31_2 or cc.DrawNode:create()

	arg_31_2:drawConvexPolygon(var_31_6, {
		center = var_31_2,
		centerColor = var_31_5,
		borderWidth = var_31_1,
		borderColor = var_31_3,
		vertColors = var_31_4
	})

	if arg_31_2 then
		function arg_31_2.setLineStipple(arg_32_0)
			return
		end

		function arg_31_2.setLineStippleEnabled(arg_33_0)
			return
		end

		function arg_31_2.setLineColor(arg_34_0, arg_34_1)
			return
		end
	end

	return arg_31_2
end

function var_0_0.newBMFontLabel(arg_35_0)
	assert(type(arg_35_0) == "table", "[framework.display] newBMFontLabel() invalid params")

	local var_35_0 = tostring(arg_35_0.text)
	local var_35_1 = arg_35_0.font
	local var_35_2 = arg_35_0.align or cc.TEXT_ALIGNMENT_LEFT
	local var_35_3 = arg_35_0.maxLineWidth or 0
	local var_35_4 = arg_35_0.offsetX or 0
	local var_35_5 = arg_35_0.offsetY or 0
	local var_35_6 = arg_35_0.x
	local var_35_7 = arg_35_0.y

	assert(var_35_1 ~= nil, "framework.display.newBMFontLabel() - not set font")

	local var_35_8 = cc.Label:createWithBMFont(var_35_1, var_35_0, var_35_2, var_35_3, cc.p(var_35_4, var_35_5))

	if not var_35_8 then
		return
	end

	if type(var_35_6) == "number" and type(var_35_7) == "number" then
		var_35_8:setPosition(var_35_6, var_35_7)
	end

	return var_35_8
end

function var_0_0.newTTFLabel(arg_36_0)
	assert(type(arg_36_0) == "table", "[framework.display] newTTFLabel() invalid params")

	local var_36_0 = tostring(arg_36_0.text)
	local var_36_1 = arg_36_0.font or var_0_0.DEFAULT_TTF_FONT
	local var_36_2 = arg_36_0.size or var_0_0.DEFAULT_TTF_FONT_SIZE
	local var_36_3 = arg_36_0.color or var_0_0.COLOR_WHITE
	local var_36_4 = arg_36_0.align or cc.TEXT_ALIGNMENT_LEFT
	local var_36_5 = arg_36_0.valign or cc.VERTICAL_TEXT_ALIGNMENT_TOP
	local var_36_6 = arg_36_0.x
	local var_36_7 = arg_36_0.y
	local var_36_8 = arg_36_0.dimensions or cc.size(0, 0)

	assert(type(var_36_2) == "number", "[framework.display] newTTFLabel() invalid params.size")

	local var_36_9

	if cc.FileUtils:getInstance():isFileExist(var_36_1) then
		var_36_9 = cc.Label:createWithTTF(var_36_0, var_36_1, var_36_2, var_36_8, var_36_4, var_36_5)

		if var_36_9 then
			var_36_9:setColor(var_36_3)
		end
	else
		var_36_9 = cc.Label:createWithSystemFont(var_36_0, var_36_1, var_36_2, var_36_8, var_36_4, var_36_5)

		if var_36_9 then
			var_36_9:setTextColor(var_36_3)
		end
	end

	if var_36_9 and var_36_6 and var_36_7 then
		var_36_9:setPosition(var_36_6, var_36_7)
	end

	return var_36_9
end

function var_0_0.align(arg_37_0, arg_37_1, arg_37_2, arg_37_3)
	arg_37_0:setAnchorPoint(var_0_0.ANCHOR_POINTS[arg_37_1])

	if arg_37_2 and arg_37_3 then
		arg_37_0:setPosition(arg_37_2, arg_37_3)
	end
end

function var_0_0.addImageAsync(arg_38_0, arg_38_1)
	var_0_2:addImageAsync(arg_38_0, arg_38_1)
end

function var_0_0.addSpriteFrames(arg_39_0, arg_39_1, arg_39_2)
	local var_39_0 = type(arg_39_2) == "function"
	local var_39_1

	if var_39_0 then
		function var_39_1()
			local var_40_0 = var_0_2:getTextureForKey(arg_39_1)

			assert(var_40_0, string.format("The texture %s, %s is unavailable.", arg_39_0, arg_39_1))
			var_0_3:addSpriteFrames(arg_39_0, var_40_0)
			arg_39_2(arg_39_0, arg_39_1)
		end
	end

	if var_0_0.TEXTURES_PIXEL_FORMAT[arg_39_1] then
		cc.Texture2D:setDefaultAlphaPixelFormat(var_0_0.TEXTURES_PIXEL_FORMAT[arg_39_1])

		if var_39_0 then
			var_0_2:addImageAsync(arg_39_1, var_39_1)
		else
			var_0_3:addSpriteFrames(arg_39_0, arg_39_1)
		end

		cc.Texture2D:setDefaultAlphaPixelFormat(cc.TEXTURE2_D_PIXEL_FORMAT_BGR_A8888)
	elseif var_39_0 then
		var_0_2:addImageAsync(arg_39_1, var_39_1)
	else
		var_0_3:addSpriteFrames(arg_39_0, arg_39_1)
	end
end

function var_0_0.removeSpriteFramesWithFile(arg_41_0, arg_41_1)
	var_0_3:removeSpriteFramesFromFile(arg_41_0)

	if arg_41_1 then
		var_0_0.removeSpriteFrameByImageName(arg_41_1)
	end
end

function var_0_0.setTexturePixelFormat(arg_42_0, arg_42_1)
	var_0_0.TEXTURES_PIXEL_FORMAT[arg_42_0] = arg_42_1
end

function var_0_0.removeSpriteFrameByImageName(arg_43_0)
	var_0_3:removeSpriteFrameByName(arg_43_0)
	cc.Director:getInstance():getTextureCache():removeTextureForKey(arg_43_0)
end

function var_0_0.newBatchNode(arg_44_0, arg_44_1)
	return cc.SpriteBatchNode:create(arg_44_0, arg_44_1 or 100)
end

function var_0_0.newSpriteFrame(arg_45_0)
	local var_45_0 = var_0_3:getSpriteFrame(arg_45_0)

	if not var_45_0 then
		printError("display.newSpriteFrame() - invalid frameName %s", tostring(arg_45_0))
	end

	return var_45_0
end

function var_0_0.newFrames(arg_46_0, arg_46_1, arg_46_2, arg_46_3)
	local var_46_0 = {}
	local var_46_1 = 1
	local var_46_2 = arg_46_1 + arg_46_2 - 1

	if arg_46_3 then
		var_46_2, arg_46_1 = arg_46_1, var_46_2
		var_46_1 = -1
	end

	for iter_46_0 = arg_46_1, var_46_2, var_46_1 do
		local var_46_3 = string.format(arg_46_0, iter_46_0)
		local var_46_4 = var_0_3:getSpriteFrame(var_46_3)

		if not var_46_4 then
			printError("display.newFrames() - invalid frame, name %s", tostring(var_46_3))

			return
		end

		var_46_0[#var_46_0 + 1] = var_46_4
	end

	return var_46_0
end

function var_0_0.newAnimation(arg_47_0, arg_47_1)
	local var_47_0 = #arg_47_0

	arg_47_1 = arg_47_1 or 1 / var_47_0

	return cc.Animation:createWithSpriteFrames(arg_47_0, arg_47_1)
end

function var_0_0.setAnimationCache(arg_48_0, arg_48_1)
	var_0_4:addAnimation(arg_48_1, arg_48_0)
end

function var_0_0.getAnimationCache(arg_49_0)
	return var_0_4:getAnimation(arg_49_0)
end

function var_0_0.removeAnimationCache(arg_50_0)
	var_0_4:removeAnimation(arg_50_0)
end

function var_0_0.removeUnusedSpriteFrames()
	var_0_3:removeUnusedSpriteFrames()
	var_0_2:removeUnusedTextures()
end

var_0_0.PROGRESS_TIMER_BAR = 1
var_0_0.PROGRESS_TIMER_RADIAL = 0

function var_0_0.newProgressTimer(arg_52_0, arg_52_1)
	if type(arg_52_0) == "string" then
		arg_52_0 = var_0_0.newSprite(arg_52_0)
	end

	local var_52_0 = cc.ProgressTimer:create(arg_52_0)

	var_52_0:setType(arg_52_1)

	return var_52_0
end

function var_0_0.captureScreen(arg_53_0, arg_53_1)
	var_0_1:captureScreen(function(arg_54_0)
		if arg_54_0 then
			local var_54_0 = cc.FileUtils:getInstance():getWritablePath() .. arg_53_1

			arg_54_0:saveToFile(var_54_0)
			arg_53_0(true, var_54_0)
		else
			arg_53_0(false)
		end
	end)
end

return var_0_0
