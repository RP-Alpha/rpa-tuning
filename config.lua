Config = {}

-- ============================================
-- PERMISSION CONFIGURATION
-- ============================================

-- Admin permissions (manage tuning shops, prices, etc.)
Config.AdminPermissions = {
    groups = { 'admin', 'god' },
    jobs = {},
    minGrade = 0,
    onDuty = false,
    convar = 'rpa:admins',
    resourceConvar = 'admin'
}

-- Mechanic job permissions (can tune any vehicle, discounted prices)
Config.MechanicPermissions = {
    groups = {},
    jobs = { 'mechanic', 'bennys' },
    minGrade = 0,
    onDuty = true,
    convar = '',
    resourceConvar = ''
}

-- Performance tuning permissions (handling adjustments)
Config.PerformanceTunePermissions = {
    groups = { 'admin', 'god' },
    jobs = { 'mechanic' },
    minGrade = 2,  -- Grade 2+ mechanics only
    onDuty = true,
    convar = '',
    resourceConvar = 'performance'
}

-- ============================================
-- SHOP CONFIGURATION
-- ============================================

-- Default tuning shop locations (can be managed in-game by admins)
Config.DefaultShops = {
    {
        id = 'lsc_burton',
        label = 'Los Santos Customs - Burton',
        coords = vector3(-337.2, -136.9, 39.0),
        heading = 0.0,
        blip = { sprite = 162, color = 17, scale = 0.8 },
        shopType = 'cosmetic', -- 'cosmetic', 'performance', 'both'
        discount = 0, -- 0 = no discount
        jobs = {},  -- Empty = public, or { 'mechanic' } for job-only
    },
    {
        id = 'lsc_airport',
        label = 'Los Santos Customs - Airport',
        coords = vector3(-1135.0, -1982.0, 13.2),
        heading = 45.0,
        blip = { sprite = 162, color = 17, scale = 0.8 },
        shopType = 'cosmetic',
        discount = 0,
        jobs = {},
    },
    {
        id = 'bennys',
        label = "Benny's Original Motorworks",
        coords = vector3(-205.0, -1305.0, 31.3),
        heading = 270.0,
        blip = { sprite = 162, color = 5, scale = 0.9 },
        shopType = 'both', -- Has performance tuning
        discount = 0,
        jobs = {},
    },
    {
        id = 'mechanic_shop',
        label = 'Hayes Auto Repair',
        coords = vector3(-1420.0, -450.0, 35.9),
        heading = 135.0,
        blip = { sprite = 72, color = 47, scale = 0.8 },
        shopType = 'both',
        discount = 20, -- 20% off for job employees
        jobs = { 'mechanic' }, -- Only for mechanics
    }
}

-- ============================================
-- TUNING CATEGORIES
-- ============================================

Config.TuningCategories = {
    -- Cosmetic Modifications
    cosmetic = {
        { modType = 0, label = 'Spoilers', type = 'standard' },
        { modType = 1, label = 'Front Bumper', type = 'standard' },
        { modType = 2, label = 'Rear Bumper', type = 'standard' },
        { modType = 3, label = 'Side Skirts', type = 'standard' },
        { modType = 4, label = 'Exhaust', type = 'standard' },
        { modType = 5, label = 'Roll Cage', type = 'standard' },
        { modType = 6, label = 'Grille', type = 'standard' },
        { modType = 7, label = 'Hood', type = 'standard' },
        { modType = 8, label = 'Fenders', type = 'standard' },
        { modType = 9, label = 'Right Fender', type = 'standard' },
        { modType = 10, label = 'Roof', type = 'standard' },
        { modType = 23, label = 'Front Wheels', type = 'standard' },
        { modType = 24, label = 'Back Wheels', type = 'standard' },
        { modType = 25, label = 'Plate Holder', type = 'standard' },
        { modType = 27, label = 'Trim', type = 'standard' },
        { modType = 28, label = 'Ornaments', type = 'standard' },
        { modType = 30, label = 'Dial', type = 'standard' },
        { modType = 33, label = 'Steering Wheel', type = 'standard' },
        { modType = 34, label = 'Shifter', type = 'standard' },
        { modType = 35, label = 'Plaques', type = 'standard' },
        { modType = 38, label = 'Hydraulics', type = 'standard' },
    },
    
    -- Performance Modifications
    performance = {
        { modType = 11, label = 'Engine', type = 'standard' },
        { modType = 12, label = 'Brakes', type = 'standard' },
        { modType = 13, label = 'Transmission', type = 'standard' },
        { modType = 14, label = 'Horns', type = 'standard' },
        { modType = 15, label = 'Suspension', type = 'standard' },
        { modType = 16, label = 'Armor', type = 'standard' },
        { modType = 18, label = 'Turbo', type = 'toggle' },
    },
    
    -- Lighting
    lighting = {
        { modType = 22, label = 'Xenon Headlights', type = 'toggle' },
        { modType = 'neon', label = 'Neon Lights', type = 'neon' },
        { modType = 'neon_color', label = 'Neon Color', type = 'neon_color' },
    },
    
    -- Colors
    colors = {
        { modType = 'primary_color', label = 'Primary Color', type = 'color' },
        { modType = 'secondary_color', label = 'Secondary Color', type = 'color' },
        { modType = 'pearl_color', label = 'Pearlescent', type = 'color' },
        { modType = 'wheel_color', label = 'Wheel Color', type = 'color' },
        { modType = 'window_tint', label = 'Window Tint', type = 'tint' },
    },
}

