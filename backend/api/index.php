<?php
// api/index.php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, User-Id");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit(0);
}

require_once '../config/database.php';

$db = Database::getInstance()->getConnection();
$method = $_SERVER['REQUEST_METHOD'];

// ============ AMBIL PATH ============
$path = '';

if (isset($_GET['path']) && !empty($_GET['path'])) {
    $path = $_GET['path'];
} else {
    $requestUri = $_SERVER['REQUEST_URI'];
    
    if (strpos($requestUri, '/api/index.php/') !== false) {
        $parts = explode('/api/index.php/', $requestUri);
        $path = explode('?', $parts[1])[0];
    } else if (strpos($requestUri, '/api/') !== false) {
        $parts = explode('/api/', $requestUri);
        $path = explode('?', $parts[1])[0];
    } else if (strpos($requestUri, 'index.php?') !== false) {
        parse_str(parse_url($requestUri, PHP_URL_QUERY), $query);
        if (isset($query['path'])) {
            $path = $query['path'];
        }
    }
    
    if (strpos($path, '?') !== false) {
        $path = substr($path, 0, strpos($path, '?'));
    }
}

// Parse JSON input
$input = json_decode(file_get_contents('php://input'), true);
$queryParams = $_GET;

$response = [];

// ============ ROUTING ============
switch ($path) {
    // AUTH
    case 'register':
        if ($method == 'POST') $response = handleRegister($db, $input);
        break;
    case 'login':
        if ($method == 'POST') $response = handleLogin($db, $input);
        break;
        
    // PRODUCTS
    case 'products':
        if ($method == 'GET') $response = handleGetProducts($db, $queryParams);
        else if ($method == 'POST') $response = handleCreateProduct($db, $input);
        break;
    case 'product':
        if ($method == 'PUT') $response = handleUpdateProduct($db, $input, $queryParams);
        else if ($method == 'DELETE') $response = handleDeleteProduct($db, $queryParams);
        break;
        
    // ORDERS
    case 'orders':
        if ($method == 'GET') $response = handleGetOrders($db, $queryParams);
        else if ($method == 'POST') $response = handleCreateOrder($db, $input);
        break;
    case 'order/status':
        if ($method == 'PUT') $response = handleUpdateOrderStatus($db, $input);
        break;
    case 'order/accept':
        if ($method == 'POST') $response = handleAcceptOrder($db, $input);
        break;
    case 'order/reject':
        if ($method == 'POST') $response = handleRejectOrder($db, $input);
        break;
    case 'order/complete':
        if ($method == 'POST') $response = handleCompleteOrder($db, $input);
        break;
        
    // QRIS
    case 'qris':
        if ($method == 'GET') $response = handleGetQris($db, $queryParams);
        break;
    case 'qris/upload':
        if ($method == 'POST') $response = handleUploadQris($db, $input);
        break;
        
    // PAYMENT
    case 'payment/qris':
        if ($method == 'GET') $response = handleGetQrisPayment($db, $queryParams);
        break;
    case 'payment/confirm':
        if ($method == 'POST') $response = handleConfirmPayment($db, $input);
        break;
        
    // PROFILE
    case 'profile':
        if ($method == 'PUT') $response = handleUpdateProfile($db, $input);
        break;
    case 'upload':
        if ($method == 'POST') $response = handleUploadImage($db);
        break;
    case 'uploads':
        if ($method == 'GET') {
            $file = $_GET['file'] ?? '';
            if (strpos($file, 'uploads/') === 0 && strpos($file, '..') === false) {
                $filePath = __DIR__ . '/../' . $file;
                if (file_exists($filePath) && is_file($filePath)) {
                    header("Access-Control-Allow-Origin: *");
                    header("Content-Type: " . mime_content_type($filePath));
                    readfile($filePath);
                    exit;
                }
            }
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'File not found']);
            exit;
        }
        break;
        
    // STATS
    case 'stats':
        if ($method == 'GET') $response = handleGetStats($db, $queryParams);
        break;
        
    // NEARBY SELLERS
    case 'sellers/nearby':
        if ($method == 'GET') $response = handleGetNearbySellers($db, $queryParams);
        break;
    
    // CHAT
    case 'chat/conversations':
        if ($method == 'GET') $response = handleGetConversations($db, $queryParams);
        break;
    case 'chat/messages':
        if ($method == 'GET') $response = handleGetMessages($db, $queryParams);
        break;
    case 'chat/send':
        if ($method == 'POST') $response = handleSendMessage($db, $input);
        break;
    case 'chat/read':
        if ($method == 'PUT') $response = handleMarkAsRead($db, $input);
        break;
        
    default:
        $response = ['success' => false, 'message' => "Endpoint not found: path='$path'"];
        break;
}

