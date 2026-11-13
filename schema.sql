-- Mini Mart Express POS & Accounting System
-- Database Schema and Initial Seed Data
-- Compatible with MariaDB / MySQL 5.7+ / 8.0+

CREATE DATABASE IF NOT EXISTS `mini_mart_pos` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `mini_mart_pos`;

-- 1. USERS & ROLES
DROP TABLE IF EXISTS `audit_logs`;
DROP TABLE IF EXISTS `losses`;
DROP TABLE IF EXISTS `restock_logs`;
DROP TABLE IF EXISTS `sale_items`;
DROP TABLE IF EXISTS `sales`;
DROP TABLE IF EXISTS `payroll`;
DROP TABLE IF EXISTS `products`;
DROP TABLE IF EXISTS `suppliers`;
DROP TABLE IF EXISTS `settings`;
DROP TABLE IF EXISTS `users`;

CREATE TABLE `users` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `username` VARCHAR(50) NOT NULL UNIQUE,
    `password` VARCHAR(255) NOT NULL,
    `full_name` VARCHAR(100) NOT NULL,
    `email` VARCHAR(100) NOT NULL,
    `role` ENUM('admin', 'manager', 'cashier') NOT NULL DEFAULT 'cashier',
    `status` ENUM('active', 'inactive') NOT NULL DEFAULT 'active',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. SUPPLIERS
CREATE TABLE `suppliers` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `company_name` VARCHAR(150) NOT NULL,
    `contact_person` VARCHAR(100) DEFAULT NULL,
    `phone` VARCHAR(50) DEFAULT NULL,
    `email` VARCHAR(100) DEFAULT NULL,
    `address` TEXT DEFAULT NULL,
    `status` ENUM('active', 'inactive') NOT NULL DEFAULT 'active',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. PRODUCTS & INVENTORY
CREATE TABLE `products` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `barcode` VARCHAR(50) NOT NULL UNIQUE,
    `name` VARCHAR(150) NOT NULL,
    `category` VARCHAR(50) NOT NULL,
    `supplier_id` INT DEFAULT NULL,
    `cost_price` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `selling_price` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `stock_quantity` INT NOT NULL DEFAULT 0,
    `low_stock_threshold` INT NOT NULL DEFAULT 10,
    `expiration_date` DATE DEFAULT NULL,
    `image_url` TEXT DEFAULT NULL,
    `status` ENUM('active', 'inactive') NOT NULL DEFAULT 'active',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`supplier_id`) REFERENCES `suppliers`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. RESTOCK LOGS
CREATE TABLE `restock_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `product_id` INT NOT NULL,
    `supplier_id` INT DEFAULT NULL,
    `quantity_added` INT NOT NULL,
    `unit_cost` DECIMAL(10,2) NOT NULL,
    `total_cost` DECIMAL(10,2) NOT NULL,
    `batch_number` VARCHAR(50) DEFAULT NULL,
    `expiration_date` DATE DEFAULT NULL,
    `notes` TEXT DEFAULT NULL,
    `recorded_by` VARCHAR(100) NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`product_id`) REFERENCES `products`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`supplier_id`) REFERENCES `suppliers`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5. LOSSES / SPOILAGE
CREATE TABLE `losses` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `product_id` INT NOT NULL,
    `product_name` VARCHAR(150) NOT NULL,
    `quantity` INT NOT NULL,
    `unit_cost` DECIMAL(10,2) NOT NULL,
    `total_loss` DECIMAL(10,2) NOT NULL,
    `reason` ENUM('expired', 'damaged', 'lost', 'other') NOT NULL DEFAULT 'damaged',
    `remarks` TEXT DEFAULT NULL,
    `logged_by` VARCHAR(100) NOT NULL,
    `logged_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`product_id`) REFERENCES `products`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 6. SALES & TRANSACTIONS
