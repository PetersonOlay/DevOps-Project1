import { useCallback, useState } from "react";
import ExpenseForm from "./components/ExpenseForm.jsx";
import ExpenseList from "./components/ExpenseList.jsx";
import SummaryView from "./components/SummaryView.jsx";

export default function App() {
  const [refreshKey, setRefreshKey] = useState(0);
  const refresh = useCallback(() => setRefreshKey((k) => k + 1), []);

  return (
    <div style={{ maxWidth: 720, margin: "2rem auto", fontFamily: "sans-serif" }}>
      <h1>Expense Tracker</h1>
      <ExpenseForm onCreated={refresh} />
      <SummaryView refreshKey={refreshKey} />
      <ExpenseList refreshKey={refreshKey} onChanged={refresh} />
    </div>
  );
}
