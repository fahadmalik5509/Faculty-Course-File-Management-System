<?php

declare(strict_types=1);

require_once __DIR__ . '/../config.php';

require_auth('hod');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    send_json(['ok' => false, 'message' => 'Method not allowed'], 405);
}

$data = parse_json_input();
$id = (int)($data['id'] ?? 0);
$action = trim((string)($data['action'] ?? ''));
$feedback = trim((string)($data['feedback'] ?? ''));

if ($id <= 0 || ($action !== 'approve' && $action !== 'reject')) {
    send_json(['ok' => false, 'message' => 'id and valid action are required'], 422);
}

$pdo = get_pdo();

if ($action === 'approve') {
    $stmt = $pdo->prepare('UPDATE teacher_uploads SET status = "approved", feedback = "", reviewed_at = NOW() WHERE id = :id');
    $stmt->execute(['id' => $id]);
    send_json(['ok' => true]);
}

if ($feedback === '') {
    send_json(['ok' => false, 'message' => 'feedback is required for reject'], 422);
}

$stmt = $pdo->prepare('UPDATE teacher_uploads SET status = "rejected", feedback = :feedback, reviewed_at = NOW() WHERE id = :id');
$stmt->execute(['id' => $id, 'feedback' => $feedback]);

send_json(['ok' => true]);
