from datetime import datetime

import jwt
from flask import request, jsonify, Blueprint, current_app
from models import get_db_connection
from token_required import token_required

routes = Blueprint('chat_routes', __name__)


@routes.route('/createChat', methods=['POST'])
@token_required
def create_chat():
    data = request.json
    token = data.get('token')
    user_id2 = data.get('user_id')

    payload = jwt.decode(token, current_app.config['SECRET_KEY'], algorithms=['HS256'])
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


@routes.route('/getChats', methods=['POST'])
@token_required
def get_chats():
    data = request.json
    token = data.get('token')

    payload = jwt.decode(token, current_app.config['SECRET_KEY'], algorithms=['HS256'])
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


@routes.route('/getMessages', methods=['POST'])
@token_required
def get_messages():
    data = request.json
    token = data.get('token')
    chat_id = data.get('chat_id')
    page = data.get('page', 1)  # Номер страницы, по умолчанию 1
    messages_per_page = 10

    # Декодируем токен для определения пользователя
    payload = jwt.decode(token, current_app.config['SECRET_KEY'], algorithms=['HS256'])
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
