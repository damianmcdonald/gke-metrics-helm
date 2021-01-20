FROM python:3.8.5-slim

# copy the source code to /app on the image
COPY main.py /app/main.py
COPY requirements.txt /app/requirements.txt

# run the pip install command in order to install all of the required libraries and their dependencies
RUN cd /app && pip install -r requirements.txt

# execute the command to launch gunicorn which exposes the public API
CMD ["bash", "-c", "cd /app && python main.py"]