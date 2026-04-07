<?php

declare(strict_types=1);

require_once __DIR__ . '/../config.php';

$user = require_auth();
$pdo = get_pdo();
$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $scope = (string)($_GET['scope'] ?? 'mine');

    if ($user['role'] === 'teacher' || $scope === 'mine') {
        $stmt = $pdo->prepare('SELECT id, owner_user_id, faculty_name, course_name, file_type, file_name, status, feedback, created_at FROM teacher_uploads WHERE owner_user_id = :uid ORDER BY created_at DESC');
        $stmt->execute(['uid' => $user['id']]);
        send_json(['ok' => true, 'items' => $stmt->fetchAll()]);
    }

    if ($user['role'] === 'hod' || $user['role'] === 'admin') {
        $status = trim((string)($_GET['status'] ?? ''));
        if ($status !== '') {
            $stmt = $pdo->prepare('SELECT id, owner_user_id, faculty_name, course_name, file_type, file_name, status, feedback, created_at FROM teacher_uploads WHERE status = :status ORDER BY created_at DESC');
            $stmt->execute(['status' => $status]);
            send_json(['ok' => true, 'items' => $stmt->fetchAll()]);
        }

        $rows = $pdo->query('SELECT id, owner_user_id, faculty_name, course_name, file_type, file_name, status, feedback, created_at FROM teacher_uploads ORDER BY created_at DESC')->fetchAll();
        send_json(['ok' => true, 'items' => $rows]);
    }

    send_json(['ok' => false, 'message' => 'Forbidden'], 403);
}

$data = parse_json_input();

if ($method === 'POST') {
    if ($user['role'] !== 'teacher') {
        send_json(['ok' => false, 'message' => 'Forbidden'], 403);
    }

    $facultyName = trim((string)($data['facultyName'] ?? ''));
    $courseName = trim((string)($data['courseName'] ?? ''));
    $fileType = trim((string)($data['fileType'] ?? ''));
    $fileName = trim((string)($data['fileName'] ?? ''));

    if ($facultyName === '' || $courseName === '' || $fileType === '' || $fileName === '') {
        send_json(['ok' => false, 'message' => 'facultyName, courseName, fileType and fileName are required'], 422);
    }

    $stmt = $pdo->prepare('INSERT INTO teacher_uploads (owner_user_id, faculty_name, course_name, file_type, file_name, status, feedback) VALUES (:uid, :faculty, :course, :type, :name, "pending", "")');
    $stmt->execute([
        'uid' => $user['id'],
        'faculty' => $facultyName,
        'course' => $courseName,
        'type' => $fileType,
        'name' => $fileName,
    ]);

    send_json(['ok' => true, 'id' => (int)$pdo->lastInsertId()], 201);
}

if ($method === 'PUT') {
    if ($user['role'] !== 'teacher') {
        send_json(['ok' => false, 'message' => 'Forbidden'], 403);
    }

    $id = (int)($data['id'] ?? 0);
    $facultyName = trim((string)($data['facultyName'] ?? ''));
    $courseName = trim((string)($data['courseName'] ?? ''));
    $fileType = trim((string)($data['fileType'] ?? ''));
    $fileName = trim((string)($data['fileName'] ?? ''));

    if ($id <= 0 || $facultyName === '' || $courseName === '' || $fileType === '') {
        send_json(['ok' => false, 'message' => 'id, facultyName, courseName and fileType are required'], 422);
    }

    $ownerCheck = $pdo->prepare('SELECT owner_user_id FROM teacher_uploads WHERE id = :id LIMIT 1');
    $ownerCheck->execute(['id' => $id]);
    $row = $ownerCheck->fetch();

    if (!$row || (int)$row['owner_user_id'] !== (int)$user['id']) {
        send_json(['ok' => false, 'message' => 'Forbidden'], 403);
    }

    if ($fileName === '') {
        $stmt = $pdo->prepare('UPDATE teacher_uploads SET faculty_name = :faculty, course_name = :course, file_type = :type WHERE id = :id');
        $stmt->execute(['faculty' => $facultyName, 'course' => $courseName, 'type' => $fileType, 'id' => $id]);
    } else {
        $stmt = $pdo->prepare('UPDATE teacher_uploads SET faculty_name = :faculty, course_name = :course, file_type = :type, file_name = :name WHERE id = :id');
        $stmt->execute(['faculty' => $facultyName, 'course' => $courseName, 'type' => $fileType, 'name' => $fileName, 'id' => $id]);
    }

    send_json(['ok' => true]);
}

if ($method === 'DELETE') {
    if ($user['role'] !== 'teacher') {
        send_json(['ok' => false, 'message' => 'Forbidden'], 403);
    }

    $id = (int)($data['id'] ?? 0);
    if ($id <= 0) {
        send_json(['ok' => false, 'message' => 'id is required'], 422);
    }

    $stmt = $pdo->prepare('DELETE FROM teacher_uploads WHERE id = :id AND owner_user_id = :uid');
    $stmt->execute(['id' => $id, 'uid' => $user['id']]);
    send_json(['ok' => true]);
}

send_json(['ok' => false, 'message' => 'Method not allowed'], 405);
