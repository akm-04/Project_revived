if not gl then
	return
end

function gl.createTexture()
	return {
		texture_id = gl._createTexture()
	}
end

function gl.createBuffer()
	return {
		buffer_id = gl._createBuffer()
	}
end

function gl.createRenderbuffer()
	return {
		renderbuffer_id = gl._createRenderuffer()
	}
end

function gl.createFramebuffer()
	return {
		framebuffer_id = gl._createFramebuffer()
	}
end

function gl.createProgram()
	return {
		program_id = gl._createProgram()
	}
end

function gl.createShader(arg_6_0)
	return {
		shader_id = gl._createShader(arg_6_0)
	}
end

function gl.deleteTexture(arg_7_0)
	local var_7_0 = 0

	if type(arg_7_0) == "number" then
		var_7_0 = arg_7_0
	elseif type(arg_7_0) == "table" then
		var_7_0 = arg_7_0.texture_id
	end

	gl._deleteTexture(var_7_0)
end

function gl.deleteBuffer(arg_8_0)
	local var_8_0 = 0

	if type(arg_8_0) == "number" then
		var_8_0 = arg_8_0
	elseif type(arg_8_0) == "table" then
		var_8_0 = arg_8_0.buffer_id
	end

	gl._deleteBuffer(var_8_0)
end

function gl.deleteRenderbuffer(arg_9_0)
	local var_9_0 = 0

	if type(arg_9_0) == "number" then
		var_9_0 = arg_9_0
	elseif type(arg_9_0) == "table" then
		var_9_0 = arg_9_0.renderbuffer_id
	end

	gl._deleteRenderbuffer(var_9_0)
end

function gl.deleteFramebuffer(arg_10_0)
	local var_10_0 = 0

	if type(arg_10_0) == "number" then
		var_10_0 = arg_10_0
	elseif type(arg_10_0) == "table" then
		var_10_0 = arg_10_0.framebuffer_id
	end

	gl._deleteFramebuffer(var_10_0)
end

function gl.deleteProgram(arg_11_0)
	local var_11_0 = 0

	if type(buffer) == "number" then
		var_11_0 = arg_11_0
	elseif type(arg_11_0) == "table" then
		var_11_0 = arg_11_0.program_id
	end

	gl._deleteProgram(var_11_0)
end

function gl.deleteShader(arg_12_0)
	local var_12_0 = 0

	if type(arg_12_0) == "number" then
		var_12_0 = arg_12_0
	elseif type(arg_12_0) == "table" then
		var_12_0 = arg_12_0.shader_id
	end

	gl._deleteShader(var_12_0)
end

function gl.bindTexture(arg_13_0, arg_13_1)
	local var_13_0 = 0

	if type(arg_13_1) == "number" then
		var_13_0 = arg_13_1
	elseif type(arg_13_1) == "table" then
		var_13_0 = arg_13_1.texture_id
	end

	gl._bindTexture(arg_13_0, var_13_0)
end

function gl.bindBuffer(arg_14_0, arg_14_1)
	local var_14_0 = 0

	if type(arg_14_1) == "number" then
		var_14_0 = arg_14_1
	elseif type(arg_14_1) == "table" then
		var_14_0 = arg_14_1.buffer_id
	end

	gl._bindBuffer(arg_14_0, var_14_0)
end

function gl.bindRenderBuffer(arg_15_0, arg_15_1)
	local var_15_0 = 0

	if type(arg_15_1) == "number" then
		var_15_0 = arg_15_1
	elseif type(arg_15_1) == "table" then
		var_15_0 = arg_15_1.buffer_id
	end

	gl._bindRenderbuffer(arg_15_0, var_15_0)
end

function gl.bindFramebuffer(arg_16_0, arg_16_1)
	local var_16_0 = 0

	if type(arg_16_1) == "number" then
		var_16_0 = arg_16_1
	elseif type(arg_16_1) == "table" then
		var_16_0 = arg_16_1.buffer_id
	end

	gl._bindFramebuffer(arg_16_0, var_16_0)
end

