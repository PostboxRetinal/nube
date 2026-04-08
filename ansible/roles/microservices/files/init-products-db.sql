-- Initialize products-db database
-- This script runs automatically on first container start

-- Create app-products user for localhost and remote connections
CREATE USER IF NOT EXISTS 'app-products'@'localhost' IDENTIFIED BY 'app-password';
CREATE USER IF NOT EXISTS 'app-products'@'%' IDENTIFIED BY 'app-password';

-- Grant privileges to app-products on products-db
GRANT ALL PRIVILEGES ON `products-db`.* TO 'app-products'@'localhost';
GRANT ALL PRIVILEGES ON `products-db`.* TO 'app-products'@'%';
FLUSH PRIVILEGES;

-- Create products table
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT NULL,
    price DECIMAL(10,2) NOT NULL,
    stock INT NOT NULL
);