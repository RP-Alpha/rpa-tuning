RegisterNetEvent('rpa-tuning:server:applyMod', function(data)
    local src = source
    local player = exports['rpa-lib']:GetFramework().Functions.GetPlayer(src)
    local price = data.price or 100 -- Fallback price
    
    if player.Functions.GetMoney('cash') >= price then
        player.Functions.RemoveMoney('cash', price)
        exports['rpa-lib']:Notify(src, _U('tuning_installed', data.modLabel, price), "success")
        -- Trigger client to actually apply mod (secured)
        TriggerClientEvent('rpa-tuning:client:applyModSecured', src, data)
    else
        exports['rpa-lib']:Notify(src, _U('tuning_poor', data.modLabel), "error")
    end
end)
