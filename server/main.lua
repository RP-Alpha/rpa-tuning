-- Get player helper
local function GetPlayer(src)
    local Framework = exports['rpa-lib']:GetFramework()
    if Framework then
        return Framework.Functions.GetPlayer(src)
    end
    return nil
end

-- Apply a vehicle mod with payment
RegisterNetEvent('rpa-tuning:server:applyMod', function(data)
    local src = source
    local player = GetPlayer(src)
    
    if not player then return end
    
    local price = data.price or 100
    local modLabel = data.modLabel or "Modification"
    
    local cash = player.PlayerData.money.cash
    
    if cash >= price then
        player.Functions.RemoveMoney('cash', price, 'tuning-mod')
        exports['rpa-lib']:Notify(src, "Installed " .. modLabel .. " for $" .. price, "success")
        -- Trigger client to actually apply mod (secured)
        TriggerClientEvent('rpa-tuning:client:applyModSecured', src, data)
    else
        exports['rpa-lib']:Notify(src, "Not enough cash for " .. modLabel .. " ($" .. price .. " required)", "error")
    end
end)

-- Apply neon lights with payment
RegisterNetEvent('rpa-tuning:server:applyNeon', function(data)
    local src = source
    local player = GetPlayer(src)
    
    if not player then return end
    
    local price = data.price or 2000
    local cash = player.PlayerData.money.cash
    
    if cash >= price then
        player.Functions.RemoveMoney('cash', price, 'tuning-neon')
        exports['rpa-lib']:Notify(src, "Neon lights installed for $" .. price, "success")
        TriggerClientEvent('rpa-tuning:client:applyNeonSecured', src, data)
    else
        exports['rpa-lib']:Notify(src, "Not enough cash ($" .. price .. " required)", "error")
    end
end)
