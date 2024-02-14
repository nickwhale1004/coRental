import jwt
from flask import request, jsonify, Blueprint, current_app
from models import get_db_connection
from token_required import token_required

routes = Blueprint('like_routes', __name__)


@routes.route('/like', methods=['POST'])
@token_required
def like():
    data = request.json
    token = data.get('token')
    liked_user_id = data.get('target_user_id')

    payload = jwt.decode(token, current_app.config['SECRET_KEY'], algorithms=['HS256'])
    user_id = payload['user_id']

    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT 1 FROM LikesModel WHERE user_id = ? AND liked_user_id = ?
    """, (user_id, liked_user_id))

    like_exists = cursor.fetchone()

    if not like_exists:
        cursor.execute("""
            INSERT INTO LikesModel (user_id, liked_user_id) VALUES (?, ?)
        """, (user_id, liked_user_id))
        conn.commit()
        message = 'Like has been added successfully'
    else:
        message = 'Like already exists'

    conn.close()
    return jsonify({'message': message})


@routes.route('/unlike', methods=['POST'])
@token_required
def unlike():
    data = request.json
    token = data.get('token')
    unliked_user_id = data.get('target_user_id')

    payload = jwt.decode(token, current_app.config['SECRET_KEY'], algorithms=['HS256'])
    user_id = payload['user_id']

    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT 1 FROM LikesModel WHERE user_id = ? AND liked_user_id = ?
    """, (user_id, unliked_user_id))

    like_exists = cursor.fetchone()

    if like_exists:
        cursor.execute("""
            DELETE FROM LikesModel WHERE user_id = ? AND liked_user_id = ?
        """, (user_id, unliked_user_id))
        conn.commit()
        message = 'Like has been removed successfully'
    else:
        message = 'Like does not exist'

    conn.close()
    return jsonify({'message': message})
