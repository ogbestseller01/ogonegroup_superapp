// src/pages/categories/categorieslang.js

export const categoriesTranslations = {
    en: {
        // ── Common ────────────────────────────────────────────────
        'category.common.refresh': 'Refresh',
        'category.common.cancel': 'Cancel',
        'category.common.confirm': 'Confirm',
        'category.common.close': 'Close',
        'category.common.retry': 'Retry',
        'category.common.edit': 'Edit',
        'category.common.delete': 'Delete',
        'category.common.create': 'Create',
        'category.common.update': 'Update',
        'category.common.na': 'N/A',
        'category.common.emDash': '—',

        // ── Access ────────────────────────────────────────────────
        'category.accessDenied': 'You do not have permission to view categories.',

        // ── List ──────────────────────────────────────────────────
        'category.list.title': 'Service Categories',
        'category.list.subtitle': 'Manage service categories and their translations',
        'category.list.addCategory': 'Add Category',
        'category.list.searchPlaceholder': 'Search categories...',
        'category.list.noMatch': 'No categories match your search',
        'category.list.noFound': 'No categories found',
        'category.list.loadFailed': 'Failed to load categories',

        // Stats
        'category.list.stat.total': 'Total Categories',
        'category.list.stat.withServices': 'With Services',
        'category.list.stat.translated': 'Translated',

        // Table columns
        'category.list.col.id': '#',
        'category.list.col.name': 'Category Name',
        'category.list.col.swahili': 'Swahili Name',
        'category.list.col.slug': 'Slug',
        'category.list.col.services': 'Services',
        'category.list.col.actions': 'Actions',

        // Mobile card
        'category.list.slugLabel': 'Slug: {slug}',
        'category.list.servicesCount': '{n} service{s}',

        // ── Delete confirm ────────────────────────────────────────
        'category.delete.title': 'Delete Category',
        'category.delete.message': 'Are you sure you want to delete "{name}"? This will not delete its associated services, but will remove the assignment.',
        'category.delete.success': 'Category deleted successfully',
        'category.delete.failed': 'Failed to delete category',

        // ── Form modal ────────────────────────────────────────────
        'category.form.editTitle': 'Edit Category',
        'category.form.createTitle': 'New Category',
        'category.form.nameEnLabel': 'Category Name (English)',
        'category.form.nameSwLabel': 'Category Name (Swahili)',
        'category.form.nameSwPlaceholder': 'e.g., Aina ya Huduma',
        'category.form.slugLabel': 'Slug (URL friendly)',
        'category.form.slugHelper': 'Leave blank to auto-generate from name',
        'category.form.slugPlaceholder': 'e.g., tv-repair',
        'category.form.descriptionLabel': 'Description',
        'category.form.descriptionPlaceholder': 'Brief description of the category...',
        'category.form.nameRequired': 'Category name is required',
        'category.form.nameTooShort': 'Must be at least 2 characters',
        'category.form.nameDuplicate': 'Category name already exists',
        'category.form.updated': 'Category updated successfully',
        'category.form.created': 'Category created successfully',
        'category.form.operationFailed': 'Operation failed',
    },

    sw: {
        // ── Common ────────────────────────────────────────────────
        'category.common.refresh': 'Onyesha Upya',
        'category.common.cancel': 'Ghairi',
        'category.common.confirm': 'Thibitisha',
        'category.common.close': 'Funga',
        'category.common.retry': 'Jaribu Tena',
        'category.common.edit': 'Hariri',
        'category.common.delete': 'Futa',
        'category.common.create': 'Unda',
        'category.common.update': 'Sasisha',
        'category.common.na': 'Hakuna',
        'category.common.emDash': '—',

        // ── Access ────────────────────────────────────────────────
        'category.accessDenied': 'Huna ruhusa kuona kategoria.',

        // ── List ──────────────────────────────────────────────────
        'category.list.title': 'Kategoria za Huduma',
        'category.list.subtitle': 'Simamia kategoria za huduma na tafsiri zake',
        'category.list.addCategory': 'Ongeza Kategoria',
        'category.list.searchPlaceholder': 'Tafuta kategoria...',
        'category.list.noMatch': 'Hakuna kategoria zinazolingana na utafutaji wako',
        'category.list.noFound': 'Hakuna kategoria zilizopatikana',
        'category.list.loadFailed': 'Imeshindwa kupakia kategoria',

        // Stats
        'category.list.stat.total': 'Jumla ya Kategoria',
        'category.list.stat.withServices': 'Zenye Huduma',
        'category.list.stat.translated': 'Zilizotafsiriwa',

        // Table columns
        'category.list.col.id': '#',
        'category.list.col.name': 'Jina la Kategoria',
        'category.list.col.swahili': 'Jina la Kiswahili',
        'category.list.col.slug': 'Slug',
        'category.list.col.services': 'Huduma',
        'category.list.col.actions': 'Vitendo',

        // Mobile card
        'category.list.slugLabel': 'Slug: {slug}',
        'category.list.servicesCount': 'huduma {n}',

        // ── Delete confirm ────────────────────────────────────────
        'category.delete.title': 'Futa Kategoria',
        'category.delete.message': 'Una uhakika unataka kufuta "{name}"? Hii haitafuta huduma zinazohusiana, lakini itaondoa ugawaji.',
        'category.delete.success': 'Kategoria imefutwa kwa mafanikio',
        'category.delete.failed': 'Imeshindwa kufuta kategoria',

        // ── Form modal ────────────────────────────────────────────
        'category.form.editTitle': 'Hariri Kategoria',
        'category.form.createTitle': 'Kategoria Mpya',
        'category.form.nameEnLabel': 'Jina la Kategoria (Kiingereza)',
        'category.form.nameSwLabel': 'Jina la Kategoria (Kiswahili)',
        'category.form.nameSwPlaceholder': 'k.m., Aina ya Huduma',
        'category.form.slugLabel': 'Slug (Rafiki ya URL)',
        'category.form.slugHelper': 'Acha wazi ili kutengeneza kiotomatiki kutoka jina',
        'category.form.slugPlaceholder': 'k.m., tv-repair',
        'category.form.descriptionLabel': 'Maelezo',
        'category.form.descriptionPlaceholder': 'Maelezo mafupi ya kategoria...',
        'category.form.nameRequired': 'Jina la kategoria linahitajika',
        'category.form.nameTooShort': 'Lazima liwe na angalau herufi 2',
        'category.form.nameDuplicate': 'Jina la kategoria tayari lipo',
        'category.form.updated': 'Kategoria imesasishwa kwa mafanikio',
        'category.form.created': 'Kategoria imeundwa kwa mafanikio',
        'category.form.operationFailed': 'Operesheni imeshindikana',
    },
};

export function tCategory(language, key, replacements) {
    let str =
        categoriesTranslations[language]?.[key] ||
        categoriesTranslations.en?.[key] ||
        key;
    if (replacements) {
        Object.entries(replacements).forEach(([k, v]) => {
            str = str.replace(new RegExp(`\\{${k}\\}`, 'g'), v);
        });
    }
    return str;
}