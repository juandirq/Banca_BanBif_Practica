import { Send } from "lucide-react";
import { money, maskAccount, getAccountById, formatDate } from "../utils/format";
import { getBalanceAfterOperation, isInsufficientBalance } from "../utils/banking";

export default function TransfersPage({
  accounts,
  movements,
  transferForm,
  setTransferForm,
  makeTransfer,
  loading,
  onFeedback,
}) {
  const selectedAccount = getAccountById(accounts, transferForm.from_account_id);
  const balanceAfter = getBalanceAfterOperation(selectedAccount?.balance, transferForm.amount);
  const insufficient = selectedAccount && isInsufficientBalance(selectedAccount.balance, transferForm.amount);

  const transferMovements = movements.filter((m) => {
    const operation = String(m.operation_type || "").toLowerCase();
    const description = String(m.description || "").toLowerCase();

    return (
      operation.includes("transferencia") ||
      operation.includes("plin") ||
      description.includes("plin")
    );
  });

  function copyAccount(number) {
    navigator.clipboard?.writeText(number);
    onFeedback("Numero de cuenta copiado.", "success");
  }

  function changeTransferType(type) {
    setTransferForm({
      transfer_type: type,
      from_account_id: "",
      to_account_number: "",
      to_contact_phone: "",
      amount: "",
      description: "",
      confirm_transfer: false,
      token_digital: "",
    });
  }

  function changeOriginAccount(accountId) {
    setTransferForm({
      ...transferForm,
      from_account_id: accountId,
      to_account_number: "",
      to_contact_phone: "",
      amount: "",
      description: "",
      confirm_transfer: false,
      token_digital: "",
    });
  }

  return (
    <section className="page-stack">
      <div className="page-title">
        <span className="section-label">Modulo de transferencias</span>
        <h2>Transferencias y PLIN</h2>
        <p>Transfiere a una cuenta BanBif o usa PLIN interoperable con un numero afiliado.</p>
      </div>

      <section className="two-columns">
        <article className="panel">
          <h2>Nueva transferencia</h2>

          <form className="form" onSubmit={makeTransfer}>
            <label>Tipo de transferencia</label>
            <select
              value={transferForm.transfer_type}
              onChange={(e) => changeTransferType(e.target.value)}
              required
            >
              <option value="">Selecciona tipo de transferencia</option>
              <option value="cuenta">A cuenta BanBif</option>
              <option value="plin">PLIN interoperable</option>
            </select>

            <label>Cuenta origen</label>
            <select
              value={transferForm.from_account_id}
              onChange={(e) => changeOriginAccount(e.target.value)}
              required
            >
              <option value="">Selecciona cuenta origen</option>
              {accounts.map((account) => (
                <option value={account.id} key={account.id}>
                  {maskAccount(account.account_number)} - {money(account.balance)}
                </option>
              ))}
            </select>

            {transferForm.transfer_type === "plin" ? (
              <>
                <label>Numero afiliado a PLIN interoperable</label>
                <input
                  value={transferForm.to_contact_phone}
                  onChange={(e) => setTransferForm({ ...transferForm, to_contact_phone: e.target.value })}
                  placeholder="Ejemplo: 987654321"
                  required
                />
              </>
            ) : (
              <>
                <label>Cuenta destino</label>
                <input
                  value={transferForm.to_account_number}
                  onChange={(e) => setTransferForm({ ...transferForm, to_account_number: e.target.value })}
                  placeholder="Numero completo de cuenta destino"
                  required
                />
                <p className="help-note">
                  La cuenta se muestra abreviada por seguridad visual. Para transferir por cuenta, ingresa el numero completo de cuenta destino. Si no tienes el numero de cuenta, usa PLIN interoperable. Monto permitido PLIN: de S/ 1.00 a S/ 500.00 por operacion y hasta S/ 2,000.00 diarios.
                </p>
              </>
            )}

            <label>Monto</label>
            <input
              type="number"
              value={transferForm.amount}
              onChange={(e) => setTransferForm({ ...transferForm, amount: e.target.value })}
              placeholder="Ejemplo: 98.70"
              min="0.01"
              step="0.01"
              required
            />

            <label>Descripcion</label>
            <input
              value={transferForm.description}
              onChange={(e) => setTransferForm({ ...transferForm, description: e.target.value })}
              placeholder="Ejemplo: Pago familiar"
            />

            <label>Token Digital</label>
            <input
              value={transferForm.token_digital}
              onChange={(e) => setTransferForm({ ...transferForm, token_digital: e.target.value })}
              placeholder="Codigo de 6 digitos"
              maxLength="6"
              required
            />

            <label className="check-line">
              <input
                type="checkbox"
                checked={transferForm.confirm_transfer}
                onChange={(e) => setTransferForm({ ...transferForm, confirm_transfer: e.target.checked })}
              />
              Confirmo cuenta destino, monto y cuenta origen.
            </label>

            <button className="primary" disabled={loading || insufficient}>
              <Send size={17} />
              Transferir
            </button>
          </form>
        </article>

        <article className="panel">
          <h2>Vista previa</h2>

          {!selectedAccount ? (
            <p className="empty">Selecciona una cuenta origen para calcular la transferencia.</p>
          ) : (
            <div className="preview-box">
              <div>
                <span>Cuenta origen</span>
                <strong>{maskAccount(selectedAccount.account_number)}</strong>
              </div>
              <div>
                <span>Saldo actual</span>
                <strong>{money(selectedAccount.balance)}</strong>
              </div>
              <div>
                <span>Monto a transferir</span>
                <strong className="negative">{money(transferForm.amount)}</strong>
              </div>
              <div>
                <span>Saldo posterior</span>
                <strong className={balanceAfter < 0 ? "negative" : "positive"}>
                  {money(balanceAfter)}
                </strong>
              </div>

              {insufficient && (
                <p className="danger-note">Saldo insuficiente para realizar la transferencia.</p>
              )}
            </div>
          )}
        </article>
      </section>

      <section className="panel">
        <h2>Cuentas disponibles</h2>
        <div className="account-list">
          {accounts.map((account) => (
            <div className="simple-account" key={account.id}>
              <strong>{maskAccount(account.account_number)}</strong>
              <span>{account.account_type} - {account.status}</span>
              <b>{money(account.balance)}</b>
              <button className="mini-link" onClick={() => copyAccount(account.account_number)}>
                Copiar numero
              </button>
            </div>
          ))}
        </div>
      </section>

      <section className="panel">
        <h2>Ultimas transferencias</h2>
        <div className="table">
          {transferMovements.length === 0 ? (
            <p className="empty">No hay transferencias recientes.</p>
          ) : (
            transferMovements.map((m) => (
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

