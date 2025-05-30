from flask import Flask, render_template, request, redirect, url_for, flash, session
import mysql.connector
import os
from werkzeug.security import generate_password_hash, check_password_hash

app = Flask(__name__)
app.secret_key = os.urandom(24)

def get_db_connection():
    return mysql.connector.connect(
        host=os.environ.get('MYSQL_HOST', 'mariadb'),
        user=os.environ.get('MYSQL_USER', 'todo_user'),
        password=os.environ.get('MYSQL_PASSWORD', 'todopass123'),
        database=os.environ.get('MYSQL_DATABASE', 'todo_db')
    )

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
        username = request.form['username'].encode('utf-8')
        password = request.form['password']
        
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # Check if username exists
        cursor.callproc('get_user_by_username', [username])
        for result in cursor.stored_results():
            if result.fetchone():
                flash('Username already exists', 'error')
                return render_template('register.html')
        
        # Create new user with hashed password
        hashed_password = generate_password_hash(password).encode('utf-8')
        cursor.callproc('create_user', [username, hashed_password])
        conn.commit()
        
        cursor.close()
        conn.close()
        
        flash('Registration successful! Please login.', 'success')
        return redirect(url_for('login'))
    
    return render_template('register.html')

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username'].encode('utf-8')
        password = request.form['password']
        
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.callproc('get_user_by_username', [username])
        user = None
        for result in cursor.stored_results():
            user = result.fetchone()
        
        if user:
            # Decode the stored hash before checking
            stored_password = user['password'].decode('utf-8')
            if check_password_hash(stored_password, password):
                session['user_id'] = user['id']
                session['username'] = user['username'].decode('utf-8')
                flash('Welcome back!', 'success')
                return redirect(url_for('tasks'))
        
        flash('Invalid username or password', 'error')
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

if __name__ == '__main__':
    app.run(host='0.0.0.0', debug=True)
