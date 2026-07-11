import { useEffect, useState } from "react";

const currencyFormatter = new Intl.NumberFormat(undefined, {
  style: "currency",
  currency: "USD",
});

export default function ExpenseList({ refreshKey, onChanged, onEdit }) {
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
    if (!window.confirm("Delete this expense? This can't be undone.")) {
      return;
    }
    const res = await fetch(`/expenses/${id}`, { method: "DELETE" });
    if (res.ok || res.status === 404) {
      onChanged();
    }
  }

  return (
    <section className="card">
      <h2>Expenses</h2>

      {loading && <p className="empty-state">Loading expenses…</p>}
      {!loading && error && <div className="message message-error">{error}</div>}
      {!loading && !error && expenses.length === 0 && (
        <p className="empty-state">No expenses yet — add your first one above.</p>
      )}

      {!loading && !error && expenses.length > 0 && (
        <table>
          <thead>
            <tr>
              <th>Date</th>
              <th>Category</th>
              <th>Description</th>
              <th className="text-right">Amount</th>
              <th>Receipt</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {expenses.map((expense) => (
              <tr key={expense.id}>
                <td>{expense.expense_date}</td>
                <td>{expense.category}</td>
                <td>{expense.description}</td>
                <td className="text-right">{currencyFormatter.format(expense.amount)}</td>
                <td>{expense.receipt_s3_key ? "📎" : "—"}</td>
                <td>
                  <div className="row-actions">
                    <button className="btn-link" onClick={() => onEdit(expense)}>
                      Edit
                    </button>
                    <button className="btn-danger" onClick={() => handleDelete(expense.id)}>
                      Delete
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </section>
  );
}
