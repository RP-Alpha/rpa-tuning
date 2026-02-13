-- RP-Alpha Tuning System
-- Full mechanic shop + performance handling tuning (like jg-tuning)

local Shops = {}
local CurrentShop = nil
local InTuningZone = false
local IsMechanic = false
local CanPerformanceTune = false
local VehicleHandling = {} -- Cached handling modifications
local PricingMultiplier = 1.0

local function ApplyPricingMultiplier(price)
    return math.floor((tonumber(price) or 0) * PricingMultiplier)
end

-- ============================================
-- SHOP MANAGEMENT
-- ============================================

local function CreateShopBlip(shop)
    if not shop.blip then return end
    
    local blip = AddBlipForCoord(shop.coords.x, shop.coords.y, shop.coords.z)
    SetBlipSprite(blip, shop.blip.sprite)
    SetBlipColour(blip, shop.blip.color)
    SetBlipScale(blip, shop.blip.scale or 0.8)
    SetBlipAsShortRange(blip, true)
    
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(shop.label)
    EndTextCommandSetBlipName(blip)
    
    return blip
end

local function InitializeShops()
    for _, shop in pairs(Shops) do
        if shop.blipHandle then
            RemoveBlip(shop.blipHandle)
        end
        shop.blipHandle = CreateShopBlip(shop)
    end
end

-- Receive shops from server
RegisterNetEvent('rpa-tuning:client:syncShops', function(shops)
    Shops = shops
    InitializeShops()
end)

-- Update mechanic status
RegisterNetEvent('rpa-tuning:client:setMechanicStatus', function(isMech, canPerf)
    IsMechanic = isMech
    CanPerformanceTune = canPerf
end)

RegisterNetEvent('rpa-tuning:client:setPricingMultiplier', function(multiplier)
    PricingMultiplier = tonumber(multiplier) or 1.0
end)

-- ============================================
-- TUNING ZONE DETECTION
-- ============================================

CreateThread(function()
    while true do
        Wait(500)
        
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        local veh = GetVehiclePedIsIn(ped, false)
        
        local nearShop = nil
        local nearDist = 999
        
        for id, shop in pairs(Shops) do
            local dist = #(pos - shop.coords)
            if dist < 30.0 and dist < nearDist then
                nearDist = dist
                nearShop = shop
            end
        end
        
        if nearShop and nearDist < 5.0 and veh ~= 0 then
            if not InTuningZone then
                InTuningZone = true
                CurrentShop = nearShop
                exports['rpa-lib']:TextUI('[E] Open Tuning Menu', 'primary')
            end
        else
            if InTuningZone then
                InTuningZone = false
                CurrentShop = nil
                exports['rpa-lib']:HideTextUI()
            end
        end
    end
end)

-- Key press handler
CreateThread(function()
    while true do
        Wait(0)
        
        if InTuningZone and IsControlJustPressed(0, 38) then -- E key
            OpenTuningMenu()
        end
    end
end)

-- ============================================
-- TUNING MENU SYSTEM
-- ============================================

function OpenTuningMenu()
    if not CurrentShop then return end
    
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    
    if veh == 0 then
        exports['rpa-lib']:Notify('You must be in a vehicle', 'error')
        return
    end
    
    -- Request permission check
    TriggerServerEvent('rpa-tuning:server:checkAccess', CurrentShop.id)
end

