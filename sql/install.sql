-- RP-Alpha Tuning System Database Schema
-- Tables are auto-created by the resource

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
);

CREATE TABLE IF NOT EXISTS `rpa_vehicle_handling` (
    `plate` VARCHAR(10) PRIMARY KEY,
    `handling_data` TEXT NOT NULL,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_handling_plate ON rpa_vehicle_handling(plate);