-- ============================================
-- HANDLING TUNING (like jg-tuning)
-- ============================================

Config.HandlingTuning = {
    enabled = true,
    
    -- Tunable properties (realistic ranges)
    properties = {
        {
            id = 'fInitialDriveForce',
            label = 'Engine Power',
            description = 'Adjusts acceleration and top speed',
            min = 0.1,
            max = 2.0,
            step = 0.05,
            default = 1.0,
            price = 5000,
        },
        {
            id = 'fBrakeForce',
            label = 'Brake Force',
            description = 'Affects stopping power',
            min = 0.5,
            max = 2.0,
            step = 0.1,
            default = 1.0,
            price = 2000,
        },
        {
            id = 'fTractionCurveMax',
            label = 'Grip (Max)',
            description = 'Maximum tire grip',
            min = 1.0,
            max = 3.0,
            step = 0.1,
            default = 2.0,
            price = 3000,
        },
        {
            id = 'fTractionCurveMin',
            label = 'Grip (Min)',
            description = 'Minimum tire grip (when sliding)',
            min = 1.0,
            max = 2.5,
            step = 0.1,
            default = 1.5,
            price = 3000,
        },
        {
            id = 'fSuspensionForce',
            label = 'Suspension Stiffness',
            description = 'How stiff the suspension is',
            min = 1.0,
            max = 4.0,
            step = 0.1,
            default = 2.0,
            price = 2500,
        },
        {
            id = 'fSuspensionReboundDamp',
            label = 'Suspension Rebound',
            description = 'Rebound damping',
            min = 0.5,
            max = 3.0,
            step = 0.1,
            default = 1.5,
            price = 2500,
        },
        {
            id = 'fDriveBiasFront',
            label = 'Drive Bias',
            description = '0 = RWD, 0.5 = AWD, 1 = FWD',
            min = 0.0,
            max = 1.0,
            step = 0.05,
            default = 0.5,
            price = 10000,
        },
        {
            id = 'nInitialDriveGears',
            label = 'Gear Count',
            description = 'Number of gears (1-8)',
            min = 1,
            max = 8,
            step = 1,
            default = 6,
            price = 5000,
            isInt = true,
        },
    },
    
    -- Max adjustments per vehicle class (to maintain balance)
    classLimits = {
        [0] = { maxPower = 1.5 },   -- Compacts
        [1] = { maxPower = 1.6 },   -- Sedans
        [2] = { maxPower = 1.7 },   -- SUVs
        [3] = { maxPower = 1.5 },   -- Coupes
        [4] = { maxPower = 1.8 },   -- Muscle
        [5] = { maxPower = 2.0 },   -- Sports Classics
        [6] = { maxPower = 2.0 },   -- Sports
        [7] = { maxPower = 2.0 },   -- Super
    },
}

-- ============================================
-- PRICING
-- ============================================

Config.Pricing = {
    -- Base prices for standard mods (per level)
    modPrices = {
        [0] = 500,      -- Spoilers
        [1] = 750,      -- Front Bumper
        [2] = 750,      -- Rear Bumper
        [3] = 500,      -- Side Skirts
        [4] = 300,      -- Exhaust
        [5] = 1500,     -- Roll Cage
        [6] = 300,      -- Grille
        [7] = 800,      -- Hood
        [8] = 400,      -- Fenders
        [9] = 400,      -- Right Fender
        [10] = 600,     -- Roof
        [11] = 2500,    -- Engine
        [12] = 1500,    -- Brakes
        [13] = 2000,    -- Transmission
        [14] = 200,     -- Horns
        [15] = 1000,    -- Suspension
        [16] = 3000,    -- Armor
        [18] = 5000,    -- Turbo
        [22] = 1500,    -- Xenon
        [23] = 1000,    -- Front Wheels
        [24] = 1000,    -- Back Wheels
    },
    
    -- Multiply price by upgrade level (level 1 = 1x, level 4 = 2x, etc.)
    levelMultiplier = 0.25,
    
    -- Neon prices
    neonInstall = 2000,
    neonColor = 500,
    
    -- Color prices
    primaryColor = 1000,
    secondaryColor = 800,
    pearlescent = 1500,
    wheelColor = 500,
    windowTint = 750,
    
    -- Mechanic discount (percentage off when mechanic is on duty)
    mechanicDiscount = 30,

    -- Global multiplier controlled by admin menu
    defaultGlobalMultiplier = 1.0,
    minGlobalMultiplier = 0.5,
    maxGlobalMultiplier = 2.0,
}

