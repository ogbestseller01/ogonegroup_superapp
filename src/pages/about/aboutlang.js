// src/pages/about/aboutlang.js

export const aboutTranslations = {
    en: {
        'about.title': 'About Page',
        'about.subtitle': 'Manage your about page content',
        'about.create': 'Create About',
        'about.edit': 'Edit About',
        'about.refresh': 'Refresh',
        'about.searchPlaceholder': 'Search content...',
        'about.status': 'Status',
        'about.published': 'Published',
        'about.notCreated': 'Not Created',
        'about.wordCount': 'Word Count',
        'about.lastUpdated': 'Last Updated',
        'about.never': 'Never',
        'about.lastUpdatedLabel': 'Last updated',
        'about.created': 'Created',
        'about.words': 'words',
        'about.noMatch': 'No content matches your search.',
        'about.noContent': 'No about content available.',
        'about.createPage': 'Create About Page',
        'about.loadFailed': 'Failed to load about content',
        'about.retry': 'Retry',

        // Modal
        'about.modal.editTitle': 'Edit About Page',
        'about.modal.createTitle': 'Create About Page',
        'about.modal.editDesc': 'Update the about page content below.',
        'about.modal.createDesc': 'Create new about page content.',
        'about.modal.content': 'Content',
        'about.modal.placeholder': 'Enter about page content...',
        'about.modal.required': 'Content is required',
        'about.modal.cancel': 'Cancel',
        'about.modal.update': 'Update',
        'about.modal.create': 'Create',
        'about.modal.updated': 'About page updated successfully',
        'about.modal.created': 'About page created successfully',
        'about.modal.failed': 'Operation failed',
    },
    sw: {
        'about.title': 'Ukurasa wa Kuhusu',
        'about.subtitle': 'Simamia maudhui ya ukurasa wa kuhusu',
        'about.create': 'Unda Kuhusu',
        'about.edit': 'Hariri Kuhusu',
        'about.refresh': 'Onyesha Upya',
        'about.searchPlaceholder': 'Tafuta maudhui...',
        'about.status': 'Hali',
        'about.published': 'Imechapishwa',
        'about.notCreated': 'Haijaundwa',
        'about.wordCount': 'Idadi ya Maneno',
        'about.lastUpdated': 'Imesasishwa Mwisho',
        'about.never': 'Kamwe',
        'about.lastUpdatedLabel': 'Imesasishwa mwisho',
        'about.created': 'Imeundwa',
        'about.words': 'maneno',
        'about.noMatch': 'Hakuna maudhui yanayolingana na utafutaji wako.',
        'about.noContent': 'Hakuna maudhui ya kuhusu yanayopatikana.',
        'about.createPage': 'Unda Ukurasa wa Kuhusu',
        'about.loadFailed': 'Imeshindwa kupakia maudhui ya kuhusu',
        'about.retry': 'Jaribu Tena',

        // Modal
        'about.modal.editTitle': 'Hariri Ukurasa wa Kuhusu',
        'about.modal.createTitle': 'Unda Ukurasa wa Kuhusu',
        'about.modal.editDesc': 'Sasisha maudhui ya ukurasa wa kuhusu hapa chini.',
        'about.modal.createDesc': 'Unda maudhui mapya ya ukurasa wa kuhusu.',
        'about.modal.content': 'Maudhui',
        'about.modal.placeholder': 'Andika maudhui ya ukurasa wa kuhusu...',
        'about.modal.required': 'Maudhui yanahitajika',
        'about.modal.cancel': 'Ghairi',
        'about.modal.update': 'Sasisha',
        'about.modal.create': 'Unda',
        'about.modal.updated': 'Ukurasa wa kuhusu umesasishwa kwa mafanikio',
        'about.modal.created': 'Ukurasa wa kuhusu umeundwa kwa mafanikio',
        'about.modal.failed': 'Operesheni imeshindikana',
    },
};

export function tAbout(language, key) {
    return (
        aboutTranslations[language]?.[key] ||
        aboutTranslations.en?.[key] ||
        key
    );
}