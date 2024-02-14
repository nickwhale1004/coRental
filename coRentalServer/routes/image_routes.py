import os
import uuid
from flask import request, jsonify, Blueprint, send_file

routes = Blueprint('image_routes', __name__)


@routes.route('/upload', methods=['POST'])
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


@routes.route('/download/<filename>', methods=['GET'])
def download(filename):
    file_path = os.path.join('uploads', filename)

    if not os.path.isfile(file_path):
        return jsonify({'error': 'File not found.'}), 404

    return send_file(file_path, as_attachment=True)
