import { useEffect, useState } from "react";

const emptyForm = { amount: "", category: "", description: "", expenseDate: "" };

export default function ExpenseForm({ onCreated, editingExpense, onCancelEdit }) {
  const [form, setForm] = useState(emptyForm);
  const [receipt, setReceipt] = useState(null);
  const [error, setError] = useState(null);
  const [justSaved, setJustSaved] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [fileInputKey, setFileInputKey] = useState(0);

  const isEditing = Boolean(editingExpense);

  useEffect(() => {
    if (editingExpense) {
      setForm({
        amount: editingExpense.amount ?? "",
        category: editingExpense.category ?? "",
        description: editingExpense.description ?? "",
        expenseDate: editingExpense.expense_date ? editingExpense.expense_date.slice(0, 10) : "",
      });
    } else {
      setForm(emptyForm);
    }
    setReceipt(null);
    setError(null);
    setJustSaved(false);
    setFileInputKey((k) => k + 1);
  }, [editingExpense]);

  function updateField(field, value) {
    setForm((f) => ({ ...f, [field]: value }));
  }

  async function handleSubmit(e) {
    e.preventDefault();
    setError(null);
    setJustSaved(false);
    setSubmitting(true);

    const body = new FormData();
    body.append("amount", form.amount);
    body.append("category", form.category);
    body.append("description", form.description);
    body.append("expense_date", form.expenseDate);
    if (receipt) {
      body.append("receipt", receipt);
    }

    try {
      const url = isEditing ? `/expenses/${editingExpense.id}` : "/expenses";
      const res = await fetch(url, { method: isEditing ? "PUT" : "POST", body });
      if (!res.ok) {
        const data = await res.json().catch(() => ({}));
        throw new Error(data.error || `request failed with ${res.status}`);
      }
      if (!isEditing) {
        setForm(emptyForm);
      }
      setReceipt(null);
      setFileInputKey((k) => k + 1);
      setJustSaved(true);
      onCreated();
    } catch (err) {
      setError(err.message);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <section className="card">
      <h2>{isEditing ? "Edit expense" : "Add expense"}</h2>

      {error && <div className="message message-error">{error}</div>}
      {justSaved && !error && (
        <div className="message message-success">
          {isEditing ? "Expense updated." : "Expense added."}
        </div>
      )}

      <form onSubmit={handleSubmit}>
        <div className="field">
          <label htmlFor="amount">Amount</label>
          <input
            id="amount"
            type="number"
            step="0.01"
            placeholder="0.00"
            required
            value={form.amount}
            onChange={(e) => updateField("amount", e.target.value)}
          />
        </div>
        <div className="field">
          <label htmlFor="category">Category</label>
          <input
            id="category"
            type="text"
            placeholder="e.g. Groceries, Travel, Utilities"
            required
            value={form.category}
            onChange={(e) => updateField("category", e.target.value)}
          />
        </div>
        <div className="field">
          <label htmlFor="description">Description</label>
          <input
            id="description"
            type="text"
            placeholder="Optional note about this expense"
            value={form.description}
            onChange={(e) => updateField("description", e.target.value)}
          />
        </div>
        <div className="field">
          <label htmlFor="expenseDate">Date</label>
          <input
            id="expenseDate"
            type="date"
            required
            value={form.expenseDate}
            onChange={(e) => updateField("expenseDate", e.target.value)}
          />
        </div>
        <div className="field">
          <label htmlFor="receipt">Receipt</label>
          <input
            key={fileInputKey}
            id="receipt"
            type="file"
            onChange={(e) => setReceipt(e.target.files[0])}
          />
          <span className="field-hint">
            Optional — attach a photo or PDF of your receipt.
            {isEditing && " Leave empty to keep the current receipt."}
          </span>
        </div>

        <div className="form-actions">
          <button type="submit" className="btn-primary" disabled={submitting}>
            {submitting ? "Saving…" : isEditing ? "Save changes" : "Add expense"}
          </button>
          {isEditing && (
            <button type="button" className="btn-secondary" onClick={onCancelEdit}>
              Cancel
            </button>
          )}
        </div>
      </form>
    </section>
  );
}
