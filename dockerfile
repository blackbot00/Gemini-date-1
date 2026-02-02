# 1. Base image (Python 3.10 slim version use pannuvom, size kumiya irukkum)
FROM python:3.10-slim

# 2. Server kulla working directory create pannuvom
WORKDIR /app

# 3. System dependencies (optional but good for networking)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# 4. Requirements-ah copy panni install pannuvom
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 5. Ella files-aiyum (bot.py, .env) copy pannuvom
COPY . .

# 6. Bot-ah run panna command
CMD ["python", "bot.py"]
