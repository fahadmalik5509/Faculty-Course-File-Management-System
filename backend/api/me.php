<?php

declare(strict_types=1);

require_once __DIR__ . '/../config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    send_json(['ok' => false, 'message' => 'Method not allowed'], 405);
}

if (!isset($_SESSION['user'])) {
    send_json(['ok' => false, 'user' => null], 200);
}

send_json(['ok' => true, 'user' => $_SESSION['user']]);
