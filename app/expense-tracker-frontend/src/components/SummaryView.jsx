import { useEffect, useState } from "react";

const currencyFormatter = new Intl.NumberFormat(undefined, {
  style: "currency",
  currency: "USD",
});

export default function SummaryView({ refreshKey }) {
  const [summary, setSummary] = useState([]);
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    fetch("/expenses/summary")
      .then((res) => {
        if (!res.ok) throw new Error(`request failed with ${res.status}`);
        return res.json();
      })
      .then(setSummary)
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false));
  }, [refreshKey]);

  return (
    <section className="card">
      <h2>Summary</h2>

      {loading && <p className="empty-state">Loading summary…</p>}
      {!loading && error && <div className="message message-error">{error}</div>}
      {!loading && !error && summary.length === 0 && (
        <p className="empty-state">Your spending summary will appear here once you add an expense.</p>
      )}

      {!loading && !error && summary.length > 0 && (
        <table>
          <thead>
            <tr>
              <th>Month</th>
              <th>Category</th>
              <th className="text-right">Total</th>
            </tr>
          </thead>
          <tbody>
            {summary.map((row, i) => (
              <tr key={i}>
                <td>{row.month?.slice(0, 7)}</td>
                <td>{row.category}</td>
                <td className="text-right">{currencyFormatter.format(row.total)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </section>
  );
}
