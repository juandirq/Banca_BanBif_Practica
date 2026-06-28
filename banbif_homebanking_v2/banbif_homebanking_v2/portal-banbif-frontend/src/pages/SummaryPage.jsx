import {
  Wallet,
  CreditCard,
  Receipt,
  PiggyBank,
  Send,
  ArrowUpRight,
  PlusCircle,
  CheckCircle2,
} from "lucide-react";
import { money, maskAccount, formatDate } from "../utils/format";

export default function SummaryPage({ dashboard, metrics, alerts, onNavigate }) {
  const accounts = dashboard?.accounts || [];
  const movements = dashboard?.last_movements || [];
  const mainAccount = accounts[0];

  return (
    <section className="page-stack">
      <section className="summary-hero">
        <div>
          <span className="section-label">Resumen general</span>
          <h2>Tu posicion financiera actual</h2>
          <p>
            Vista rapida de saldos, operaciones, pagos, creditos y alertas. Las
            operaciones se administran por modulos separados.
          </p>

          {alerts.length > 0 && (
            <div className="alert-strip">
              {alerts.map((alert) => (
                <span key={alert}>{alert}</span>
              ))}
            </div>
          )}
        </div>

        <div className="bank-card">
          <span>Cuenta principal</span>
          <strong>{maskAccount(mainAccount?.account_number)}</strong>
          <p>{mainAccount?.account_type || "Sin cuenta"} - {mainAccount?.currency || "PEN"}</p>
          <h3>{money(mainAccount?.balance)}</h3>
        </div>
      </section>

      <section className="metric-grid">
        <article className="metric">
          <Wallet />
          <span>Saldo total</span>
          <strong>{money(dashboard?.total_balance)}</strong>
          <small>Disponible entre tus cuentas</small>
        </article>

        <article className="metric">
          <CreditCard />
          <span>Cuentas activas</span>
          <strong>{dashboard?.accounts_count || 0}</strong>
          <small>Cuentas vinculadas al cliente</small>
        </article>

        <article className="metric">
          <Receipt />
          <span>Pagos procesados</span>
          <strong>{metrics.paymentsCount}</strong>
          <small>Total pagado: {money(metrics.paymentTotal)}</small>
        </article>

        <article className="metric">
          <PiggyBank />
          <span>Creditos solicitados</span>
          <strong>{metrics.creditsCount}</strong>
          <small>En evaluacion: {metrics.pendingCredits}</small>
        </article>

        <article className="metric">
          <Send />
          <span>Transferencias</span>
          <strong>{metrics.transfers}</strong>
          <small>Segun ultimos movimientos</small>
        </article>

        <article className="metric">
          <ArrowUpRight />
          <span>Monto crediticio</span>
          <strong>{money(metrics.creditTotal)}</strong>
          <small>Solicitudes registradas</small>
        </article>
      </section>

      <section className="two-columns">
        <article className="panel">
          <div className="panel-head">
            <div>
              <h2>Actividad reciente</h2>
              <p>Ultimas operaciones registradas.</p>
            </div>
            <button className="mini-link" onClick={() => onNavigate("transferencias")}>
              Ver operaciones
            </button>
          </div>

          <div className="table">
            {movements.length === 0 ? (
              <p className="empty">No hay movimientos recientes.</p>
            ) : (
              movements.slice(0, 5).map((m) => (
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
        </article>

        <article className="panel">
          <div className="panel-head">
            <div>
              <h2>Accesos rapidos</h2>
              <p>Atajos a modulos bancarios.</p>
            </div>
          </div>

          <div className="quick-grid">
            <button onClick={() => onNavigate("ahorros")}>
              <PlusCircle />
              Depositar / abrir cuenta
            </button>
            <button onClick={() => onNavigate("pagos")}>
              <Receipt />
              Pagar servicio
            </button>
            <button onClick={() => onNavigate("transferencias")}>
              <Send />
              Transferir
            </button>
            <button onClick={() => onNavigate("creditos")}>
              <CreditCard />
              Solicitar credito
            </button>
          </div>

          <div className="notice">
            <CheckCircle2 />
            <span>
              Tus operaciones quedan registradas y puedes consultarlas desde los modulos del portal.
            </span>
          </div>
        </article>
      </section>
    </section>
  );
}