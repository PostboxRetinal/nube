-- Initialize orders-db database
-- This script runs automatically on first container start

-- Create app-orders user for localhost and remote connections
CREATE USER IF NOT EXISTS 'app-orders'@'localhost' IDENTIFIED BY 'app-password';
CREATE USER IF NOT EXISTS 'app-orders'@'%' IDENTIFIED BY 'app-password';

-- Grant privileges to app-orders on orders-db
GRANT ALL PRIVILEGES ON `orders-db`.* TO 'app-orders'@'localhost';
GRANT ALL PRIVILEGES ON `orders-db`.* TO 'app-orders'@'%';
FLUSH PRIVILEGES;

-- Create orders table
CREATE TABLE IF NOT EXISTS orders (
    id VARCHAR(36) PRIMARY KEY,
    user_id INT NOT NULL,
    total DECIMAL(10,2) NOT NULL,
    created_at DATETIME NOT NULL
);

-- Create order_items table
CREATE TABLE IF NOT EXISTS order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id VARCHAR(36) NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    CONSTRAINT fk_order_items_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
);