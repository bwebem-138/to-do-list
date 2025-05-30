from flask import Flask, render_template, request, redirect, url_for, session, flash
import mysql.connector
import hashlib
import os
import logging

# Fix the template_folder path - it should be relative
app = Flask(__name__, template_folder='templates')  # Note: changed from 'template' to 'templates'
app.secret_key = os.urandom(24)

# Update the database configuration to match docker-compose.yml
db_config = {
    'host': 'mariadb',  # Update to match container name in docker-compose
    'user': 'todo_user',
    'password': 'todopass123',  # Update to match docker-compose
    'database': 'todo_db'
}

# Hilfsfunktion für die Verbindung zur DB
def get_db_connection():
    return mysql.connector.connect(**db_config)

# Passwort mit SHA-256 hashen
def hash_password(password):
    return hashlib.sha256(password.encode()).hexdigest()

# Add logging configuration
logging.basicConfig(level=logging.DEBUG)

# ========================================
# Route: Startseite / Login
# ========================================
@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        # Add validation for form data
        if 'username' not in request.form or 'password' not in request.form:
            flash('Please provide both username and password')
            return redirect(url_for('login'))
            
        username = request.form['username']
        password = hash_password(request.form['password'])

        try:
            conn = get_db_connection()
            cursor = conn.cursor(dictionary=True)
            cursor.callproc('get_user_by_username', [username])
            
            user = None
            for result in cursor.stored_results():
                user = result.fetchone()

            if user and user['password'] == password:
                session['user_id'] = user['id']
                session['username'] = user['username']
                return redirect(url_for('tasks'))
            else:
                flash('Invalid username or password')
                return redirect(url_for('login'))

        except Exception as e:
            app.logger.error(f"Database error: {str(e)}")
            flash('An error occurred. Please try again later.')
            return redirect(url_for('login'))
        finally:
            cursor.close()
            conn.close()

    return render_template('login.html')

# ========================================
# Route: Registrierung
# ========================================
@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        # Validate form data
        if 'username' not in request.form or 'password' not in request.form:
            flash('Please provide both username and password')
            return redirect(url_for('register'))
        
        username = request.form['username']
        password = request.form['password']
        
        # Validate input
        if not username or not password:
            flash('Username and password cannot be empty')
            return redirect(url_for('register'))
            
        # Hash password
        hashed_password = hash_password(password)

        try:
            conn = get_db_connection()
            cursor = conn.cursor()
            cursor.callproc('create_user', [username, hashed_password])
            conn.commit()
            flash('Registration successful! Please login.')
            return redirect(url_for('login'))

        except mysql.connector.Error as e:
            app.logger.error(f"Database error: {str(e)}")
            flash('Registration failed. Username may already exist.')
            return redirect(url_for('register'))
        finally:
            cursor.close()
            conn.close()

    return render_template('register.html')

# ========================================
# Route: Aufgabenliste anzeigen
# ========================================
@app.route('/tasks')
def tasks():
    if 'user_id' not in session:
        return redirect(url_for('login'))

    user_id = session['user_id']
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.callproc('get_tasks', [user_id])

        tasks = []
        for result in cursor.stored_results():
            tasks = result.fetchall()

    finally:
        cursor.close()
        conn.close()

    return render_template('tasks.html', tasks=tasks, username=session.get('username'))

# ========================================
# Route: Aufgabe hinzufügen
# ========================================
@app.route('/add', methods=['POST'])
def add():
    if 'user_id' not in session:
        return redirect(url_for('login'))

    title = request.form['title']
    user_id = session['user_id']

    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.callproc('add_task', [user_id, title])
        conn.commit()
    finally:
        cursor.close()
        conn.close()

    return redirect(url_for('tasks'))

# ========================================
# Route: Aufgabe löschen
# ========================================
@app.route('/delete/<int:task_id>')
def delete(task_id):
    if 'user_id' not in session:
        return redirect(url_for('login'))

    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.callproc('delete_task', [task_id])
        conn.commit()
    finally:
        cursor.close()
        conn.close()

    return redirect(url_for('tasks'))

# ========================================
# Route: Logout
# ========================================
@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))

# ========================================
# Add a root route that redirects to login
# ========================================
@app.route('/')
def index():
    return redirect(url_for('login'))

# ========================================
# Main
# ========================================
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
