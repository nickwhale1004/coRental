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
            'country': user[6],
            'about': user[7]
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
            country = ?,
            about = ?
        WHERE id = ?
    """, (
        new_user_data.get('first_name'),
        new_user_data.get('last_name'),
        new_user_data.get('third_name'),
        new_user_data.get('age'),
        new_user_data.get('gender'),
        new_user_data.get('country'),
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

    # Получаем данные текущего пользователя
    cursor.execute("SELECT * FROM UserModel WHERE id = ?", (user_id,))
    current_user = cursor.fetchone()
    if not current_user:
        return jsonify({'message': 'User not found.'}), 404

    search_type = search_data['type']
    user_age_from = search_data['user_age_from']
    user_age_to = search_data['user_age_to']
    user_gender = search_data['user_gender']
    house_price_from = search_data['house_price_from']
    house_price_to = search_data['house_price_to']

    # Получаем всех подходящих пользователей
    sql_query = """
    SELECT UserModel.*, HouseModel.*
    FROM UserModel
    LEFT JOIN HouseModel ON UserModel.id = HouseModel.user_id
    WHERE UserModel.id != ?
    """
    params = [user_id]

    if user_age_from is not None:
        sql_query += " AND (UserModel.age > ?)"
        params.append(user_age_from)
    if user_age_to is not None:
        sql_query += " AND (UserModel.age < ?)"
        params.append(user_age_to)
    if user_gender is not None:
        sql_query += " AND (UserModel.gender = ?)"
        params.append(user_gender)

    cursor.execute(sql_query, params)
    matched_users = cursor.fetchall()

    # Получаем дома в указанном диапазоне цен
    sql_query = "SELECT * FROM HouseModel WHERE 1=1"
    params = []

    if house_price_from is not None:
        sql_query += " AND (price > ?)"
        params.append(house_price_from)
    if house_price_to is not None:
        sql_query += " AND (price < ?)"
        params.append(house_price_to)

    cursor.execute(sql_query, params)
    houses = cursor.fetchall()

    # Применяем приоритезацию
    prioritized_users = prioritize_users(current_user, matched_users)

    # Добавляем информацию о доме и лайках
    houses = [dict(house) for house in houses]

    for user in prioritized_users:
        cursor.execute("SELECT 1 FROM LikesModel WHERE user_id = ? AND liked_user_id = ?", (user_id, user['id']))
        user['is_liked'] = cursor.fetchone() is not None
        user['house'] = next((house for house in houses if house['user_id'] == user['id']), None)

        cursor.execute("""
            INSERT INTO UserViews (user_id, viewed_user_id)
            SELECT ?, ?
            WHERE NOT EXISTS (
                SELECT 1 FROM UserViews WHERE user_id = ? AND viewed_user_id = ?
            )
        """, (user_id, user['id'], user_id, user['id']))

    conn.commit()
    conn.close()

    return jsonify({'users': [dict(user) for user in prioritized_users]})


def prioritize_users(current_user, users):
    same_gender = [user for user in users if user['gender'] == current_user['gender']]
    different_gender = [user for user in users if user['gender'] != current_user['gender']]

    def age_difference(user):
        return abs(user['age'] - current_user['age'])

    same_gender.sort(key=age_difference)
    different_gender.sort(key=age_difference)

    same_origin = [user for user in same_gender if user['country'] == current_user['country']]
    different_origin = [user for user in same_gender if user['country'] != current_user['country']]

    same_origin_diff_gender = [user for user in different_gender if user['country'] == current_user['country']]
    different_origin_diff_gender = [user for user in different_gender if user['country'] != current_user['country']]

    prioritized_users = []
    prioritized_users.extend(same_origin)
    prioritized_users.extend(different_origin)
    prioritized_users.extend(same_origin_diff_gender)
    prioritized_users.extend(different_origin_diff_gender)

    return prioritized_users
