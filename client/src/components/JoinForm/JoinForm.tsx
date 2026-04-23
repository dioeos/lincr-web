import React from "react";

interface JoinFormProps {
  code: string;
  setCode: React.Dispatch<React.SetStateAction<string>>;
  handleSubmit: React.SubmitEventHandler<HTMLFormElement>;
}

export default function JoinForm({
  code,
  setCode,
  handleSubmit,
}: JoinFormProps) {
  return (
    <div>
      <form onSubmit={handleSubmit}>
        <label>
          Enter Room Code:
          <input
            type="text"
            value={code}
            onChange={(event: React.ChangeEvent<HTMLInputElement>) =>
              setCode(event.target.value)
            }
            maxLength={7}
            placeholder="Enter room code"
          />
          <button type="submit">Join</button>
        </label>
      </form>
    </div>
  );
}
