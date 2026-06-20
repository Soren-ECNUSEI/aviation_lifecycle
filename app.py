from flask import Flask, render_template, request, redirect, url_for, flash
import mysql.connector
from datetime import datetime

app = Flask(__name__)
app.secret_key = 'your-secret-key'

db_config = {
    'host': 'localhost',
    'user': 'root',
    'password': '363205',
    'database': 'aviation',
    'autocommit': False,
    'raise_on_warnings': True
}

def get_db_connection():
    return mysql.connector.connect(**db_config)

def fmt_datetime(s):
    """将 datetime-local 输入格式 (YYYY-MM-DDTHH:MM) 转为 MySQL DATETIME 格式 (YYYY-MM-DD HH:MM:SS)"""
    if not s:
        return None
    try:
        return datetime.strptime(s, '%Y-%m-%dT%H:%M').strftime('%Y-%m-%d %H:%M:%S')
    except ValueError:
        return s  # 已经是正确格式则原样返回

def call_procedure(proc_name, args):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        placeholders = ', '.join(['%s'] * len(args))
        cursor.execute(f"CALL {proc_name}({placeholders})", args)
        # 消费存储过程内部语句（INSERT/UPDATE）产生的结果集
        for _ in cursor.stored_results():
            pass
        conn.commit()
        return True, '操作成功'
    except mysql.connector.Error as err:
        conn.rollback()
        return False, f'错误: {err.msg}'
    finally:
        cursor.close()
        conn.close()

# ---------- 首页 ----------
@app.route('/')
def index():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT COUNT(*) AS cnt FROM component WHERE retired=0")
    active_comps = cursor.fetchone()['cnt']
    cursor.execute("SELECT COUNT(*) AS cnt FROM installation_record WHERE remove_time IS NULL")
    installed = cursor.fetchone()['cnt']
    cursor.execute("SELECT COUNT(*) AS cnt FROM aircraft WHERE status='ACTIVE'")
    active_aircraft = cursor.fetchone()['cnt']
    cursor.close()
    conn.close()
    return render_template('index.html', active_comps=active_comps, installed=installed, active_aircraft=active_aircraft)

# ---------- 人员入档 ----------
@app.route('/operator/add', methods=['GET', 'POST'])
def operator_add():
    if request.method == 'POST':
        conn = get_db_connection()
        cursor = conn.cursor()
        try:
            cursor.execute(
                "INSERT INTO operator (name, role, contact) VALUES (%s, %s, %s)",
                (request.form['name'], request.form['role'],
                 request.form.get('contact') or None)
            )
            conn.commit()
            flash('人员入档成功', 'success')
        except mysql.connector.Error as err:
            conn.rollback()
            flash(f'入档失败: {err.msg}', 'danger')
        finally:
            cursor.close()
            conn.close()
        return redirect(url_for('operator_add'))
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT operator_id, name, role, contact FROM operator ORDER BY operator_id DESC")
    operators = cursor.fetchall()
    cursor.close()
    conn.close()
    roles = ['INSTALLER', 'TECHNICIAN', 'APPROVER', 'ADMIN']
    return render_template('operator_add.html', operators=operators, roles=roles)

# ---------- 飞机入库 ----------
@app.route('/aircraft/add', methods=['GET', 'POST'])
def aircraft_add():
    if request.method == 'POST':
        conn = get_db_connection()
        cursor = conn.cursor()
        try:
            cursor.execute(
                "INSERT INTO aircraft (registration, model, status, entry_date) VALUES (%s, %s, %s, %s)",
                (request.form['registration'], request.form['model'],
                 request.form.get('status', 'ACTIVE'), request.form['entry_date'])
            )
            conn.commit()
            flash('飞机入库成功', 'success')
        except mysql.connector.Error as err:
            conn.rollback()
            flash(f'入库失败: {err.msg}', 'danger')
        finally:
            cursor.close()
            conn.close()
        return redirect(url_for('aircraft_add'))
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT aircraft_id, registration, model, status, entry_date FROM aircraft ORDER BY aircraft_id DESC")
    aircrafts = cursor.fetchall()
    cursor.close()
    conn.close()
    statuses = ['ACTIVE', 'MAINTENANCE', 'RETIRED']
    return render_template('aircraft_add.html', aircrafts=aircrafts, statuses=statuses)

