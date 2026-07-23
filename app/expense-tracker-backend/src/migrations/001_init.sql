CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  amount NUMERIC(10, 2) NOT NULL,
  category TEXT NOT NULL,
  description TEXT,
  expense_date DATE NOT NULL,
  receipt_s3_key TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses (category);
CREATE INDEX IF NOT EXISTS idx_expenses_expense_date ON expenses (expense_date);
