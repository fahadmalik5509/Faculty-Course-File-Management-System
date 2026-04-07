<?php

declare(strict_types=1);

session_start();

const DB_HOST = '127.0.0.1';
const DB_PORT = '3306';
const DB_NAME = 'faculty_management_system';
const DB_USER = 'root';
const DB_PASS = '';

function get_pdo(): PDO
{
    static $pdo = null;

    if ($pdo instanceof PDO) {
        return $pdo;
    }

    $dsn = 'mysql:host=' . DB_HOST . ';port=' . DB_PORT . ';dbname=' . DB_NAME . ';charset=utf8mb4';

    $pdo = new PDO($dsn, DB_USER, DB_PASS, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);

    return $pdo;
}

function send_json(array $payload, int $status = 200): void
{
    http_response_code($status);
    header('Content-Type: application/json');
    echo json_encode($payload);
    exit;
}

function parse_json_input(): array
{
    $raw = file_get_contents('php://input');
    if (!$raw) {
        return [];
    }

    $data = json_decode($raw, true);
    return is_array($data) ? $data : [];
}

function require_auth(?string $role = null): array
{
    if (!isset($_SESSION['user'])) {
        send_json(['ok' => false, 'message' => 'Unauthorized'], 401);
    }

    $user = $_SESSION['user'];

    if ($role !== null && ($user['role'] ?? null) !== $role) {
        send_json(['ok' => false, 'message' => 'Forbidden'], 403);
    }

    return $user;
}
