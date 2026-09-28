export function pushNumber(
  name: string,
  fallback: number,
  min: number,
  max: number,
): number {
  const value = Number(process.env[name]);
  return Number.isInteger(value) && value >= min && value <= max
    ? value
    : fallback;
}

export const messageTtlMs = () =>
  pushNumber('PUSH_MESSAGE_TTL_SECONDS', 3600, 60, 86400) * 1000;
export const maxAttempts = () => pushNumber('PUSH_MAX_ATTEMPTS', 5, 1, 10);
export const retentionDays = () =>
  pushNumber('PUSH_RETENTION_DAYS', 30, 1, 365);
