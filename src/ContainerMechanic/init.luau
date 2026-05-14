--!strict

-- Container Mechanic


---------- Services ----------

local CollectionService = game:GetService("CollectionService")


---------- Class ----------

--- CollectionService wrapper for creating container-based mechanisms with custom configs.
local Class = {}
Class.__index = Class


----- Class types -----

type CFieldData<T> = {
	_isRunning: boolean,

    _configInstanceTagName: string,
	_configInstance_container: {[Instance]: Instance},
	_configInstance_parentChangedConnection: {[Instance]: RBXScriptConnection},

	_getConfigFromConfigInstanceFn: ((configInstance: Instance) -> T)?,
	_setUpContainerFn: ((container: Instance, config: T) -> ())?,
	_cleanUpContainerFn: ((container: Instance) -> ())?,
}

export type CObjectType<T> = typeof(setmetatable({} :: CFieldData<T>, Class))


----- Class fields -----

function Class.new<T>(tagName: string): CObjectType<T>
	local self = setmetatable({}, Class) :: CObjectType<T>
	self._isRunning = false
	self._configInstanceTagName = tagName
	self._configInstance_container = {}
	self._configInstance_parentChangedConnection = {}
	self._getConfigFromConfigInstanceFn = nil
	self._setUpContainerFn = nil
	self._cleanUpContainerFn = nil
	return self
end


--- Setters ---

function Class.setFunction_getConfigFromInstance<T>(self: CObjectType<T>, newFunction: (configInstance: Instance) -> T)
	self._getConfigFromConfigInstanceFn = newFunction
end

function Class.setFunction_setUpContainer<T>(self: CObjectType<T>, newFunction: (container: Instance, config: T) -> ())
	self._setUpContainerFn = newFunction
end

function Class.setFunction_cleanUpContainer<T>(self: CObjectType<T>, newFunction: (container: Instance) -> ())
	self._cleanUpContainerFn = newFunction
end


--- Tagged objects ---

function Class._onObjectTagged<T>(self: CObjectType<T>, object: Instance)
    -- Validate parent container
    local configContainer = object.Parent
    if not configContainer then
        warn(`[Container Mechanic]: Unable to find parent container for config instance '{object}'.`)
        return
    end

	-- Validate config
	local config = self:_getConfigFromConfigInstance(object)
	if not config then
		warn(`[Container Mechanic]: Unable to retrieve config for config instance '{object}'.`)
		return
	end

    -- Clean up existing container
    if self._configInstance_container[object] then
        self:_cleanUpContainer(self._configInstance_container[object])
    end
    self._configInstance_container[object] = configContainer

    -- Set up container
	task.defer(function()
		self:_setUpContainer(configContainer, config)
	end)

    -- Parent changed
    if self._configInstance_parentChangedConnection[object] then
        self._configInstance_parentChangedConnection[object]:Disconnect()
    end
    self._configInstance_parentChangedConnection[object] = (
        object:GetPropertyChangedSignal("Parent"):Connect(function()
            self:_cleanUpContainer(configContainer)
            configContainer = object.Parent
            if configContainer then
                self:_setUpContainer(configContainer, config)
            end
        end)
    )
end

function Class._getConfigFromConfigInstance<T>(self: CObjectType<T>, configInstance: Instance): T?
	if self._getConfigFromConfigInstanceFn then
		return self._getConfigFromConfigInstanceFn(configInstance)
	else
		warn(`[Container Mechanic]: 'Get config from instance' function not set for tag '{self._configInstanceTagName}'!`)
		return nil
	end
end

function Class._setUpContainer<T>(self: CObjectType<T>, container: Instance, config: T)
	if self._setUpContainerFn then
		self._setUpContainerFn(container, config)
	else
		warn(`[Container Mechanic]: 'Set up container' function not set for tag '{self._configInstanceTagName}'!`)
	end
end


--- Removed objects ---

function Class._onObjectRemoved<T>(self: CObjectType<T>, object: Instance)
	-- Clean up container
    local configContainer = self._configInstance_container[object]
    if configContainer then
        self:_cleanUpContainer(configContainer)
    end
    self._configInstance_container[object] = nil

	-- Disconnect parent changed
    if self._configInstance_parentChangedConnection[object] then
        self._configInstance_parentChangedConnection[object]:Disconnect()
    end
    self._configInstance_parentChangedConnection[object] = nil
end

function Class._cleanUpContainer<T>(self: CObjectType<T>, container: Instance)
	if self._cleanUpContainerFn then
		self._cleanUpContainerFn(container)
	else
		warn(`[Container Mechanic]: 'Clean up container' function not set for tag '{self._configInstanceTagName}'!`)
	end
end


--- Run ---

function Class.run<T>(self: CObjectType<T>)
	-- Check first time running
	if self._isRunning then
		warn(`[Container Mechanic]: Thread for tag '{self._configInstanceTagName}' is already running!`)
		return
	end
	self._isRunning = true

	-- Check functions
	if not self._getConfigFromConfigInstanceFn then
		warn(`[Container Mechanic]: 'Get config from instance' function not set for tag '{self._configInstanceTagName}'!`)
	end
	if not self._setUpContainerFn then
		warn(`[Container Mechanic]: 'Set up container' function not set for tag '{self._configInstanceTagName}'!`)
	end
	if not self._cleanUpContainerFn then
		warn(`[Container Mechanic]: 'Clean up container' function not set for tag '{self._configInstanceTagName}'!`)
	end

	-- Connect events
	local initialTagged = CollectionService:GetTagged(self._configInstanceTagName)
    task.defer(function()
        for _, object in initialTagged do
            task.defer(self._onObjectTagged, self, object)
        end
    end)
    CollectionService:GetInstanceAddedSignal(self._configInstanceTagName):Connect(function(object: Instance)
		self:_onObjectTagged(object)
	end)
    CollectionService:GetInstanceRemovedSignal(self._configInstanceTagName):Connect(function(object: Instance)
		self:_onObjectRemoved(object)
	end)
end


---------- Return class ----------

table.freeze(Class)
return Class
