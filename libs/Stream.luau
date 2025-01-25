--!nocheck

local Signal = require(script.Parent.Signal)

export type Stream<T...> = {
	Appended:Signal.Signal<T...>,
	Append:(self:Stream<T...>,T...) -> (),
	List:(self:Stream<T...>) -> {{any}},
	Destroy:(self:Stream<T...>) -> ()
}

local Stream = {
	STREAM_END = "STREAM_END"
}
local prototype:Stream<any> = {}
prototype.__index = prototype
Stream.prototype = prototype
Stream.ClassName = "Stream"
prototype.Class = Stream
prototype.ClassName = "Stream"

function Stream.new<T...>(fn:((stream:Stream<T...>) -> ())?):Stream<T...>
	local stream = setmetatable({
		_arr = {},
		Appended = Signal.new()
	},prototype)
	if fn then
		task.defer(fn,stream)
	end
	return stream
end

function Stream.from_signal<T...>(sig:Signal.Signal<T...>):Stream<T...>
	return Stream.new(function(stream)
		sig:Connect(function(...)
			stream:Append(...)
		end)
	end)
end

function Stream.is(obj:any):boolean
	return type(obj) == "table" and getmetatable(obj).ClassName == "Stream"
end

function prototype:Append(...)
	table.insert(self._arr,{...})
	self.Appended:Fire(...)
end

function prototype:List()
	return table.clone(self._arr)
end

function prototype:Destroy()
	self.Appended:Destroy()
	setmetatable(self,nil)
	table.clear(self)
end

return Stream