--!nocheck

export type Locker = {
	Locked:boolean,
	Lock:(self:Locker) -> (),
	Unlock:(self:Locker) -> ()
}

local Locker = {}

local prototype:Locker = {}
prototype.__index = prototype
Locker.prototype = prototype
Locker.ClassName = "Locker"
prototype.Class = Locker
prototype.ClassName = "Locker"

function Locker.new():Locker
	local self = setmetatable({
		Locked = false,
		_queue = {},
		_current = nil
	},prototype)
	return self
end

function prototype:Lock()
	local running = coroutine.running()
	if not self._current then
		self._current = running
		self.Locked = true
		return
	end
	table.insert(self._queue,running)
	coroutine.yield()
end

function prototype:Unlock()
	if #self._queue == 0 then
		self.Locked = false
		return
	end
	local thread = self._queue[1]
	table.remove(self._queue,1)
	task.defer(thread)
end

function prototype:Destroy()
	for _, thread in self._queue do
		task.defer(thread)
	end
	table.clear(self)
end

return Locker