echo json_encode($response);

// ============ HANDLER FUNCTIONS ============

// ==================== REGISTER ====================

function handleRegister($db, $input) {
    try {
        // Cek email sudah terdaftar
        $stmt = $db->prepare("SELECT id FROM users WHERE email = ?");
        $stmt->execute([$input['email']]);
        if ($stmt->fetch()) {
            echo json_encode(['success' => false, 'message' => 'Email already registered']);
            exit;
        }
        
        // Insert user (phone bisa null)
        $phone = isset($input['phone']) ? $input['phone'] : null;
        
        $stmt = $db->prepare("INSERT INTO users (name, email, password, phone, role) VALUES (?, ?, ?, ?, ?)");
        $hashedPassword = password_hash($input['password'], PASSWORD_DEFAULT);
        $stmt->execute([
            $input['name'],
            $input['email'],
            $hashedPassword,
            $phone,
            $input['role'] ?? 'buyer'
        ]);
        
        $userId = $db->lastInsertId();
        
        // Jika role = seller, buat store_name otomatis
        if (($input['role'] ?? 'buyer') == 'seller') {
            $storeName = 'Toko ' . $input['name'];
            $stmt = $db->prepare("UPDATE users SET store_name = ? WHERE id = ?");
            $stmt->execute([$storeName, $userId]);
        }
        
        // Ambil data user
        $stmt = $db->prepare("SELECT id, name, email, phone, role, profile_picture, store_name, qris_image FROM users WHERE id = ?");
        $stmt->execute([$userId]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        
        // Buat token
        $token = base64_encode(json_encode([
            'id' => $user['id'],
            'email' => $user['email'],
            'exp' => time() + 86400
        ]));
        
        echo json_encode([
            'success' => true,
            'data' => [
                'user' => $user,
                'token' => $token
            ]
        ]);
        exit;
    } catch(PDOException $e) {
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        exit;
    }
}

// ==================== LOGIN ====================

function handleLogin($db, $input) {
    try {
        $stmt = $db->prepare("SELECT * FROM users WHERE email = ?");
        $stmt->execute([$input['email']]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($user && password_verify($input['password'], $user['password'])) {
            $token = base64_encode(json_encode([
                'id' => $user['id'],
                'email' => $user['email'],
                'exp' => time() + 86400
            ]));
            
            echo json_encode([
                'success' => true,
                'data' => [
                    'user' => [
                        'id' => $user['id'],
                        'name' => $user['name'],
                        'email' => $user['email'],
                        'phone' => $user['phone'],
                        'role' => $user['role'],
                        'profile_picture' => $user['profile_picture'] ?? null,
                        'store_name' => $user['store_name'] ?? null,
                        'qris_image' => $user['qris_image'] ?? null,
                    ],
                    'token' => $token
                ]
            ]);
            exit;
        } else {
            echo json_encode(['success' => false, 'message' => 'Invalid email or password']);
            exit;
        }
    } catch(PDOException $e) {
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        exit;
    }
}

// ==================== PRODUCTS ====================

function handleGetProducts($db, $params) {
    try {
        $sellerId = $params['seller_id'] ?? null;
        $sql = "SELECT * FROM products WHERE is_published = 1";
        if ($sellerId) $sql .= " AND seller_id = " . intval($sellerId);
        $sql .= " ORDER BY created_at DESC";
        
        $stmt = $db->query($sql);
        $products = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        foreach ($products as &$product) {
            $product['id'] = (string)$product['id'];
            $product['seller_id'] = (string)$product['seller_id'];
            $product['price'] = floatval($product['price']);
            $product['stock'] = intval($product['stock']);
        }
        
        echo json_encode(['success' => true, 'data' => $products]);
        exit;
    } catch(PDOException $e) {
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        exit;
    }
}

function handleCreateProduct($db, $input) {
    try {
        $stmt = $db->prepare("INSERT INTO products (seller_id, name, description, price, stock, category, images, main_image, is_published) 
                              VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)");
        $stmt->execute([
            $input['seller_id'],
            $input['name'],
            $input['description'] ?? '',
            $input['price'],
            $input['stock'] ?? 0,
            $input['category'] ?? '',
            $input['images'] ?? '',
            $input['main_image'] ?? '',
            $input['is_published'] ?? 1
        ]);
        
        echo json_encode(['success' => true, 'data' => ['id' => $db->lastInsertId()]]);
        exit;
    } catch(PDOException $e) {
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        exit;
    }
}

function handleUpdateProduct($db, $input, $params) {
    try {
        $productId = $params['id'] ?? null;
        if (!$productId) {
            echo json_encode(['success' => false, 'message' => 'Product ID required']);
            exit;
        }
        
        $fields = [];
        $values = [];
        foreach ($input as $key => $value) {
            $fields[] = "$key = ?";
            $values[] = $value;
        }
        $values[] = $productId;
        
        $sql = "UPDATE products SET " . implode(', ', $fields) . " WHERE id = ?";
        $stmt = $db->prepare($sql);
        $stmt->execute($values);
        
        echo json_encode(['success' => true]);
        exit;
    } catch(PDOException $e) {
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        exit;
    }
}

function handleDeleteProduct($db, $params) {
    try {
        $productId = $params['id'] ?? null;
        if (!$productId) {
            echo json_encode(['success' => false, 'message' => 'Product ID required']);
            exit;
        }
        
        $stmt = $db->prepare("DELETE FROM products WHERE id = ?");
        $stmt->execute([$productId]);
        
        echo json_encode(['success' => true]);
        exit;
    } catch(PDOException $e) {
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        exit;
    }
}

// ==================== ORDERS ====================

function handleGetOrders($db, $params) {
    try {
        $sellerId = $params['seller_id'] ?? null;
        $buyerId = $params['buyer_id'] ?? null;
        $status = $params['status'] ?? null;
        
        $sql = "SELECT o.*, u.name as buyer_name 
                FROM orders o 
                LEFT JOIN users u ON o.buyer_id = u.id 
                WHERE 1=1";
        
        if ($sellerId) $sql .= " AND o.seller_id = " . intval($sellerId);
        if ($buyerId) $sql .= " AND o.buyer_id = " . intval($buyerId);
        if ($status) $sql .= " AND o.status = '" . addslashes($status) . "'";
        
        $sql .= " ORDER BY o.created_at DESC";
        
        $stmt = $db->query($sql);
        $orders = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        foreach ($orders as &$order) {
            $stmt = $db->prepare("SELECT * FROM order_items WHERE order_id = ?");
            $stmt->execute([$order['id']]);
            $order['items'] = $stmt->fetchAll(PDO::FETCH_ASSOC);
        }
        
        echo json_encode(['success' => true, 'data' => $orders]);
        exit;
    } catch(PDOException $e) {
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        exit;
    }
}

function handleCreateOrder($db, $input) {
    try {
        $db->beginTransaction();
        
        // Generate order number
        $orderNumber = 'ORD-' . time() . '-' . rand(1000, 9999);
        
        // Insert order
        $stmt = $db->prepare("INSERT INTO orders (order_number, buyer_id, seller_id, total_amount, shipping_cost, tax, discount, payment_method, shipping_address, notes) 
                              VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
        $stmt->execute([
            $orderNumber,
            $input['buyer_id'],
            $input['seller_id'],
            $input['total'],
            $input['shipping_cost'] ?? 0,
            $input['tax'] ?? 0,
            $input['discount'] ?? 0,
            $input['payment_method'] ?? 'qris',
            $input['shipping_address'] ?? '',
            $input['notes'] ?? ''
        ]);
        
        $orderId = $db->lastInsertId();
        
        // Insert order items
        foreach ($input['items'] as $item) {
            $stmt = $db->prepare("INSERT INTO order_items (order_id, product_id, product_name, price, quantity, subtotal) VALUES (?, ?, ?, ?, ?, ?)");
            $stmt->execute([
                $orderId,
                $item['productId'],
                $item['productName'],
                $item['price'],
                $item['quantity'],
                $item['price'] * $item['quantity']
            ]);
            
            // Update stock
            $stmt = $db->prepare("UPDATE products SET stock = stock - ? WHERE id = ?");
            $stmt->execute([$item['quantity'], $item['productId']]);
        }
        
        // Create payment record
        $stmt = $db->prepare("INSERT INTO payments (order_id, seller_id, payment_method, amount, status) VALUES (?, ?, ?, ?, 'pending')");
        $stmt->execute([
            $orderId,
            $input['seller_id'],
            $input['payment_method'] ?? 'qris',
            $input['total']
        ]);
        
        // Create transaction record
        $stmt = $db->prepare("INSERT INTO transactions (order_id, buyer_id, seller_id, amount, payment_method, status) VALUES (?, ?, ?, ?, ?, 'pending')");
        $stmt->execute([
            $orderId,
            $input['buyer_id'],
            $input['seller_id'],
            $input['total'],
            $input['payment_method'] ?? 'qris'
        ]);
        
        $db->commit();
        
        echo json_encode([
            'success' => true,
            'data' => [
                'id' => $orderId,
                'order_number' => $orderNumber
            ]
        ]);
        exit;
    } catch(PDOException $e) {
        $db->rollBack();
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        exit;
    }
}

function handleUpdateOrderStatus($db, $input) {
    try {
        $orderId = $input['order_id'] ?? null;
        $status = $input['status'] ?? null;
        
        if (!$orderId || !$status) {
            echo json_encode(['success' => false, 'message' => 'Missing parameters']);
            exit;
        }
        
        $stmt = $db->prepare("UPDATE orders SET status = ? WHERE id = ?");
        $stmt->execute([$status, $orderId]);
        
        // Update payment status if completed
        if ($status == 'completed') {
            $stmt = $db->prepare("UPDATE payments SET status = 'paid', paid_at = NOW() WHERE order_id = ?");
            $stmt->execute([$orderId]);
            
            $stmt = $db->prepare("UPDATE transactions SET status = 'success' WHERE order_id = ?");
            $stmt->execute([$orderId]);
        }
        
        echo json_encode(['success' => true]);
        exit;
    } catch(PDOException $e) {
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        exit;
    }
}

function handleAcceptOrder($db, $input) {
    $input['status'] = 'processing';
    handleUpdateOrderStatus($db, $input);
}

function handleRejectOrder($db, $input) {
    $input['status'] = 'rejected';
    handleUpdateOrderStatus($db, $input);
}

function handleCompleteOrder($db, $input) {
    $input['status'] = 'completed';
    handleUpdateOrderStatus($db, $input);
}

// ==================== QRIS ====================

function handleGetQris($db, $params) {
    try {
        $sellerId = $params['seller_id'] ?? null;
        
        if (!$sellerId) {
            $headers = getallheaders();
            $userId = $headers['User-Id'] ?? null;
            if ($userId) {
                $sellerId = $userId;
            }
        }
        
        if (!$sellerId) {
            echo json_encode([
                'success' => false, 
                'message' => 'Seller ID required'
            ]);
            exit;
        }
        
        $stmt = $db->prepare("SELECT qris_image FROM users WHERE id = ?");
        $stmt->execute([$sellerId]);
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        
        $qrisImage = $result['qris_image'] ?? null;
        
        if ($qrisImage) {
            $possiblePaths = [
                __DIR__ . '/../' . $qrisImage,
                __DIR__ . '/../../' . $qrisImage,
                __DIR__ . '/uploads/qris/' . basename($qrisImage),
                __DIR__ . '/../uploads/qris/' . basename($qrisImage),
            ];
            
            $filePath = null;
            foreach ($possiblePaths as $path) {
                if (file_exists($path)) {
                    $filePath = $path;
                    break;
                }
            }
            
            if ($filePath && file_exists($filePath)) {
                $imageData = file_get_contents($filePath);
                $base64 = base64_encode($imageData);
                $qrisImage = 'data:image/png;base64,' . $base64;
            } else {
                $qrisImage = null;
            }
        }
        
        echo json_encode([
            'success' => true, 
            'data' => ['qris_image' => $qrisImage]
        ]);
        exit;
    } catch(PDOException $e) {
        echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
        exit;
    }
}

function handleUploadQris($db, $input) {
    try {
        $headers = getallheaders();
        $userId = $headers['User-Id'] ?? null;
        
        if (!$userId) {
            echo json_encode(['success' => false, 'message' => 'User ID required']);
            exit;
        }
        
        // Cek apakah user adalah seller
        $stmt = $db->prepare("SELECT id, role FROM users WHERE id = ?");
        $stmt->execute([$userId]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$user || $user['role'] != 'seller') {
            echo json_encode(['success' => false, 'message' => 'User is not a seller']);
            exit;
        }
        
        $uploadDir = __DIR__ . '/../uploads/qris/';
        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0777, true);
        }
        
        if (isset($input['qris_image']) && !empty($input['qris_image'])) {
            $base64Image = $input['qris_image'];
            
            if (strpos($base64Image, 'base64,') !== false) {
                $base64Image = explode('base64,', $base64Image)[1];
            }
            
            $imageData = base64_decode($base64Image);
            if ($imageData === false) {
                echo json_encode(['success' => false, 'message' => 'Invalid image data']);
                exit;
            }
            
            $fileName = 'qris_' . $userId . '_' . time() . '.png';
            $targetPath = $uploadDir . $fileName;
            
            if (file_put_contents($targetPath, $imageData) !== false) {
                $dbPath = 'uploads/qris/' . $fileName;
                $stmt = $db->prepare("UPDATE users SET qris_image = ? WHERE id = ?");
                $stmt->execute([$dbPath, $userId]);
                
                $base64Response = base64_encode($imageData);
                
                echo json_encode([
                    'success' => true,
                    'data' => [
                        'qris_image' => 'data:image/png;base64,' . $base64Response
                    ]
                ]);
                exit;
            }
        }
        
        echo json_encode(['success' => false, 'message' => 'No image provided']);
        exit;
    } catch(PDOException $e) {
        echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
        exit;
    }
}

// ==================== PAYMENT QRIS ====================

function handleGetQrisPayment($db, $params) {
    try {
        $orderId = $params['order_id'] ?? null;
        if (!$orderId) {
            echo json_encode(['success' => false, 'message' => 'Order ID required']);
            exit;
        }
        
        $stmt = $db->prepare("
            SELECT p.*, 
                   o.order_number, 
                   u.name as seller_name, 
                   u.qris_image as seller_qris 
            FROM payments p 
            JOIN orders o ON p.order_id = o.id 
            JOIN users u ON p.seller_id = u.id 
            WHERE p.order_id = ?
        ");
        $stmt->execute([$orderId]);
        $payment = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$payment) {
            echo json_encode(['success' => false, 'message' => 'Payment not found']);
            exit;
        }
        
        $qrisImage = $payment['seller_qris'] ?? null;
        if ($qrisImage) {
            $possiblePaths = [
                __DIR__ . '/../' . $qrisImage,
                __DIR__ . '/../../' . $qrisImage,
                __DIR__ . '/uploads/qris/' . basename($qrisImage),
                __DIR__ . '/../uploads/qris/' . basename($qrisImage),
            ];
            
            $filePath = null;
            foreach ($possiblePaths as $path) {
                if (file_exists($path)) {
                    $filePath = $path;
                    break;
                }
            }
            
            if ($filePath && file_exists($filePath)) {
                $imageData = file_get_contents($filePath);
                $base64 = base64_encode($imageData);
                $payment['seller_qris'] = 'data:image/png;base64,' . $base64;
            } else {
                $payment['seller_qris'] = null;
            }
        }
        
        echo json_encode([
            'success' => true, 
            'data' => $payment
        ]);
        exit;
    } catch(PDOException $e) {
        echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
        exit;
    } catch(Exception $e) {
        echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
        exit;
    }
}

function handleConfirmPayment($db, $input) {
    try {
        $orderId = $input['order_id'] ?? null;
        if (!$orderId) {
            echo json_encode(['success' => false, 'message' => 'Order ID required']);
            exit;
        }
        
        $db->beginTransaction();
        
        // Update order status
        $stmt = $db->prepare("UPDATE orders SET payment_status = 'paid', status = 'processing' WHERE id = ?");
        $stmt->execute([$orderId]);
        
        // Update payment status
        $stmt = $db->prepare("UPDATE payments SET status = 'paid', paid_at = NOW() WHERE order_id = ?");
        $stmt->execute([$orderId]);
        
        // Update transaction status
        $stmt = $db->prepare("UPDATE transactions SET status = 'success' WHERE order_id = ?");
        $stmt->execute([$orderId]);
        
        $db->commit();
        
        echo json_encode([
            'success' => true, 
            'message' => 'Payment confirmed successfully'
        ]);
        exit;
    } catch(PDOException $e) {
        $db->rollBack();
        echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
        exit;
    } catch(Exception $e) {
        echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
        exit;
    }
}

// ==================== PROFILE ====================

function handleUpdateProfile($db, $input) {
    try {
        $userId = $input['id'] ?? null;
        if (!$userId) {
            echo json_encode(['success' => false, 'message' => 'User ID required']);
            exit;
        }
        
        $fields = [];
        $values = [];
        foreach ($input as $key => $value) {
            if ($key != 'id') {
                $fields[] = "$key = ?";
                $values[] = $value;
            }
        }
        $values[] = $userId;
        
        $sql = "UPDATE users SET " . implode(', ', $fields) . " WHERE id = ?";
        $stmt = $db->prepare($sql);
        $stmt->execute($values);
        
        echo json_encode(['success' => true]);
        exit;
    } catch(PDOException $e) {
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        exit;
    }
}

// ==================== UPLOAD IMAGE (WEB COMPATIBLE) ====================

function handleUploadImage($db) {
    try {
        $headers = getallheaders();
        $userId = $headers['User-Id'] ?? null;
        
        if (!$userId) {
            echo json_encode(['success' => false, 'message' => 'User ID required']);
            exit;
        }
        
        // 🔧 PERBAIKAN: Cek dari JSON input (untuk web base64)
        $input = json_decode(file_get_contents('php://input'), true);
        
        if (isset($input['image']) && !empty($input['image'])) {
            $base64Image = $input['image'];
            
            // Hapus prefix data:image/...;base64,
            if (strpos($base64Image, 'base64,') !== false) {
                $base64Image = explode('base64,', $base64Image)[1];
            }
            
            $imageData = base64_decode($base64Image);
            if ($imageData === false) {
                echo json_encode(['success' => false, 'message' => 'Invalid image data']);
                exit;
            }
            
            $uploadDir = __DIR__ . '/../uploads/profiles/';
            if (!is_dir($uploadDir)) {
                mkdir($uploadDir, 0777, true);
            }
            
            $fileName = 'profile_' . $userId . '_' . time() . '.png';
            $targetPath = $uploadDir . $fileName;
            
            if (file_put_contents($targetPath, $imageData) !== false) {
                $url = 'uploads/profiles/' . $fileName;
                
                $stmt = $db->prepare("UPDATE users SET profile_picture = ? WHERE id = ?");
                $stmt->execute([$url, $userId]);
                
                $httpHost = $_SERVER['HTTP_HOST'] ?? 'localhost:8000';
                $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
                $fullUrl = "$protocol://$httpHost/api/index.php?path=uploads&file=" . $url;
                
                echo json_encode([
                    'success' => true,
                    'data' => ['url' => $fullUrl]
                ]);
                exit;
            } else {
                echo json_encode(['success' => false, 'message' => 'Failed to save image']);
                exit;
            }
        }
        // 🔧 PERBAIKAN: Cek dari file upload (untuk mobile)
        else if (isset($_FILES['image']) && $_FILES['image']['error'] === UPLOAD_ERR_OK) {
            $file = $_FILES['image'];
            
            $uploadDir = __DIR__ . '/../uploads/profiles/';
            if (!is_dir($uploadDir)) {
                mkdir($uploadDir, 0777, true);
            }
            
            $extension = pathinfo($file['name'], PATHINFO_EXTENSION);
            $fileName = 'profile_' . $userId . '_' . time() . '.' . $extension;
            $targetPath = $uploadDir . $fileName;
            
            if (move_uploaded_file($file['tmp_name'], $targetPath)) {
                $url = 'uploads/profiles/' . $fileName;
                
                $stmt = $db->prepare("UPDATE users SET profile_picture = ? WHERE id = ?");
                $stmt->execute([$url, $userId]);
                
                $httpHost = $_SERVER['HTTP_HOST'] ?? 'localhost:8000';
                $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
                $fullUrl = "$protocol://$httpHost/api/index.php?path=uploads&file=" . $url;
                
                echo json_encode([
                    'success' => true,
                    'data' => ['url' => $fullUrl]
                ]);
                exit;
            } else {
                echo json_encode(['success' => false, 'message' => 'Failed to move uploaded file']);
                exit;
            }
        }
        
        echo json_encode(['success' => false, 'message' => 'No image provided']);
        exit;
    } catch(PDOException $e) {
        echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
        exit;
    } catch(Exception $e) {
        echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
        exit;
    }
}

// ==================== STATS ====================

function handleGetStats($db, $params) {
    try {
        $sellerId = $params['seller_id'] ?? null;
        if (!$sellerId) {
            echo json_encode(['success' => false, 'message' => 'Seller ID required']);
            exit;
        }
        
        $stmt = $db->prepare("SELECT COUNT(*) as total FROM orders WHERE seller_id = ?");
        $stmt->execute([$sellerId]);
        $totalOrders = $stmt->fetch(PDO::FETCH_ASSOC)['total'];
        
        $stmt = $db->prepare("SELECT COUNT(*) as pending FROM orders WHERE seller_id = ? AND status = 'pending'");
        $stmt->execute([$sellerId]);
        $pendingOrders = $stmt->fetch(PDO::FETCH_ASSOC)['pending'];
        
        $stmt = $db->prepare("SELECT COUNT(*) as completed FROM orders WHERE seller_id = ? AND status = 'completed'");
        $stmt->execute([$sellerId]);
        $completedOrders = $stmt->fetch(PDO::FETCH_ASSOC)['completed'];
        
        $stmt = $db->prepare("SELECT COALESCE(SUM(total_amount), 0) as income FROM orders WHERE seller_id = ? AND status = 'completed' AND DATE(created_at) = CURDATE()");
        $stmt->execute([$sellerId]);
        $todayIncome = $stmt->fetch(PDO::FETCH_ASSOC)['income'];
        
        $stmt = $db->prepare("SELECT COUNT(*) as total FROM products WHERE seller_id = ?");
        $stmt->execute([$sellerId]);
        $totalProducts = $stmt->fetch(PDO::FETCH_ASSOC)['total'];
        
        echo json_encode([
            'success' => true,
            'data' => [
                'totalOrders' => intval($totalOrders),
                'pendingOrders' => intval($pendingOrders),
                'completedOrders' => intval($completedOrders),
                'todayIncome' => floatval($todayIncome),
                'totalProducts' => intval($totalProducts),
                'averageRating' => 4.7
            ]
        ]);
        exit;
    } catch(PDOException $e) {
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        exit;
    }
}

// ==================== NEARBY SELLERS ====================

function handleGetNearbySellers($db, $params) {
    try {
        $sellers = [
            [
                'id' => 1,
                'name' => 'Dapur Bunda Telkom',
                'rating' => 4.8,
                'description' => 'Menyediakan aneka masakan rumahan lezat dan sehat.',
                'categories' => ['Makanan', 'Minuman', 'Camilan'],
                'distance' => 150,
                'isOpen' => true,
            ],
            [
                'id' => 2,
                'name' => 'Kopi Kampus',
                'rating' => 4.5,
                'description' => 'Kopi kekinian dengan biji pilihan.',
                'categories' => ['Minuman', 'Kopi'],
                'distance' => 200,
                'isOpen' => true,
            ],
        ];
        
        echo json_encode(['success' => true, 'data' => $sellers]);
        exit;
    } catch(PDOException $e) {
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        exit;
    }
}

// ==================== CHAT ====================

function handleGetConversations($db, $params) {
    try {
        $userId = $params['user_id'] ?? null;
        if (!$userId) {
            echo json_encode(['success' => false, 'message' => 'User ID required']);
            exit;
        }
        
        $sql = "SELECT 
                    CASE 
                        WHEN m.sender_id = ? THEN m.receiver_id 
                        ELSE m.sender_id 
                    END as other_user_id,
                    u.name as other_user_name,
                    u.role as other_user_role,
                    u.profile_picture as other_user_avatar,
                    u.store_name as other_user_store,
                    m.message as last_message,
                    m.created_at as last_message_time,
                    m.sender_id as last_sender_id,
                    (
                        SELECT COUNT(*) FROM messages 
                        WHERE sender_id = other_user_id 
                        AND receiver_id = ? 
                        AND is_read = 0
                    ) as unread_count
                FROM messages m
                JOIN users u ON u.id = CASE 
                    WHEN m.sender_id = ? THEN m.receiver_id 
                    ELSE m.sender_id 
                END
                WHERE m.id IN (
                    SELECT MAX(id) FROM messages 
                    WHERE sender_id = ? OR receiver_id = ?
                    GROUP BY CASE 
                        WHEN sender_id = ? THEN receiver_id 
                        ELSE sender_id 
                    END
                )
                ORDER BY m.created_at DESC";
        
        $stmt = $db->prepare($sql);
        $stmt->execute([$userId, $userId, $userId, $userId, $userId, $userId]);
        $conversations = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode(['success' => true, 'data' => $conversations]);
        exit;
    } catch(PDOException $e) {
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        exit;
    }
}

function handleGetMessages($db, $params) {
    try {
        $userId = $params['user_id'] ?? null;
        $otherUserId = $params['other_user_id'] ?? null;
        
        if (!$userId || !$otherUserId) {
            echo json_encode(['success' => false, 'message' => 'Both user IDs required']);
            exit;
        }
        
        $sql = "SELECT m.*, 
                    sender.name as sender_name,
                    receiver.name as receiver_name
                FROM messages m
                JOIN users sender ON m.sender_id = sender.id
                JOIN users receiver ON m.receiver_id = receiver.id
                WHERE (m.sender_id = ? AND m.receiver_id = ?)
                   OR (m.sender_id = ? AND m.receiver_id = ?)
                ORDER BY m.created_at ASC";
        
        $stmt = $db->prepare($sql);
        $stmt->execute([$userId, $otherUserId, $otherUserId, $userId]);
        $messages = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode(['success' => true, 'data' => $messages]);
        exit;
    } catch(PDOException $e) {
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        exit;
    }
}

function handleSendMessage($db, $input) {
    try {
        $senderId = $input['sender_id'] ?? null;
        $receiverId = $input['receiver_id'] ?? null;
        $message = $input['message'] ?? null;
        
        if (!$senderId || !$receiverId || !$message) {
            echo json_encode(['success' => false, 'message' => 'Missing required fields']);
            exit;
        }
        
        $stmt = $db->prepare("INSERT INTO messages (sender_id, receiver_id, message) VALUES (?, ?, ?)");
        $stmt->execute([$senderId, $receiverId, trim($message)]);
        
        $messageId = $db->lastInsertId();
        
        // Fetch the inserted message
        $stmt = $db->prepare("SELECT m.*, sender.name as sender_name, receiver.name as receiver_name 
                              FROM messages m 
                              JOIN users sender ON m.sender_id = sender.id 
                              JOIN users receiver ON m.receiver_id = receiver.id 
                              WHERE m.id = ?");
        $stmt->execute([$messageId]);
        $msg = $stmt->fetch(PDO::FETCH_ASSOC);
        
        echo json_encode(['success' => true, 'data' => $msg]);
        exit;
    } catch(PDOException $e) {
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        exit;
    }
}

function handleMarkAsRead($db, $input) {
    try {
        $userId = $input['user_id'] ?? null;
        $otherUserId = $input['other_user_id'] ?? null;
        
        if (!$userId || !$otherUserId) {
            echo json_encode(['success' => false, 'message' => 'Both user IDs required']);
            exit;
        }
        
        $stmt = $db->prepare("UPDATE messages SET is_read = 1 WHERE sender_id = ? AND receiver_id = ? AND is_read = 0");
        $stmt->execute([$otherUserId, $userId]);
        
        echo json_encode(['success' => true, 'data' => ['updated' => $stmt->rowCount()]]);
        exit;
    } catch(PDOException $e) {
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        exit;
    }
}
?>