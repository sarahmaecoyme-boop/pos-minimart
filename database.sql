-- ==============================================================================
-- DATABASE SCHEMA: pos_mini_mart_db
-- Mini Mart Express - POS & Computer Accounting Relational Schema
-- Suitable for: MySQL 5.7+ / 8.0+ / MariaDB 10.4+ (XAMPP Standard)
-- Features: Normalized 3NF Tables, Foreign Key Constraints, Indexes,
--           Analytical Views for Accounting, and Complete Demo Seed Data.
-- ==============================================================================

CREATE DATABASE IF NOT EXISTS `pos_mini_mart_db` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `pos_mini_mart_db`;

SET FOREIGN_KEY_CHECKS = 0;

-- Drop existing tables to allow clean re-import
DROP VIEW IF EXISTS `vw_monthly_income_statement`;
DROP VIEW IF EXISTS `vw_product_stock_status`;
DROP VIEW IF EXISTS `vw_senior_pwd_audit`;
DROP VIEW IF EXISTS `vw_top_selling_products`;

DROP TABLE IF EXISTS `system_audit_logs`;
DROP TABLE IF EXISTS `payroll_records`;
DROP TABLE IF EXISTS `inventory_losses`;
DROP TABLE IF EXISTS `stock_batches`;
DROP TABLE IF EXISTS `sale_items`;
DROP TABLE IF EXISTS `sales`;
DROP TABLE IF EXISTS `cash_drawer_shifts`;
DROP TABLE IF EXISTS `products`;
DROP TABLE IF EXISTS `categories`;
DROP TABLE IF EXISTS `customers`;
DROP TABLE IF EXISTS `suppliers`;
DROP TABLE IF EXISTS `system_settings`;
DROP TABLE IF EXISTS `users`;

SET FOREIGN_KEY_CHECKS = 1;

-- ==============================================================================
-- 1. SYSTEM SETTINGS
-- ==============================================================================
CREATE TABLE `system_settings` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `setting_key` VARCHAR(50) NOT NULL UNIQUE,
    `setting_value` TEXT NOT NULL,
    `description` VARCHAR(255) DEFAULT NULL,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ==============================================================================
-- 2. USERS & ROLES
-- ==============================================================================
CREATE TABLE `users` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `username` VARCHAR(50) NOT NULL UNIQUE,
    `password_hash` VARCHAR(255) NOT NULL,
    `full_name` VARCHAR(100) NOT NULL,
    `email` VARCHAR(100) DEFAULT NULL,
    `phone` VARCHAR(30) DEFAULT NULL,
    `role` ENUM('admin', 'manager', 'cashier') NOT NULL DEFAULT 'cashier',
    `status` ENUM('active', 'inactive', 'suspended') NOT NULL DEFAULT 'active',
    `last_login` DATETIME DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_users_role` (`role`),
    INDEX `idx_users_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ==============================================================================
-- 3. PRODUCT CATEGORIES
-- ==============================================================================
CREATE TABLE `categories` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `category_name` VARCHAR(50) NOT NULL UNIQUE,
    `description` VARCHAR(255) DEFAULT NULL,
    `tax_applicable` TINYINT(1) NOT NULL DEFAULT 1,
    `status` ENUM('active', 'inactive') NOT NULL DEFAULT 'active',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ==============================================================================
-- 4. SUPPLIERS
-- ==============================================================================
CREATE TABLE `suppliers` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `company_name` VARCHAR(150) NOT NULL,
    `contact_person` VARCHAR(100) DEFAULT NULL,
    `phone` VARCHAR(50) DEFAULT NULL,
    `email` VARCHAR(100) DEFAULT NULL,
    `address` TEXT DEFAULT NULL,
    `tin_number` VARCHAR(50) DEFAULT NULL,
    `status` ENUM('active', 'inactive') NOT NULL DEFAULT 'active',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ==============================================================================
