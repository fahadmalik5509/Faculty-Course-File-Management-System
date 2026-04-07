<?php

declare(strict_types=1);

require_once __DIR__ . '/../config.php';

$user = require_auth('admin');
$pdo = get_pdo();
$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $rows = $pdo->query("SELECT id, faculty_name, course_name FROM course_allocations ORDER BY CASE WHEN faculty_name = 'Fahad Malik' THEN 0 ELSE 1 END, updated_at DESC")->fetchAll();
    send_json(['ok' => true, 'items' => $rows]);
}

$data = parse_json_input();

if ($method === 'POST') {
    $facultyName = trim((string)($data['facultyName'] ?? ''));
    $courseName = trim((string)($data['courseName'] ?? ''));

    if ($facultyName === '' || $courseName === '') {
        send_json(['ok' => false, 'message' => 'facultyName and courseName are required'], 422);
    }

    $stmt = $pdo->prepare('INSERT INTO course_allocations (faculty_name, course_name) VALUES (:faculty, :course)');
    $stmt->execute(['faculty' => $facultyName, 'course' => $courseName]);
    send_json(['ok' => true, 'id' => (int)$pdo->lastInsertId()], 201);
}

if ($method === 'PUT') {
    $id = (int)($data['id'] ?? 0);
    $facultyName = trim((string)($data['facultyName'] ?? ''));
    $courseName = trim((string)($data['courseName'] ?? ''));

    if ($id <= 0 || $facultyName === '' || $courseName === '') {
        send_json(['ok' => false, 'message' => 'id, facultyName and courseName are required'], 422);
    }

    $stmt = $pdo->prepare('UPDATE course_allocations SET faculty_name = :faculty, course_name = :course WHERE id = :id');
    $stmt->execute(['faculty' => $facultyName, 'course' => $courseName, 'id' => $id]);
    send_json(['ok' => true]);
}

if ($method === 'DELETE') {
    $id = (int)($data['id'] ?? 0);
    if ($id <= 0) {
        send_json(['ok' => false, 'message' => 'id is required'], 422);
    }

    $stmt = $pdo->prepare('DELETE FROM course_allocations WHERE id = :id');
    $stmt->execute(['id' => $id]);
    send_json(['ok' => true]);
}

send_json(['ok' => false, 'message' => 'Method not allowed'], 405);
