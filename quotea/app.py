from flask import Flask, jsonify
from flask_cors import CORS
import os
import psycopg2
import socket

app = Flask(__name__)
CORS(app,resources={r"/api/*": {"origins": "*"}})

def get_sentences():
    conn = psycopg2.connect(
        host=os.environ.get('POSTGRES_HOST', '/cloudsql/sistemyon-odev:europe-west4:odev-postgres'),
        database=os.environ.get('POSTGRES_DB', 'appdb'),
        user=os.environ.get('POSTGRES_USER', 'appuser'),
        password=os.environ.get('POSTGRES_PASSWORD', 'testUser123')
    )
    
    # conn = psycopg2.connect(
    #     host=os.environ.get('POSTGRES_HOST', 'localhost'),
    #     database=os.environ.get('POSTGRES_DB', 'postgres'),
    #     user=os.environ.get('POSTGRES_USER', 'testUser'),
    #     password=os.environ.get('POSTGRES_PASSWORD', 'testPassword')
    # )
    c = conn.cursor()
    c.execute("SELECT person, sentence FROM sentences ORDER BY RANDOM() LIMIT 1")
    rows = c.fetchall()
    conn.close()
    return [{"person": row[0], "sentence": row[1]} for row in rows]

@app.route('/api/sentences')
def sentences():
    return jsonify(get_sentences())

@app.route('/api/vm-info')
def vm_info():
    return {'hostname': socket.gethostname()}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5757)