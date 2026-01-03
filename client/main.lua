local function OpenTuning()
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
    
    -- Camera logic for modview could be added here
end

RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('getMods', function(data, cb)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then cb({}) return end

    local mods = {}
    
    if data.type == 'toggle' then
         -- Turbo etc
         table.insert(mods, { label = "None", index = false, price = 0, installed = not IsToggleModOn(veh, data.modType) })
         table.insert(mods, { label = "Install", index = true, price = 5000, installed = IsToggleModOn(veh, data.modType) })
    elseif data.type == 'custom_color' then
         -- Colors placeholder
         table.insert(mods, { label = "Black", index = 0, price = 1000 })
         table.insert(mods, { label = "White", index = 111, price = 1000 })
         table.insert(mods, { label = "Red", index = 27, price = 1000 })
         table.insert(mods, { label = "Blue", index = 64, price = 1000 })
    else
        -- Standard Mods
        local count = GetNumVehicleMods(veh, data.modType)
        local current = GetVehicleMod(veh, data.modType)
        
        table.insert(mods, { label = "Stock", index = -1, price = 0, installed = (current == -1) })
        for i = 0, count - 1 do
            local label = GetModTextLabel(veh, data.modType, i)
            if label == nil or label == "" then label = "Level " .. (i + 1) end
            table.insert(mods, { label = label, index = i, price = 1000, installed = (current == i) }) -- Fixed price for now
        end
    end
    
    cb(mods)
end)

RegisterNUICallback('applyMod', function(data, cb)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    
    -- In real impl: Verify money on server first
    -- TriggerServerEvent('rpa-tuning:pay', data.price)
    -- If success:
    
    if data.type == 'toggle' then
        ToggleVehicleMod(veh, data.modType, data.modIndex)
    elseif data.type == 'custom_color' then
        SetVehicleColours(veh, data.modIndex, data.modIndex)
    else
        SetVehicleMod(veh, data.modType, data.modIndex, false)
    end
    
    cb('ok')
end)

-- Entry Point
CreateThread(function()
    -- Add Blips / Zones for tuning shops
    local shops = {
        vector3(-337.2, -136.9, 39.0), -- LSC Burton
    }
    
    for k, coords in pairs(shops) do
         exports['rpa-lib']:AddTargetZone('mechanic_'..k, coords, vector3(5, 5, 4), {
            options = {
                {
                    label = "Open Mod Shop",
                    icon = "fas fa-wrench",
                    action = OpenTuning,
                    canInteract = function() return IsPedInAnyVehicle(PlayerPedId(), false) end
                }
            }
         })
    end
end)
