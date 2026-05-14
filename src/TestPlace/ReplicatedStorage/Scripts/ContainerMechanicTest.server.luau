--!strict

-- Container Mechanic Test


---------- Services ----------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


---------- Imports ----------

local _Modules = ReplicatedStorage:WaitForChild("Modules")
local ContainerMechanic = require(_Modules:WaitForChild("ContainerMechanic"))


---------- Types ----------

type MechanicConfig = {
    getBounceHeight: () -> number,
    getEnabled: () -> boolean,
}


---------- Constants ----------

local Constants = {}

Constants.localPlayer = Players.LocalPlayer

table.freeze(Constants)


---------- Local functions ----------


----- Main -----

local function main()
    local tagName = "BouncePadConfig"
    local container_touchedConnection = {} :: {[Instance]: RBXScriptConnection}
    local mechanic = ContainerMechanic.new(tagName)
    mechanic:setFunction_getConfigFromInstance(function(configInstance: Instance): MechanicConfig
        return {
            getBounceHeight = function() return tonumber(configInstance:GetAttribute("BounceHeight")) or 0 end,
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
                local character = otherPart.Parent
                local player = Players:GetPlayerFromCharacter(character)
                if not (character and player) then
                    return
                end
                if player ~= Constants.localPlayer then
                    return
                end

                local bounceHeight = config.getBounceHeight()
                -- dx = (vf^2 - v0^2) / 2a
                -- v0 = sqrt(-dx * 2a)
                local bounceVelocityY = math.sqrt(bounceHeight * 2 * workspace.Gravity)
                local velocity = otherPart.AssemblyLinearVelocity
                local newVelocity = Vector3.new(velocity.X, bounceVelocityY, velocity.Z)
                otherPart.AssemblyLinearVelocity = newVelocity
            end)
        end
    end)
    mechanic:setFunction_cleanUpContainer(function(container: Instance)
        if container_touchedConnection[container] then
            container_touchedConnection[container]:Disconnect()
        end
        container_touchedConnection[container] = nil
    end)
    mechanic:run()
end


---------- Calling function ----------

main()
