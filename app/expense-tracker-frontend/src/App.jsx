import { useCallback, useState } from "react";
import ExpenseForm from "./components/ExpenseForm.jsx";
import ExpenseList from "./components/ExpenseList.jsx";
import SummaryView from "./components/SummaryView.jsx";

export default function App() {
  const [refreshKey, setRefreshKey] = useState(0);
  const [editingExpense, setEditingExpense] = useState(null);

  const refresh = useCallback(() => {
    setRefreshKey((k) => k + 1);
    setEditingExpense(null);
  }, []);

  return (
    <div className="page">
      <header className="page-header">
        <h1>💰 Expense Tracker</h1>
        <p>
          Track your spending, attach receipts, and see totals by category and month. Fill in the
          form below to add your first expense — click "Edit" on any row later to update it.
        </p>
      </header>

      <ExpenseForm
        onCreated={refresh}
        editingExpense={editingExpense}
        onCancelEdit={() => setEditingExpense(null)}
      />
      <SummaryView refreshKey={refreshKey} />
      <ExpenseList refreshKey={refreshKey} onChanged={refresh} onEdit={setEditingExpense} />
    </div>
  );
}