-- Receive access confirmation
RegisterNetEvent('rpa-tuning:client:openMenu', function(shopData, discount)
    if not shopData then return end
    
    CurrentShop = shopData
    CurrentShop.discount = discount
    
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    
    SetVehicleModKit(veh, 0)
    
    local options = {}
    
    -- Cosmetic mods
    if shopData.shopType == 'cosmetic' or shopData.shopType == 'both' then
        table.insert(options, {
            title = '🎨 Cosmetic Modifications',
            description = 'Spoilers, bumpers, body kits, etc.',
            icon = 'fas fa-paint-brush',
            arrow = true,
            onSelect = function()
                OpenCategoryMenu('cosmetic')
            end
        })
        
        table.insert(options, {
            title = '💡 Lighting',
            description = 'Xenon lights, neon, etc.',
            icon = 'fas fa-lightbulb',
            arrow = true,
            onSelect = function()
                OpenCategoryMenu('lighting')
            end
        })
        
        table.insert(options, {
            title = '🎨 Colors',
            description = 'Paint, window tint, etc.',
            icon = 'fas fa-palette',
            arrow = true,
            onSelect = function()
                OpenCategoryMenu('colors')
            end
        })
    end
    
    -- Performance mods
    if shopData.shopType == 'performance' or shopData.shopType == 'both' then
        table.insert(options, {
            title = '⚡ Performance Upgrades',
            description = 'Engine, brakes, transmission, turbo',
            icon = 'fas fa-tachometer-alt',
            arrow = true,
            onSelect = function()
                OpenCategoryMenu('performance')
            end
        })
    end
    
    -- Handling tuning (mechanics only)
    if CanPerformanceTune and Config.HandlingTuning.enabled then
        table.insert(options, {
            title = '🔧 Advanced Handling Tuning',
            description = 'Fine-tune vehicle handling properties',
            icon = 'fas fa-sliders-h',
            arrow = true,
            onSelect = function()
                OpenHandlingMenu()
            end
        })
    end
    
    -- Discount info
    if discount > 0 then
        table.insert(options, {
            title = '💰 Employee Discount Active',
            description = discount .. '% off all modifications',
            icon = 'fas fa-tag',
            disabled = true
        })
    end
    
    lib.registerContext({
        id = 'rpa_tuning_main',
        title = '🔧 ' .. shopData.label,
        options = options
    })
    
    lib.showContext('rpa_tuning_main')
end)

-- Open a tuning category
function OpenCategoryMenu(category)
    local catConfig = Config.TuningCategories[category]
    if not catConfig then return end
    
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    
    if veh == 0 then return end
    
    local options = {}
    
    for _, mod in ipairs(catConfig) do
        local modData = GetModInfo(veh, mod)
        
        table.insert(options, {
            title = mod.label,
            description = modData.description,
            icon = modData.icon,
            arrow = true,
            onSelect = function()
                if mod.type == 'standard' then
                    OpenModLevelMenu(mod, modData)
                elseif mod.type == 'toggle' then
                    OpenToggleMenu(mod, modData)
                elseif mod.type == 'color' then
                    OpenColorMenu(mod)
                elseif mod.type == 'tint' then
                    OpenTintMenu()
                elseif mod.type == 'neon' then
                    OpenNeonMenu()
                elseif mod.type == 'neon_color' then
                    OpenNeonColorMenu()
                end
            end
        })
    end
    
    lib.registerContext({
        id = 'rpa_tuning_category_' .. category,
        title = '🔧 ' .. category:gsub("^%l", string.upper),
        menu = 'rpa_tuning_main',
        options = options
    })
    
    lib.showContext('rpa_tuning_category_' .. category)
end

-- Get mod info for display
function GetModInfo(veh, mod)
    local info = {
        description = 'Not available',
        icon = 'fas fa-wrench',
        count = 0,
        current = -1
    }
    
    if mod.type == 'standard' then
        local count = GetNumVehicleMods(veh, mod.modType)
        local current = GetVehicleMod(veh, mod.modType)
        
        info.count = count
        info.current = current
        info.description = count > 0 and (count .. ' options available') or 'Not available for this vehicle'
        
        if current >= 0 then
            info.description = 'Installed: Level ' .. (current + 1)
        end
    elseif mod.type == 'toggle' then
        local isOn = IsToggleModOn(veh, mod.modType)
        info.description = isOn and 'Installed' or 'Not installed'
        info.icon = 'fas fa-check-circle'
    elseif mod.type == 'color' then
        info.description = 'Change color'
        info.icon = 'fas fa-palette'
    end
    
    return info
end

