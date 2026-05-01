import axios from "axios";

const api = axios.create({
  baseURL: `${window.location.origin}/api/v1`,
  withCredentials: true,
  headers: { "Content-Type": "application/json" },
});
export default api;
