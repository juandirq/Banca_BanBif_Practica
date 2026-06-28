import { formatDate } from "../utils/format";

export default function ProfilePage({ user }) {
  return (
    <section className="page-stack">
      <div className="page-title">
        <span className="section-label">Perfil del cliente</span>
        <h2>Datos personales</h2>
        <p>Informacion del usuario autenticado en el portal.</p>
      </div>

      <section className="profile-grid">
        <article className="panel profile-card">
          <div className="avatar">{user.full_name?.charAt(0) || "U"}</div>
          <h2>{user.full_name}</h2>
          <p>{user.email}</p>
          <span>Documento: {user.document}</span>
        </article>

        <article className="panel">
          <h2>Informacion de contacto</h2>
          <div className="info-list">
            <div>
              <span>Telefono</span>
              <strong>{user.phone || "No registrado"}</strong>
            </div>
            <div>
              <span>Direccion</span>
              <strong>{user.address || "No registrada"}</strong>
            </div>
            <div>
              <span>Cliente desde</span>
              <strong>{formatDate(user.created_at)}</strong>
            </div>
          </div>
        </article>
      </section>
    </section>
  );
}