-- Open standard mod levels
function OpenModLevelMenu(mod, modData)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    
    if veh == 0 then return end
    
    local options = {}
    local basePrice = Config.Pricing.modPrices[mod.modType] or 500
    local discount = CurrentShop and CurrentShop.discount or 0
    
    -- Stock option
    local currentMod = GetVehicleMod(veh, mod.modType)
    table.insert(options, {
        title = 'Stock',
        description = currentMod == -1 and '✓ Currently Installed' or 'Free',
        icon = 'fas fa-undo',
        onSelect = function()
            if currentMod ~= -1 then
                SetVehicleMod(veh, mod.modType, -1, false)
                exports['rpa-lib']:Notify('Reverted to stock', 'success')
            end
        end
    })
    
    -- Mod levels
    local count = GetNumVehicleMods(veh, mod.modType)
    for i = 0, count - 1 do
        local label = GetModTextLabel(veh, mod.modType, i)
        if not label or label == '' then
            label = 'Level ' .. (i + 1)
        end
        
        local price = math.floor(basePrice * (1 + (i * Config.Pricing.levelMultiplier)))
        price = ApplyPricingMultiplier(price)
        local finalPrice = math.floor(price * (1 - discount / 100))
        
        local isInstalled = currentMod == i
        
        table.insert(options, {
            title = label,
            description = isInstalled and '✓ Currently Installed' or ('$' .. finalPrice),
            icon = isInstalled and 'fas fa-check' or 'fas fa-plus',
            onSelect = function()
                if not isInstalled then
                    TriggerServerEvent('rpa-tuning:server:purchaseMod', {
                        shopId = CurrentShop.id,
                        modType = mod.modType,
                        modIndex = i,
                        modLabel = label,
                        price = finalPrice,
                        type = 'standard'
                    })
                end
            end
        })
    end
    
    lib.registerContext({
        id = 'rpa_tuning_mod_' .. mod.modType,
        title = '🔧 ' .. mod.label,
        menu = 'rpa_tuning_category_cosmetic',
        options = options
    })
    
    lib.showContext('rpa_tuning_mod_' .. mod.modType)
end

-- Toggle mod menu (turbo, xenon)
function OpenToggleMenu(mod, modData)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    
    if veh == 0 then return end
    
    local isOn = IsToggleModOn(veh, mod.modType)
    local basePrice = Config.Pricing.modPrices[mod.modType] or 1000
    basePrice = ApplyPricingMultiplier(basePrice)
    local discount = CurrentShop and CurrentShop.discount or 0
    local finalPrice = math.floor(basePrice * (1 - discount / 100))
    
    local options = {
        {
            title = isOn and 'Remove ' .. mod.label or 'Install ' .. mod.label,
            description = isOn and 'Free' or ('$' .. finalPrice),
            icon = isOn and 'fas fa-times' or 'fas fa-plus',
            onSelect = function()
                if isOn then
                    ToggleVehicleMod(veh, mod.modType, false)
                    exports['rpa-lib']:Notify(mod.label .. ' removed', 'success')
                else
                    TriggerServerEvent('rpa-tuning:server:purchaseMod', {
                        shopId = CurrentShop.id,
                        modType = mod.modType,
                        modIndex = true,
                        modLabel = mod.label,
                        price = finalPrice,
                        type = 'toggle'
                    })
                end
            end
        }
    }
    
    lib.registerContext({
        id = 'rpa_tuning_toggle_' .. mod.modType,
        title = '🔧 ' .. mod.label,
        menu = 'rpa_tuning_main',
        options = options
    })
    
    lib.showContext('rpa_tuning_toggle_' .. mod.modType)
end

-- ============================================
-- HANDLING TUNING SYSTEM
-- ============================================

function OpenHandlingMenu()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    
    if veh == 0 then return end
    
    local plate = GetVehicleNumberPlateText(veh)
    local options = {}
    
    for _, prop in ipairs(Config.HandlingTuning.properties) do
        local currentVal = GetVehicleHandlingFloat(veh, 'CHandlingData', prop.id)
        if prop.isInt then
            currentVal = GetVehicleHandlingInt(veh, 'CHandlingData', prop.id)
        end
        
        table.insert(options, {
            title = prop.label,
            description = 'Current: ' .. string.format('%.2f', currentVal) .. ' | $' .. ApplyPricingMultiplier(prop.price),
            icon = 'fas fa-sliders-h',
            arrow = true,
            onSelect = function()
                OpenHandlingPropertyMenu(prop, currentVal)
            end
        })
    end
    
    table.insert(options, {
        title = '🔄 Reset All Handling',
        description = 'Restore default handling values',
        icon = 'fas fa-undo',
        onSelect = function()
            local confirm = lib.alertDialog({
                header = 'Reset Handling',
                content = 'This will reset all handling modifications. Continue?',
                centered = true,
                cancel = true
            })
            if confirm == 'confirm' then
                TriggerServerEvent('rpa-tuning:server:resetHandling', plate)
            end
        end
    })
    
    lib.registerContext({
        id = 'rpa_tuning_handling',
        title = '🔧 Advanced Handling',
        menu = 'rpa_tuning_main',
        options = options
    })
    
    lib.showContext('rpa_tuning_handling')
