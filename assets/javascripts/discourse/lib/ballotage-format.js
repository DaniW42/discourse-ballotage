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

// "in 6 days" / "in 5 hours" in the page language, picking the largest
// sensible unit. Used for the time left until a ballot opens or closes.
export function formatRelative(value) {
  if (!value) {
    return "";
  }
  const diffMs = new Date(value).getTime() - Date.now();
  const minutes = Math.round(diffMs / 60000);
  const hours = Math.round(diffMs / 3600000);
  const days = Math.round(diffMs / 86400000);
  const rtf = new Intl.RelativeTimeFormat(
    document.documentElement.lang || undefined,
    { numeric: "auto" }
  );
  if (Math.abs(days) >= 2) {
    return rtf.format(days, "day");
  }
  if (Math.abs(hours) >= 2) {
    return rtf.format(hours, "hour");
  }
  return rtf.format(minutes, "minute");
}

// Share of the ballot period already elapsed, 0–100.
export function elapsedPercent(startsAt, endsAt) {
  const start = new Date(startsAt).getTime();
  const end = new Date(endsAt).getTime();
  if (!(end > start)) {
    return 0;
  }
  const pct = ((Date.now() - start) / (end - start)) * 100;
  return Math.min(100, Math.max(0, Math.round(pct)));
}