-- ============================================
-- GENERAL SETTINGS
-- ============================================

Config.Settings = {
    -- Require vehicle to be in a specific spot for tuning
    useMarker = true,
    markerType = 1,
    markerColor = { r = 255, g = 165, b = 0, a = 100 },
    
    -- Save vehicle mods to database (persistent across restarts)
    persistMods = true,
    
    -- Debug mode
    debug = false,
    
    -- Admin command
    adminCommand = 'tuningadmin',
}

-- Color palette for color picker
Config.Colors = {
    { id = 0, label = 'Metallic Black' },
    { id = 1, label = 'Metallic Graphite Black' },
    { id = 2, label = 'Metallic Black Steel' },
    { id = 3, label = 'Metallic Dark Silver' },
    { id = 4, label = 'Metallic Silver' },
    { id = 5, label = 'Metallic Blue Silver' },
    { id = 6, label = 'Metallic Steel Gray' },
    { id = 7, label = 'Metallic Shadow Silver' },
    { id = 8, label = 'Metallic Stone Silver' },
    { id = 9, label = 'Metallic Midnight Silver' },
    { id = 10, label = 'Metallic Gun Metal' },
    { id = 11, label = 'Metallic Anthracite Grey' },
    { id = 27, label = 'Metallic Red' },
    { id = 28, label = 'Metallic Torino Red' },
    { id = 29, label = 'Metallic Formula Red' },
    { id = 30, label = 'Metallic Blaze Red' },
    { id = 31, label = 'Metallic Graceful Red' },
    { id = 32, label = 'Metallic Garnet Red' },
    { id = 33, label = 'Metallic Desert Red' },
    { id = 34, label = 'Metallic Cabernet Red' },
    { id = 35, label = 'Metallic Candy Red' },
    { id = 36, label = 'Metallic Sunrise Orange' },
    { id = 38, label = 'Metallic Gold' },
    { id = 39, label = 'Metallic Orange' },
    { id = 49, label = 'Metallic Dark Green' },
    { id = 50, label = 'Metallic Racing Green' },
    { id = 51, label = 'Metallic Sea Green' },
    { id = 52, label = 'Metallic Olive Green' },
    { id = 53, label = 'Metallic Green' },
    { id = 54, label = 'Metallic Gasoline Blue Green' },
    { id = 61, label = 'Metallic Dark Blue' },
    { id = 62, label = 'Metallic Midnight Blue' },
    { id = 63, label = 'Metallic Saxony Blue' },
    { id = 64, label = 'Metallic Blue' },
    { id = 65, label = 'Metallic Mariner Blue' },
    { id = 66, label = 'Metallic Harbor Blue' },
    { id = 67, label = 'Metallic Diamond Blue' },
    { id = 68, label = 'Metallic Surf Blue' },
    { id = 69, label = 'Metallic Nautical Blue' },
    { id = 70, label = 'Metallic Bright Blue' },
    { id = 71, label = 'Metallic Purple Blue' },
    { id = 72, label = 'Metallic Spinnaker Blue' },
    { id = 73, label = 'Metallic Ultra Blue' },
    { id = 88, label = 'Metallic Yellow' },
    { id = 89, label = 'Metallic Race Yellow' },
    { id = 91, label = 'Metallic Flur Yellow' },
    { id = 106, label = 'Util Black' },
    { id = 107, label = 'Util Black Poly' },
    { id = 111, label = 'Util White' },
    { id = 112, label = 'Worn White' },
    { id = 134, label = 'Matte Black' },
    { id = 135, label = 'Matte Gray' },
    { id = 136, label = 'Matte Light Grey' },
    { id = 145, label = 'Matte White' },
}

-- Window tint options
Config.WindowTints = {
    { id = 0, label = 'None', price = 0 },
    { id = 1, label = 'Pure Black', price = 1000 },
    { id = 2, label = 'Dark Smoke', price = 750 },
    { id = 3, label = 'Light Smoke', price = 500 },
    { id = 4, label = 'Stock', price = 0 },
    { id = 5, label = 'Limo', price = 1200 },
    { id = 6, label = 'Green', price = 800 },
}