end

function OpenHandlingPropertyMenu(prop, currentVal)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    
    if veh == 0 then return end
    
    local plate = GetVehicleNumberPlateText(veh)
    local adjustedPrice = ApplyPricingMultiplier(prop.price)
    
    local input = lib.inputDialog('Adjust ' .. prop.label, {
        {
            type = 'slider',
            label = prop.label,
            description = prop.description,
            default = math.floor(currentVal * 100),
            min = math.floor(prop.min * 100),
            max = math.floor(prop.max * 100),
            step = math.floor(prop.step * 100)
        }
    })
    
    if input then
        local newVal = input[1] / 100
        
        -- Preview the change
        if prop.isInt then
            SetVehicleHandlingInt(veh, 'CHandlingData', prop.id, math.floor(newVal))
        else
            SetVehicleHandlingFloat(veh, 'CHandlingData', prop.id, newVal + 0.0)
        end
        
        -- Confirm and save
        local confirm = lib.alertDialog({
            header = 'Confirm Purchase',
            content = 'Apply ' .. prop.label .. ' = ' .. string.format('%.2f', newVal) .. ' for $' .. adjustedPrice .. '?',
            centered = true,
            cancel = true
        })
        
        if confirm == 'confirm' then
            TriggerServerEvent('rpa-tuning:server:purchaseHandling', {
                plate = plate,
                property = prop.id,
                value = newVal,
                price = adjustedPrice
            })
        else
            -- Revert preview
            if prop.isInt then
                SetVehicleHandlingInt(veh, 'CHandlingData', prop.id, math.floor(currentVal))
            else
                SetVehicleHandlingFloat(veh, 'CHandlingData', prop.id, currentVal + 0.0)
            end
        end
    end
end

-- Apply saved handling when entering vehicle
RegisterNetEvent('rpa-tuning:client:applyHandling', function(handlingData)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    
    if veh == 0 then return end
    
    for propId, value in pairs(handlingData) do
        -- Find property config
        for _, prop in ipairs(Config.HandlingTuning.properties) do
            if prop.id == propId then
                if prop.isInt then
                    SetVehicleHandlingInt(veh, 'CHandlingData', propId, math.floor(value))
                else
                    SetVehicleHandlingFloat(veh, 'CHandlingData', propId, value + 0.0)
                end
                break
            end
        end
    end
end)

-- ============================================
-- MOD APPLICATION (from server)
-- ============================================

RegisterNetEvent('rpa-tuning:client:applyMod', function(data)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    
    if veh == 0 then return end
    
    if data.type == 'standard' then
        SetVehicleMod(veh, data.modType, data.modIndex, false)
    elseif data.type == 'toggle' then
        ToggleVehicleMod(veh, data.modType, data.modIndex == true)
    elseif data.type == 'color' then
        if data.colorType == 'primary' then
            local _, secondary = GetVehicleColours(veh)
            SetVehicleColours(veh, data.colorIndex, secondary)
        elseif data.colorType == 'secondary' then
            local primary, _ = GetVehicleColours(veh)
            SetVehicleColours(veh, primary, data.colorIndex)
        elseif data.colorType == 'pearl' then
            local pearl, wheel = GetVehicleExtraColours(veh)
            SetVehicleExtraColours(veh, data.colorIndex, wheel)
        elseif data.colorType == 'wheel' then
            local pearl, wheel = GetVehicleExtraColours(veh)
            SetVehicleExtraColours(veh, pearl, data.colorIndex)
        end
    elseif data.type == 'tint' then
        SetVehicleWindowTint(veh, data.tintIndex)
    elseif data.type == 'neon' then
        SetVehicleNeonLightEnabled(veh, 0, true)
        SetVehicleNeonLightEnabled(veh, 1, true)
        SetVehicleNeonLightEnabled(veh, 2, true)
        SetVehicleNeonLightEnabled(veh, 3, true)
    elseif data.type == 'neon_color' then
        SetVehicleNeonLightsColour(veh, data.r, data.g, data.b)
    end
end)

