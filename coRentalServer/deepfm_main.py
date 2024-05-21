import sqlite3
import pandas as pd
import numpy as np
import tensorflow as tf
from sklearn.preprocessing import LabelEncoder
from tensorflow.python.keras.layers import Input, Embedding, Dense, Flatten, Concatenate
from tensorflow.python.keras.models import Model
from keras.api.optimizers import Adam
from config import Config


# Функции для работы с базой данных
def get_db_connection():
    conn = sqlite3.connect(Config.DATABASE)
    conn.row_factory = sqlite3.Row
    return conn


def fetch_data_from_db():
    conn = get_db_connection()
    cursor = conn.cursor()

    # Извлечение данных пользователей
    cursor.execute("SELECT id, gender, age, country FROM UserModel")
    users_data = pd.DataFrame(cursor.fetchall())

    # Извлечение данных лайков
    cursor.execute("SELECT user_id, liked_user_id FROM LikesModel")
    likes_data = pd.DataFrame(cursor.fetchall())

    conn.close()
    return users_data, likes_data


def prepare_data_for_model(users_data, likes_data):
    # Присвоение идентификаторов для дополнительных признаков
    gender_encoder = LabelEncoder()
    country_encoder = LabelEncoder()

    users_data['gender'] = gender_encoder.fit_transform(users_data['gender'])
    users_data['country'] = country_encoder.fit_transform(users_data['country'])

    # Объединение данных о пользователях с данными о лайках
    merged_data = likes_data.merge(users_data, left_on='user_id', right_on='id', how='left')
    merged_data = merged_data.merge(users_data, left_on='liked_user_id', right_on='id', how='left',
                                    suffixes=('', '_liked'))

    # Входные данные для модели
    user_ids = merged_data['user_id'].values
    liked_user_ids = merged_data['liked_user_id'].values
    labels = np.ones(len(user_ids))  # Поскольку это лайки, метки будут 1

    # Дополнительные признаки
    user_genders = merged_data['gender'].values
    liked_user_genders = merged_data['gender_liked'].values
    user_ages = merged_data['age'].values
    liked_user_ages = merged_data['age_liked'].values
    user_countries = merged_data['country'].values
    liked_user_countries = merged_data['country_liked'].values

    # Пример ввода для модели
    inputs = [user_ids, liked_user_ids, user_genders, liked_user_genders, user_ages, liked_user_ages, user_countries,
              liked_user_countries]

    return inputs, labels


# Функция для создания модели DeepFM
def create_deepfm_model(num_users, embedding_size=10):
    # Входные данные
    user_id_input = Input(shape=(1,), name='user_id')
    liked_user_id_input = Input(shape=(1,), name='liked_user_id')
    user_gender_input = Input(shape=(1,), name='user_gender')
    liked_user_gender_input = Input(shape=(1,), name='liked_user_gender')
    user_age_input = Input(shape=(1,), name='user_age')
    liked_user_age_input = Input(shape=(1,), name='liked_user_age')
    user_country_input = Input(shape=(1,), name='user_country')
    liked_user_country_input = Input(shape=(1,), name='liked_user_country')

    # Эмбеддинги
    user_embedding = Embedding(input_dim=num_users, output_dim=embedding_size, name='user_embedding')(user_id_input)
    liked_user_embedding = Embedding(input_dim=num_users, output_dim=embedding_size, name='liked_user_embedding')(
        liked_user_id_input)

    # FM часть
    user_embedding_flat = Flatten()(user_embedding)
    liked_user_embedding_flat = Flatten()(liked_user_embedding)
    fm_interaction = tf.reduce_sum(tf.multiply(user_embedding_flat, liked_user_embedding_flat), axis=1)

    # DNN часть
    concat_embeddings = Concatenate()([user_embedding_flat, liked_user_embedding_flat])
    concat_features = Concatenate()(
        [concat_embeddings, user_gender_input, liked_user_gender_input, user_age_input, liked_user_age_input,
         user_country_input, liked_user_country_input])

    hidden_layer = Dense(128, activation='relu')(concat_features)
    hidden_layer = Dense(64, activation='relu')(hidden_layer)
    dnn_output = Dense(1, activation='sigmoid')(hidden_layer)

    # Объединение FM и DNN частей
    output = fm_interaction + dnn_output

    # Модель
    model = Model(
        inputs=[user_id_input, liked_user_id_input, user_gender_input, liked_user_gender_input, user_age_input,
                liked_user_age_input, user_country_input, liked_user_country_input], outputs=output)
    model.compile(optimizer=Adam(learning_rate=0.001), loss='binary_crossentropy', metrics=['AUC'])

    return model


# Функция для предсказания топ-N пользователей, которые могут понравиться user_id
def recommend_top_n(model, user_id, user_data, n=5):
    user_ids = np.full((len(user_data),), user_id)
    liked_user_ids = user_data['user_id'].values

    # Дополнительные признаки
    user_genders = np.full((len(user_data),), user_data[user_data['user_id'] == user_id]['gender'].values[0])
    liked_user_genders = user_data['gender'].values
    user_ages = np.full((len(user_data),), user_data[user_data['user_id'] == user_id]['age'].values[0])
    liked_user_ages = user_data['age'].values
    user_countries = np.full((len(user_data),), user_data[user_data['user_id'] == user_id]['country'].values[0])
    liked_user_countries = user_data['country'].values

    # Предсказание вероятностей
    inputs = [user_ids, liked_user_ids, user_genders, liked_user_genders, user_ages, liked_user_ages, user_countries,
              liked_user_countries]
    predictions = model.predict(inputs)

    # Получение топ-N рекомендаций
    top_n_indices = np.argsort(predictions, axis=0)[-n:][::-1].flatten()
    top_n_users = liked_user_ids[top_n_indices]

    return top_n_users


# Основная функция для подготовки данных и обучения модели
def fit_model():
    # Подготовка данных
    users_data, likes_data = fetch_data_from_db()
    inputs, labels = prepare_data_for_model(users_data, likes_data)

    # Создание и обучение модели
    num_users = users_data['id'].nunique()
    model = create_deepfm_model(num_users)
    model.fit(inputs, labels, epochs=10, batch_size=32)
