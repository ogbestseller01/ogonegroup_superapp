export const BANNER_TYPES = ['hero', 'promo', 'sidebar', 'popup', 'splash'];

export const STATUS_COLORS = {
    active: { bg: 'rgba(16,185,129,0.12)', fg: '#047857' },
    draft:  { bg: 'rgba(100,116,139,0.15)', fg: '#475569' },
    expired:{ bg: 'rgba(239,68,68,0.12)', fg: '#b91c1c' },
};

export const displayStatus = (banner) => {
    if (banner.status === 'active' && banner.is_expired) return 'expired';
    return banner.status;
};

export const fmtDate = (value) => {
    if (!value) return '-';
    const d = new Date(value);
    return Number.isNaN(d.getTime())
        ? '-'
        : d.toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' });
};

export const fmtDateTime = (value) => {
    if (!value) return '-';
    const d = new Date(value);
    return Number.isNaN(d.getTime()) ? '-' : d.toLocaleString();
};