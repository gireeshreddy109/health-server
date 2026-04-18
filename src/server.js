const express = require('express')
const http = require('http')
const cors = require('cors')
const helmet = require('helmet')
const morgan = require('morgan')
const { Server } = require('socket.io')

require('dotenv').config({ quiet: true })

const app = express()
const httpServer = http.createServer(app)

const clientUrl = process.env.CLIENT_URL || 'http://localhost:3000'

const io = new Server(httpServer, {
  cors: {
    origin: clientUrl,
    credentials: true,
  },
})

io.on('connection', (socket) => {
  console.log(`Socket connected: ${socket.id}`)

  socket.on('disconnect', () => {
    console.log(`Socket disconnected: ${socket.id}`)
  })
})

app.use(helmet())
app.use(
  cors({
    origin: clientUrl,
    credentials: true,
  }),
)
app.use(morgan('dev'))
app.use(express.json())

app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() })
})

app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' })
})

app.use((err, req, res, next) => {
  console.error(err.stack)

  res.status(err.status || 500).json({
    error: err.message || 'Internal Server Error',
  })
})

const PORT = process.env.PORT || 5000

httpServer.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`)
})

module.exports = { app, httpServer, io }
