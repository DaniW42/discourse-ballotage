// Formats a server timestamp in the plugin's configured timezone, so every
// viewer sees the same wall-clock times regardless of their own device.
export function formatDateTime(value, timeZone) {
  if (!value) {
    return "";
  }
  const options = { dateStyle: "medium", timeStyle: "short" };
  try {
    return new Intl.DateTimeFormat(document.documentElement.lang || undefined, {
      ...options,
      timeZone: timeZone || undefined,
    }).format(new Date(value));
  } catch {
    // Unknown timezone setting — fall back to the viewer's local time.
    return new Intl.DateTimeFormat(undefined, options).format(new Date(value));
  }
}

// YYYY-MM-DD for <input type="date">, `days` from today in local time.
export function isoDateFromToday(days) {
  const d = new Date();
  d.setDate(d.getDate() + days);
  const pad = (n) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}
