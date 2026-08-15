local var_0_0 = {}
local var_0_1 = {
	GRAY = {
		cc.GrayFilter
	},
	RGB = {
		cc.RGBFilter,
		3,
		{
			1,
			1,
			1
		}
	},
	HUE = {
		cc.HueFilter,
		1,
		{
			0
		}
	},
	BRIGHTNESS = {
		cc.BrightnessFilter,
		1,
		{
			0
		}
	},
	SATURATION = {
		cc.SaturationFilter,
		1,
		{
			1
		}
	},
	CONTRAST = {
		cc.ContrastFilter,
		1,
		{
			1
		}
	},
	EXPOSURE = {
		cc.ExposureFilter,
		1,
		{
			0
		}
	},
	GAMMA = {
		cc.GammaFilter,
		1,
		{
			1
		}
	},
	HAZE = {
		cc.HazeFilter,
		2,
		{
			0,
			0
		}
	},
	SEPIA = {
		cc.SepiaFilter
	},
	GAUSSIAN_VBLUR = {
		cc.GaussianVBlurFilter,
		1,
		{
			0
		}
	},
	GAUSSIAN_HBLUR = {
		cc.GaussianHBlurFilter,
		1,
		{
			0
		}
	},
	ZOOM_BLUR = {
		cc.ZoomBlurFilter,
		3,
		{
			1,
			0.5,
			0.5
		}
	},
	MOTION_BLUR = {
		cc.MotionBlurFilter,
		2,
		{
			1,
			0
		}
	},
	SHARPEN = {
		cc.SharpenFilter,
		2,
		{
			0,
			0
		}
	},
	MASK = {
		cc.MaskFilter,
		1
	},
	DROP_SHADOW = {
		cc.DropShadowFilter,
		1
	},
	CUSTOM = {
		cc.CustomFilter,
		1
	}
}

;({}).GAUSSIAN_BLUR = {}

function var_0_0.newFilter(arg_1_0, arg_1_1)
	local var_1_0 = var_0_1[arg_1_0]

	assert(var_1_0, "filter.newFilter() - filter " .. arg_1_0 .. " is not found.")

	local var_1_1, var_1_2, var_1_3 = unpack(var_1_0)

	if arg_1_0 == "CUSTOM" then
		return var_1_1:create(arg_1_1)
	end

	local var_1_4 = arg_1_1 and #arg_1_1 or 0

	if var_1_2 == nil then
		if var_1_4 == 0 then
			return var_1_1:create()
		end
	elseif var_1_2 == 0 then
		return var_1_1:create()
	else
		if var_1_4 == 0 then
			return var_1_1:create(unpack(var_1_3))
		end

		assert(var_1_4 == var_1_2, string.format("filter.newFilter() - the parameters have a wrong amount! Expect %d, get %d.", var_1_2, var_1_4))
	end

	return var_1_1:create(unpack(arg_1_1))
end

function var_0_0.newFilters(arg_2_0, arg_2_1)
	assert(#arg_2_0 == #arg_2_1, "filter.newFilters() - Please ensure the filters and the parameters have the same amount.")

	local var_2_0 = {}

	for iter_2_0 in ipairs(arg_2_0) do
		table.insert(var_2_0, var_0_0.newFilter(arg_2_0[iter_2_0], arg_2_1[iter_2_0]))
	end

	return var_2_0
end

return var_0_0
