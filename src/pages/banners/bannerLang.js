const en = {
    'banner.accessDenied': 'You do not have permission to view banners.',
    'banner.common.retry': 'Retry',
    'banner.common.refresh': 'Refresh',
    'banner.common.cancel': 'Cancel',
    'banner.common.create': 'Create',
    'banner.common.update': 'Save',
    'banner.common.delete': 'Delete',
    'banner.common.close': 'Close',

    'banner.list.title': 'Banners',
    'banner.list.subtitle': 'Manage promotional banners shown in the app.',
    'banner.list.add': 'New Banner',
    'banner.list.search': 'Search title or type',
    'banner.list.allTypes': 'All types',
    'banner.list.allStatus': 'All statuses',
    'banner.list.loadFailed': 'Failed to load banners.',
    'banner.list.noFound': 'No banners yet.',
    'banner.list.noMatch': 'No banners match your filters.',

    'banner.col.image': 'Image',
    'banner.col.title': 'Title',
    'banner.col.type': 'Type',
    'banner.col.link': 'Link',
    'banner.col.status': 'Status',
    'banner.col.expires': 'Expires',
    'banner.col.order': 'Order',
    'banner.col.actions': 'Actions',

    'banner.status.active': 'Active',
    'banner.status.draft': 'Draft',
    'banner.status.expired': 'Expired',

    'banner.type.hero': 'Hero',
    'banner.type.promo': 'Promo',
    'banner.type.sidebar': 'Sidebar',
    'banner.type.popup': 'Popup',
    'banner.type.splash': 'Splash',

    'banner.action.edit': 'Edit',
    'banner.action.delete': 'Delete',
    'banner.action.setActive': 'Set Active',
    'banner.action.setDraft': 'Set Draft',

    'banner.form.createTitle': 'New Banner',
    'banner.form.editTitle': 'Edit Banner',
    'banner.form.title': 'Title (optional)',
    'banner.form.type': 'Type',
    'banner.form.link': 'Link (optional)',
    'banner.form.linkPlaceholder': 'https://example.com',
    'banner.form.status': 'Status',
    'banner.form.startsAt': 'Starts at (optional)',
    'banner.form.expiresAt': 'Expires at (optional)',
    'banner.form.sortOrder': 'Sort order',
    'banner.form.image': 'Banner image',
    'banner.form.imageRequired': 'Please choose an image.',
    'banner.form.created': 'Banner created.',
    'banner.form.updated': 'Banner updated.',
    'banner.form.failed': 'Operation failed.',
    'banner.form.changeImage': 'Change image',

    'banner.delete.title': 'Delete Banner',
    'banner.delete.message': 'Delete this banner? It will no longer appear in the app.',
    'banner.delete.success': 'Banner deleted.',
    'banner.status.updated': 'Status updated.',
};

const sw = {
    'banner.accessDenied': 'Huna ruhusa ya kuona banners.',
    'banner.common.retry': 'Jaribu tena',
    'banner.common.refresh': 'Onyesha upya',
    'banner.common.cancel': 'Ghairi',
    'banner.common.create': 'Tengeneza',
    'banner.common.update': 'Hifadhi',
    'banner.common.delete': 'Futa',
    'banner.common.close': 'Funga',

    'banner.list.title': 'Banners',
    'banner.list.subtitle': 'Simamia banners zinazoonekana kwenye app.',
    'banner.list.add': 'Banner Mpya',
    'banner.list.search': 'Tafuta jina au aina',
    'banner.list.allTypes': 'Aina zote',
    'banner.list.allStatus': 'Hali zote',
    'banner.list.loadFailed': 'Imeshindwa kupakia banners.',
    'banner.list.noFound': 'Hakuna banner bado.',
    'banner.list.noMatch': 'Hakuna banner inayolingana.',

    'banner.col.image': 'Picha',
    'banner.col.title': 'Jina',
    'banner.col.type': 'Aina',
    'banner.col.link': 'Kiungo',
    'banner.col.status': 'Hali',
    'banner.col.expires': 'Inaisha',
    'banner.col.order': 'Mpangilio',
    'banner.col.actions': 'Vitendo',

    'banner.status.active': 'Inafanya kazi',
    'banner.status.draft': 'Rasimu',
    'banner.status.expired': 'Imeisha',

    'banner.type.hero': 'Hero',
    'banner.type.promo': 'Promo',
    'banner.type.sidebar': 'Sidebar',
    'banner.type.popup': 'Popup',
    'banner.type.splash': 'Splash',

    'banner.action.edit': 'Hariri',
    'banner.action.delete': 'Futa',
    'banner.action.setActive': 'Washa',
    'banner.action.setDraft': 'Weka rasimu',

    'banner.form.createTitle': 'Banner Mpya',
    'banner.form.editTitle': 'Hariri Banner',
    'banner.form.title': 'Jina (hiari)',
    'banner.form.type': 'Aina',
    'banner.form.link': 'Kiungo (hiari)',
    'banner.form.linkPlaceholder': 'https://example.com',
    'banner.form.status': 'Hali',
    'banner.form.startsAt': 'Inaanza (hiari)',
    'banner.form.expiresAt': 'Inaisha (hiari)',
    'banner.form.sortOrder': 'Mpangilio',
    'banner.form.image': 'Picha ya banner',
    'banner.form.imageRequired': 'Chagua picha.',
    'banner.form.created': 'Banner imetengenezwa.',
    'banner.form.updated': 'Banner imesasishwa.',
    'banner.form.failed': 'Imeshindwa.',
    'banner.form.changeImage': 'Badilisha picha',

    'banner.delete.title': 'Futa Banner',
    'banner.delete.message': 'Futa banner hii? Haitaoonekana tena kwenye app.',
    'banner.delete.success': 'Banner imefutwa.',
    'banner.status.updated': 'Hali imesasishwa.',
};

export const tBanner = (language, key, replacements = {}) => {
    const dict = language === 'sw' ? sw : en;
    let text = dict[key] ?? en[key] ?? key;
    Object.keys(replacements).forEach((k) => {
        text = text.replace(new RegExp(`\\{${k}\\}`, 'g'), replacements[k]);
    });
    return text;
};