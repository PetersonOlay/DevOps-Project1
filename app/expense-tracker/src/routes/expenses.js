const express = require("express");
const multer = require("multer");
const crypto = require("crypto");
const { getPool } = require("../db");
const { receiptKey, uploadReceipt, deleteReceipt, presignedReceiptUrl } = require("../s3");

const router = express.Router();
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 10 * 1024 * 1024 } });

router.post("/expenses", upload.single("receipt"), async (req, res, next) => {
  try {
    const { amount, category, description, expense_date: expenseDate } = req.body;
    if (!amount || !category || !expenseDate) {
      return res.status(400).json({ error: "amount, category, and expense_date are required" });
    }

    const pool = await getPool();
    const id = crypto.randomUUID();

    let receiptS3Key = null;
    if (req.file) {
      receiptS3Key = receiptKey(id, req.file.originalname);
      await uploadReceipt(receiptS3Key, req.file.buffer, req.file.mimetype);
    }

    const result = await pool.query(
      `INSERT INTO expenses (id, amount, category, description, expense_date, receipt_s3_key)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id, amount, category, description, expense_date, receipt_s3_key, created_at`,
      [id, amount, category, description || null, expenseDate, receiptS3Key]
    );

    res.status(201).json(result.rows[0]);
  } catch (err) {
    next(err);
  }
});

router.get("/expenses", async (req, res, next) => {
  try {
    const { category, month } = req.query;
    const pool = await getPool();

    const conditions = [];
    const params = [];

    if (category) {
      params.push(category);
      conditions.push(`category = $${params.length}`);
    }
    if (month) {
      params.push(`${month}-01`);
      conditions.push(`date_trunc('month', expense_date) = $${params.length}::date`);
    }

    const where = conditions.length ? `WHERE ${conditions.join(" AND ")}` : "";
    const result = await pool.query(
      `SELECT id, amount, category, description, expense_date, receipt_s3_key, created_at
       FROM expenses ${where} ORDER BY expense_date DESC`,
      params
    );

    res.json(result.rows);
  } catch (err) {
    next(err);
  }
});

router.get("/expenses/summary", async (req, res, next) => {
  try {
    const pool = await getPool();
    const result = await pool.query(
      `SELECT category, date_trunc('month', expense_date) AS month, SUM(amount) AS total
       FROM expenses GROUP BY category, month ORDER BY month DESC, category`
    );
    res.json(result.rows);
  } catch (err) {
    next(err);
  }
});

router.get("/expenses/:id", async (req, res, next) => {
  try {
    const pool = await getPool();
    const result = await pool.query("SELECT * FROM expenses WHERE id = $1", [req.params.id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "not found" });
    }

    const expense = result.rows[0];
    if (expense.receipt_s3_key) {
      expense.receipt_url = await presignedReceiptUrl(expense.receipt_s3_key);
    }

    res.json(expense);
  } catch (err) {
    next(err);
  }
});

router.delete("/expenses/:id", async (req, res, next) => {
  try {
    const pool = await getPool();
    const result = await pool.query("DELETE FROM expenses WHERE id = $1 RETURNING receipt_s3_key", [
      req.params.id,
    ]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "not found" });
    }

    const { receipt_s3_key: receiptS3Key } = result.rows[0];
    if (receiptS3Key) {
      await deleteReceipt(receiptS3Key);
    }

    res.status(204).send();
  } catch (err) {
    next(err);
  }
});

module.exports = router;
