import sqlite3

from config import Config


def get_db_connection():
    conn = sqlite3.connect(Config.DATABASE)
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
            country VARCHAR(50),
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

    cursor.execute("""
            CREATE TABLE IF NOT EXISTS LikesModel (
                user_id INTEGER PRIMARY KEY,
                liked_user_id INTEGER
            )
        """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS UserViews (
            id INTEGER PRIMARY KEY,
            user_id INTEGER,
            viewed_user_id INTEGER,
            FOREIGN KEY (user_id) REFERENCES UserModel(id),
            FOREIGN KEY (viewed_user_id) REFERENCES UserModel(id)
        )
    """)

    conn.commit()
    conn.close()
