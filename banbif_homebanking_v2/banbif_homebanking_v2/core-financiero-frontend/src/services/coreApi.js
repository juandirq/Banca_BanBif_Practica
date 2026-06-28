import axios from "axios";

const API_URL = import.meta.env.VITE_CORE_API_URL || "http://127.0.0.1:8001/api/core";

function getCoreToken() {
  return sessionStorage.getItem("coreToken");
}

function authConfig() {
  const token = getCoreToken();

  if (!token) {
    return {};
  }

  return {
    headers: {
      Authorization: `Bearer ${token}`
    }
  };
}

export async function loginAnalyst(username, password) {
  const response = await axios.post(`${API_URL}/auth/login`, {
    username,
    password
  });

  return response.data;
}

export async function getSolicitudes() {
  const response = await axios.get(`${API_URL}/solicitudes`, authConfig());
  return response.data;
}

export async function tomarDecision(solicitudId, decision, observacion, analyst) {
  const response = await axios.post(
    `${API_URL}/solicitudes/${solicitudId}/decision`,
    {
      decision,
      observacion,
      analista: analyst.full_name || "Analista BanBif"
    },
    authConfig()
  );

  return response.data;
}

export async function desembolsarSolicitud(solicitudId) {
  const response = await axios.post(
    `${API_URL}/solicitudes/${solicitudId}/desembolsar`,
    {},
    authConfig()
  );

  return response.data;
}

export async function getResumenRecuperaciones() {
  const response = await axios.get(`${API_URL}/recuperaciones/resumen`, authConfig());
  return response.data;
}

export async function getCarteraRecuperaciones(banda = "TODAS") {
  const config = {
    ...authConfig(),
    params: banda && banda !== "TODAS" ? { banda } : {}
  };

  const response = await axios.get(`${API_URL}/recuperaciones/cartera`, config);
  return response.data;
}

export async function getGestionesRecuperacion(recoveryCaseId) {
  const response = await axios.get(
    `${API_URL}/recuperaciones/${recoveryCaseId}/gestiones`,
    authConfig()
  );

  return response.data;
}

export async function registrarGestionRecuperacion(recoveryCaseId, payload) {
  const response = await axios.post(
    `${API_URL}/recuperaciones/${recoveryCaseId}/gestion`,
    payload,
    authConfig()
  );

  return response.data;
}

export async function derivarCasoJudicial(recoveryCaseId, comment) {
  const response = await axios.post(
    `${API_URL}/recuperaciones/${recoveryCaseId}/judicial`,
    { comment },
    authConfig()
  );

  return response.data;
}

export async function castigarCasoRecuperacion(recoveryCaseId, comment) {
  const response = await axios.post(
    `${API_URL}/recuperaciones/${recoveryCaseId}/castigar`,
    { comment },
    authConfig()
  );

  return response.data;
}

