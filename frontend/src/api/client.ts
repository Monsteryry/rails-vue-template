export class ApiError extends Error {
  constructor(
    public status: number,
    message: string,
  ) {
    super(message)
  }
}

export async function apiFetch<T>(path: string, init: RequestInit = {}): Promise<T> {
  const response = await fetch(`/api${path}`, {
    ...init,
    headers: { Accept: 'application/json', 'Content-Type': 'application/json', ...init.headers },
  })
  if (!response.ok) throw new ApiError(response.status, `${response.status} ${response.statusText}`)
  return response.json() as Promise<T>
}

export interface Health {
  status: string
  rails: string
  database: string
}

export const getHealth = () => apiFetch<Health>('/health')
