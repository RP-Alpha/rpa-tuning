-- RP-Alpha Tuning System - Server Side
-- Shop management, payments, handling persistence

local Shops = {}
local VehicleHandling = {} -- Cache for handling modifications

-- ============================================
-- INITIALIZATION
-- ============================================

CreateThread(function()
    -- Create database tables
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `rpa_tuning_shops` (
            `id` VARCHAR(50) PRIMARY KEY,
            `label` VARCHAR(100) NOT NULL,
            `coords_x` FLOAT NOT NULL,
            `coords_y` FLOAT NOT NULL,
            `coords_z` FLOAT NOT NULL,
            `heading` FLOAT DEFAULT 0,
            `shop_type` VARCHAR(20) DEFAULT 'cosmetic',
            `discount` INT DEFAULT 0,
            `jobs` TEXT,
            `blip_sprite` INT DEFAULT 162,
            `blip_color` INT DEFAULT 17,
            `blip_scale` FLOAT DEFAULT 0.8,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
    
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `rpa_vehicle_handling` (
            `plate` VARCHAR(10) PRIMARY KEY,
            `handling_data` TEXT NOT NULL,
            `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ]])
    
    Wait(500)
    LoadShops()
end)

-- Load shops from database
function LoadShops()
    local result = MySQL.query.await('SELECT * FROM rpa_tuning_shops')
    
    Shops = {}
    
    if result and #result > 0 then
        for _, row in ipairs(result) do
            local jobs = {}
            if row.jobs and row.jobs ~= '' then
                jobs = json.decode(row.jobs) or {}
            end
            
            Shops[row.id] = {
                id = row.id,
                label = row.label,
                coords = vector3(row.coords_x, row.coords_y, row.coords_z),
                heading = row.heading,
                shopType = row.shop_type,
                discount = row.discount,
                jobs = jobs,
                blip = {
                    sprite = row.blip_sprite,
                    color = row.blip_color,
                    scale = row.blip_scale
                }
            }
        end
        print('[rpa-tuning] Loaded ' .. #result .. ' shops from database')
    else
        -- Load default shops
        for _, shop in ipairs(Config.DefaultShops) do
            Shops[shop.id] = shop
            SaveShopToDatabase(shop)
        end
        print('[rpa-tuning] Loaded ' .. #Config.DefaultShops .. ' default shops')
    end
end

-- Save shop to database
function SaveShopToDatabase(shop)
    MySQL.query([[
        INSERT INTO rpa_tuning_shops (id, label, coords_x, coords_y, coords_z, heading, shop_type, discount, jobs, blip_sprite, blip_color, blip_scale)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            label = VALUES(label),
            coords_x = VALUES(coords_x),
            coords_y = VALUES(coords_y),
            coords_z = VALUES(coords_z),
            heading = VALUES(heading),
            shop_type = VALUES(shop_type),
            discount = VALUES(discount),
            jobs = VALUES(jobs),
            blip_sprite = VALUES(blip_sprite),
            blip_color = VALUES(blip_color),
            blip_scale = VALUES(blip_scale)
    ]], {
        shop.id,
        shop.label,
        shop.coords.x,
        shop.coords.y,
        shop.coords.z,
        shop.heading or 0,
        shop.shopType or 'cosmetic',
        shop.discount or 0,
        json.encode(shop.jobs or {}),
        shop.blip and shop.blip.sprite or 162,
        shop.blip and shop.blip.color or 17,
        shop.blip and shop.blip.scale or 0.8
    })
end

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

local function GetPlayer(source)
    local Framework = exports['rpa-lib']:GetFramework()
    if Framework then
        return Framework.Functions.GetPlayer(source)
    end
    return nil
end

local function HasAdminPermission(source)
    return exports['rpa-lib']:HasPermission(source, Config.AdminPermissions, 'tuning')
end

local function HasMechanicPermission(source)
    return exports['rpa-lib']:HasPermission(source, Config.MechanicPermissions, 'tuning')
end

local function HasPerformancePermission(source)
    return exports['rpa-lib']:HasPermission(source, Config.PerformanceTunePermissions, 'tuning')
end

local function CanAccessShop(source, shop)
    if not shop then return false end
    
    -- Public shop (no job restriction)
    if not shop.jobs or #shop.jobs == 0 then
        return true, 0
    end
    
    -- Check if player has required job
    local player = GetPlayer(source)
    if not player then return false end
    
    local playerJob = player.PlayerData.job
    
    for _, jobName in ipairs(shop.jobs) do
        if playerJob.name == jobName then
            return true, shop.discount or 0
        end
    end
    
    return false, 0
end

-- ============================================
-- SHOP SYNC
-- ============================================

RegisterNetEvent('rpa-tuning:server:requestShops', function()
    local src = source
    TriggerClientEvent('rpa-tuning:client:syncShops', src, Shops)
    
    -- Send mechanic status
    local isMechanic = HasMechanicPermission(src)
    local canPerformance = HasPerformancePermission(src)
    TriggerClientEvent('rpa-tuning:client:setMechanicStatus', src, isMechanic, canPerformance)
end)

RegisterNetEvent('rpa-tuning:server:reloadShops', function()
    local src = source
    if not HasAdminPermission(src) then return end
    
    LoadShops()
    TriggerClientEvent('rpa-tuning:client:syncShops', -1, Shops)
    exports['rpa-lib']:Notify(src, 'Shops reloaded', 'success')
end)

-- ============================================
-- ACCESS CHECK
-- ============================================

RegisterNetEvent('rpa-tuning:server:checkAccess', function(shopId)
    local src = source
    local shop = Shops[shopId]
    
    if not shop then
        exports['rpa-lib']:Notify(src, 'Shop not found', 'error')
        return
    end
    
    local canAccess, discount = CanAccessShop(src, shop)
    
    if not canAccess then
        exports['rpa-lib']:Notify(src, 'You do not have access to this shop', 'error')
        return
    end
    
    -- Apply mechanic discount if applicable
    if HasMechanicPermission(src) then
        discount = math.max(discount, Config.Pricing.mechanicDiscount)
    end
    
    TriggerClientEvent('rpa-tuning:client:openMenu', src, shop, discount)
end)

-- ============================================
-- PURCHASES
-- ============================================

RegisterNetEvent('rpa-tuning:server:purchaseMod', function(data)
    local src = source
    local player = GetPlayer(src)
    
    if not player then return end
    
    local price = data.price or 0
    local modLabel = data.modLabel or 'Modification'
    
    -- Verify shop access
    local shop = Shops[data.shopId]
    if not shop then
        exports['rpa-lib']:Notify(src, 'Invalid shop', 'error')
        return
    end
    
    local canAccess = CanAccessShop(src, shop)
    if not canAccess then
        exports['rpa-lib']:Notify(src, 'No access', 'error')
        return
    end
    
    -- Check money
    local cash = player.PlayerData.money.cash or 0
    local bank = player.PlayerData.money.bank or 0
    
    if cash >= price then
        player.Functions.RemoveMoney('cash', price, 'tuning-' .. (data.type or 'mod'))
    elseif bank >= price then
        player.Functions.RemoveMoney('bank', price, 'tuning-' .. (data.type or 'mod'))
    else
        exports['rpa-lib']:Notify(src, 'Not enough money ($' .. price .. ' required)', 'error')
        return
    end
    
    -- Apply the mod
    TriggerClientEvent('rpa-tuning:client:applyMod', src, data)
    exports['rpa-lib']:Notify(src, modLabel .. ' installed for $' .. price, 'success')
    
    print('[rpa-tuning] Player ' .. src .. ' purchased ' .. modLabel .. ' for $' .. price)
end)

-- ============================================
-- HANDLING TUNING
-- ============================================

RegisterNetEvent('rpa-tuning:server:purchaseHandling', function(data)
    local src = source
    local player = GetPlayer(src)
    
    if not player then return end
    
    -- Verify performance permission
    if not HasPerformancePermission(src) then
        exports['rpa-lib']:Notify(src, 'You do not have permission to tune handling', 'error')
        return
    end
    
    local price = data.price or 0
    
    -- Check money
    local cash = player.PlayerData.money.cash or 0
    
    if cash >= price then
        player.Functions.RemoveMoney('cash', price, 'handling-tune')
    else
        exports['rpa-lib']:Notify(src, 'Not enough cash ($' .. price .. ' required)', 'error')
        return
    end
    
    -- Save handling modification
    SaveHandlingProperty(data.plate, data.property, data.value)
    
    exports['rpa-lib']:Notify(src, 'Handling modified for $' .. price, 'success')
    print('[rpa-tuning] Player ' .. src .. ' modified handling on ' .. data.plate .. ': ' .. data.property .. ' = ' .. data.value)
end)

function SaveHandlingProperty(plate, property, value)
    plate = plate:gsub('%s+', '') -- Trim plate
    
    -- Get existing data
    if not VehicleHandling[plate] then
        local result = MySQL.query.await('SELECT handling_data FROM rpa_vehicle_handling WHERE plate = ?', { plate })
        if result and result[1] then
            VehicleHandling[plate] = json.decode(result[1].handling_data) or {}
        else
            VehicleHandling[plate] = {}
        end
    end
    
    -- Update property
    VehicleHandling[plate][property] = value
    
    -- Save to database
    MySQL.query([[
        INSERT INTO rpa_vehicle_handling (plate, handling_data)
        VALUES (?, ?)
        ON DUPLICATE KEY UPDATE handling_data = VALUES(handling_data)
    ]], { plate, json.encode(VehicleHandling[plate]) })
end

RegisterNetEvent('rpa-tuning:server:getHandling', function(plate)
    local src = source
    plate = plate:gsub('%s+', '')
    
    -- Check cache first
    if VehicleHandling[plate] then
        TriggerClientEvent('rpa-tuning:client:applyHandling', src, VehicleHandling[plate])
        return
    end
    
    -- Load from database
    local result = MySQL.query.await('SELECT handling_data FROM rpa_vehicle_handling WHERE plate = ?', { plate })
    
    if result and result[1] then
        VehicleHandling[plate] = json.decode(result[1].handling_data) or {}
        TriggerClientEvent('rpa-tuning:client:applyHandling', src, VehicleHandling[plate])
    end
end)

RegisterNetEvent('rpa-tuning:server:resetHandling', function(plate)
    local src = source
    
    if not HasPerformancePermission(src) then
        exports['rpa-lib']:Notify(src, 'No permission', 'error')
        return
    end
    
    plate = plate:gsub('%s+', '')
    
    VehicleHandling[plate] = nil
    MySQL.query('DELETE FROM rpa_vehicle_handling WHERE plate = ?', { plate })
    
    exports['rpa-lib']:Notify(src, 'Handling reset for ' .. plate, 'success')
end)

-- ============================================
-- ADMIN MANAGEMENT
-- ============================================

RegisterNetEvent('rpa-tuning:server:openAdminMenu', function()
    local src = source
    
    if not HasAdminPermission(src) then
        exports['rpa-lib']:Notify(src, 'No permission', 'error')
        return
    end
    
    TriggerClientEvent('rpa-tuning:client:openAdminMenu', src)
end)

RegisterNetEvent('rpa-tuning:server:createShop', function(shopData)
    local src = source
    
    if not HasAdminPermission(src) then
        exports['rpa-lib']:Notify(src, 'No permission', 'error')
        return
    end
    
    if Shops[shopData.id] then
        exports['rpa-lib']:Notify(src, 'Shop ID already exists', 'error')
        return
    end
    
    Shops[shopData.id] = shopData
    SaveShopToDatabase(shopData)
    
    TriggerClientEvent('rpa-tuning:client:syncShops', -1, Shops)
    exports['rpa-lib']:Notify(src, 'Shop "' .. shopData.label .. '" created', 'success')
end)

RegisterNetEvent('rpa-tuning:server:updateShop', function(shopData)
    local src = source
    
    if not HasAdminPermission(src) then
        exports['rpa-lib']:Notify(src, 'No permission', 'error')
        return
    end
    
    Shops[shopData.id] = shopData
    SaveShopToDatabase(shopData)
    
    TriggerClientEvent('rpa-tuning:client:syncShops', -1, Shops)
    exports['rpa-lib']:Notify(src, 'Shop updated', 'success')
end)

RegisterNetEvent('rpa-tuning:server:deleteShop', function(shopId)
    local src = source
    
    if not HasAdminPermission(src) then
        exports['rpa-lib']:Notify(src, 'No permission', 'error')
        return
    end
    
    if not Shops[shopId] then
        exports['rpa-lib']:Notify(src, 'Shop not found', 'error')
        return
    end
    
    local label = Shops[shopId].label
    Shops[shopId] = nil
    
    MySQL.query('DELETE FROM rpa_tuning_shops WHERE id = ?', { shopId })
    
    TriggerClientEvent('rpa-tuning:client:syncShops', -1, Shops)
    exports['rpa-lib']:Notify(src, 'Shop "' .. label .. '" deleted', 'success')
end)

-- ============================================
-- PLAYER JOIN
-- ============================================

AddEventHandler('playerJoining', function()
    local src = source
    Wait(3000)
    TriggerClientEvent('rpa-tuning:client:syncShops', src, Shops)
    
    local isMechanic = HasMechanicPermission(src)
    local canPerformance = HasPerformancePermission(src)
    TriggerClientEvent('rpa-tuning:client:setMechanicStatus', src, isMechanic, canPerformance)
end)

print('[rpa-tuning] Server loaded')
