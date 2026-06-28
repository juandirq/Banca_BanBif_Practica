import { money, maskAccount, formatDate, getAccountById } from "../utils/format";
import { getBalanceAfterOperation, isInsufficientBalance } from "../utils/banking";

export default function PaymentsPage({
  accounts,
  payments,
  paymentForm,
  setPaymentForm,
  makePayment,
  loading,
}) {
  const selectedAccount = getAccountById(accounts, paymentForm.account_id);
  const balanceAfter = getBalanceAfterOperation(selectedAccount?.balance, paymentForm.amount);
  const insufficient = selectedAccount && isInsufficientBalance(selectedAccount.balance, paymentForm.amount);

  function changeAccount(accountId) {
    setPaymentForm({
      account_id: accountId,
      service: "",
      contract_number: "",
      amount: "",
      confirm_payment: false,
      token_digital: "",
    });
  }

  function changeService(service) {
    setPaymentForm({
      ...paymentForm,
      service,
      contract_number: "",
      amount: "",
      confirm_payment: false,
      token_digital: "",
    });
  }

  return (
    <section className="page-stack">
      <div className="page-title">
        <span className="section-label">Modulo de pagos</span>
        <h2>Pagos y obligaciones</h2>
        <p>Paga servicios, tarjetas o prestamos con validacion de saldo y Token Digital.</p>
      </div>

      <section className="two-columns">
        <article className="panel">
          <h2>Nuevo pago</h2>

          <form className="form" onSubmit={makePayment}>
            <label>Cuenta de cargo</label>
            <select
              value={paymentForm.account_id}
              onChange={(e) => changeAccount(e.target.value)}
              required
            >
              <option value="">Selecciona cuenta</option>
              {accounts.map((account) => (
                <option value={account.id} key={account.id}>
                  {maskAccount(account.account_number)} - {money(account.balance)}
                </option>
              ))}
            </select>

            <label>Tipo de pago</label>
            <select
              value={paymentForm.service}
              onChange={(e) => changeService(e.target.value)}
              required
            >
              <option value="">Selecciona tipo de pago</option>
              <option value="Luz">Luz</option>
              <option value="Agua">Agua</option>
              <option value="Internet">Internet</option>
              <option value="Telefonia">Telefonia</option>
              <option value="Tarjeta de credito BanBif">Tarjeta de credito BanBif</option>
              <option value="Prestamo">Prestamo</option>
            </select>

            <label>Codigo / contrato</label>
            <input
              value={paymentForm.contract_number}
              onChange={(e) => setPaymentForm({ ...paymentForm, contract_number: e.target.value })}
              placeholder="Ejemplo: TC-****-1234 / LUZ-2026-001"
              required
            />

            <label>Monto a pagar</label>
            <input
              type="number"
              value={paymentForm.amount}
              onChange={(e) => setPaymentForm({ ...paymentForm, amount: e.target.value })}
              placeholder="Ejemplo: 98.70"
              min="0.01"
              step="0.01"
              required
            />

            <p className="help-note">
              Para tarjeta de credito BanBif, el pago minimo referencial no debe ser menor a S/ 30.00. 
              Los pagos de servicios pueden registrarse desde S/ 1.00 en la demo.
            </p>            <label>Token Digital</label>
            <input
              value={paymentForm.token_digital}
              onChange={(e) => setPaymentForm({ ...paymentForm, token_digital: e.target.value })}
              placeholder="Codigo de 6 digitos"
              maxLength="6"
              required
            />

            <label className="check-line">
              <input
                type="checkbox"
                checked={paymentForm.confirm_payment}
                onChange={(e) => setPaymentForm({ ...paymentForm, confirm_payment: e.target.checked })}
              />
              Confirmo que los datos del pago son correctos.
            </label>

            <button className="primary" disabled={loading || insufficient}>
              Pagar
            </button>
          </form>
        </article>

        <article className="panel">
          <h2>Vista previa</h2>

          {!selectedAccount ? (
            <p className="empty">Selecciona una cuenta para calcular la operacion.</p>
          ) : (
            <div className="preview-box">
              <div>
                <span>Cuenta</span>
                <strong>{maskAccount(selectedAccount.account_number)}</strong>
              </div>
              <div>
                <span>Saldo actual</span>
                <strong>{money(selectedAccount.balance)}</strong>
              </div>
              <div>
                <span>Monto del pago</span>
                <strong className="negative">{money(paymentForm.amount)}</strong>
              </div>
              <div>
                <span>Saldo posterior</span>
                <strong className={balanceAfter < 0 ? "negative" : "positive"}>
                  {money(balanceAfter)}
                </strong>
              </div>

              {insufficient && (
                <p className="danger-note">Saldo insuficiente para procesar este pago.</p>
              )}
            </div>
          )}
        </article>
      </section>

      <section className="panel">
        <h2>Pagos recientes</h2>
        <div className="table">
          {payments.length === 0 ? (
            <p className="empty">No tienes pagos registrados.</p>
          ) : (
            payments.map((p) => (
              <div className="row" key={p.id}>
                <div>
                  <strong>{p.servicio}</strong>
                  <span>Codigo {p.numero_contrato} - {p.estado} - {formatDate(p.created_at)}</span>
                </div>
                <b className="negative">{money(p.monto)}</b>
              </div>
            ))
          )}
        </div>
      </section>
    </section>
  );
}