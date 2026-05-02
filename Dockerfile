FROM node:20-alpine

WORKDIR /app

COPY package.json .
RUN npm install

# Install sqlite3 agar bisa dipakai di terminal
RUN apk add --no-cache sqlite

COPY . .
RUN mkdir -p /app/data

EXPOSE 3000
CMD ["node", "server.js"]