-- ============================================
-- COLOR MENUS
-- ============================================

function OpenColorMenu(mod)
    local colorType = mod.modType:gsub('_color', '')
    local discount = CurrentShop and CurrentShop.discount or 0
    local basePrice = Config.Pricing[mod.modType] or 1000
    basePrice = ApplyPricingMultiplier(basePrice)
    local finalPrice = math.floor(basePrice * (1 - discount / 100))
    
    local options = {}
    
    for _, color in ipairs(Config.Colors) do
        table.insert(options, {
            title = color.label,
            description = '$' .. finalPrice,
            icon = 'fas fa-circle',
            onSelect = function()
                TriggerServerEvent('rpa-tuning:server:purchaseMod', {
                    shopId = CurrentShop.id,
                    type = 'color',
                    colorType = colorType,
                    colorIndex = color.id,
                    modLabel = color.label,
                    price = finalPrice
                })
            end
        })
    end
    
    lib.registerContext({
        id = 'rpa_tuning_color_' .. colorType,
        title = '🎨 ' .. mod.label,
        menu = 'rpa_tuning_category_colors',
        options = options
    })
    
    lib.showContext('rpa_tuning_color_' .. colorType)
end

function OpenTintMenu()
    local discount = CurrentShop and CurrentShop.discount or 0
    local options = {}
    
    for _, tint in ipairs(Config.WindowTints) do
        local finalPrice = math.floor(ApplyPricingMultiplier(tint.price) * (1 - discount / 100))
        
        table.insert(options, {
            title = tint.label,
            description = finalPrice > 0 and ('$' .. finalPrice) or 'Free',
            icon = 'fas fa-window-maximize',
            onSelect = function()
                if finalPrice > 0 then
                    TriggerServerEvent('rpa-tuning:server:purchaseMod', {
                        shopId = CurrentShop.id,
                        type = 'tint',
                        tintIndex = tint.id,
                        modLabel = tint.label,
                        price = finalPrice
                    })
                else
                    local ped = PlayerPedId()
                    local veh = GetVehiclePedIsIn(ped, false)
                    SetVehicleWindowTint(veh, tint.id)
                    exports['rpa-lib']:Notify('Window tint applied', 'success')
                end
            end
        })
    end
    
    lib.registerContext({
        id = 'rpa_tuning_tint',
        title = '🪟 Window Tint',
        menu = 'rpa_tuning_category_colors',
        options = options
    })
    
    lib.showContext('rpa_tuning_tint')
end

function OpenNeonMenu()
    local discount = CurrentShop and CurrentShop.discount or 0
    local basePrice = ApplyPricingMultiplier(Config.Pricing.neonInstall)
    local finalPrice = math.floor(basePrice * (1 - discount / 100))
    
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    local hasNeon = IsVehicleNeonLightEnabled(veh, 0)
    
    local options = {
        {
            title = hasNeon and 'Remove Neon Lights' or 'Install Neon Lights',
            description = hasNeon and 'Free' or ('$' .. finalPrice),
            icon = hasNeon and 'fas fa-times' or 'fas fa-plus',
            onSelect = function()
                if hasNeon then
                    SetVehicleNeonLightEnabled(veh, 0, false)
                    SetVehicleNeonLightEnabled(veh, 1, false)
                    SetVehicleNeonLightEnabled(veh, 2, false)
                    SetVehicleNeonLightEnabled(veh, 3, false)
                    exports['rpa-lib']:Notify('Neon lights removed', 'success')
                else
                    TriggerServerEvent('rpa-tuning:server:purchaseMod', {
                        shopId = CurrentShop.id,
                        type = 'neon',
                        modLabel = 'Neon Lights',
                        price = finalPrice
                    })
                end
            end
        }
    }
    
    lib.registerContext({
        id = 'rpa_tuning_neon',
        title = '💡 Neon Lights',
        menu = 'rpa_tuning_category_lighting',
        options = options
    })
    
    lib.showContext('rpa_tuning_neon')
end

