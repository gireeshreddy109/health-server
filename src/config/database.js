const { Pool } = require('pg')

require('dotenv').config({ quiet: true })

const pool = new Pool({
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT, 10),
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
})

pool
  .query('SELECT NOW()')
  .then(() => {
    console.log('PostgreSQL connected')
  })
  .catch((error) => {
    console.error('PostgreSQL connection failed:', error.message)
    process.exit(1)
  })

module.exports = pool
