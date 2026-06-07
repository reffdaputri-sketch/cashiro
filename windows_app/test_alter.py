import sqlite3

db_path = r'F:\KIOSLY\windows_app\.dart_tool\sqflite_common_ffi\databases\cashiro.db'
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

try:
    cursor.execute('ALTER TABLE products ADD COLUMN supplier_id INTEGER')
    conn.commit()
    print("Added successfully!")
except Exception as e:
    print("Error adding column:", e)

conn.close()
