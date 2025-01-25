--!nocheck

local Signal = require(script.Parent.Signal)
local table = require(script.Parent.Table)
local Stream = require(script.Parent.Stream)

export type Process = {
	NewRun:Signal.Signal<any?>,
	RunFinished:Signal.Signal<boolean,any?>,
	Running:boolean,
	RunningId:any?,
	In:Stream.Stream<...any?>?,
	Out:Stream.Stream<...any?>?,
	Run:(self:Process,fn:(cleanup:{any},finish:() -> (),in_stream:Stream.Stream<...any?>,out_stream:Stream.Stream<...any?>) -> (),id:any?) -> (),
	Kill:(self:Process) -> ()
}

local Process = {}

local prototype:Process = {}
prototype.__index = prototype
Process.prototype = prototype
Process.ClassName = "Process"
prototype.Class = Process
prototype.ClassName = "Process"

function Process.new():Process
	return setmetatable({
		NewRun = Signal.new(),
		RunFinished = Signal.new(),
		Running = false,
		RunningId = nil,
		In = nil,
		Out = nil,
		_cleanup_fn = nil
	},prototype)
end

function prototype:Run(fn,id)
	if self.Running then
		error("Process is already running",2)
	end
	local cleanup_tbl = {}
	local in_stream = Stream.new()
	local out_stream = Stream.new()
	local function finish_fn(killed:boolean)
		table.cleanup(cleanup_tbl)
		self.Running = false
		self.RunningId = nil
		self._cleanup_fn = nil
		self.In:Destroy()
		self.In = nil
		self.Out:Destroy()
		self.Out = nil
		self.RunFinished:Fire(killed,id)
	end
	task.spawn(function()
		fn(cleanup_tbl,function()
			local thread = coroutine.running()
			task.defer(function()
				task.cancel(thread)
				finish_fn(false)
			end)
			coroutine.yield()
		end,in_stream,out_stream)
		finish_fn(false)
	end)
	self._cleanup_fn = function()
		finish_fn(true)
	end
	self.Running = true
	self.RunningId = id
	self.In = in_stream
	self.Out = out_stream
	self.NewRun:Fire(id)
end

function prototype:Kill()
	if self._cleanup_fn then
		self._cleanup_fn()
	end
end

return Process