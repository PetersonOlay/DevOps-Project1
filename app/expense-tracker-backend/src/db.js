const { Pool } = require("pg");

let pool;

async function getPool() {
  if (pool) {
    return pool;
  }

  pool = new Pool({
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT || 5432),
    database: process.env.DB_NAME,
    user: process.env.DB_USERNAME,
    password: process.env.DB_PASSWORD,
    ssl: { rejectUnauthorized: false },
    max: 5,
  });

  return pool;
}

module.exports = { getPool };
