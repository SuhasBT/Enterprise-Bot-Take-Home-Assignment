import os
import socket
from flask import Flask, jsonify

app = Flask(__name__)

@app.route("/")
def home():
    app_name = os.getenv("APP_NAME", "unknown")
    version = os.getenv("VERSION", "unknown")
    pod = socket.gethostname()
    return jsonify({"app": app_name, "version": version, "pod": pod})

@app.route("/healthz")
def health():
    return "OK", 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
