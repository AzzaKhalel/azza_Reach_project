<?php
    define('USER', $USER);
    define('PASSWORD', $PASSWORD);
    define('HOST', $HOST);
    define('DATABASE', $DATABASE);
    try {
        $connection = new PDO("mysql:host=".HOST.";dbname=".DATABASE, USER, PASSWORD);
    } catch (PDOException $e) {
        exit("Error: " . $e->getMessage());
    }
?>