--!nocheck

local RunService = game:GetService("RunService")
local Signal = require(script.Signal)
local PropertyHandler = require(script.PropertyHandler)
local LerpUtils = require(script.LerpUtils)
local table = require(script.Table)

export type Settings = {
	Lenght:number,
	Ease:(number) -> number,
	StepEach:number?,
	EventHandler:RBXScriptSignal|Signal.Signal<>|nil,
	TargetValues:{[Instance|{[string]:any}]:{[string]:any}},
	FixedStartValues:{[Instance|{[string]:any}]:{[string]:any}}?,
}

export type Tween = {
	PropertyChanged:Signal.Signal<string>,
	GetPropertyChangedSignal:(self:Tween,name:string) -> Signal.Signal<>,
	Completed:Signal.Signal<boolean>,
	Playing:boolean,
	Paused:boolean,
	Started:boolean,
	Finished:boolean,
	Lenght:number,
	Reversed:boolean,
	Ease:(number) -> number,
	StepEach:number,
	Progress:number,
	EventHandler:Signal.Signal<>,
	TargetValues:{[Instance|{[string]:any}]:{[string]:any}},
	StartValues:{[Instance|{[string]:any}]:{[string]:any}},
	Play:(self:Tween,reverse:boolean?) -> (),
	Pause:(self:Tween) -> (),
	Stop:(self:Tween) -> (),
	Resume:(self:Tween,reverse:boolean?) -> ()
}

local TweenPlus = {
	LerpUtils = LerpUtils
}

local prototype:Tween = {}
local object_creator = PropertyHandler.extend(prototype)
prototype.__index = prototype
TweenPlus.prototype = prototype
TweenPlus.ClassName = "TweenPlus"
prototype.Class = TweenPlus
prototype.ClassName = "TweenPlus"

TweenPlus.basic_linear = LerpUtils.enum_ease(Enum.EasingStyle.Linear,Enum.EasingDirection.InOut)

function TweenPlus.new_tween(setts:Settings):Tween
	local objs = {}
	local start_values:{[Instance|{[string]:any}]:{[string]:any}} = {}
	if setts.FixedStartValues then
		for obj, props in pairs(setts.FixedStartValues) do
			start_values[obj] = {}
			table.insert(objs,obj)
			for prop_name, default_value in pairs(props) do
				start_values[obj][prop_name] = default_value
			end
		end
	end
	for obj, props in pairs(setts.TargetValues) do
		if not table.haskey(start_values,obj) then
			start_values[obj] = {}
		end
		for prop_name, val in pairs(props) do
			if not table.haskey(start_values[obj],prop_name) then
				start_values[obj][prop_name] = obj[prop_name]
			end
		end
	end
	return object_creator({
		Playing = false,
		Paused = false,
		Reversed = false,
		Lenght = setts.Lenght,
		Ease = setts.Ease,
		StepEach = setts.StepEach or 0,
		Progress = 0,
		EventHandler = if Signal.is(setts.EventHandler) then setts.EventHandler else Signal.wrap(setts.EventHandler or RunService.Heartbeat),
		TargetValues = setts.TargetValues,
		StartValues = start_values,
		Completed = Signal.new(),
		Started = false,
		Finished = false,
		_stop = false,
		_complete_on_stop = true
	})
end

function TweenPlus.simple(obj:Instance|{[string]:any},target_values:{[string]:any},lenght:number,ease:(number) -> number):Tween
	return TweenPlus.new_tween({
		Lenght = lenght,
		Ease = ease,
		TargetValues = {
			[obj] = target_values
		}
	})
end

function TweenPlus.simple_multi(target_values:{[Instance|{[string]:any}]:{[string]:any}},lenght:number,ease:(number) -> number):Tween
	return TweenPlus.new_tween({
		Lenght = lenght,
		Ease = ease,
		TargetValues = target_values
	})
end

function TweenPlus.is(obj:any):boolean
	return type(obj) == "table" and getmetatable(obj).ClassName == "TweenPlus"
end

function prototype:Play(reverse:boolean?)
	self._objs = table.keys(self.TargetValues)
	self.Reversed = if reverse ~= nil then reverse else false
	if self.Playing or self.Paused then
		self.Playing = true
		self.Paused = false
		self.Progress = 0
		self.Completed:Fire(true)
		return
	end
	local self:Tween = self
	local last_step = os.clock()
	self._start_time = last_step
	self._observers = {}
	self._ignore_observer_set = {
		progress = false
	}
	self._observers.progress_set_conn = self:GetPropertyChangedSignal("Progress"):Connect(function()
		if self._ignore_observer_set.progress then
			self._ignore_observer_set.progress = false
			return
		end
		self._start_time = os.clock() - self.Progress * self.Lenght
	end)
	
	self._observers.reversed_set_conn = self:GetPropertyChangedSignal("Reversed"):Connect(function()
		self.Progress = 1 - self.Progress
	end)
	self._handler_fn = function()
		if not self.Playing or self.Paused then
			return
		end
		local now = os.clock()
		if last_step + self.StepEach > now then
			return
		end
		last_step = now
		local progress = (now - self._start_time) / self.Lenght
		local function stop(cancelled:boolean)
			if self.Progress ~= progress then
				self._ignore_observer_set.progress = true
				self.Progress = progress
			end
			self.Playing = false
			self.Paused = false
			for _, conn:Signal.Connection<any> in pairs(self._observers) do
				conn:Disconnect()
			end
			self._handler_conn:Disconnect()
			self.Reversed = false
			self.Finished = true
			self.Completed:Fire(cancelled)
		end
		if self._stop then
			stop(true)
			self._stop = false
			return
		end
		if progress > 1 then
			progress = 1
		end
		for _, obj:Instance|{[string]:any} in pairs(self._objs) do
			for prop_name:string, prop_target:any in pairs(self.TargetValues[obj]) do
				if self.Reversed then
					obj[prop_name] = LerpUtils.lerp(self.Ease(1-progress),prop_target,self.StartValues[obj][prop_name])
				else
					obj[prop_name] = LerpUtils.lerp(self.Ease(progress),prop_target,self.StartValues[obj][prop_name])
				end
			end
		end
		self._ignore_observer_set.progress = true
		self.Progress = progress
		if progress == 1 then
			stop(false)
		end
	end
	self.Playing = true
	self.Paused = false
	self.Started = true
	self._handler_conn = self.EventHandler:Connect(self._handler_fn)
end

function prototype:Stop()
	self._stop = true
end

function prototype:Pause()
	self.Playing = false
	self.Paused = true
end

function prototype:Resume(reverse:boolean?)
	if self.Paused then
		self.Playing = true
		self.Paused = false
		if reverse ~= nil then
			self.Reversed = reverse
		end
		if not reverse then
			self._start_time = os.clock() - self.Progress * self.Lenght
		end
	else
		self:Play()
	end
end

return TweenPlus