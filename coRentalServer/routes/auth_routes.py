import jwt
from flask import request, jsonify, Blueprint, current_app
from models import get_db_connection
from token_required import token_required

routes = Blueprint('auth_routes', __name__)


@routes.route('/register', methods=['POST'])
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

    token = jwt.encode({'user_id': user_id}, current_app.config['SECRET_KEY'], algorithm='HS256')
    return jsonify({'token': token, 'message': 'Login successful!'})


@routes.route('/login', methods=['POST'])
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

        token = jwt.encode({'user_id': user_id}, current_app.config['SECRET_KEY'], algorithm='HS256')
        conn.close()
        return jsonify({'token': token, 'message': 'Login successful!'})
    else:
        conn.close()
        return jsonify({'message': 'Invalid credentials'}), 401


@routes.route('/verify_token', methods=['POST'])
@token_required
def verify_token():
    token = request.json.get('token')
    decoded = jwt.decode(token, current_app .config['SECRET_KEY'], algorithms=['HS256'])
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
