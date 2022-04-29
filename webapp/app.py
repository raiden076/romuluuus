import os

from flask import Flask

app = Flask(__name__)


@app.route("/")
def hello():
    return "Why are you looking at this page?"


if __name__ == "__main__":
    app.run(host="0.0.0.0")
