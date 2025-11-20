# База: легкий Python
FROM python:3.11-slim

# Щоб Python не кешував байткод і одразу логував у stdout
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Робоча директорія всередині контейнера
WORKDIR /app

# Оновити пакети і поставити базові залежності для компіляції (якщо потрібно)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Спочатку тільки requirements.txt (для кешу Docker)
COPY requirements.txt /app/

RUN pip install --no-cache-dir -r requirements.txt

# Тепер копіюємо решту коду
COPY . /app/

# Якщо у тебе статичні файли — можна зібрати їх при збірці (опційно):
# RUN python manage.py collectstatic --noinput

# Порт, на якому буде слухати gunicorn
EXPOSE 8000

# Стандартна команда: gunicorn як WSGI-сервер
# Замінити `project.wsgi:application` на твій реальний модуль WSGI
CMD ["gunicorn", "project.wsgi:application", "--bind", "0.0.0.0:8000"]
