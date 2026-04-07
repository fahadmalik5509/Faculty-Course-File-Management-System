# Faculty Course File Management System
# Complete Local Run Guide (Laragon + PHP + MySQL)

This guide is for beginners and covers everything needed to run the project locally.

You can run this project in two valid ways:
1. Automated script mode (`run-local.bat`) - fastest for demo/viva
2. Manual Laragon UI mode - classic Laragon workflow

## Common required steps (for both methods)

1. Install Laragon (includes MySQL and PHP).
2. Keep this project folder complete (must contain `backend`, `frontend`, and `run-local.bat`).
3. Check backend database config in `backend/config.php`:
- DB_HOST = 127.0.0.1
- DB_PORT = 3306
- DB_NAME = faculty_management_system
- DB_USER = root
- DB_PASS = empty string

## Method A: Quick start (automated script)

If you prefer automation, use the included script from the project root:

1. One-click (double-click in File Explorer)
- run-local.bat

2. Terminal command
```powershell
.\run-local.bat
```

What it automates:
- Starts MySQL directly
- Imports backend/db/schema.sql
- Imports backend/db/seed.sql
- Starts a local PHP server from the current folder
- Opens the app URL in your browser

## Method B: Manual Laragon UI setup

## 1. What you need to install

1. Laragon (Full edition recommended)
2. A browser (Chrome or Edge)
3. Optional: VS Code

Laragon already includes Apache, MySQL, PHP, and phpMyAdmin in one package.

## 2. Install Laragon

1. Download Laragon from the official website.
2. Install it with default options.
3. Open Laragon after installation.
4. Click Start All (or start Apache and MySQL individually).

You should see services running:
- Apache: Running
- MySQL: Running

## 3. Place project in Laragon web root

Required for Method B only.

1. Copy this project folder to:
	C:\laragon\www\Faculty Course File Management System
2. Confirm these paths exist:
	- C:\laragon\www\Faculty Course File Management System\index.html
	- C:\laragon\www\Faculty Course File Management System\backend
	- C:\laragon\www\Faculty Course File Management System\frontend

## 4. Create database and tables

1. In Laragon, open Menu -> Database -> phpMyAdmin.
2. Login with default credentials if asked:
	- Username: root
	- Password: blank (empty)
3. In phpMyAdmin, click Import.
4. Choose file:
	backend/db/schema.sql
5. Click Go.

This creates:
- Database: faculty_management_system
- Tables: users, course_allocations, teacher_uploads

## 5. Seed demo data (recommended)

1. Still in phpMyAdmin, click Import again.
2. Choose file:
	backend/db/seed.sql
3. Click Go.

This resets and inserts demo data for quick viva testing.

## 6. Verify backend database config

Check file:
- backend/config.php

Expected values:
- DB_HOST = 127.0.0.1
- DB_PORT = 3306
- DB_NAME = faculty_management_system
- DB_USER = root
- DB_PASS = empty string

If your Laragon MySQL password is not empty, change DB_PASS accordingly.

## 7. Run the application

Open this URL in browser:
- http://localhost/Faculty%20Course%20File%20Management%20System/

The root index redirects to frontend pages automatically.

## 8. Demo login accounts

After importing seed.sql, use:

1. Admin
- Email: admin@fms.com
- Password: 12345678

2. HOD
- Email: hod@fms.com
- Password: 12345678

3. Teacher
- Email: teacher@fms.com
- Password: 12345678

## 9. Feature flow test checklist

1. Admin flow
- Login as admin
- Open admin dashboard
- Create allocation
- Edit allocation
- Delete allocation
- Confirm stats update

2. Teacher flow
- Login as teacher
- Save file record
- Edit file record
- Delete file record

3. HOD flow
- Login as hod
- See pending teacher records
- Approve one record
- Reject one record with feedback

4. Access control
- Try logging into wrong role page with another role account
- App should deny access

## 10. Common issues and fixes

1. Error: Failed to fetch or API not reachable
- Make sure Apache is running in Laragon
- Open URL directly to confirm server:
	http://localhost/Faculty%20Course%20File%20Management%20System/backend/api/me.php

2. Error: SQLSTATE Access denied
- DB credentials in backend/config.php do not match your MySQL
- Fix DB_USER or DB_PASS

3. Error: Table does not exist
- You did not import schema.sql
- Import backend/db/schema.sql again

4. Login fails for all users
- Import backend/db/seed.sql again
- Confirm users table contains admin@fms.com, hod@fms.com, teacher@fms.com

5. Blank page or broken JS
- Hard refresh browser: Ctrl + F5
- For Method B only: verify project is in Laragon www path

## 11. Project architecture summary

1. Frontend
- frontend/pages
- frontend/assets/css
- frontend/assets/js

2. Backend
- backend/api (PHP endpoints)
- backend/config.php (DB + session config)
- backend/db/schema.sql and backend/db/seed.sql

3. Runtime model
- Local PHP sessions for authentication
- Local MySQL for data storage
- Fully local runtime with no external cloud dependency

## 12. Viva speaking points (quick)

1. This is a role-based Faculty Course File Management System.
2. Backend is local PHP + MySQL under Laragon.
3. Users table handles authentication and roles.
4. Admin manages course allocations.
5. Teacher manages course file records.
6. HOD reviews and approves/rejects records.
7. Access is role-restricted on backend APIs.