# ---------- 部件入库 ----------
@app.route('/component/add', methods=['GET', 'POST'])
def component_add():
    if request.method == 'POST':
        args = (request.form['serial_number'], int(request.form['model_id']),
                request.form.get('batch_no', ''), request.form.get('production_date', None),
                int(request.form.get('operator_id', 0)) if request.form.get('operator_id') else None)
        success, msg = call_procedure('AddComponent', args)
        flash(msg, 'success' if success else 'danger')
        return redirect(url_for('component_add'))
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT model_id, model_code FROM component_model")
    models = cursor.fetchall()
    cursor.execute("SELECT operator_id, name FROM operator WHERE role IN ('INSTALLER','ADMIN')")
    operators = cursor.fetchall()
    cursor.close()
    conn.close()
    return render_template('component_add.html', models=models, operators=operators)

# ---------- 部件安装 ----------
@app.route('/component/install', methods=['GET', 'POST'])
def component_install():
    if request.method == 'POST':
        args = (int(request.form['component_id']), int(request.form['aircraft_id']),
                request.form['position'], fmt_datetime(request.form['install_time']),
                request.form.get('install_reason', ''),
                int(request.form.get('operator_id', 0)) if request.form.get('operator_id') else None)
        success, msg = call_procedure('InstallComponent', args)
        flash(msg, 'success' if success else 'danger')
        return redirect(url_for('component_install'))
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT aircraft_id, registration FROM aircraft WHERE status='ACTIVE'")
    aircrafts = cursor.fetchall()
    cursor.execute("SELECT component_id, serial_number, status FROM component WHERE status IN ('IN_STOCK','REMOVED') AND retired=0")
    components = cursor.fetchall()
    cursor.execute("SELECT operator_id, name FROM operator WHERE role IN ('INSTALLER','ADMIN')")
    operators = cursor.fetchall()
    cursor.close()
    conn.close()
    return render_template('component_install.html', aircrafts=aircrafts, components=components, operators=operators)

