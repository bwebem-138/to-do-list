from flask import Flask, render_template, request, redirect, url_for, flash, session
import mysql.connector
import os
from werkzeug.security import generate_password_hash, check_password_hash
import hashlib
import re
from email_validator import validate_email, EmailNotValidError

app = Flask(__name__)
app.secret_key = os.urandom(24)

def get_db_connection():
    return mysql.connector.connect(
        host=os.environ.get('MYSQL_HOST', 'mariadb'),
        user=os.environ.get('MYSQL_USER', 'todo_user'),
        password=os.environ.get('MYSQL_PASSWORD', 'todopass123'),
        database=os.environ.get('MYSQL_DATABASE', 'todo_db')
    )

def hash_username(username):
    return hashlib.sha256(username.lower().encode('utf-8')).hexdigest()

@app.route('/')
def index():
    if 'user_id' not in session:
        return redirect(url_for('login'))
    return redirect(url_for('tasks'))

@app.route('/tasks')
def tasks():
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.callproc('get_tasks', [session['user_id']])
    tasks = []
    for result in cursor.stored_results():
        raw_tasks = result.fetchall()
        # Decode the BLOB title for each task
        tasks = [{**task, 'title': task['title'].decode('utf-8')} for task in raw_tasks]
    
    cursor.close()
    conn.close()
    
    return render_template('tasks.html', tasks=tasks, username=session.get('username'))

@app.route('/add', methods=['POST'])
def add():
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    title = request.form.get('title').encode('utf-8')  # Encode the title before saving
    if title:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.callproc('add_task', [session['user_id'], title])
        conn.commit()
        cursor.close()
        conn.close()
        flash('Task added successfully!', 'success')
    return redirect(url_for('tasks'))

@app.route('/toggle/<int:task_id>', methods=['POST'])
def toggle(task_id):
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.callproc('toggle_task', [task_id])
    conn.commit()
    cursor.close()
    conn.close()
    return redirect(url_for('tasks'))

@app.route('/delete/<int:task_id>')
def delete(task_id):
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.callproc('delete_task', [task_id])
    conn.commit()
    cursor.close()
    conn.close()
    flash('Task deleted successfully!', 'success')
    return redirect(url_for('tasks'))

@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        email = request.form['email']
        password = request.form['password']
        name = request.form['name']
        
        # Validate input
        is_valid, message = validate_user_input(email, password, name)
        if not is_valid:
            flash(message, 'error')
            return render_template('register.html')
        
        # Hash email for storage
        email_hash = hash_username(email)  # Reusing existing hash function
        display_name = name.encode('utf-8')
        
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # Check if email hash exists
        cursor.callproc('get_user_by_email_hash', [email_hash])
        for result in cursor.stored_results():
            if result.fetchone():
                flash('Email already registered', 'error')
                return render_template('register.html')
        
        hashed_password = generate_password_hash(password).encode('utf-8')
        # Modified stored procedure to include email_hash and display_name
        cursor.callproc('create_user', [email_hash, display_name, hashed_password])
        conn.commit()
        
        cursor.close()
        conn.close()
        
        flash('Registration successful! Please login.', 'success')
        return redirect(url_for('login'))
    
    return render_template('register.html')

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        email = request.form['email']
        password = request.form['password']
        
        # Hash email for lookup
        email_hash = hash_username(email)
        
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.callproc('get_user_by_email_hash', [email_hash])
        user = None
        for result in cursor.stored_results():
            user = result.fetchone()
        
        if user:
            stored_password = user['password'].decode('utf-8')
            if check_password_hash(stored_password, password):
                session['user_id'] = user['id']
                session['display_name'] = user['display_name'].decode('utf-8')
                flash('Welcome back!', 'success')
                return redirect(url_for('tasks'))
        
        flash('Invalid email or password', 'error')
        cursor.close()
        conn.close()
    
    return render_template('login.html')

@app.route('/logout')
def logout():
    session.clear()
    flash('You have been logged out', 'info')
    return redirect(url_for('login'))

@app.route('/delete_account', methods=['POST'])
def delete_account():
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.callproc('delete_account', [session['user_id']])
    conn.commit()
    cursor.close()
    conn.close()
    
    session.clear()
    flash('Your account has been deleted', 'info')
    return redirect(url_for('login'))

def validate_password(password):
    """Password must be at least 12 characters and contain upper, lower, number and special char"""
    if len(password) < 12:
        return False, "Password must be at least 12 characters long"
    
    if not re.search(r"[A-Z]", password):
        return False, "Password must contain at least one uppercase letter"
    
    if not re.search(r"[a-z]", password):
        return False, "Password must contain at least one lowercase letter"
    
    if not re.search(r"\d", password):
        return False, "Password must contain at least one number"
    
    if not re.search(r"[!@#$%^&*(),.?\":{}|<>]", password):
        return False, "Password must contain at least one special character"
    
    return True, "Password is valid"

def validate_user_input(email, password, name):
    try:
        # Validate email
        email_info = validate_email(email, check_deliverability=False)
        email = email_info.normalized
        
        # Validate password
        is_valid_password, password_message = validate_password(password)
        if not is_valid_password:
            return False, password_message
        
        # Validate name (at least 2 characters, only letters and spaces)
        if not re.match(r"^[A-Za-z\s]{2,}$", name):
            return False, "Name must contain only letters and spaces, and be at least 2 characters long"
        
        return True, "All inputs are valid"
    
    except EmailNotValidError as e:
        return False, str(e)

if __name__ == '__main__':
    # Remove debug mode and use production settings
    app.run(host='0.0.0.0', debug=False)
