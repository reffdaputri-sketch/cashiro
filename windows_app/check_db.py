import sqlite3
import os

db_path = None
for root, dirs, files in os.walk(r'F:\KIOSLY\windows_app'):
    if 'cashiro.db' in files:
        db_path = os.path.join(root, 'cashiro.db')
        break

if not db_path:
    # try Documents
    p = os.path.join(os.environ['USERPROFILE'], 'Documents', 'cashiro.db')
    if os.path.exists(p):
        db_path = p

if not db_path:
    print("cashiro.db not found!")
    exit(1)

print("DB path:", db_path)
try:
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    print("--- Products Table Schema ---")
    cursor.execute("PRAGMA table_info(products)")
    for row in cursor.fetchall():
        print(row)
        
    print("--- DB Version ---")
    cursor.execute("PRAGMA user_version")
    print(cursor.fetchone())

    conn.close()
except Exception as e:
    print("Error:", e)
