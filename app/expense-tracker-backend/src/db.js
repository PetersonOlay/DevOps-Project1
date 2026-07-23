const { Pool } = require("pg");
const { getDbCredentials } = require("./secrets");

let pool;

async function getPool() {
  if (pool) {
    return pool;
  }

  const { username, password } = await getDbCredentials();

  pool = new Pool({
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT || 5432),
    database: process.env.DB_NAME,
    user: username,
    password,
    ssl: { rejectUnauthorized: false },
    max: 5,
  });

  return pool;
}

module.exports = { getPool };
