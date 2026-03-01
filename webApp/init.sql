CREATE DATABASE IF NOT EXISTS users_db;
CREATE DATABASE IF NOT EXISTS products_db;
CREATE DATABASE IF NOT EXISTS orders_db;

USE users_db;

CREATE TABLE users (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255),
    email VARCHAR(255),
    username VARCHAR(255),
    password VARCHAR(255)
);

INSERT INTO users VALUES
    (null, "Juan", "juan12@gmail.com", "JuanSolano23", "juan123"),
    (null, "Maria", "mariaT6@gmail.com", "MariaSoto_6", "maria456");

USE products_db;

CREATE TABLE products (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    stock INT NOT NULL
);

INSERT INTO products VALUES
    (null, "Keyboard", "Mechanical keyboard", 79.99, 15),
    (null, "Mouse", "Wireless mouse", 29.99, 40);

USE orders_db;

CREATE TABLE orders (
    id CHAR(36) NOT NULL PRIMARY KEY,
    user_id INT NOT NULL,
    total DECIMAL(10,2) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE order_items (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    order_id CHAR(36) NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
);

INSERT INTO orders VALUES
    ("00000000-0000-0000-0000-000000000001", 1, 139.97, NOW());

INSERT INTO order_items VALUES
    (null, "00000000-0000-0000-0000-000000000001", 1, 1, 79.99),
    (null, "00000000-0000-0000-0000-000000000001", 2, 2, 59.98);