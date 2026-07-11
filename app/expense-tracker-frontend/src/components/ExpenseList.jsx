import { useEffect, useState } from "react";

export default function ExpenseList({ refreshKey, onChanged }) {
  const [expenses, setExpenses] = useState([]);
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    fetch("/expenses")
      .then((res) => {
        if (!res.ok) throw new Error(`request failed with ${res.status}`);
        return res.json();
      })
      .then(setExpenses)
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false));
  }, [refreshKey]);

  async function handleDelete(id) {
    const res = await fetch(`/expenses/${id}`, { method: "DELETE" });
    if (res.ok || res.status === 404) {
      onChanged();
    }
  }

  if (loading) return <p>Loading expenses…</p>;
  if (error) return <p style={{ color: "crimson" }}>{error}</p>;
  if (expenses.length === 0) return <p>No expenses yet.</p>;

  return (
    <div>
      <h2>Expenses</h2>
      <table style={{ width: "100%", borderCollapse: "collapse" }}>
        <thead>
          <tr>
            <th align="left">Date</th>
            <th align="left">Category</th>
            <th align="left">Description</th>
            <th align="right">Amount</th>
            <th align="left">Receipt</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          {expenses.map((expense) => (
            <tr key={expense.id}>
              <td>{expense.expense_date}</td>
              <td>{expense.category}</td>
              <td>{expense.description}</td>
              <td align="right">{Number(expense.amount).toFixed(2)}</td>
              <td>{expense.receipt_s3_key ? "yes" : "—"}</td>
              <td>
                <button onClick={() => handleDelete(expense.id)}>Delete</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