# ---------- 部件拆卸/更换 ----------
@app.route('/component/replace', methods=['GET', 'POST'])
def component_replace():
    if request.method == 'POST':
        action = request.form['action_type']
        if action == 'remove':
            args = (int(request.form['install_id']), fmt_datetime(request.form['remove_time']),
                    request.form.get('remove_reason', ''),
                    int(request.form.get('operator_id', 0)) if request.form.get('operator_id') else None)
            success, msg = call_procedure('RemoveComponent', args)
        elif action == 'replace':
            args = (int(request.form['old_install_id']), int(request.form['new_component_id']),
                    int(request.form['aircraft_id']), request.form['position'],
                    fmt_datetime(request.form['install_time']), request.form.get('install_reason', ''),
                    request.form.get('remove_reason', ''),
                    int(request.form.get('operator_id', 0)) if request.form.get('operator_id') else None)
            success, msg = call_procedure('ReplaceComponent', args)
        else:
            success, msg = False, '未知操作类型'
        flash(msg, 'success' if success else 'danger')
        return redirect(url_for('component_replace'))
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT ir.install_id, c.serial_number, a.registration, ir.position, ir.install_time
        FROM installation_record ir
        JOIN component c ON ir.component_id = c.component_id
        JOIN aircraft a ON ir.aircraft_id = a.aircraft_id
        WHERE ir.remove_time IS NULL
    """)
    installations = cursor.fetchall()
    cursor.execute("SELECT component_id, serial_number, status FROM component WHERE status IN ('IN_STOCK','REMOVED') AND retired=0")
    available = cursor.fetchall()
    cursor.execute("SELECT aircraft_id, registration FROM aircraft WHERE status='ACTIVE'")
    aircrafts = cursor.fetchall()
    cursor.execute("SELECT operator_id, name FROM operator WHERE role IN ('INSTALLER','ADMIN')")
    operators = cursor.fetchall()
    cursor.close()
    conn.close()
    return render_template('component_replace.html', installations=installations, available=available, aircrafts=aircrafts, operators=operators)

# ---------- 维修管理 ----------
@app.route('/maintenance', methods=['GET', 'POST'])
def maintenance():
    if request.method == 'POST':
        sub = request.form['sub_action']
        if sub == 'create':
            args = (int(request.form['component_id']), request.form['maintenance_type'],
                    fmt_datetime(request.form['start_time']),
                    int(request.form.get('technician_id', 0)) if request.form.get('technician_id') else None)
            success, msg = call_procedure('CreateMaintenanceRecord', args)
        elif sub == 'complete':
            args = (int(request.form['maintenance_id']), fmt_datetime(request.form['end_time']),
                    request.form['result'])
            success, msg = call_procedure('CompleteMaintenance', args)
            if success:
                # 维修完成后，若部件仍有有效安装记录则恢复为已安装状态
                conn2 = get_db_connection()
                cur2 = conn2.cursor(dictionary=True)
                cur2.execute(
                    "SELECT component_id FROM maintenance_record WHERE maintenance_id = %s",
                    (int(request.form['maintenance_id']),)
                )
                mr = cur2.fetchone()
                if mr:
                    cur2.execute(
                        "SELECT 1 FROM installation_record WHERE component_id = %s AND remove_time IS NULL",
                        (mr['component_id'],)
                    )
                    if cur2.fetchone():
                        cur2.execute(
                            "UPDATE component SET status = 'INSTALLED' WHERE component_id = %s",
                            (mr['component_id'],)
                        )
                        conn2.commit()
                cur2.close()
                conn2.close()
        else:
            success, msg = False, '未知操作'
        flash(msg, 'success' if success else 'danger')
        return redirect(url_for('maintenance'))
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT component_id, serial_number, status FROM component WHERE retired=0")
    components = cursor.fetchall()
    cursor.execute("SELECT maintenance_id, component_id, maintenance_type, start_time FROM maintenance_record WHERE end_time IS NULL")
    open_orders = cursor.fetchall()
    cursor.execute("SELECT operator_id, name FROM operator WHERE role='TECHNICIAN'")
    techs = cursor.fetchall()
    cursor.close()
    conn.close()
    return render_template('maintenance.html', components=components, open_orders=open_orders, techs=techs)

# ---------- 部件退役 ----------
@app.route('/component/retire', methods=['GET', 'POST'])
def component_retire():
    if request.method == 'POST':
        args = (int(request.form['component_id']), fmt_datetime(request.form['retire_time']),
                request.form['reason'],
                int(request.form.get('approved_by', 0)) if request.form.get('approved_by') else None)
        success, msg = call_procedure('RetireComponent', args)
        flash(msg, 'success' if success else 'danger')
        return redirect(url_for('component_retire'))
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT component_id, serial_number, status FROM component WHERE retired=0")
    components = cursor.fetchall()
    cursor.execute("SELECT operator_id, name FROM operator WHERE role='APPROVER'")
    approvers = cursor.fetchall()
    cursor.close()
    conn.close()
    return render_template('component_retire.html', components=components, approvers=approvers)

# ---------- 飞行管理 ----------
@app.route('/flight', methods=['GET', 'POST'])
def flight():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT aircraft_id, registration FROM aircraft WHERE status='ACTIVE'")
    aircrafts = cursor.fetchall()
    cursor.close()
    conn.close()

    stats_result = None
    serial_number = ''
    start_time = ''
    end_time = ''

    if request.method == 'POST':
        action = request.form.get('action', '')
        if action == 'add_log':
            args = (int(request.form['aircraft_id']), fmt_datetime(request.form['takeoff_time']),
                    fmt_datetime(request.form['landing_time']), request.form.get('flight_type', ''))
            success, msg = call_procedure('AddFlightLog', args)
            flash(msg, 'success' if success else 'danger')
            return redirect(url_for('flight'))
        elif action == 'query_stats':
            serial_number = request.form['serial_number']
            try:
                start_time = datetime.strptime(request.form['start_time'], '%Y-%m-%dT%H:%M').strftime('%Y-%m-%d %H:%M:%S')
                end_time = datetime.strptime(request.form['end_time'], '%Y-%m-%dT%H:%M').strftime('%Y-%m-%d %H:%M:%S')
            except:
                flash('时间格式错误', 'danger')
                return redirect(url_for('flight'))
            if end_time <= start_time:
                flash('结束时间必须晚于开始时间', 'danger')
                return redirect(url_for('flight'))
            conn = get_db_connection()
            cursor = conn.cursor(dictionary=True)
            query = """
                SELECT c.serial_number, COUNT(fl.flight_id) AS flight_count,
                       ROUND(SUM(TIMESTAMPDIFF(MINUTE, fl.takeoff_time, fl.landing_time)) / 60.0, 2) AS total_hours
                FROM component c
                JOIN installation_record ir ON c.component_id = ir.component_id
                JOIN flight_log fl ON ir.aircraft_id = fl.aircraft_id
                    AND fl.takeoff_time >= ir.install_time
                    AND (ir.remove_time IS NULL OR fl.landing_time <= ir.remove_time)
                WHERE c.serial_number = %s
                    AND fl.takeoff_time >= %s AND fl.landing_time <= %s
                GROUP BY c.component_id
            """
            cursor.execute(query, (serial_number, start_time, end_time))
            stats = cursor.fetchone()
            aircraft_usage = []
            if stats:
                cursor.execute("""
                    SELECT a.registration, COUNT(fl.flight_id) AS total_flights,
                           ROUND(SUM(TIMESTAMPDIFF(MINUTE, fl.takeoff_time, fl.landing_time)) / 60.0, 2) AS total_hours
                    FROM flight_log fl
                    JOIN aircraft a ON fl.aircraft_id = a.aircraft_id
                    JOIN installation_record ir ON a.aircraft_id = ir.aircraft_id
                    WHERE ir.component_id = (SELECT component_id FROM component WHERE serial_number = %s)
                      AND fl.takeoff_time >= ir.install_time
                      AND (ir.remove_time IS NULL OR fl.landing_time <= ir.remove_time)
                      AND fl.takeoff_time >= %s AND fl.landing_time <= %s
                    GROUP BY a.aircraft_id
                """, (serial_number, start_time, end_time))
                aircraft_usage = cursor.fetchall()
            cursor.close()
            conn.close()
            stats_result = {'stats': stats, 'aircraft_usage': aircraft_usage}

    return render_template('flight.html', aircrafts=aircrafts, stats_result=stats_result,
                           serial_number=serial_number, start_time=start_time, end_time=end_time)

# ---------- 生命周期追溯 ----------
@app.route('/lifecycle', methods=['GET', 'POST'])
def lifecycle():
    component_info = None
    install_records = []
    maintenance_records = []
    serial_number = ''
    if request.method == 'POST':
        serial_number = request.form['serial_number']
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("""
            SELECT c.serial_number, c.status, cm.model_code, c.total_flight_hours,
                   c.total_flight_cycles, c.retired, c.created_at AS in_stock_time,
                   sr.retirement_time, sr.reason AS retire_reason
            FROM component c
            JOIN component_model cm ON c.model_id = cm.model_id
            LEFT JOIN scrap_retirement_record sr ON c.component_id = sr.component_id
            WHERE c.serial_number = %s
        """, (serial_number,))
        component_info = cursor.fetchone()
        if component_info:
            cursor.execute("""
                SELECT ir.install_id, ir.install_time, ir.remove_time, ir.position,
                       ir.install_reason, ir.remove_reason,
                       a.registration AS aircraft_reg
                FROM installation_record ir
                JOIN aircraft a ON ir.aircraft_id = a.aircraft_id
                WHERE ir.component_id = (SELECT component_id FROM component WHERE serial_number = %s)
                ORDER BY ir.install_time
            """, (serial_number,))
            install_records = cursor.fetchall()
            cursor.execute("""
                SELECT mr.maintenance_id, mr.maintenance_type,
                       mr.start_time, mr.end_time, mr.result,
                       op.name AS technician_name
                FROM maintenance_record mr
                LEFT JOIN operator op ON mr.technician_id = op.operator_id
                WHERE mr.component_id = (SELECT component_id FROM component WHERE serial_number = %s)
                ORDER BY mr.start_time
            """, (serial_number,))
            maintenance_records = cursor.fetchall()
        cursor.close()
        conn.close()
    return render_template('lifecycle.html', serial_number=serial_number,
                           component=component_info,
                           install_records=install_records,
                           maintenance_records=maintenance_records)

# ---------- 部件实例列表 ----------
@app.route('/components')
def component_list():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    status_filter = request.args.get('status', '')
    model_filter = request.args.get('model_id', '')
    search_sn = request.args.get('search', '')
    query = """
        SELECT c.component_id, c.serial_number, cm.model_code, c.batch_no,
               c.production_date, c.status, c.total_flight_hours,
               c.total_flight_cycles, c.retired, c.created_at
        FROM component c
        JOIN component_model cm ON c.model_id = cm.model_id
        WHERE 1=1
    """
    params = []
    if status_filter:
        query += " AND c.status = %s"
        params.append(status_filter)
    if model_filter:
        query += " AND c.model_id = %s"
        params.append(int(model_filter))
    if search_sn:
        query += " AND c.serial_number LIKE %s"
        params.append(f"%{search_sn}%")
    query += " ORDER BY c.created_at DESC"
    cursor.execute(query, params)
    components = cursor.fetchall()
    cursor.execute("SELECT DISTINCT status FROM component")
    statuses = [row['status'] for row in cursor.fetchall()]
    cursor.execute("SELECT model_id, model_code FROM component_model")
    models = cursor.fetchall()
    cursor.close()
    conn.close()
    return render_template('component_list.html', components=components,
                           statuses=statuses, models=models,
                           current_status=status_filter, current_model=model_filter,
                           current_search=search_sn)

# ---------- 部件型号管理 ----------
@app.route('/component-models', methods=['GET', 'POST'])
def component_models():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    if request.method == 'POST':
        try:
            cursor.execute(
                "INSERT INTO component_model (model_code, category, design_life_hours, maintenance_interval_hours, applicable_aircraft) "
                "VALUES (%s, %s, %s, %s, %s)",
                (request.form['model_code'], request.form['category'],
                 int(request.form['design_life_hours']),
                 request.form.get('maintenance_interval_hours') or None,
                 request.form.get('applicable_aircraft') or None)
            )
            conn.commit()
            flash('型号添加成功', 'success')
        except mysql.connector.Error as err:
            conn.rollback()
            flash(f'添加失败: {err.msg}', 'danger')
    category_filter = request.args.get('category', '')
    search_code = request.args.get('search', '')
    query = "SELECT * FROM component_model WHERE 1=1"
    params = []
    if category_filter:
        query += " AND category = %s"
        params.append(category_filter)
    if search_code:
        query += " AND model_code LIKE %s"
        params.append(f"%{search_code}%")
    query += " ORDER BY model_code"
    cursor.execute(query, params)
    models = cursor.fetchall()
    cursor.execute("SELECT DISTINCT category FROM component_model")
    categories = [row['category'] for row in cursor.fetchall()]
    cursor.close()
    conn.close()
    return render_template('component_model_list.html', models=models,
                           categories=categories, current_category=category_filter,
                           current_search=search_code)

if __name__ == '__main__':
    app.run(debug=True)