function gl.getUniform(arg_17_0, arg_17_1)
	local var_17_0 = 0
	local var_17_1 = 0

	if type(arg_17_0) == "number" then
		var_17_0 = arg_17_0
	else
		var_17_0 = arg_17_0.program_id
	end

	if type(arg_17_1) == "number" then
		var_17_1 = arg_17_1
	else
		var_17_1 = arg_17_1.location_id
	end

	return gl._getUniform(var_17_0, var_17_1)
end

function gl.compileShader(arg_18_0)
	gl._compileShader(arg_18_0.shader_id)
end

function gl.shaderSource(arg_19_0, arg_19_1)
	gl._shaderSource(arg_19_0.shader_id, arg_19_1)
end

function gl.getShaderParameter(arg_20_0, arg_20_1)
	return gl._getShaderParameter(arg_20_0.shader_id, arg_20_1)
end

function gl.getShaderInfoLog(arg_21_0)
	return gl._getShaderInfoLog(arg_21_0.shader_id)
end

function gl.attachShader(arg_22_0, arg_22_1)
	local var_22_0 = 0

	if type(arg_22_0) == "number" then
		var_22_0 = arg_22_0
	elseif type(arg_22_0) == "table" then
		var_22_0 = arg_22_0.program_id
	end

	gl._attachShader(var_22_0, arg_22_1.shader_id)
end

function gl.linkProgram(arg_23_0)
	local var_23_0 = 0

	if type(arg_23_0) == "number" then
		var_23_0 = arg_23_0
	elseif type(arg_23_0) == "table" then
		var_23_0 = arg_23_0.program_id
	end

	gl._linkProgram(var_23_0)
end

function gl.getProgramParameter(arg_24_0, arg_24_1)
	local var_24_0 = 0

	if type(arg_24_0) == "number" then
		var_24_0 = arg_24_0
	elseif type(arg_24_0) == "table" then
		var_24_0 = arg_24_0.program_id
	end

	return gl._getProgramParameter(var_24_0, arg_24_1)
end

function gl.useProgram(arg_25_0)
	local var_25_0 = 0

	if type(arg_25_0) == "number" then
		var_25_0 = arg_25_0
	elseif type(arg_25_0) == "table" then
		var_25_0 = arg_25_0.program_id
	end

	gl._useProgram(var_25_0)
end

function gl.getAttribLocation(arg_26_0, arg_26_1)
	local var_26_0 = 0

	if type(arg_26_0) == "number" then
		var_26_0 = arg_26_0
	elseif type(arg_26_0) == "table" then
		var_26_0 = arg_26_0.program_id
	end

	return gl._getAttribLocation(var_26_0, arg_26_1)
end

function gl.getUniformLocation(arg_27_0, arg_27_1)
	local var_27_0 = 0

	if type(arg_27_0) == "number" then
		var_27_0 = arg_27_0
	elseif type(arg_27_0) == "table" then
		var_27_0 = arg_27_0.program_id
	end

	return gl._getUniformLocation(var_27_0, arg_27_1)
end

function gl.getActiveAttrib(arg_28_0, arg_28_1)
	local var_28_0 = 0

	if type(arg_28_0) == "number" then
		var_28_0 = arg_28_0
	elseif type(arg_28_0) == "table" then
		var_28_0 = arg_28_0.program_id
	end

	return gl._getActiveAttrib(var_28_0, arg_28_1)
end

function gl.getActiveUniform(arg_29_0, arg_29_1)
	local var_29_0 = 0

	if type(arg_29_0) == "number" then
		var_29_0 = arg_29_0
	elseif type(arg_29_0) == "table" then
		var_29_0 = arg_29_0.program_id
	end

	return gl._getActiveUniform(var_29_0, arg_29_1)
end

function gl.getAttachedShaders(arg_30_0)
	local var_30_0 = 0

	if type(arg_30_0) == "number" then
		var_30_0 = arg_30_0
	elseif type(arg_30_0) == "table" then
		var_30_0 = arg_30_0.program_id
	end

	return gl._getAttachedShaders(var_30_0)
end

function gl.glNodeCreate()
	return cc.GLNode:create()
end
