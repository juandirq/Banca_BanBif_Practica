import { useState } from "react";
import { money, maskAccount, formatDate } from "../utils/format";

export default function SavingsPage({
  accounts,
  movements,
  depositForm,
  setDepositForm,
  newAccountForm,
  setNewAccountForm,
  makeDeposit,
  createAccount,
  loading,
  onFeedback,
}) {
  const [accountFilter, setAccountFilter] = useState("todos");
  const [typeFilter, setTypeFilter] = useState("todos");

  const filteredMovements = movements.filter((movement) => {
    const matchAccount =
      accountFilter === "todos" || Number(movement.account_id) === Number(accountFilter);

    const operation = String(movement.operation_type || "").toLowerCase();
    const matchType =
      typeFilter === "todos" ||
      operation.includes(typeFilter.toLowerCase());

    return matchAccount && matchType;
  });

  function copyAccount(number) {
    navigator.clipboard?.writeText(number);
    onFeedback("Numero de cuenta copiado.", "success");
  }

  return (
    <section className="page-stack">
      <div className="page-title">
        <span className="section-label">Modulo de ahorros</span>
        <h2>Cuentas y estado de cuenta</h2>
        <p>Administra tus cuentas digitales, consulta saldos y revisa movimientos.</p>
      </div>

      <section className="panel">
        <div className="panel-head">
          <div>
            <h2>Mis cuentas</h2>
            <p>Cuentas enmascaradas para proteger la informacion del cliente.</p>
          </div>
        </div>

        <div className="account-list">
          {accounts.map((account) => (
            <div className="account-card" key={account.id}>
              <span>{account.account_type}</span>
              <strong>{maskAccount(account.account_number)}</strong>
              <p>{account.currency} - {account.status}</p>
              <h3>{money(account.balance)}</h3>
              <button className="card-action" onClick={() => copyAccount(account.account_number)}>
                Copiar numero real
              </button>
            </div>
          ))}
        </div>
      </section>

      <section className="two-columns">
        <article className="panel">
          <h2>Abrir Cuenta Ahorro Digital</h2>
          <p>Cuenta Ahorro Digital referencial sin monto minimo y sin costo de mantenimiento para la demo. Cuenta Sueldo y Cuenta Corriente requieren validacion del banco.</p>

          <form className="form" onSubmit={createAccount}>
            <label>Producto</label>
            <select
              value={newAccountForm.account_type}
              onChange={(e) => setNewAccountForm({ ...newAccountForm, account_type: e.target.value })}
            >
              <option>Cuenta Ahorro Digital</option>
              
              
            </select>

            <label>Moneda</label>
            <select
              value={newAccountForm.currency}
              onChange={(e) => setNewAccountForm({ ...newAccountForm, currency: e.target.value })}
            >
              <option value="PEN">Soles - PEN</option>
              <option value="USD">Dolares - USD</option>
            </select>

            <div className="account-benefits">
              <span>Sin monto minimo</span>
              <span>Sin mantenimiento</span>
              <span>Disponible 24/7</span>
            </div>

            <label className="check-line">
              <input
                type="checkbox"
                checked={newAccountForm.accept_terms}
                onChange={(e) => setNewAccountForm({ ...newAccountForm, accept_terms: e.target.checked })}
              />
              Confirmo que deseo abrir una nueva cuenta y acepto condiciones referenciales.
            </label>

            <button className="primary" disabled={loading || !newAccountForm.accept_terms}>
              Abrir cuenta
            </button>
          </form>
        </article>

        <article className="panel">
          <h2>Realizar deposito</h2>
          <form className="form" onSubmit={makeDeposit}>
            <label>Cuenta destino</label>
            <select
              value={depositForm.account_id}
              onChange={(e) => setDepositForm({ ...depositForm, account_id: e.target.value })}
              required
            >
              <option value="">Selecciona cuenta</option>
              {accounts.map((account) => (
                <option value={account.id} key={account.id}>
                  {maskAccount(account.account_number)} - {money(account.balance)}
                </option>
              ))}
            </select>

            <label>Monto</label>
            <input
              type="number"
              value={depositForm.amount}
              onChange={(e) => setDepositForm({ ...depositForm, amount: e.target.value })}
              placeholder="Ejemplo: 98.70"
              min="0.01"
              step="0.01"
              required
            />

            <label>Descripcion</label>
            <input
              value={depositForm.description}
              onChange={(e) => setDepositForm({ ...depositForm, description: e.target.value })}
              placeholder="Ejemplo: Deposito inicial"
            />

            <button className="primary" disabled={loading}>Depositar</button>
          </form>
        </article>
      </section>

      <section className="panel">
        <h2>Estado de cuenta</h2>
        <p>Filtra los movimientos por cuenta y tipo de operacion.</p>

        <div className="statement-filters">
          <select value={accountFilter} onChange={(e) => setAccountFilter(e.target.value)}>
            <option value="todos">Todas las cuentas</option>
            {accounts.map((account) => (
              <option key={account.id} value={account.id}>
                {maskAccount(account.account_number)}
              </option>
            ))}
          </select>

          <select value={typeFilter} onChange={(e) => setTypeFilter(e.target.value)}>
            <option value="todos">Todas las operaciones</option>
            <option value="deposito">Depositos</option>
            <option value="pago">Pagos</option>
            <option value="transferencia">Transferencias</option>
          </select>
        </div>

        <div className="table">
          {filteredMovements.length === 0 ? (
            <p className="empty">No hay movimientos para el filtro seleccionado.</p>
          ) : (
            filteredMovements.map((m) => (
              <div className="row" key={m.id}>
                <div>
                  <strong>{m.description}</strong>
                  <span>{m.operation_type} - {formatDate(m.created_at)}</span>
                </div>
                <b className={Number(m.amount) < 0 ? "negative" : "positive"}>
                  {money(m.amount)}
                </b>
              </div>
            ))
          )}
        </div>
      </section>
    </section>
  );
}