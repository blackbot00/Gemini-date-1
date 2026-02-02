FROM python:3.10-slim

WORKDIR /app

# Requirements install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# All files copy
COPY . .

# Intha line unga files enga irukku nu logs-la kaatum (Debugging-kaga)
RUN ls -R

CMD ["python", "bot.py"]
