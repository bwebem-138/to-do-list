from flask import Flask, render_template, request, redirect, session
import mariadb
import bcrypt
import os

# Create Flask app
app = Flask(__name__, template_folder="/todolist/templates", static_folder="/todolist/static")
app.secret_key = os.urandom(24)

# Connect to the database
conn = mariadb.connect(
    host="mariadb",
    port=3306,
    user="todo_user",
    password="todopass123",
    database="todo_db"
)
cursor = conn.cursor()

# Default route
@app.route("/")
def default_route():
    return redirect('/login')

# Register
@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        email = request.form['email']
        password = request.form['password']

        hashed_email = bcrypt.hashpw(email.encode(), bcrypt.gensalt())
        hashed_pw = bcrypt.hashpw(password.encode(), bcrypt.gensalt())

        cursor.execute("CALL RegisterUser(%s, %s)", (hashed_email, hashed_pw))
        conn.commit()

        return redirect('/login')

    return render_template('register.html')

# Login
@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        email = request.form['email']
        password = request.form['password']

        cursor.execute("CALL AuthenticateUser(%s)", (email,))
        user = cursor.fetchone()

        if user and bcrypt.checkpw(password.encode(), user[1].encode()):
            session['user'] = email
            return redirect('/todo')

    return render_template('login.html')

# Logout
@app.route('/logout')
def logout():
    session.pop('user', None)
    return redirect('/login')

# Task management
@app.route('/todo', methods=['GET', 'POST'])
def todo():
    if 'user' not in session:
        return redirect('/login')

    cursor.execute("CALL GetTasks(%s)", (session['user'],))
    tasks = cursor.fetchall()

    return render_template('todo.html', tasks=tasks)

@app.route('/add_task', methods=['POST'])
def add_task():
    if 'user' not in session:
        return redirect('/login')

    task = request.form['task']
    cursor.execute("CALL AddTask(%s, %s)", (session['user'], task))
    conn.commit()

    return redirect('/todo')

@app.route('/delete_task/<int:task_id>')
def delete_task(task_id):
    if 'user' not in session:
        return redirect('/login')

    cursor.execute("CALL DeleteTask(%s)", (task_id,))
    conn.commit()

    return redirect('/todo')

@app.route('/delete_account', methods=['GET', 'POST'])
def delete_account():
    if 'user' not in session:
        return redirect('/login')

    if request.method == 'POST':
        password = request.form['password']

        # Fetch the hashed password from DB
        cursor.execute("CALL AuthenticateUser(%s)", (session['user'],))
        user = cursor.fetchone()

        # Verify the password before deletion
        if user and bcrypt.checkpw(password.encode(), user[1].encode()):
            cursor.execute("CALL DeleteUser(%s)", (session['user'],))
            conn.commit()
            session.pop('user', None)
            return redirect('/register')

    return render_template('delete_account.html')

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')
