const { test } = require("node:test");
const assert = require("node:assert/strict");
const http = require("node:http");
const app = require("../src/index");

test("GET /healthz returns 200 and status ok", async () => {
  const server = app.listen(0);
  const { port } = server.address();

  try {
    const body = await new Promise((resolve, reject) => {
      http
        .get(`http://127.0.0.1:${port}/healthz`, (res) => {
          assert.equal(res.statusCode, 200);
          let data = "";
          res.on("data", (chunk) => (data += chunk));
          res.on("end", () => resolve(data));
        })
        .on("error", reject);
    });

    assert.deepEqual(JSON.parse(body), { status: "ok" });
  } finally {
    server.close();
  }
});
