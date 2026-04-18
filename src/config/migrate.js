const fs = require('fs')
const path = require('path')
const pool = require('./database')

require('dotenv').config({ quiet: true })

async function runMigrations() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      filename VARCHAR(255) PRIMARY KEY,
      run_at TIMESTAMPTZ DEFAULT NOW()
    )
  `)

  const migrationsDir = path.join(__dirname, '../../migrations')
  const files = fs.readdirSync(migrationsDir).sort()

  for (const file of files) {
    if (!file.endsWith('.sql')) {
      continue
    }

    const { rows } = await pool.query(
      'SELECT filename FROM schema_migrations WHERE filename = $1',
      [file],
    )

    if (rows.length > 0) {
      console.log(`Skipping ${file} - already ran`)
      continue
    }

    const sql = fs.readFileSync(path.join(migrationsDir, file), 'utf8')

    try {
      await pool.query('BEGIN')
      await pool.query(sql)
      await pool.query('INSERT INTO schema_migrations (filename) VALUES ($1)', [file])
      await pool.query('COMMIT')
      console.log(`Ran migration: ${file}`)
    } catch (error) {
      await pool.query('ROLLBACK')
      throw error
    }
  }

  console.log('All migrations complete')
  await pool.end()
}

runMigrations().catch((error) => {
  console.error('Migration run failed:', error.message)
  process.exit(1)
})
