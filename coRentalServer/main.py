from flask import Flask

import routes.auth_routes
import routes.chat_routes
import routes.image_routes
import routes.like_routes
import routes.user_routes

from config import Config
from models import create_tables

app = Flask(__name__)
app.config['SECRET_KEY'] = Config.SECRET_KEY
app.config['DATABASE'] = Config.DATABASE


def register_blueprints():
    app.register_blueprint(routes.auth_routes.routes)
    app.register_blueprint(routes.like_routes.routes)
    app.register_blueprint(routes.user_routes.routes)
    app.register_blueprint(routes.chat_routes.routes)
    app.register_blueprint(routes.image_routes.routes)


if __name__ == '__main__':
    create_tables()
    register_blueprints()
    app.run()