CREATE TABLE `sales` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `receipt_no` VARCHAR(50) NOT NULL UNIQUE,
    `cashier_id` INT DEFAULT NULL,
    `cashier_name` VARCHAR(100) NOT NULL,
    `subtotal` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `tax_rate` DECIMAL(5,4) NOT NULL DEFAULT 0.1200,
    `tax_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `discount_type` ENUM('none', 'senior_pwd', 'custom') NOT NULL DEFAULT 'none',
    `discount_id_no` VARCHAR(50) DEFAULT NULL,
    `discount_rate` DECIMAL(5,4) NOT NULL DEFAULT 0.0000,
    `discount_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `grand_total` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `payment_method` ENUM('Cash', 'GCash', 'Maya', 'MariBank', 'Card') NOT NULL DEFAULT 'Cash',
    `payment_ref_code` VARCHAR(100) DEFAULT NULL,
    `amount_tendered` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `change_due` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `status` ENUM('completed', 'voided') NOT NULL DEFAULT 'completed',
    `void_reason` TEXT DEFAULT NULL,
    `voided_by` VARCHAR(100) DEFAULT NULL,
    `voided_at` DATETIME DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 7. SALE ITEMS
CREATE TABLE `sale_items` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `sale_id` INT NOT NULL,
    `product_id` INT DEFAULT NULL,
    `barcode` VARCHAR(50) NOT NULL,
    `product_name` VARCHAR(150) NOT NULL,
    `category` VARCHAR(50) DEFAULT NULL,
    `unit_cost` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `unit_price` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `quantity` INT NOT NULL DEFAULT 1,
    `total_price` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`sale_id`) REFERENCES `sales`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`product_id`) REFERENCES `products`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 8. PAYROLL
CREATE TABLE `payroll` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `employee_name` VARCHAR(100) NOT NULL,
    `role` VARCHAR(50) NOT NULL DEFAULT 'Staff',
    `pay_period` VARCHAR(50) NOT NULL,
    `hourly_rate` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `hours_worked` DECIMAL(6,2) NOT NULL DEFAULT 0.00,
    `overtime_hours` DECIMAL(6,2) NOT NULL DEFAULT 0.00,
    `overtime_pay` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `gross_salary` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `sss_deduction` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `philhealth_deduction` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `pagibig_deduction` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `tax_deduction` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `other_deductions` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `total_deductions` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `net_pay` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `status` ENUM('paid', 'pending') NOT NULL DEFAULT 'paid',
    `recorded_by` VARCHAR(100) NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 9. AUDIT LOGS
