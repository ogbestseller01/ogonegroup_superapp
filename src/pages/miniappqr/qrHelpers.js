export const VALIDITIES = ['week', 'month', 'half_year', 'year', 'never'];

export const STATUS_COLORS = {
    active: { bg: 'rgba(16,185,129,0.12)', fg: '#047857' },
    expiring: { bg: 'rgba(245,158,11,0.15)', fg: '#b45309' },
    expired: { bg: 'rgba(239,68,68,0.12)', fg: '#b91c1c' },
    revoked: { bg: 'rgba(100,116,139,0.15)', fg: '#475569' },
};

/** Row status for display: an active code that ends within 7 days shows as "expiring". */
export const displayStatus = (qr) => {
    if (qr.status === 'active' && qr.days_left !== null && qr.days_left <= 7) return 'expiring';
    return qr.status;
};

/** Same maths as Laravel's MiniAppQr::expiryFor(), only for the form preview. */
export const previewExpiry = (validity) => {
    const d = new Date();
    switch (validity) {
        case 'week': d.setDate(d.getDate() + 7); break;
        case 'month': d.setMonth(d.getMonth() + 1); break;
        case 'half_year': d.setMonth(d.getMonth() + 6); break;
        case 'year': d.setFullYear(d.getFullYear() + 1); break;
        default: return null;
    }
    return d;
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