from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import os
import socket

# Intentar connectar a PostgreSQL si està disponible
db_conn = None
try:
    import psycopg2
    db_conn = psycopg2.connect(
        host=os.environ.get('DB_HOST', 'postgres'),
        port=os.environ.get('DB_PORT', '5432'),
        database=os.environ.get('DB_NAME', 'greendevcorp'),
        user=os.environ.get('DB_USER', 'gsx'),
        password=os.environ.get('DB_PASSWORD', 'gsx123')
    )
    db_conn.autocommit = True
    
    # Crear taula si no existeix
    with db_conn.cursor() as cur:
        cur.execute('''
            CREATE TABLE IF NOT EXISTS visits (
                id SERIAL PRIMARY KEY,
                path VARCHAR(255),
                timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
    print("✅ Connected to PostgreSQL")
except Exception as e:
    print(f"⚠️ PostgreSQL not available: {e}")

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        
        visits = None
        if db_conn:
            try:
                with db_conn.cursor() as cur:
                    # Registrar visita
                    cur.execute("INSERT INTO visits (path) VALUES (%s)", (self.path,))
                    # Comptar total
                    cur.execute("SELECT COUNT(*) FROM visits")
                    visits = cur.fetchone()[0]
            except Exception as e:
                visits = f"DB error: {e}"
        
        response = {
            "status": "ok",
            "message": "Hello from Python backend!",
            "path": self.path,
            "hostname": socket.gethostname(),
            "total_visits": visits
        }
        self.wfile.write(json.dumps(response).encode())
    
    def log_message(self, format, *args):
        print(f"[APP] {args[0]}")

if __name__ == "__main__":
    server = HTTPServer(("0.0.0.0", 8080), Handler)
    print("Backend running on port 8080")
    server.serve_forever()