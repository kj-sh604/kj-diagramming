// analytics stripped in this fork: trackEvent is intentionally a no-op so
// nothing ever leaves the client
export const trackEvent = (
  category: string,
  action: string,
  label?: string,
  value?: number,
) => {};
