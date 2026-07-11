import { useState } from "react";

export default function ExpenseForm({ onCreated }) {
  const [amount, setAmount] = useState("");
  const [category, setCategory] = useState("");
  const [description, setDescription] = useState("");
  const [expenseDate, setExpenseDate] = useState("");
  const [receipt, setReceipt] = useState(null);
  const [error, setError] = useState(null);
  const [submitting, setSubmitting] = useState(false);

  async function handleSubmit(e) {
    e.preventDefault();
    setError(null);
    setSubmitting(true);

    const body = new FormData();
    body.append("amount", amount);
    body.append("category", category);
    body.append("description", description);
    body.append("expense_date", expenseDate);
    if (receipt) {
      body.append("receipt", receipt);
    }

    try {
      const res = await fetch("/expenses", { method: "POST", body });
      if (!res.ok) {
        const data = await res.json().catch(() => ({}));
        throw new Error(data.error || `request failed with ${res.status}`);
      }
      setAmount("");
      setCategory("");
      setDescription("");
      setExpenseDate("");
      setReceipt(null);
      e.target.reset();
      onCreated();
    } catch (err) {
      setError(err.message);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} style={{ marginBottom: "2rem" }}>
      <h2>Add expense</h2>
      {error && <p style={{ color: "crimson" }}>{error}</p>}
      <div>
        <label>
          Amount
          <input
            type="number"
            step="0.01"
            required
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
          />
        </label>
      </div>
      <div>
        <label>
          Category
          <input
            type="text"
            required
            value={category}
            onChange={(e) => setCategory(e.target.value)}
          />
        </label>
      </div>
      <div>
        <label>
          Description
          <input
            type="text"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
          />
        </label>
      </div>
      <div>
        <label>
          Date
          <input
            type="date"
            required
            value={expenseDate}
            onChange={(e) => setExpenseDate(e.target.value)}
          />
        </label>
      </div>
      <div>
        <label>
          Receipt
          <input type="file" onChange={(e) => setReceipt(e.target.files[0])} />
        </label>
      </div>
      <button type="submit" disabled={submitting}>
        {submitting ? "Saving…" : "Add expense"}
      </button>
    </form>
  );
}
