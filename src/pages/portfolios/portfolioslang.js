// src/pages/portfolios/portfolioslang.js

export const portfoliosTranslations = {
    en: {
        // ── Common ────────────────────────────────────────────────
        'portfolio.common.refresh': 'Refresh',
        'portfolio.common.cancel': 'Cancel',
        'portfolio.common.confirm': 'Confirm',
        'portfolio.common.close': 'Close',
        'portfolio.common.view': 'View Portfolio',
        'portfolio.common.delete': 'Delete',
        'portfolio.common.all': 'All Technicians',
        'portfolio.common.unknown': 'Unknown',
        'portfolio.common.emDash': '—',
        'portfolio.common.noImage': 'No Image',
        'portfolio.common.noDescription': 'No description',
        'portfolio.common.noDescriptionProvided': 'No description provided',

        // ── Access ────────────────────────────────────────────────
        'portfolio.accessDenied': 'You do not have permission to view portfolios.',

        // ── Header ────────────────────────────────────────────────
        'portfolio.header.title': 'Portfolio Management',
        'portfolio.header.subtitle': 'Showcasing technician work and expertise',

        // ── Filters ───────────────────────────────────────────────
        'portfolio.filter.technician': 'Technician',
        'portfolio.filter.searchPlaceholder': 'Search portfolios...',

        // ── Summary cards ─────────────────────────────────────────
        'portfolio.stats.totalPortfolios': 'Total Portfolios',
        'portfolio.stats.technicians': 'Technicians',
        'portfolio.stats.activeItems': 'Active Items',
        'portfolio.stats.recent': 'Recent',

        // ── Table ─────────────────────────────────────────────────
        'portfolio.table.col.portfolio': 'Portfolio',
        'portfolio.table.col.technician': 'Technician',
        'portfolio.table.col.description': 'Description',
        'portfolio.table.col.created': 'Created',
        'portfolio.table.col.actions': 'Actions',
        'portfolio.table.noFound': 'No portfolios found',
        'portfolio.table.itemLabel': 'Portfolio #{id}',

        // ── Action menu ───────────────────────────────────────────
        'portfolio.menu.viewPortfolio': 'View Portfolio',
        'portfolio.menu.delete': 'Delete',

        // ── Delete confirm ────────────────────────────────────────
        'portfolio.delete.title': 'Delete Portfolio',
        'portfolio.delete.message': 'Are you sure you want to delete this portfolio item?',

        // ── Detail dialog ─────────────────────────────────────────
        'portfolio.dialog.title': 'Portfolio Details',
        'portfolio.dialog.description': 'Description',
        'portfolio.dialog.technicianInfo': 'Technician Information',
        'portfolio.dialog.details': 'Details',
        'portfolio.dialog.created': 'Created: {date}',
        'portfolio.dialog.portfolioLabel': 'Portfolio #{id}',

        // ── Toasts ────────────────────────────────────────────────
        'portfolio.toast.loadFailed': 'Failed to load portfolios',
        'portfolio.toast.deleteSuccess': 'Portfolio deleted successfully',
        'portfolio.toast.deleteFailed': 'Failed to delete portfolio',
    },

    sw: {
        // ── Common ────────────────────────────────────────────────
        'portfolio.common.refresh': 'Onyesha Upya',
        'portfolio.common.cancel': 'Ghairi',
        'portfolio.common.confirm': 'Thibitisha',
        'portfolio.common.close': 'Funga',
        'portfolio.common.view': 'Ona Portfolio',
        'portfolio.common.delete': 'Futa',
        'portfolio.common.all': 'Mafundi Wote',
        'portfolio.common.unknown': 'Haijulikani',
        'portfolio.common.emDash': '—',
        'portfolio.common.noImage': 'Hakuna Picha',
        'portfolio.common.noDescription': 'Hakuna maelezo',
        'portfolio.common.noDescriptionProvided': 'Hakuna maelezo yaliyotolewa',

        // ── Access ────────────────────────────────────────────────
        'portfolio.accessDenied': 'Huna ruhusa kuona portfolios.',

        // ── Header ────────────────────────────────────────────────
        'portfolio.header.title': 'Usimamizi wa Portfolio',
        'portfolio.header.subtitle': 'Kuonyesha kazi na utaalam wa mafundi',

        // ── Filters ───────────────────────────────────────────────
        'portfolio.filter.technician': 'Fundi',
        'portfolio.filter.searchPlaceholder': 'Tafuta portfolios...',

        // ── Summary cards ─────────────────────────────────────────
        'portfolio.stats.totalPortfolios': 'Jumla ya Portfolio',
        'portfolio.stats.technicians': 'Mafundi',
        'portfolio.stats.activeItems': 'Vipengele Hai',
        'portfolio.stats.recent': 'Hivi Karibuni',

        // ── Table ─────────────────────────────────────────────────
        'portfolio.table.col.portfolio': 'Portfolio',
        'portfolio.table.col.technician': 'Fundi',
        'portfolio.table.col.description': 'Maelezo',
        'portfolio.table.col.created': 'Imeundwa',
        'portfolio.table.col.actions': 'Vitendo',
        'portfolio.table.noFound': 'Hakuna portfolios zilizopatikana',
        'portfolio.table.itemLabel': 'Portfolio #{id}',

        // ── Action menu ───────────────────────────────────────────
        'portfolio.menu.viewPortfolio': 'Ona Portfolio',
        'portfolio.menu.delete': 'Futa',

        // ── Delete confirm ────────────────────────────────────────
        'portfolio.delete.title': 'Futa Portfolio',
        'portfolio.delete.message': 'Una uhakika unataka kufuta kipengele hiki cha portfolio?',

        // ── Detail dialog ─────────────────────────────────────────
        'portfolio.dialog.title': 'Maelezo ya Portfolio',
        'portfolio.dialog.description': 'Maelezo',
        'portfolio.dialog.technicianInfo': 'Taarifa za Fundi',
        'portfolio.dialog.details': 'Maelezo',
        'portfolio.dialog.created': 'Imeundwa: {date}',
        'portfolio.dialog.portfolioLabel': 'Portfolio #{id}',

        // ── Toasts ────────────────────────────────────────────────
        'portfolio.toast.loadFailed': 'Imeshindwa kupakia portfolios',
        'portfolio.toast.deleteSuccess': 'Portfolio imefutwa kwa mafanikio',
        'portfolio.toast.deleteFailed': 'Imeshindwa kufuta portfolio',
    },
};

export function tPortfolio(language, key, replacements) {
    let str =
        portfoliosTranslations[language]?.[key] ||
        portfoliosTranslations.en?.[key] ||
        key;
    if (replacements) {
        Object.entries(replacements).forEach(([k, v]) => {
            str = str.replace(new RegExp(`\\{${k}\\}`, 'g'), v);
        });
    }
    return str;
}