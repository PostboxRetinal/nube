-- Initialize users-db database
-- This script runs automatically on first container start

-- Create app-users user for localhost and remote connections
CREATE USER IF NOT EXISTS 'app-users'@'localhost' IDENTIFIED BY 'app-password';
CREATE USER IF NOT EXISTS 'app-users'@'%' IDENTIFIED BY 'app-password';

-- Grant privileges to app-users on users-db
GRANT ALL PRIVILEGES ON `users-db`.* TO 'app-users'@'localhost';
GRANT ALL PRIVILEGES ON `users-db`.* TO 'app-users'@'%';
FLUSH PRIVILEGES;

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    username VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(100) NOT NULL
);