-- 5. CUSTOMERS & DISCOUNT BENEFICIARIES (Senior / PWD / Loyalty)
-- ==============================================================================
CREATE TABLE `customers` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `full_name` VARCHAR(100) NOT NULL,
    `customer_type` ENUM('regular', 'senior_citizen', 'pwd', 'employee') NOT NULL DEFAULT 'regular',
    `id_card_number` VARCHAR(50) DEFAULT NULL COMMENT 'OSCA / PWD ID number for compliance',
    `phone` VARCHAR(30) DEFAULT NULL,
    `email` VARCHAR(100) DEFAULT NULL,
    `loyalty_points` INT NOT NULL DEFAULT 0,
    `status` ENUM('active', 'inactive') NOT NULL DEFAULT 'active',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_customers_id_card` (`id_card_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ==============================================================================
-- 6. PRODUCTS & INVENTORY
-- ==============================================================================
CREATE TABLE `products` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `barcode` VARCHAR(50) NOT NULL UNIQUE,
    `product_name` VARCHAR(150) NOT NULL,
    `category_id` INT DEFAULT NULL,
    `supplier_id` INT DEFAULT NULL,
    `cost_price` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `selling_price` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `stock_quantity` INT NOT NULL DEFAULT 0,
    `min_stock_alert` INT NOT NULL DEFAULT 10,
    `expiration_date` DATE DEFAULT NULL,
    `unit_of_measure` VARCHAR(20) NOT NULL DEFAULT 'pcs',
    `image_url` TEXT DEFAULT NULL,
    `status` ENUM('active', 'inactive', 'archived') NOT NULL DEFAULT 'active',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`category_id`) REFERENCES `categories`(`id`) ON DELETE SET NULL,
    FOREIGN KEY (`supplier_id`) REFERENCES `suppliers`(`id`) ON DELETE SET NULL,
    INDEX `idx_products_barcode` (`barcode`),
    INDEX `idx_products_stock` (`stock_quantity`),
    INDEX `idx_products_exp` (`expiration_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ==============================================================================
-- 7. STOCK BATCHES / RESTOCK LOGS
-- ==============================================================================
CREATE TABLE `stock_batches` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `product_id` INT NOT NULL,
    `supplier_id` INT DEFAULT NULL,
    `quantity_added` INT NOT NULL,
    `purchase_unit_cost` DECIMAL(10,2) NOT NULL,
    `total_purchase_cost` DECIMAL(10,2) NOT NULL,
    `batch_number` VARCHAR(50) DEFAULT NULL,
    `expiration_date` DATE DEFAULT NULL,
    `invoice_reference` VARCHAR(50) DEFAULT NULL,
    `notes` TEXT DEFAULT NULL,
    `received_by` VARCHAR(100) NOT NULL,
    `received_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`product_id`) REFERENCES `products`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`supplier_id`) REFERENCES `suppliers`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ==============================================================================
-- 8. INVENTORY LOSSES & SPOILAGE
-- ==============================================================================
CREATE TABLE `inventory_losses` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `product_id` INT NOT NULL,
    `product_name` VARCHAR(150) NOT NULL,
    `quantity_lost` INT NOT NULL,
    `unit_cost` DECIMAL(10,2) NOT NULL,
    `total_loss_value` DECIMAL(10,2) NOT NULL,
    `reason` ENUM('expired', 'damaged', 'lost', 'shrinkage', 'other') NOT NULL DEFAULT 'damaged',
    `remarks` TEXT DEFAULT NULL,
    `recorded_by` VARCHAR(100) NOT NULL,
    `recorded_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`product_id`) REFERENCES `products`(`id`) ON DELETE CASCADE,
    INDEX `idx_losses_date` (`recorded_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ==============================================================================
