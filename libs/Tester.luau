local Stream = require(script.Parent.Stream)

local Tester = {
	Enum = {
		ErrorType = {
			LUA_ERROR = "LUA_ERROR",
			ASSERT_ERROR = "ASSERT_ERROR"
		}
	}
}

function Tester.test(tests:{[string]:() -> (boolean, string?)}):Stream.Stream<string|any,boolean?,"LUA_ERROR"|"ASSERT_ERROR"|nil,string?>
	return Stream.new(function(stream)
		for name, test in pairs(tests) do
			local success, val_or_err, func_err_msg = pcall(function()
				return test()
			end)
			if success then
				if val_or_err then
					stream:Append(name,true)
				else
					stream:Append(name,false,"ASSERT_ERROR",func_err_msg)
				end
			else
				stream:Append(name,false,"LUA_ERROR",val_or_err)
			end
		end
		stream:Append(Stream.STREAM_END)
	end)
end

function Tester.log(tests:{[string]:() -> (boolean, string?)})
	local stream = Tester.test(tests)
	local conn
	conn = stream.Appended:Connect(function(name,success,error_type,error_msg)
		if name == Stream.STREAM_END then
			conn:Disconnect()
			return
		end
		if success then
			print(`OK {name}`)
		else
			if error_type == "ASSERT_ERROR" then
				if error_msg then
					warn(`ASSERT_ERROR {name}: {error_msg}`)
				else
					warn(`ASSERT_ERROR {name}`)
				end
			else
				warn(`LUA_ERROR {name}: {error_msg}`)
			end
		end
	end)
end

return Tester
