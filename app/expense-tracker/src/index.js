const express = require("express");
const expensesRouter = require("./routes/expenses");

const app = express();
app.use(express.json());

app.get("/healthz", (req, res) => res.status(200).json({ status: "ok" }));

app.use(expensesRouter);

app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: "internal server error" });
});

if (require.main === module) {
  const port = process.env.PORT || 3000;
  app.listen(port, () => {
    console.log(`expense-tracker listening on ${port}`);
  });
}

module.exports = app;