function OpenNeonColorMenu()
    local discount = CurrentShop and CurrentShop.discount or 0
    local basePrice = ApplyPricingMultiplier(Config.Pricing.neonColor)
    local finalPrice = math.floor(basePrice * (1 - discount / 100))
    
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    
    if not IsVehicleNeonLightEnabled(veh, 0) then
        exports['rpa-lib']:Notify('Install neon lights first', 'error')
        return
    end
    
    local colors = {
        { label = 'White', r = 255, g = 255, b = 255 },
        { label = 'Blue', r = 0, g = 0, b = 255 },
        { label = 'Electric Blue', r = 0, g = 150, b = 255 },
        { label = 'Mint', r = 50, g = 255, b = 155 },
        { label = 'Green', r = 0, g = 255, b = 0 },
        { label = 'Yellow', r = 255, g = 255, b = 0 },
        { label = 'Orange', r = 255, g = 150, b = 0 },
        { label = 'Red', r = 255, g = 0, b = 0 },
        { label = 'Pink', r = 255, g = 0, b = 255 },
        { label = 'Purple', r = 150, g = 0, b = 255 },
    }
    
    local options = {}
    
    for _, color in ipairs(colors) do
        table.insert(options, {
            title = color.label,
            description = '$' .. finalPrice,
            icon = 'fas fa-circle',
            onSelect = function()
                TriggerServerEvent('rpa-tuning:server:purchaseMod', {
                    shopId = CurrentShop.id,
                    type = 'neon_color',
                    r = color.r,
                    g = color.g,
                    b = color.b,
                    modLabel = color.label .. ' Neon',
                    price = finalPrice
                })
            end
        })
    end
    
    lib.registerContext({
        id = 'rpa_tuning_neon_color',
        title = '🌈 Neon Color',
        menu = 'rpa_tuning_category_lighting',
        options = options
    })
    
    lib.showContext('rpa_tuning_neon_color')
end

-- ============================================
-- VEHICLE ENTRY - APPLY SAVED HANDLING
-- ============================================

AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkPlayerEnteredVehicle' then
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        
        if veh ~= 0 then
            local plate = GetVehicleNumberPlateText(veh)
            TriggerServerEvent('rpa-tuning:server:getHandling', plate)
        end
    end
end)

-- ============================================
-- INIT
-- ============================================

CreateThread(function()
    Wait(1000)
    TriggerServerEvent('rpa-tuning:server:requestShops')
    TriggerServerEvent('rpa-tuning:server:requestPricingMultiplier')
end)

-- Admin command
RegisterCommand(Config.Settings.adminCommand, function()
    TriggerServerEvent('rpa-tuning:server:openAdminMenu')
end, false)

RegisterNetEvent('rpa-tuning:client:openAdminMenu', function()
    OpenAdminMenu()
end)

function OpenAdminMenu()
    lib.registerContext({
        id = 'rpa_tuning_admin',
        title = '⚙️ Tuning Admin',
        options = {
            {
                title = '🏪 Manage Shops',
                description = 'Add, edit, or remove tuning shops',
                icon = 'fas fa-store',
                arrow = true,
                onSelect = function()
                    TriggerEvent('rpa-tuning:client:openShopManager')
                end
            },
            {
                title = '💰 Pricing Override',
                description = 'Adjust global pricing multiplier',
                icon = 'fas fa-dollar-sign',
                arrow = true,
                onSelect = function()
                    local input = lib.inputDialog('Pricing Multiplier', {
                        {
                            type = 'number',
                            label = 'Global Multiplier',
                            description = ('Current: x%.2f | Range: %.2f - %.2f'):format(
                                PricingMultiplier,
                                Config.Pricing.minGlobalMultiplier,
                                Config.Pricing.maxGlobalMultiplier
                            ),
                            default = PricingMultiplier,
                            min = Config.Pricing.minGlobalMultiplier,
                            max = Config.Pricing.maxGlobalMultiplier
                        }
                    })

                    if input and input[1] then
                        TriggerServerEvent('rpa-tuning:server:setPricingMultiplier', input[1])
                    end
                end
            },
            {
                title = '🔄 Reload Shops',
                description = 'Refresh shop data from database',
                icon = 'fas fa-sync',
                onSelect = function()
                    TriggerServerEvent('rpa-tuning:server:reloadShops')
                end
            }
        }
    })
    
    lib.showContext('rpa_tuning_admin')
end

print('[rpa-tuning] Client loaded')
