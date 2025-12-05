import os
import mysql.connector
from flask import Flask, render_template_string, request, redirect, url_for

app = Flask(__name__)

# --- Configuration ---
# In the legacy environment, these might be hardcoded.
# In OCI, we will inject these via Environment Variables.
DB_HOST = os.environ.get('DB_HOST', 'localhost')
DB_USER = os.environ.get('DB_USER', 'app_user')
DB_PASSWORD = os.environ.get('DB_PASSWORD', 'Welcome123!')
DB_NAME = os.environ.get('DB_NAME', 'employee_directory')

def get_db_connection():
    try:
        conn = mysql.connector.connect(
            host=DB_HOST,
            user=DB_USER,
            password=DB_PASSWORD,
            database=DB_NAME
            ssl_disabled=True
        )
        return conn
    except mysql.connector.Error as err:
        return None

# --- HTML Template (Embedded for single-file portability) ---
HTML_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>Legacy Employee Directory</title>
    <style>
        body { font-family: sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
        .header { background-color: #f4f4f4; padding: 20px; border-radius: 5px; }
        .status { padding: 10px; margin-bottom: 20px; border-radius: 4px; }
        .connected { background-color: #dff0d8; color: #3c763d; }
        .error { background-color: #f2dede; color: #a94442; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { padding: 10px; border: 1px solid #ddd; text-align: left; }
        th { background-color: #333; color: white; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Employee Directory v1.0</h1>
        <p>Running on Host: <strong>{{ hostname }}</strong></p>
    </div>

    {% if db_status %}
        <div class="status connected">✅ Connected to Database at <strong>{{ db_host }}</strong></div>
        
        <h3>Add New Employee</h3>
        <form action="/add" method="post">
            <input type="text" name="name" placeholder="Name" required>
            <input type="text" name="role" placeholder="Job Title" required>
            <input type="email" name="email" placeholder="Email" required>
            <button type="submit">Add Employee</button>
        </form>

        <h3>Directory Listing</h3>
        <table>
            <tr><th>ID</th><th>Name</th><th>Role</th><th>Email</th></tr>
            {% for emp in employees %}
            <tr>
                <td>{{ emp[0] }}</td>
                <td>{{ emp[1] }}</td>
                <td>{{ emp[2] }}</td>
                <td>{{ emp[3] }}</td>
            </tr>
            {% endfor %}
        </table>
    {% else %}
        <div class="status error">❌ Database Connection Failed. Check environment variables.</div>
    {% endif %}
</body>
</html>
"""

@app.route('/')
def index():
    conn = get_db_connection()
    employees = []
    db_status = False
    
    if conn and conn.is_connected():
        db_status = True
        cursor = conn.cursor()
        cursor.execute('SELECT id, name, role, email FROM employees')
        employees = cursor.fetchall()
        cursor.close()
        conn.close()

    return render_template_string(HTML_TEMPLATE, 
                                hostname=os.uname()[1], 
                                db_status=db_status, 
                                db_host=DB_HOST,
                                employees=employees)

@app.route('/add', methods=['POST'])
def add_employee():
    conn = get_db_connection()
    if conn:
        cursor = conn.cursor()
        name = request.form['name']
        role = request.form['role']
        email = request.form['email']
        cursor.execute('INSERT INTO employees (name, role, email) VALUES (%s, %s, %s)', (name, role, email))
        conn.commit()
        conn.close()
    return redirect(url_for('index'))

if __name__ == '__main__':
    # Listen on all interfaces
    app.run(host='0.0.0.0', port=5000)