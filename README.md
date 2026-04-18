# Health Server

Phase 0 backend and infrastructure for the appointment booking system described in `PRD_01` and `PRD_02`.

## Stack

- Node.js + Express
- PostgreSQL
- Redis
- RabbitMQ
- Socket.io
- Docker Compose

## Scripts

- `npm run dev` - start the API with nodemon on `http://localhost:5000`
- `npm start` - start the API with Node.js

## Infrastructure

Run `docker compose up -d` from this folder to start PostgreSQL, Redis, and RabbitMQ.