CREATE TABLE `audit_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT DEFAULT NULL,
    `username` VARCHAR(100) NOT NULL,
    `role` VARCHAR(50) NOT NULL,
    `action` VARCHAR(100) NOT NULL,
    `details` TEXT DEFAULT NULL,
    `ip_address` VARCHAR(50) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 10. SETTINGS
CREATE TABLE `settings` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `setting_key` VARCHAR(50) NOT NULL UNIQUE,
    `setting_value` TEXT NOT NULL,
    `description` VARCHAR(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- INITIAL SEED DATA
-- ============================================================

-- Settings
INSERT INTO `settings` (`setting_key`, `setting_value`, `description`) VALUES
('store_name', 'Mini Mart Express', 'Store Name on Receipts and UI'),
('store_branch', 'Branch #04 - Main Boulevard', 'Store Branch Details'),
('store_phone', '+63 (02) 8923-4567', 'Store Contact Number'),
('default_tax_rate', '0.12', 'Default VAT tax rate (0.12 = 12%)'),
('low_stock_default', '10', 'Default threshold for low stock warnings'),
('currency_symbol', '₱', 'Currency Symbol displayed throughout POS');

-- Users (password is '123456' for all demo accounts; bcrypt hashes included, plus plain fallback)
INSERT INTO `users` (`id`, `username`, `password`, `full_name`, `email`, `role`, `status`) VALUES
(1, 'admin', '$2y$10$4y9pQ.5tF4r4uYp6Efg6bO4J591bOq.z90e9jKqR8M2zE2rL9.V9m', 'Administrator (Admin User)', 'admin@minimart.local', 'admin', 'active'),
(2, 'manager', '$2y$10$4y9pQ.5tF4r4uYp6Efg6bO4J591bOq.z90e9jKqR8M2zE2rL9.V9m', 'Store Manager (Maria Santos)', 'manager@minimart.local', 'manager', 'active'),
(3, 'cashier', '$2y$10$4y9pQ.5tF4r4uYp6Efg6bO4J591bOq.z90e9jKqR8M2zE2rL9.V9m', 'Front Cashier (John Dela Cruz)', 'cashier@minimart.local', 'cashier', 'active');

-- Suppliers
INSERT INTO `suppliers` (`id`, `company_name`, `contact_person`, `phone`, `email`, `address`, `status`) VALUES
(1, 'San Miguel Distribution Co.', 'Robert Tan', '0917-111-2233', 'orders@sanmiguel.com.ph', 'Pasig City, Metro Manila', 'active'),
(2, 'Universal Robina Corp (URC)', 'Elena Gomez', '0918-222-3344', 'supply@urc.com.ph', 'Quezon City, Metro Manila', 'active'),
(3, 'Nestle Philippines Inc.', 'Carlos Reyes', '0919-333-4455', 'sales@nestle.com.ph', 'Makati City, Metro Manila', 'active'),
(4, 'Coca-Cola Beverages PH', 'Dennis Lim', '0920-444-5566', 'distro@coca-cola.com.ph', 'Taguig City, Metro Manila', 'active'),
(5, 'Monde Nissin Corporation', 'Grace Aquino', '0921-555-6677', 'orders@mondenissin.com', 'Santa Rosa, Laguna', 'active'),
(6, 'Procter & Gamble Philippines', 'Patricia Diaz', '0922-666-7788', 'contact@pgph.com', 'BGC, Taguig City', 'active');

-- Products (with realistic barcodes, prices, stock levels, and expiration dates)
-- Note: Some items have low stock (<= 10) to showcase alerts, and some are near expiration!
INSERT INTO `products` (`id`, `barcode`, `name`, `category`, `supplier_id`, `cost_price`, `selling_price`, `stock_quantity`, `low_stock_threshold`, `expiration_date`, `image_url`, `status`) VALUES
(1, '4800016644815', 'San Miguel Pale Pilsen Can 330ml', 'Beverages', 1, 48.00, 65.00, 48, 10, '2027-06-30', 'https://images.unsplash.com/photo-1608278049247-f7035544d67d?w=300', 'active'),
(2, '4800016053013', 'San Miguel Light 330ml Bottle', 'Beverages', 1, 46.00, 62.00, 8, 10, '2027-05-15', 'https://images.unsplash.com/photo-1535958636474-b021ee887b13?w=300', 'active'),
(3, '4800014118301', 'Coca-Cola Original Taste 1.5L', 'Beverages', 4, 62.00, 78.00, 24, 10, '2027-04-20', 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=300', 'active'),
(4, '4800014118318', 'Sprite Lemon-Lime 1.5L', 'Beverages', 4, 60.00, 75.00, 15, 10, '2027-03-10', 'https://images.unsplash.com/photo-1625772299848-391b6a87d7b3?w=300', 'active'),
(5, '4800011123456', 'Nature Spring Mineral Water 500ml', 'Beverages', 1, 10.00, 18.00, 60, 15, '2027-12-31', 'https://images.unsplash.com/photo-1548839140-29a749e1bc4e?w=300', 'active'),
(6, '4800047812908', 'Piattos Cheese Flavored Chips 85g', 'Snacks', 2, 32.00, 42.00, 4, 10, '2026-11-28', 'https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=300', 'active'),
(7, '4800047812915', 'Nova Multigrain Country Cheddar 78g', 'Snacks', 2, 31.00, 41.00, 32, 10, '2027-01-15', 'https://images.unsplash.com/photo-1527842891421-42eec6e703ea?w=300', 'active'),
(8, '4807770270016', 'Lucky Me! Instant Pancit Canton Original', 'Noodles', 5, 12.00, 17.50, 50, 15, '2027-08-20', 'https://images.unsplash.com/photo-1612927601601-6638404737ce?w=300', 'active'),
(9, '4807770270023', 'Lucky Me! Pancit Canton Chilimansi', 'Noodles', 5, 12.00, 17.50, 6, 15, '2026-11-25', 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=300', 'active'),
(10, '4800361376045', 'Nescafe Classic Instant Coffee 100g Jar', 'Groceries', 3, 115.00, 145.00, 18, 5, '2027-10-10', 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=300', 'active'),
(11, '4800361376052', 'Bear Brand Fortified Powdered Milk 320g', 'Dairy', 3, 98.00, 125.00, 3, 10, '2026-12-05', 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=300', 'active'),
(12, '4800092112349', 'Century Tuna Flakes in Oil 180g', 'Canned Goods', 1, 38.00, 49.00, 40, 10, '2028-02-14', 'https://images.unsplash.com/photo-1534483509719-3feaee7c30da?w=300', 'active'),
(13, '4800092112356', 'Argentina Corned Beef 175g', 'Canned Goods', 1, 36.00, 46.50, 35, 10, '2028-03-20', 'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=300', 'active'),
(14, '4800012398741', 'Safeguard Pure White Soap 130g', 'Hygiene', 6, 42.00, 54.00, 25, 8, '2028-09-30', 'https://images.unsplash.com/photo-1607613009820-a29f7bb81c04?w=300', 'active'),
(15, '4800012398758', 'Colgate Total Clean Mint Toothpaste 150g', 'Hygiene', 6, 85.00, 110.00, 5, 10, '2027-02-18', 'https://images.unsplash.com/photo-1559591937-e1032b4b4556?w=300', 'active'),
(16, '4807770112233', 'Monde Special Mamon Classic 6s', 'Bakery', 5, 52.00, 68.00, 2, 8, '2026-11-20', 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=300', 'active');

-- Restock Logs
INSERT INTO `restock_logs` (`product_id`, `supplier_id`, `quantity_added`, `unit_cost`, `total_cost`, `batch_number`, `expiration_date`, `notes`, `recorded_by`) VALUES
(1, 1, 48, 48.00, 2304.00, 'BATCH-SMC-091', '2027-06-30', 'Monthly beverage restocking', 'Store Manager (Maria Santos)'),
(6, 2, 20, 32.00, 640.00, 'BATCH-URC-442', '2026-11-28', 'Snack aisle delivery', 'Store Manager (Maria Santos)'),
(10, 3, 20, 115.00, 2300.00, 'BATCH-NES-102', '2027-10-10', 'Coffee refill', 'Store Manager (Maria Santos)');

-- Inventory Losses
INSERT INTO `losses` (`product_id`, `product_name`, `quantity`, `unit_cost`, `total_loss`, `reason`, `remarks`, `logged_by`) VALUES
(6, 'Piattos Cheese Flavored Chips 85g', 2, 32.00, 64.00, 'damaged', 'Crushed during shelf stocking', 'Store Manager (Maria Santos)'),
(16, 'Monde Special Mamon Classic 6s', 1, 52.00, 52.00, 'expired', 'Past pull-out date', 'Store Manager (Maria Santos)');

-- Payroll Records
INSERT INTO `payroll` (`employee_name`, `role`, `pay_period`, `hourly_rate`, `hours_worked`, `overtime_hours`, `overtime_pay`, `gross_salary`, `sss_deduction`, `philhealth_deduction`, `pagibig_deduction`, `tax_deduction`, `other_deductions`, `total_deductions`, `net_pay`, `status`, `recorded_by`) VALUES
('John Dela Cruz', 'Cashier', 'Nov 01 - Nov 15, 2026', 85.00, 80.00, 4.00, 425.00, 7225.00, 350.00, 180.00, 100.00, 0.00, 0.00, 630.00, 6595.00, 'paid', 'Store Manager (Maria Santos)'),
('Maria Santos', 'Store Manager', 'Nov 01 - Nov 15, 2026', 150.00, 80.00, 0.00, 0.00, 12000.00, 550.00, 300.00, 100.00, 650.00, 0.00, 1600.00, 10400.00, 'paid', 'Administrator (Admin User)'),
('Kevin Bautista', 'Inventory Clerk', 'Nov 01 - Nov 15, 2026', 80.00, 75.00, 0.00, 0.00, 6000.00, 300.00, 150.00, 100.00, 0.00, 0.00, 550.00, 5450.00, 'paid', 'Store Manager (Maria Santos)');

-- Initial Sales and Sale Items
INSERT INTO `sales` (`id`, `receipt_no`, `cashier_id`, `cashier_name`, `subtotal`, `tax_rate`, `tax_amount`, `discount_type`, `discount_id_no`, `discount_rate`, `discount_amount`, `grand_total`, `payment_method`, `payment_ref_code`, `amount_tendered`, `change_due`, `status`, `created_at`) VALUES
(1, 'REC-20260001', 3, 'Front Cashier (John Dela Cruz)', 143.00, 0.1200, 17.16, 'none', NULL, 0.0000, 0.00, 160.16, 'Cash', NULL, 200.00, 39.84, 'completed', DATE_SUB(NOW(), INTERVAL 2 HOUR)),
(2, 'REC-20260002', 3, 'Front Cashier (John Dela Cruz)', 270.00, 0.1200, 25.92, 'senior_pwd', 'OSCA-94821', 0.2000, 54.00, 241.92, 'GCash', 'GC-749201', 241.92, 0.00, 'completed', DATE_SUB(NOW(), INTERVAL 1 HOUR));

INSERT INTO `sale_items` (`sale_id`, `product_id`, `barcode`, `product_name`, `category`, `unit_cost`, `unit_price`, `quantity`, `total_price`) VALUES
(1, 1, '4800016644815', 'San Miguel Pale Pilsen Can 330ml', 'Beverages', 48.00, 65.00, 1, 65.00),
(1, 3, '4800014118301', 'Coca-Cola Original Taste 1.5L', 'Beverages', 62.00, 78.00, 1, 78.00),
(2, 10, '4800361376045', 'Nescafe Classic Instant Coffee 100g Jar', 'Groceries', 115.00, 145.00, 1, 145.00),
(2, 11, '4800361376052', 'Bear Brand Fortified Powdered Milk 320g', 'Dairy', 98.00, 125.00, 1, 125.00);

-- Initial Audit Logs
INSERT INTO `audit_logs` (`user_id`, `username`, `role`, `action`, `details`, `ip_address`) VALUES
(1, 'admin', 'admin', 'System Init', 'Database initialized and pre-configured successfully.', '127.0.0.1'),
(1, 'admin', 'admin', 'User Login', 'Admin logged in to system setup.', '127.0.0.1'),
(2, 'manager', 'manager', 'Inventory Restock', 'Restocked 48 units of San Miguel Pale Pilsen.', '127.0.0.1'),
(3, 'cashier', 'cashier', 'Sale Transaction', 'Completed transaction REC-20260001 (Cash ₱160.16)', '127.0.0.1'),
(3, 'cashier', 'cashier', 'Sale Transaction', 'Completed transaction REC-20260002 with Senior/PWD Discount OSCA-94821 (GCash ₱241.92)', '127.0.0.1');
