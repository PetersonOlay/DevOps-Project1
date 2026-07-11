import { useEffect, useState } from "react";

export default function SummaryView({ refreshKey }) {
  const [summary, setSummary] = useState([]);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetch("/expenses/summary")
      .then((res) => {
        if (!res.ok) throw new Error(`request failed with ${res.status}`);
        return res.json();
      })
      .then(setSummary)
      .catch((err) => setError(err.message));
  }, [refreshKey]);

  if (error) return null;
  if (summary.length === 0) return null;

  return (
    <div style={{ marginBottom: "2rem" }}>
      <h2>Summary</h2>
      <table style={{ width: "100%", borderCollapse: "collapse" }}>
        <thead>
          <tr>
            <th align="left">Month</th>
            <th align="left">Category</th>
            <th align="right">Total</th>
          </tr>
        </thead>
        <tbody>
          {summary.map((row, i) => (
            <tr key={i}>
              <td>{row.month?.slice(0, 7)}</td>
              <td>{row.category}</td>
              <td align="right">{Number(row.total).toFixed(2)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
