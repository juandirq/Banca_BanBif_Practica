import { useState } from "react";
import {
  Landmark,
  LogOut,
  RefreshCcw,
  LayoutDashboard,
  PiggyBank,
  Receipt,
  Send,
  CreditCard,
  User,
  Bell,
  CheckCircle2,
} from "lucide-react";
import Toast from "./Toast";

const navItems = [
  { key: "resumen", label: "Resumen", icon: LayoutDashboard },
  { key: "ahorros", label: "Ahorros", icon: PiggyBank },
  { key: "pagos", label: "Pagos", icon: Receipt },
  { key: "transferencias", label: "Transferencias", icon: Send },
  { key: "creditos", label: "Creditos", icon: CreditCard },
  { key: "perfil", label: "Perfil", icon: User },
];

export default function Layout({
  user,
  activePage,
  onNavigate,
  onLogout,
  onRefresh,
  alerts,
  toast,
  children,
}) {
  const [openNotifications, setOpenNotifications] = useState(false);
  const [seen, setSeen] = useState(false);

  const count = seen ? 0 : alerts.length;

  function toggleNotifications() {
    setOpenNotifications((value) => !value);
    setSeen(true);
  }

  return (
    <main className="app-shell">
      <aside className="sidebar">
        <div className="side-brand">
          <Landmark />
          <div>
            <strong>BanBif</strong>
            <span>Banca Digital</span>
          </div>
        </div>

        <nav className="nav-menu">
          {navItems.map((item) => {
            const Icon = item.icon;
            return (
              <button
                key={item.key}
                className={activePage === item.key ? "active" : ""}
                onClick={() => onNavigate(item.key)}
              >
                <Icon size={18} />
                {item.label}
              </button>
            );
          })}
        </nav>

        <div className="side-note">
          <span>Zona segura</span>
          <strong>Sesion bancaria activa</strong>
        </div>

        <button className="logout" onClick={onLogout}>
          <LogOut size={18} />
          Cerrar sesion
        </button>
      </aside>

      <section className="content">
        <header className="topbar">
          <div>
            <p>Bienvenido de nuevo</p>
            <h1>{user?.full_name || "Cliente BanBif"}</h1>
          </div>

          <div className="top-actions">
            <div className="notification-wrap">
              <button className="notification" title="Notificaciones" onClick={toggleNotifications}>
                <Bell size={18} />
                {count > 0 && <span>{count}</span>}
              </button>

              {openNotifications && (
                <div className="notification-panel">
                  <h3>Notificaciones</h3>

                  {alerts.length === 0 ? (
                    <p>No tienes alertas pendientes.</p>
                  ) : (
                    alerts.map((alert) => (
                      <div className="notification-item" key={alert}>
                        <CheckCircle2 size={17} />
                        <span>{alert}</span>
                      </div>
                    ))
                  )}
                </div>
              )}
            </div>

            <button className="ghost" onClick={onRefresh}>
              <RefreshCcw size={18} />
              Actualizar
            </button>
          </div>
        </header>

        <Toast toast={toast} />

        {children}
      </section>
    </main>
  );
}