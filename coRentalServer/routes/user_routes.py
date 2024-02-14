import sqlite3

import jwt
from flask import request, jsonify, Blueprint, current_app
from models import get_db_connection
from token_required import token_required

routes = Blueprint('user_routes', __name__)


@routes.route('/getUser', methods=['POST'])
@token_required
def get_user_data():
    data = request.json
    token = data.get('token')

    try:
        payload = jwt.decode(token, current_app.config['SECRET_KEY'], algorithms=['HS256'])
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


@routes.route('/updateUser', methods=['POST'])
@token_required
def update_user_data():
    data = request.json
    token = data.get('token')
    new_user_data = data.get('user')

    payload = jwt.decode(token, current_app.config['SECRET_KEY'], algorithms=['HS256'])
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


@routes.route('/searchUsers', methods=['POST'])
@token_required
def search_users():
    token = request.json.get('token')

    user_id = jwt.decode(token, current_app.config['SECRET_KEY'], algorithms=['HS256'])['user_id']

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

    sql_query = """
    SELECT UserModel.*, HouseModel.* 
    FROM UserModel
    LEFT JOIN HouseModel ON UserModel.id = HouseModel.user_id
    WHERE 1=1
    """
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
        cursor.execute("SELECT 1 FROM LikesModel WHERE user_id = ? AND liked_user_id = ?", (user_id, user['id']))
        user['is_liked'] = cursor.fetchone() is not None
        user['house'] = next((house for house in houses if house['user_id'] == user['id']), None)

    conn.close()

    return jsonify({'users': matched_users})
