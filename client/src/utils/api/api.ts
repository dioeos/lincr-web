import axios from "axios";

const api = axios.create({
  baseURL: import.meta.env.VITE_DEV_API_BASE_URL
    ? import.meta.env.VITE_DEV_API_BASE_URL
    : "",
  withCredentials: true,
  headers: { "Content-Type": "application/json" },
});
export default api;
