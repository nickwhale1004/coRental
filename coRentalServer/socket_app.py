from datetime import datetime

from flask_socketio import SocketIO, join_room, emit
import sqlite3

import jwt
from flask import Flask, request, jsonify

app = Flask(__name__)
app.config['SECRET_KEY'] = '8VDmUhXEtmAYYLh1tRNpCsbFstyIZD'
app.config['DATABASE'] = 'users.db'
socketio = SocketIO(app, cors_allowed_origins="*", engineio_logger=True, logger=True)


@socketio.on("connect")
def handle_connect(data):
    print("Connected!")
    token = data.get('token')
    try:
        payload = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
        user_id = payload['user_id']
        join_room(user_id)

    except jwt.ExpiredSignatureError:
        return jsonify({'message': 'Token expired'})

    except jwt.InvalidTokenError:
        return jsonify({'message': 'Invalid token'})


@socketio.on('send_message')
def handle_send_message(data):
    token = data.get('token')
    chat_id = data.get('chat_id')
    message_text = data.get('text')

    try:
        payload = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
        user_id_from = payload['user_id']

        conn = get_db_connection()
        cursor = conn.cursor()

        cursor.execute("SELECT * FROM UserModel WHERE id = ?", (user_id_from,))
        user_from = cursor.fetchone()

        cursor.execute("SELECT * FROM ChatModel WHERE id = ?", (chat_id,))
        chat_model = cursor.fetchone()
        user_id_to = chat_model[0] if chat_model[0] != user_id_from else chat_model[1]

        if user_from:
            cursor.execute("""
                    INSERT INTO MessageModel (chat_id, sender_id, message_text, timestamp)
                    VALUES (?, ?, ?, CURRENT_TIMESTAMP)
                """, (chat_id, user_id_from, message_text))
            last_id = cursor.lastrowid
            cursor.execute("SELECT timestamp FROM MessageModel WHERE id = ?", (last_id,))
            timestamp = cursor.fetchall()[0]

            conn.commit()
            conn.close()

            new_message = {
                'id': last_id,
                'user_name': user_from[1] + ' ' + user_from[2],
                'message_text': message_text,
                'timestamp': datetime.strptime(''.join(timestamp), '%Y-%m-%d %H:%M:%S').isoformat() + 'Z'
            }
            emit('receive_message', new_message, room=user_id_to)
            emit('receive_message', new_message, room=user_id_from)

    except Exception:
        pass


def get_db_connection():
    conn = sqlite3.connect(app.config['DATABASE'])
    conn.row_factory = sqlite3.Row
    return conn


if __name__ == '__main__':
    socketio.run(app, port=3000)
