# Stage 1: build C++ engine as Linux shared object
FROM python:3.12-slim AS builder
WORKDIR /app

# Cài đặt dependencies cơ bản
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       build-essential \
    && rm -rf /var/lib/apt/lists/*

# Cấu hình môi trường
ENV PYTHONUNBUFFERED=1

# Copy engine sources, headers and opening book
COPY engine.cpp connect4_algorithm.cpp connect4_algorithm.hpp OpeningBook.hpp TranspositionTable.hpp MoveSorter.hpp Position.hpp 7x6.book ./

# Compile into .so for Linux
RUN g++ -O3 -std=c++17 -shared -fPIC \
       connect4_algorithm.cpp engine.cpp \
       -o libconnect.so

# # Install Python dependencies
# RUN pip install --no-cache-dir fastapi uvicorn pydantic typing

# Copy file requirements.txt và cài đặt dependencies
COPY requirements.txt .
RUN pip install --upgrade pip
RUN pip install -r requirements.txt


# Stage 2: application image

# Copy shared library and application code
COPY --from=builder /app/libconnect.so ./libconnect.so
COPY app.py 7x6.book engine_cache.json ./

# Sử dụng biến môi trường PORT (do Render cung cấp)
EXPOSE $PORT

# Khởi chạy ứng dụng với uvicorn
CMD uvicorn app:app --host 0.0.0.0 --port $PORT