-- 9. CASH DRAWER SHIFTS
-- ==============================================================================
CREATE TABLE `cash_drawer_shifts` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `cashier_id` INT NOT NULL,
    `cashier_name` VARCHAR(100) NOT NULL,
    `opening_cash` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `closing_cash` DECIMAL(10,2) DEFAULT NULL,
    `expected_cash` DECIMAL(10,2) DEFAULT NULL,
    `cash_discrepancy` DECIMAL(10,2) DEFAULT 0.00,
    `shift_start` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `shift_end` DATETIME DEFAULT NULL,
    `status` ENUM('open', 'closed') NOT NULL DEFAULT 'open',
    FOREIGN KEY (`cashier_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ==============================================================================
-- 10. SALES TRANSACTIONS
-- ==============================================================================
CREATE TABLE `sales` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `receipt_no` VARCHAR(50) NOT NULL UNIQUE,
    `shift_id` INT DEFAULT NULL,
    `cashier_id` INT DEFAULT NULL,
    `cashier_name` VARCHAR(100) NOT NULL,
    `customer_id` INT DEFAULT NULL,
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
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`cashier_id`) REFERENCES `users`(`id`) ON DELETE SET NULL,
    FOREIGN KEY (`customer_id`) REFERENCES `customers`(`id`) ON DELETE SET NULL,
    INDEX `idx_sales_receipt` (`receipt_no`),
    INDEX `idx_sales_created` (`created_at`),
    INDEX `idx_sales_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ==============================================================================
-- 11. SALE ITEMS (Line Items)
-- ==============================================================================
CREATE TABLE `sale_items` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `sale_id` INT NOT NULL,
    `product_id` INT DEFAULT NULL,
    `barcode` VARCHAR(50) NOT NULL,
    `product_name` VARCHAR(150) NOT NULL,
    `category_name` VARCHAR(50) DEFAULT NULL,
    `unit_cost` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `unit_price` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `quantity` INT NOT NULL DEFAULT 1,
    `subtotal_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`sale_id`) REFERENCES `sales`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`product_id`) REFERENCES `products`(`id`) ON DELETE SET NULL,
    INDEX `idx_sale_items_product` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ==============================================================================
-- 12. HR & PAYROLL RECORDS
-- ==============================================================================
CREATE TABLE `payroll_records` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `employee_id` INT DEFAULT NULL,
    `employee_name` VARCHAR(100) NOT NULL,
    `role_position` VARCHAR(50) NOT NULL DEFAULT 'Cashier',
    `pay_period` VARCHAR(50) NOT NULL,
    `hourly_rate` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `regular_hours` DECIMAL(6,2) NOT NULL DEFAULT 0.00,
    `overtime_hours` DECIMAL(6,2) NOT NULL DEFAULT 0.00,
    `overtime_pay` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `gross_pay` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `sss_deduction` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `philhealth_deduction` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `pagibig_deduction` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `withholding_tax` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `other_deductions` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `total_deductions` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `net_take_home_pay` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `disbursement_status` ENUM('paid', 'pending', 'cancelled') NOT NULL DEFAULT 'paid',
    `processed_by` VARCHAR(100) NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`employee_id`) REFERENCES `users`(`id`) ON DELETE SET NULL,
    INDEX `idx_payroll_period` (`pay_period`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ==============================================================================
-- 13. SYSTEM AUDIT LOG TRAIL
-- ==============================================================================
CREATE TABLE `system_audit_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT DEFAULT NULL,
    `username` VARCHAR(100) NOT NULL,
    `role` VARCHAR(50) NOT NULL,
    `action` VARCHAR(100) NOT NULL,
    `details` TEXT DEFAULT NULL,
    `ip_address` VARCHAR(50) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_audit_action` (`action`),
    INDEX `idx_audit_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ==============================================================================
-- 14. ANALYTICAL SQL VIEWS (For Accounting & Reporting)
-- ==============================================================================

-- VIEW 1: Product Stock & Alerts View
CREATE VIEW `vw_product_stock_status` AS
SELECT 
    p.id,
    p.barcode,
    p.product_name,
    c.category_name,
    s.company_name AS supplier_name,
    p.cost_price,
    p.selling_price,
    p.stock_quantity,
    p.min_stock_alert,
    p.expiration_date,
    CASE 
        WHEN p.stock_quantity <= 0 THEN 'OUT_OF_STOCK'
        WHEN p.stock_quantity <= p.min_stock_alert THEN 'LOW_STOCK'
        ELSE 'NORMAL'
    END AS stock_status,
    CASE 
        WHEN p.expiration_date IS NULL THEN 'NO_DATE'
        WHEN p.expiration_date < CURDATE() THEN 'EXPIRED'
        WHEN p.expiration_date <= DATE_ADD(CURDATE(), INTERVAL 30 DAY) THEN 'EXPIRING_SOON'
        ELSE 'VALID'
    END AS expiration_status
FROM `products` p
LEFT JOIN `categories` c ON p.category_id = c.id
LEFT JOIN `suppliers` s ON p.supplier_id = s.id;

-- VIEW 2: Top Selling Products
CREATE VIEW `vw_top_selling_products` AS
SELECT 
    si.barcode,
    si.product_name,
    si.category_name,
    SUM(si.quantity) AS total_units_sold,
    SUM(si.subtotal_amount) AS total_gross_sales,
    SUM((si.unit_price - si.unit_cost) * si.quantity) AS estimated_gross_profit
FROM `sale_items` si
JOIN `sales` s ON si.sale_id = s.id
WHERE s.status = 'completed'
GROUP BY si.barcode, si.product_name, si.category_name
ORDER BY total_units_sold DESC;

-- VIEW 3: Senior Citizen & PWD Compliance Audit View
CREATE VIEW `vw_senior_pwd_audit` AS
SELECT 
    s.receipt_no,
    s.created_at AS transaction_time,
    s.cashier_name,
    s.discount_id_no AS osca_pwd_id,
    s.subtotal AS original_amount,
    s.discount_amount AS discount_granted,
    s.tax_amount AS vat_amount,
    s.grand_total AS final_paid,
    s.payment_method
FROM `sales` s
WHERE s.discount_type = 'senior_pwd' AND s.status = 'completed'
ORDER BY s.created_at DESC;

-- VIEW 4: Monthly Income Statement Summary
CREATE VIEW `vw_monthly_income_statement` AS
SELECT 
    DATE_FORMAT(s.created_at, '%Y-%m') AS sales_month,
    COALESCE(SUM(s.grand_total), 0) AS total_sales_revenue,
    COALESCE((
        SELECT SUM(si.unit_cost * si.quantity)
        FROM `sale_items` si
        JOIN `sales` s2 ON si.sale_id = s2.id
        WHERE s2.status = 'completed' AND DATE_FORMAT(s2.created_at, '%Y-%m') = DATE_FORMAT(s.created_at, '%Y-%m')
    ), 0) AS total_cost_of_goods_sold,
    (
        COALESCE(SUM(s.grand_total), 0) - 
        COALESCE((
            SELECT SUM(si.unit_cost * si.quantity)
            FROM `sale_items` si
            JOIN `sales` s2 ON si.sale_id = s2.id
            WHERE s2.status = 'completed' AND DATE_FORMAT(s2.created_at, '%Y-%m') = DATE_FORMAT(s.created_at, '%Y-%m')
        ), 0)
    ) AS gross_profit_margin,
    COALESCE((
        SELECT SUM(net_take_home_pay)
        FROM `payroll_records`
        WHERE disbursement_status = 'paid' AND DATE_FORMAT(created_at, '%Y-%m') = DATE_FORMAT(s.created_at, '%Y-%m')
    ), 0) AS total_payroll_expense,
    COALESCE((
        SELECT SUM(total_loss_value)
        FROM `inventory_losses`
        WHERE DATE_FORMAT(recorded_at, '%Y-%m') = DATE_FORMAT(s.created_at, '%Y-%m')
    ), 0) AS total_inventory_losses
FROM `sales` s
WHERE s.status = 'completed'
GROUP BY DATE_FORMAT(s.created_at, '%Y-%m');

-- ==============================================================================
-- 15. SEED DATA POPULATION
-- ==============================================================================

-- System Settings
INSERT INTO `system_settings` (`setting_key`, `setting_value`, `description`) VALUES
('store_name', 'Mini Mart Express', 'Store Name on Receipts and UI'),
('store_branch', 'Branch #04 - Main Boulevard', 'Store Branch Details'),
('store_tin', '294-819-391-000', 'BIR VAT Registered TIN'),
('store_phone', '+63 (02) 8923-4567', 'Store Contact Number'),
('default_tax_rate', '0.12', 'Standard VAT rate (12%)'),
('low_stock_threshold', '10', 'Default product alert threshold'),
('currency_symbol', '₱', 'Currency symbol');

-- Users (Demo passwords are '123456')
INSERT INTO `users` (`id`, `username`, `password_hash`, `full_name`, `email`, `role`, `status`) VALUES
(1, 'admin', '$2y$10$4y9pQ.5tF4r4uYp6Efg6bO4J591bOq.z90e9jKqR8M2zE2rL9.V9m', 'Administrator (Admin User)', 'admin@minimart.local', 'admin', 'active'),
(2, 'manager', '$2y$10$4y9pQ.5tF4r4uYp6Efg6bO4J591bOq.z90e9jKqR8M2zE2rL9.V9m', 'Store Manager (Maria Santos)', 'manager@minimart.local', 'manager', 'active'),
(3, 'cashier', '$2y$10$4y9pQ.5tF4r4uYp6Efg6bO4J591bOq.z90e9jKqR8M2zE2rL9.V9m', 'Front Cashier (John Dela Cruz)', 'cashier@minimart.local', 'cashier', 'active');

-- Categories
INSERT INTO `categories` (`id`, `category_name`, `description`, `tax_applicable`, `status`) VALUES
(1, 'Beverages', 'Cold drinks, sodas, beer, juices, and mineral water', 1, 'active'),
(2, 'Snacks', 'Potato chips, crackers, and packed snacks', 1, 'active'),
(3, 'Noodles', 'Instant noodles, ramen, and cup noodles', 1, 'active'),
(4, 'Groceries', 'Canned tuna, corned beef, condiments, coffee', 1, 'active'),
(5, 'Dairy', 'Powdered milk, fresh milk, and dairy items', 1, 'active'),
(6, 'Hygiene', 'Bath soaps, shampoos, toothpaste, toiletries', 1, 'active'),
(7, 'Bakery', 'Breads, pastries, and baked goods', 1, 'active');

-- Suppliers
INSERT INTO `suppliers` (`id`, `company_name`, `contact_person`, `phone`, `email`, `address`, `status`) VALUES
(1, 'San Miguel Distribution Co.', 'Robert Tan', '0917-111-2233', 'orders@sanmiguel.com.ph', 'Pasig City, Metro Manila', 'active'),
(2, 'Universal Robina Corp (URC)', 'Elena Gomez', '0918-222-3344', 'supply@urc.com.ph', 'Quezon City, Metro Manila', 'active'),
(3, 'Nestle Philippines Inc.', 'Carlos Reyes', '0919-333-4455', 'sales@nestle.com.ph', 'Makati City, Metro Manila', 'active'),
(4, 'Coca-Cola Beverages PH', 'Dennis Lim', '0920-444-5566', 'distro@coca-cola.com.ph', 'Taguig City, Metro Manila', 'active'),
(5, 'Monde Nissin Corporation', 'Grace Aquino', '0921-555-6677', 'orders@mondenissin.com', 'Santa Rosa, Laguna', 'active'),
(6, 'Procter & Gamble Philippines', 'Patricia Diaz', '0922-666-7788', 'contact@pgph.com', 'BGC, Taguig City', 'active');

-- Customers (Senior Citizen / PWD records)
INSERT INTO `customers` (`id`, `full_name`, `customer_type`, `id_card_number`, `phone`, `loyalty_points`, `status`) VALUES
(1, 'Teresita Ramos', 'senior_citizen', 'OSCA-94821', '0917-555-1234', 15, 'active'),
(2, 'Edgardo Bautista', 'pwd', 'PWD-84910', '0918-666-2345', 10, 'active'),
(3, 'Carlos Mendoza', 'regular', NULL, '0919-777-3456', 45, 'active');

-- Products
INSERT INTO `products` (`id`, `barcode`, `product_name`, `category_id`, `supplier_id`, `cost_price`, `selling_price`, `stock_quantity`, `min_stock_alert`, `expiration_date`, `image_url`, `status`) VALUES
(1, '4800016644815', 'San Miguel Pale Pilsen Can 330ml', 1, 1, 48.00, 65.00, 48, 10, '2027-06-30', 'https://images.unsplash.com/photo-1608278049247-f7035544d67d?w=300', 'active'),
(2, '4800016053013', 'San Miguel Light 330ml Bottle', 1, 1, 46.00, 62.00, 8, 10, '2027-05-15', 'https://images.unsplash.com/photo-1535958636474-b021ee887b13?w=300', 'active'),
(3, '4800014118301', 'Coca-Cola Original Taste 1.5L', 1, 4, 62.00, 78.00, 24, 10, '2027-04-20', 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=300', 'active'),
(4, '4800014118318', 'Sprite Lemon-Lime 1.5L', 1, 4, 60.00, 75.00, 15, 10, '2027-03-10', 'https://images.unsplash.com/photo-1625772299848-391b6a87d7b3?w=300', 'active'),
(5, '4800011123456', 'Nature Spring Mineral Water 500ml', 1, 1, 10.00, 18.00, 60, 15, '2027-12-31', 'https://images.unsplash.com/photo-1548839140-29a749e1bc4e?w=300', 'active'),
(6, '4800047812908', 'Piattos Cheese Flavored Chips 85g', 2, 2, 32.00, 42.00, 4, 10, '2026-11-28', 'https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=300', 'active'),
(7, '4800047812915', 'Nova Multigrain Country Cheddar 78g', 2, 2, 31.00, 41.00, 32, 10, '2027-01-15', 'https://images.unsplash.com/photo-1527842891421-42eec6e703ea?w=300', 'active'),
(8, '4807770270016', 'Lucky Me! Instant Pancit Canton Original', 3, 5, 12.00, 17.50, 50, 15, '2027-08-20', 'https://images.unsplash.com/photo-1612927601601-6638404737ce?w=300', 'active'),
(9, '4807770270023', 'Lucky Me! Pancit Canton Chilimansi', 3, 5, 12.00, 17.50, 6, 15, '2026-11-25', 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=300', 'active'),
(10, '4800361376045', 'Nescafe Classic Instant Coffee 100g Jar', 4, 3, 115.00, 145.00, 18, 5, '2027-10-10', 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=300', 'active'),
(11, '4800361376052', 'Bear Brand Fortified Powdered Milk 320g', 5, 3, 98.00, 125.00, 3, 10, '2026-12-05', 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=300', 'active'),
(12, '4800092112349', 'Century Tuna Flakes in Oil 180g', 4, 1, 38.00, 49.00, 40, 10, '2028-02-14', 'https://images.unsplash.com/photo-1534483509719-3feaee7c30da?w=300', 'active'),
(13, '4800092112356', 'Argentina Corned Beef 175g', 4, 1, 36.00, 46.50, 35, 10, '2028-03-20', 'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=300', 'active'),
(14, '4800012398741', 'Safeguard Pure White Soap 130g', 6, 6, 42.00, 54.00, 25, 8, '2028-09-30', 'https://images.unsplash.com/photo-1607613009820-a29f7bb81c04?w=300', 'active'),
(15, '4800012398758', 'Colgate Total Clean Mint Toothpaste 150g', 6, 6, 85.00, 110.00, 5, 10, '2027-02-18', 'https://images.unsplash.com/photo-1559591937-e1032b4b4556?w=300', 'active'),
(16, '4807770112233', 'Monde Special Mamon Classic 6s', 7, 5, 52.00, 68.00, 2, 8, '2026-11-20', 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=300', 'active');

-- Stock Batches
INSERT INTO `stock_batches` (`product_id`, `supplier_id`, `quantity_added`, `purchase_unit_cost`, `total_purchase_cost`, `batch_number`, `expiration_date`, `notes`, `received_by`) VALUES
(1, 1, 48, 48.00, 2304.00, 'BATCH-SMC-091', '2027-06-30', 'Monthly warehouse delivery', 'Store Manager (Maria Santos)'),
(6, 2, 20, 32.00, 640.00, 'BATCH-URC-442', '2026-11-28', 'Snack aisle delivery', 'Store Manager (Maria Santos)'),
(10, 3, 20, 115.00, 2300.00, 'BATCH-NES-102', '2027-10-10', 'Coffee restocking', 'Store Manager (Maria Santos)');

-- Inventory Losses
INSERT INTO `inventory_losses` (`product_id`, `product_name`, `quantity_lost`, `unit_cost`, `total_loss_value`, `reason`, `remarks`, `recorded_by`) VALUES
(6, 'Piattos Cheese Flavored Chips 85g', 2, 32.00, 64.00, 'damaged', 'Crushed during shelf stocking', 'Store Manager (Maria Santos)'),
(16, 'Monde Special Mamon Classic 6s', 1, 52.00, 52.00, 'expired', 'Past pull-out date', 'Store Manager (Maria Santos)');

-- Payroll Records
INSERT INTO `payroll_records` (`employee_id`, `employee_name`, `role_position`, `pay_period`, `hourly_rate`, `regular_hours`, `overtime_hours`, `overtime_pay`, `gross_pay`, `sss_deduction`, `philhealth_deduction`, `pagibig_deduction`, `withholding_tax`, `other_deductions`, `total_deductions`, `net_take_home_pay`, `disbursement_status`, `processed_by`) VALUES
(3, 'John Dela Cruz', 'Cashier', 'Nov 01 - Nov 15, 2026', 85.00, 80.00, 4.00, 425.00, 7225.00, 350.00, 180.00, 100.00, 0.00, 0.00, 630.00, 6595.00, 'paid', 'Store Manager (Maria Santos)'),
(2, 'Maria Santos', 'Store Manager', 'Nov 01 - Nov 15, 2026', 150.00, 80.00, 0.00, 0.00, 12000.00, 550.00, 300.00, 100.00, 650.00, 0.00, 1600.00, 10400.00, 'paid', 'Administrator (Admin User)'),
(NULL, 'Kevin Bautista', 'Inventory Clerk', 'Nov 01 - Nov 15, 2026', 80.00, 75.00, 0.00, 0.00, 6000.00, 300.00, 150.00, 100.00, 0.00, 0.00, 550.00, 5450.00, 'paid', 'Store Manager (Maria Santos)');

-- Sales and Line Items
INSERT INTO `sales` (`id`, `receipt_no`, `cashier_id`, `cashier_name`, `customer_id`, `subtotal`, `tax_rate`, `tax_amount`, `discount_type`, `discount_id_no`, `discount_rate`, `discount_amount`, `grand_total`, `payment_method`, `payment_ref_code`, `amount_tendered`, `change_due`, `status`, `created_at`) VALUES
(1, 'REC-20260001', 3, 'Front Cashier (John Dela Cruz)', 3, 143.00, 0.1200, 17.16, 'none', NULL, 0.0000, 0.00, 160.16, 'Cash', NULL, 200.00, 39.84, 'completed', DATE_SUB(NOW(), INTERVAL 2 HOUR)),
(2, 'REC-20260002', 3, 'Front Cashier (John Dela Cruz)', 1, 270.00, 0.1200, 25.92, 'senior_pwd', 'OSCA-94821', 0.2000, 54.00, 241.92, 'GCash', 'GC-749201', 241.92, 0.00, 'completed', DATE_SUB(NOW(), INTERVAL 1 HOUR));

INSERT INTO `sale_items` (`sale_id`, `product_id`, `barcode`, `product_name`, `category_name`, `unit_cost`, `unit_price`, `quantity`, `subtotal_amount`) VALUES
(1, 1, '4800016644815', 'San Miguel Pale Pilsen Can 330ml', 'Beverages', 48.00, 65.00, 1, 65.00),
(1, 3, '4800014118301', 'Coca-Cola Original Taste 1.5L', 'Beverages', 62.00, 78.00, 1, 78.00),
(2, 10, '4800361376045', 'Nescafe Classic Instant Coffee 100g Jar', 'Groceries', 115.00, 145.00, 1, 145.00),
(2, 11, '4800361376052', 'Bear Brand Fortified Powdered Milk 320g', 'Dairy', 98.00, 125.00, 1, 125.00);

-- Audit Trail
INSERT INTO `system_audit_logs` (`user_id`, `username`, `role`, `action`, `details`, `ip_address`) VALUES
(1, 'admin', 'admin', 'System Init', 'Database schema pos_mini_mart_db initialized successfully.', '127.0.0.1'),
(1, 'admin', 'admin', 'User Login', 'Admin user authenticated.', '127.0.0.1'),
(3, 'cashier', 'cashier', 'Sale Transaction', 'Processed sale #REC-20260001 (₱160.16 Cash)', '127.0.0.1'),
(3, 'cashier', 'cashier', 'Sale Transaction', 'Processed sale #REC-20260002 with Senior Citizen Discount OSCA-94821 (₱241.92 GCash)', '127.0.0.1');
