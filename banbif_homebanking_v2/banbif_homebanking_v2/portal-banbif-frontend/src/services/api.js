import axios from "axios";

const api = axios.create({
  baseURL: import.meta.env.VITE_PORTAL_API_URL || "http://127.0.0.1:8000",
  timeout: 10000,
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem("banbif_token");

  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }

  return config;
});

export default api;