import { useEffect, useState } from "react";
import { useNavigate } from "react-router";
import type { Room } from "../../types/room";

import api from "../../utils/api/api";
import JoinForm from "../../components/JoinForm/JoinForm";
import Layout from "../../components/Layout/Layout";

export default function JoinInit() {
  const navigate = useNavigate();
  const [code, setCode] = useState<string>("");
  const [error, setError] = useState<string>("");

  const handleSubmit = async (
    e: React.ChangeEvent<HTMLFormElement>,
  ): Promise<void> => {
    e.preventDefault();
    const normalizedCode: string = code.trim().toUpperCase();

    if (normalizedCode.length !== 7) {
      setError("Please enter a valid room code");
      return;
    }

    try {
      const response = await api.get<Room>(`rooms/${normalizedCode}`);
      const room: Room = response.data;
      console.log(room);
      setError("");
      navigate(`/room/${code}`, {
        state: {
          janus_room_id: response.data.janus_room_id,
          role: "guest",
        },
        replace: true,
      });
    } catch (err) {
      setError("Please enter a valid room code");
    }
  };

  return (
    <Layout>
      <div>
        {error && <p>{error}</p>}
        <JoinForm code={code} setCode={setCode} handleSubmit={handleSubmit} />
      </div>
    </Layout>
  );
}
