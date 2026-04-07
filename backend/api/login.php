<?php

declare(strict_types=1);

require_once __DIR__ . '/../config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    send_json(['ok' => false, 'message' => 'Method not allowed'], 405);
}

$data = parse_json_input();
$email = trim((string)($data['email'] ?? ''));
$password = (string)($data['password'] ?? '');
$expectedRole = trim((string)($data['expectedRole'] ?? ''));

if ($email === '' || $password === '' || $expectedRole === '') {
    send_json(['ok' => false, 'message' => 'Email, password and role are required'], 422);
}

$pdo = get_pdo();
$stmt = $pdo->prepare('SELECT id, email, password_hash, role FROM users WHERE email = :email LIMIT 1');
$stmt->execute(['email' => $email]);
$user = $stmt->fetch();

$storedPassword = (string)($user['password_hash'] ?? '');
$isValidPassword = $user && (
    password_verify($password, $storedPassword) ||
    hash_equals($storedPassword, $password)
);

if (!$isValidPassword) {
    send_json(['ok' => false, 'message' => 'Invalid email or password'], 401);
}

if ($user['role'] !== $expectedRole) {
    send_json(['ok' => false, 'message' => 'This account does not have access to this portal.'], 403);
}

$_SESSION['user'] = [
    'id' => (int)$user['id'],
    'email' => $user['email'],
    'role' => $user['role'],
];

send_json([
    'ok' => true,
    'user' => [
        'id' => (int)$user['id'],
        'email' => $user['email'],
        'role' => $user['role'],
    ],
]);
