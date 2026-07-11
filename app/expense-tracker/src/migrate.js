const fs = require("fs");
const path = require("path");
const { getPool } = require("./db");

async function migrate() {
  const pool = await getPool();
  const sql = fs.readFileSync(path.join(__dirname, "migrations", "001_init.sql"), "utf8");

  await pool.query(sql);
  console.log("Migration complete");
  await pool.end();
}

migrate().catch((err) => {
  console.error("Migration failed:", err);
  process.exit(1);
});
