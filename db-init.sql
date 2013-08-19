DROP DATABASE fbdata;

CREATE DATABASE IF NOT EXISTS fbdata;

CREATE USER 'fbresearch'@'%' IDENTIFIED BY 'fbresearch';
GRANT ALL ON fbdata.* TO 'fbresearch'@'%';

USE fbdata;

CREATE TABLE IF NOT EXISTS users (seq BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    userid BIGINT NOT NULL, UNIQUE INDEX idx_userid (userid), 
    username VARCHAR(255) NOT NULL, UNIQUE INDEX idx_username (username), 
    sta_frnd TINYINT(1) UNSIGNED DEFAULT NULL, INDEX idx_sta_frnd (sta_frnd), 
    sta_like TINYINT(1) UNSIGNED DEFAULT NULL, INDEX idx_sta_like (sta_like),
    sta_info TINYINT(1) UNSIGNED DEFAULT NULL, INDEX idx_sta_info (sta_info), 
    ts_frnd TIMESTAMP DEFAULT 0, ts_like TIMESTAMP DEFAULT 0, ts_info TIMESTAMP DEFAULT 0,
    frndlist LONGTEXT DEFAULT NULL,
    basicinfo LONGTEXT DEFAULT NULL)
    ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
