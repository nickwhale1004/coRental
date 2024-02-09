import os
import sqlite3
import uuid
from datetime import datetime

import jwt
from flask import Flask, request, jsonify, send_file

app = Flask(__name__)
app.config['SECRET_KEY'] = '8VDmUhXEtmAYYLh1tRNpCsbFstyIZD'
app.config['DATABASE'] = 'users.db'


def get_db_connection():
    conn = sqlite3.connect(app.config['DATABASE'])
    conn.row_factory = sqlite3.Row
    return conn


def create_tables():
    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS UserModel (
            id INTEGER PRIMARY KEY,
            first_name VARCHAR(50),
            last_name VARCHAR(50),
            third_name VARCHAR(50),
            age INTEGER,
            gender INTEGER,
            about VARCHAR(100)
        )
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS UserAuth (
            id INTEGER PRIMARY KEY,
            login VARCHAR(100) UNIQUE NOT NULL,
            password VARCHAR(100) NOT NULL,
            user_id INTEGER,
            FOREIGN KEY (user_id) REFERENCES UserModel (id)
        )
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS SearchModel (
            id INTEGER PRIMARY KEY,
            type INTEGER,
            user_age_from INTEGER,
            user_age_to INTEGER,
            user_gender INTEGER,
            house_price_from INTEGER,
            house_price_to INTEGER,
            user_id INTEGER,
            FOREIGN KEY (user_id) REFERENCES UserModel (id)
        )
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS HouseModel (
            id INTEGER PRIMARY KEY,
            address VARCHAR(100),
            price INTEGER,
            image_url VARCHAR(200),
            user_id INTEGER,
            FOREIGN KEY (user_id) REFERENCES UserModel (id)
        )
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS ChatModel (
            id INTEGER PRIMARY KEY,
            user_id1 INTEGER,
            user_id2 INTEGER,
            FOREIGN KEY (user_id1) REFERENCES UserModel (id),
            FOREIGN KEY (user_id2) REFERENCES UserModel (id)
        )
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS MessageModel (
            id INTEGER PRIMARY KEY,
            chat_id INTEGER,
            sender_id INTEGER,
            message_text TEXT,
            timestamp DATETIME,
            FOREIGN KEY (chat_id) REFERENCES ChatModel (id),
            FOREIGN KEY (sender_id) REFERENCES UserModel (id)
        )
    """)

    conn.commit()
    conn.close()


@app.route('/register', methods=['POST'])
def register():
    data = request.json

    conn = get_db_connection()
    cursor = conn.cursor()

    new_user = (
        data.get('user').get('first_name'),
        data.get('user').get('last_name'),
        data.get('user').get('third_name'),
        data.get('user').get('age'),
        data.get('user').get('gender'),
        data.get('user').get('about')
    )
    cursor.execute("""
        INSERT INTO UserModel (first_name, last_name, third_name, age, gender, about)
        VALUES (?, ?, ?, ?, ?, ?)
    """, new_user)
    user_id = cursor.lastrowid

    new_auth = (
        data.get('login'),
        data.get('password'),
        user_id
    )
    cursor.execute("""
        INSERT INTO UserAuth (login, password, user_id)
        VALUES (?, ?, ?)
    """, new_auth)

    if data.get('user').get("house"):
        new_house = (
            data.get('user').get("house").get("address"),
            data.get('user').get("house").get("price"),
            data.get('user').get("house").get("image_url"),
            user_id
        )
        cursor.execute("""
               INSERT INTO HouseModel (address, price, image_url, user_id)
               VALUES (?, ?, ?, ?)
           """, new_house)

    if data.get('user').get("search"):
        new_search = (
            data.get('user').get("search").get("type"),
            data.get('user').get("search").get("user_age_from"),
            data.get('user').get("search").get("user_age_to"),
            data.get('user').get("search").get("user_gender"),
            data.get('user').get("search").get("house_price_from"),
            data.get('user').get("search").get("house_price_to"),
            user_id
        )
        cursor.execute("""
                       INSERT INTO SearchModel (type, user_age_from, user_age_to, user_gender, house_price_from, house_price_to, user_id)
                       VALUES (?, ?, ?, ?, ?, ?, ?)
                   """, new_search)

    conn.commit()
    conn.close()

    token = jwt.encode({'user_id': user_id}, app.config['SECRET_KEY'], algorithm='HS256')
    return jsonify({'token': token, 'message': 'Login successful!'})


@app.route('/login', methods=['POST'])
def login():
    data = request.json
    login = data.get('login')
    password = data.get('password')

    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT * FROM UserAuth WHERE login=?", (login,))
    auths = cursor.fetchone()

    if auths and auths['password'] == password:
        user_id = auths['user_id']

        cursor.execute("SELECT * FROM UserModel WHERE id=?", (user_id,))

        token = jwt.encode({'user_id': user_id}, app.config['SECRET_KEY'], algorithm='HS256')
        conn.close()
        return jsonify({'token': token, 'message': 'Login successful!'})
    else:
        conn.close()
        return jsonify({'message': 'Invalid credentials'}), 401


@app.route('/verify_token', methods=['POST'])
def verify_token():
    try:
        token = request.json.get('token')
        decoded = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
        user_id = decoded['user_id']

        conn = get_db_connection()
        cursor = conn.cursor()

        cursor.execute("SELECT id FROM UserModel WHERE id = ?", (user_id,))
        user = cursor.fetchone()

        conn.close()

        if user:
            return jsonify({'message': 'Token is valid.', 'user_id': user_id})
        else:
            return jsonify({'message': 'Invalid token.'}), 401

    except jwt.ExpiredSignatureError:
        return jsonify({'message': 'Token has expired.'}), 401
    except jwt.InvalidTokenError:
        return jsonify({'message': 'Invalid token.'}), 401


@app.route('/upload', methods=['POST'])
def upload():
    if 'image' not in request.files:
        return jsonify({'error': 'No image provided.'}), 400

    image_file = request.files['image']
    if image_file.filename == '':
        return jsonify({'error': 'Empty filename.'}), 400

    if not os.path.exists('uploads'):
        os.makedirs('uploads')

    filename = str(uuid.uuid4()) + '.' + image_file.filename.rsplit('.', 1)[1]
    save_path = os.path.join('uploads', filename)

    image_file.save(save_path)
    download_url = request.host_url + 'download/' + filename

    return jsonify({'url': download_url}), 200


@app.route('/download/<filename>', methods=['GET'])
def download(filename):
    file_path = os.path.join('uploads', filename)

    if not os.path.isfile(file_path):
        return jsonify({'error': 'File not found.'}), 404

    return send_file(file_path, as_attachment=True)


@app.route('/getUser', methods=['POST'])
def get_user_data():
    data = request.json
    token = data.get('token')

    try:
        payload = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
        user_id = payload['user_id']

        conn = get_db_connection()
        cursor = conn.cursor()

        cursor.execute("SELECT * FROM UserModel WHERE id = ?", (user_id,))
        user = cursor.fetchone()

        if user:
            user_data = {
                'first_name': user[1],
                'last_name': user[2],
                'third_name': user[3],
                'age': user[4],
                'gender': user[5],
                'about': user[6]
            }

            cursor.execute("SELECT * FROM HouseModel WHERE user_id = ?", (user_id,))
            house = cursor.fetchone()

            if house:
                house_data = {
                    'address': house[1],
                    'price': house[2],
                    'image_url': house[3]
                }
                user_data['house'] = house_data

            cursor.execute("SELECT * FROM SearchModel WHERE user_id = ?", (user_id,))
            search = cursor.fetchone()

            if search:
                search_data = {
                    'type': search[1],
                    'user_age_from': search[2],
                    'user_age_to': search[3],
                    'user_gender': search[4],
                    'house_price_from': search[5],
                    'house_price_to': search[6]
                }
                user_data['search'] = search_data

            conn.close()
            return jsonify(user_data)
        else:
            conn.close()
            return jsonify({'message': 'User not found'})

    except jwt.ExpiredSignatureError:
        return jsonify({'message': 'Token expired'})

    except jwt.InvalidTokenError:
        return jsonify({'message': 'Invalid token'})


@app.route('/updateUser', methods=['POST'])
def update_user_data():
    data = request.json
    token = data.get('token')
    new_user_data = data.get('user')

    try:
        payload = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
        user_id = payload['user_id']

        conn = get_db_connection()
        cursor = conn.cursor()

        cursor.execute("""
            UPDATE UserModel
            SET first_name = ?,
                last_name = ?,
                third_name = ?,
                age = ?,
                gender = ?,
                about = ?
            WHERE id = ?
        """, (
            new_user_data.get('first_name'),
            new_user_data.get('last_name'),
            new_user_data.get('third_name'),
            new_user_data.get('age'),
            new_user_data.get('gender'),
            new_user_data.get('about'),
            user_id
        ))

        if new_user_data.get('house'):
            house_data = new_user_data.get('house')
            cursor.execute("""SELECT * FROM HouseModel WHERE user_id = ?""", (user_id,))
            houses = cursor.fetchall()

            sql = """
                UPDATE HouseModel
                SET address = ?,
                    price = ?,
                    image_url = ?
                WHERE user_id = ?
            """
            if not houses:
                sql = """
                    INSERT INTO HouseModel (address, price, image_url, user_id)
                    VALUES (?, ?, ?, ?)
                """

            cursor.execute(sql, (
                house_data.get('address'),
                house_data.get('price'),
                house_data.get('image_url'),
                user_id
            ))

        if new_user_data.get('search'):
            search_data = new_user_data.get('search')
            cursor.execute("""
                UPDATE SearchModel
                SET type = ?,
                    user_age_from = ?,
                    user_age_to = ?,
                    user_gender = ?,
                    house_price_from = ?,
                    house_price_to = ?
                WHERE user_id = ?
            """, (
                search_data.get('type'),
                search_data.get('user_age_from'),
                search_data.get('user_age_to'),
                search_data.get('user_gender'),
                search_data.get('house_price_from'),
                search_data.get('house_price_to'),
                user_id
            ))

        conn.commit()
        conn.close()

        return jsonify({'message': 'User data updated successfully'})

    except jwt.ExpiredSignatureError:
        return jsonify({'message': 'Token expired'})

    except jwt.InvalidTokenError:
        return jsonify({'message': 'Invalid token'})


@app.route('/searchUsers', methods=['POST'])
def search_users():
    token = request.json.get('token')

    if not token:
        return jsonify({'message': 'Authorization token is missing.'}), 401

    try:
        user_id = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])['user_id']
    except jwt.DecodeError:
        return jsonify({'message': 'Invalid token.'}), 401

    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.row_factory = sqlite3.Row

    cursor.execute("SELECT * FROM SearchModel WHERE user_id = ?", (user_id,))
    search_data = cursor.fetchone()

    if not search_data:
        return jsonify({'message': 'Search parameters not found for the user.'}), 404

    search_type = search_data['type']
    user_age_from = search_data['user_age_from']
    user_age_to = search_data['user_age_to']
    user_gender = search_data['user_gender']
    house_price_from = search_data['house_price_from']
    house_price_to = search_data['house_price_to']

    sql_query = "SELECT UserModel.*, HouseModel.* FROM UserModel LEFT JOIN HouseModel ON UserModel.id = HouseModel.user_id WHERE 1=1"
    params = []

    if user_age_from is not None:
        sql_query += " AND (UserModel.age > ?)"
        params.extend([user_age_from])
    if user_age_to is not None:
        sql_query += " AND (UserModel.age < ?)"
        params.extend([user_age_to])

    if user_gender is not None:
        sql_query += " AND (UserModel.gender = ?)"
        params.append(user_gender)

    cursor.execute(sql_query, params)
    matched_users = cursor.fetchall()

    sql_query = "SELECT * FROM HouseModel WHERE 1=1"
    params = []

    if house_price_from is not None:
        sql_query += " AND (price > ?)"
        params.extend([house_price_from])
    if house_price_to is not None:
        sql_query += " AND (price < ?)"
        params.extend([house_price_to])

    cursor.execute(sql_query, params)
    houses = cursor.fetchall()

    matched_user_ids = set(user['id'] for user in matched_users)

    if search_type == 0:
        matched_users = [dict(user) for user in matched_users if user['id'] in matched_user_ids and
                         all(house['user_id'] != user['id'] for house in houses)]
    else:
        matched_users = [dict(user) for user in matched_users if user['id'] in matched_user_ids and
                         any(house['user_id'] == user['id'] for house in houses)]

    matched_users = [dict(user) for user in matched_users if user['id'] != user_id]

    houses = [dict(house) for house in houses]

    for user in matched_users:
        user['house'] = next((house for house in houses if house['user_id'] == user['id']), None)

    conn.close()

    return jsonify({'users': matched_users})


@app.route('/createChat', methods=['POST'])
def create_chat():
    data = request.json
    token = data.get('token')
    user_id2 = data.get('user_id')

    try:
        payload = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
        user_id1 = payload['user_id']

        conn = get_db_connection()
        cursor = conn.cursor()

        cursor.execute("SELECT * FROM UserModel WHERE id = ?", (user_id1,))
        user1 = cursor.fetchone()

        cursor.execute("SELECT * FROM UserModel WHERE id = ?", (user_id2,))
        user2 = cursor.fetchone()

        if user1 and user2:
            cursor.execute("""
                SELECT * FROM ChatModel
                WHERE (user_id1 = ? AND user_id2 = ?) OR (user_id1 = ? AND user_id2 = ?)
            """, (user_id1, user_id2, user_id2, user_id1))

            existing_chat = cursor.fetchone()

            if not existing_chat:
                cursor.execute("INSERT INTO ChatModel (user_id1, user_id2) VALUES (?, ?)", (user_id1, user_id2))
                conn.commit()
                conn.close()
                return jsonify({'message': 'Chat created successfully'})
            else:
                conn.close()
                return jsonify({'message': 'Chat already exists'})
        else:
            conn.close()
            return jsonify({'message': 'User not found'})

    except jwt.ExpiredSignatureError:
        return jsonify({'message': 'Token expired'})

    except jwt.InvalidTokenError:
        return jsonify({'message': 'Invalid token'})


@app.route('/getChats', methods=['POST'])
def get_chats():
    data = request.json
    token = data.get('token')

    try:
        payload = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
        user_id = payload['user_id']

        conn = get_db_connection()
        cursor = conn.cursor()

        cursor.execute("""
            SELECT ChatModel.id,
       UserModel.first_name,
       UserModel.last_name,
       MessageModel.message_text,
       MessageModel.timestamp
