<?php
try {
    $pdo = new PDO('mysql:host=localhost;dbname=backend_adminfix', 'root', '');
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    $sql = file_get_contents(__DIR__ . '/create_messages_table.sql');
    $pdo->exec($sql);
    echo "Messages table created successfully!\n";
} catch(Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
?>
