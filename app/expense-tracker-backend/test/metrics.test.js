const { test } = require("node:test");
const assert = require("node:assert/strict");
const http = require("node:http");
const app = require("../src/index");

test("GET /metrics returns Prometheus-format output", async () => {
  const server = app.listen(0);
  const { port } = server.address();

  try {
    const body = await new Promise((resolve, reject) => {
      http
        .get(`http://127.0.0.1:${port}/metrics`, (res) => {
          assert.equal(res.statusCode, 200);
          let data = "";
          res.on("data", (chunk) => (data += chunk));
          res.on("end", () => resolve(data));
        })
        .on("error", reject);
    });

    assert.match(body, /^# HELP/m);
    assert.match(body, /http_requests_total/);
    assert.match(body, /process_cpu_user_seconds_total/);
  } finally {
    server.close();
  }
});
