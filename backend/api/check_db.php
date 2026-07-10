<?php
header('Content-Type: application/json');
require_once '../config/database.php';

try {
    $db = Database::getInstance()->getConnection();
    
    // Check columns
    $stmt = $db->query("DESCRIBE users");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Check sellers
    $stmt2 = $db->query("SELECT id, name, role, store_name, map_active, latitude, longitude FROM users WHERE role = 'seller'");
    $sellers = $stmt2->fetchAll(PDO::FETCH_ASSOC);
    
    // Check all users
    $stmt3 = $db->query("SELECT id, name, role, store_name, map_active FROM users");
    $all_users = $stmt3->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'columns' => $columns,
        'sellers' => $sellers,
        'all_users' => $all_users
    ], JSON_PRETTY_PRINT);
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ], JSON_PRETTY_PRINT);
}
