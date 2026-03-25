
CREATE DATABASE IF NOT EXISTS app_db;
USE app_db;

CREATE TABLE IF NOT EXISTS users (
    id int NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name varchar(255),
    email varchar(255),
    username varchar(255),
    password varchar(255)
);

CREATE TABLE IF NOT EXISTS products (
    id int NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name varchar(255) NOT NULL,
    description text,
    price decimal(10,2) NOT NULL,
    stock int NOT NULL
);

INSERT INTO users VALUES(null, "Sebastian", "sebastian@gmail.com", "sebastian", "123"),
    (null, "Laura", "laura@gmail.com", "laura", "456");

INSERT INTO products VALUES
    (null, "Teclado RGB", "Redragon K552 RGB", 79.99, 10),
    (null, "Attack Shark X11", "Wireless Gaming Mouse", 49.99, 25);

