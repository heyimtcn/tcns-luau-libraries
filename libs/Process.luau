--!nocheck

local Signal = require(script.Parent.Signal)
local table = require(script.Parent.Table)
local Stream = require(script.Parent.Stream)

export type Process = {
	NewRun:Signal.Signal<>,
	RunFinished:Signal.Signal<FinishedProcessInfo>,
	Running:boolean,
	RunningId:any?,
	RunningUserdata:any?,
	In:Stream.Stream<...any?>?,
	Out:Stream.Stream<...any?>?,
	Run:(self:Process,fn:(userdata:any?,cleanup:{any},finish:() -> (),in_stream:Stream.Stream<...any?>,out_stream:Stream.Stream<...any?>) -> (),id:any?) -> (),
	Kill:(self:Process) -> ()
}

export type FinishedProcessInfo = {
	Killed:boolean,
	Id:any?,
	Userdata:any?,
	In:Stream.Stream<...any?>,
	Out:Stream.Stream<...any?>
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
		RunningUserdata = nil,
		In = nil,
		Out = nil,
		_cleanup_fn = nil
	},prototype)
end

function prototype:Run(fn,id,userdata)
	if self.Running then
		error(`A process is already running ({self.RunningId})`,2)
	end
	local cleanup_tbl = {}
	local in_stream = Stream.new()
	local out_stream = Stream.new()
	local function finish_fn(killed:boolean)
		local finished_process_info = {
			Killed = killed,
			Id = self.RunningId,
			Userdata = self.RunningUserdata,
			In = self.In,
			Out = self.Out
		}
		table.cleanup(cleanup_tbl)
		self.Running = false
		self.RunningId = nil
		self.RunningUserdata = nil
		self._cleanup_fn = nil
		self.In = nil
		self.Out = nil
		self.RunFinished:Fire(finished_process_info)
	end
	self.Running = true
	self.RunningId = id
	self.RunningUserdata = userdata
	self.In = in_stream
	self.Out = out_stream
	task.spawn(function()
		fn(userdata,cleanup_tbl,function()
			local thread = coroutine.running()
			task.defer(function()
				task.cancel(thread)
				finish_fn(false)
			end)
			coroutine.yield()
		end,in_stream,out_stream)
	end)
	self._cleanup_fn = function()
		finish_fn(true)
	end
	self.NewRun:Fire()
end

function prototype:Kill()
	if self._cleanup_fn then
		self._cleanup_fn()
	end
end

return Process