FROM ChatModel
JOIN UserModel ON ((ChatModel.user_id1 = UserModel.id AND ChatModel.user_id2 = ?) OR
                   (ChatModel.user_id2 = UserModel.id AND ChatModel.user_id1 = ?))
LEFT JOIN (
    SELECT chat_id, MAX(timestamp) AS max_timestamp
    FROM MessageModel
    GROUP BY chat_id
) AS LatestMessage ON ChatModel.id = LatestMessage.chat_id
LEFT JOIN MessageModel ON LatestMessage.chat_id = MessageModel.chat_id AND LatestMessage.max_timestamp = MessageModel.timestamp
WHERE ChatModel.user_id1 = ? OR ChatModel.user_id2 = ?
        """, (user_id, user_id, user_id,user_id))

        chats = cursor.fetchall()
        chat_list = []

        for chat in chats:
            timestamp = None
            if chat[4]:
                timestamp = datetime.strptime(chat[4], '%Y-%m-%d %H:%M:%S').isoformat() + 'Z'

            chat_data = {
                'id': chat[0],
                'user_name': f'{chat[1]} {chat[2]}',
                'last_message': chat[3],
                'timestamp': timestamp
            }
            chat_list.append(chat_data)

        conn.close()
        return jsonify({'chats': chat_list})

    except jwt.ExpiredSignatureError:
        return jsonify({'message': 'Token expired'})

    except jwt.InvalidTokenError:
        return jsonify({'message': 'Invalid token'})


@app.route('/getMessages', methods=['POST'])
def get_messages():
    data = request.json
    token = data.get('token')
    chat_id = data.get('chat_id')
    page = data.get('page', 1)  # Номер страницы, по умолчанию 1
    messages_per_page = 10

    try:
        # Декодируем токен для определения пользователя
        payload = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
        user_id = payload['user_id']

        conn = get_db_connection()
        cursor = conn.cursor()

        # Проверяем, что пользователь имеет доступ к этому чату
        cursor.execute("""
            SELECT 1 FROM ChatModel WHERE id = ? AND (user_id1 = ? OR user_id2 = ?)
        """, (chat_id, user_id, user_id))

        chat_exists = cursor.fetchone()

        if chat_exists:
            # Вычисляем смещение для запроса сообщений в зависимости от страницы
            offset = (page - 1) * messages_per_page

            # Получаем список сообщений в чате
            cursor.execute("""
                SELECT MessageModel.id, UserModel.first_name, UserModel.last_name, MessageModel.message_text, MessageModel.timestamp
                FROM MessageModel
                JOIN UserModel ON MessageModel.sender_id = UserModel.id
                WHERE MessageModel.chat_id = ?
                ORDER BY MessageModel.timestamp DESC
                LIMIT ? OFFSET ?
            """, (chat_id, messages_per_page, offset))

            messages = cursor.fetchall()
            message_list = []

            for message in messages:
                message_data = {
                    'id': message[0],
                    'user_name': f'{message[1]} {message[2]}',
                    'message_text': message[3],
                    'timestamp': datetime.strptime(message[4], '%Y-%m-%d %H:%M:%S').isoformat() + 'Z'
                }
                message_list.append(message_data)

            conn.close()
            return jsonify({'messages': message_list})
        else:
            conn.close()
            return jsonify({'message': 'Access denied to this chat'})

    except jwt.ExpiredSignatureError:
        return jsonify({'message': 'Token expired'})

    except jwt.InvalidTokenError:
        return jsonify({'message': 'Invalid token'})


if __name__ == '__main__':
    create_tables()

    app.run()
