# container-mechanic

CollectionService wrapper for creating container-based mechanisms with custom configs.

## Usage

Each mechanism is indicated using a child `Instance` with the mechanism's tag.

For a user-friendly experience:
- Use a `Configuration` for the tagged instance.
- Name both the tag and the configuration instance as `<Mechanism>Config`.
- Use [instance attributes](https://create.roblox.com/docs/studio/properties#instance-attributes) for the configs.

Each mechanic must define three functions: `getConfigFromInstance`, `setUpContainer`, and `cleanUpContainer`.
- These functions are automatically called by `ContainerMechanic` when a tagged instance is added, moved, or removed.

Dynamic configs:
- All configs are retrieved only when the instance is tagged.
- To detect changeable configs, consider using function-based configs (see example below).

Example mechanism for detecting touched event:

```luau
-- Define config type for mechanism
type MechanicConfig = {
    getEnabled: () -> boolean,
}

-- Set up container mechanic functions
local tagName = YOUR_TAG_NAME
local container_touchedConnection = {} :: {[Instance]: RBXScriptConnection}
local mechanic = ContainerMechanic.new(tagName)
mechanic:setFunction_getConfigFromInstance(function(configInstance: Instance): MechanicConfig
    return {
        -- function-based config allows retrieving the instantaneous value
        getEnabled = function() return configInstance:GetAttribute("Enabled") == true end,
    }
end)
mechanic:setFunction_setUpContainer(function(container: Instance, config: MechanicConfig)
    if container:IsA("BasePart") then
        if container_touchedConnection[container] then
            container_touchedConnection[container]:Disconnect()
        end
        container_touchedConnection[container] = container.Touched:Connect(function(otherPart: BasePart)
            if not config.getEnabled() then
                return
            end
            print("Part touch detected!")
        end)
    end
end)
mechanic:setFunction_cleanUpContainer(function(container: Instance)
    if container_touchedConnection[container] then
        container_touchedConnection[container]:Disconnect()
    end
    container_touchedConnection[container] = nil
end)

-- Start running the mechanic
mechanic:run()
```

## Credits

Similar modules:
- KashTheKing's [Mechanic](https://wally.run/package/kashtheking/mechanic)
