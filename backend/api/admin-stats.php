<?php

declare(strict_types=1);

require_once __DIR__ . '/../config.php';

require_auth('admin');
$pdo = get_pdo();

$facultyCount = (int)$pdo->query("SELECT COUNT(*) FROM users WHERE role = 'teacher'")->fetchColumn();
$courseCount = (int)$pdo->query('SELECT COUNT(DISTINCT course_name) FROM course_allocations')->fetchColumn();
$fileCount = (int)$pdo->query('SELECT COUNT(*) FROM teacher_uploads')->fetchColumn();

send_json([
    'ok' => true,
    'stats' => [
        'facultyCount' => $facultyCount,
        'courseCount' => $courseCount,
        'fileCount' => $fileCount,
    ],
]);
