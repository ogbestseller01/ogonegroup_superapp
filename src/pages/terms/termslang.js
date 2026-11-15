// src/pages/terms/termslang.js

export const termsTranslations = {
    en: {
        'terms.title': 'Terms & Conditions',
        'terms.subtitle': 'Manage your terms and conditions content',
        'terms.create': 'Create Terms',
        'terms.edit': 'Edit Terms',
        'terms.refresh': 'Refresh',
        'terms.searchPlaceholder': 'Search content...',
        'terms.status': 'Status',
        'terms.published': 'Published',
        'terms.notCreated': 'Not Created',
        'terms.wordCount': 'Word Count',
        'terms.lastUpdated': 'Last Updated',
        'terms.never': 'Never',
        'terms.lastUpdatedLabel': 'Last updated',
        'terms.created': 'Created',
        'terms.words': 'words',
        'terms.noMatch': 'No content matches your search.',
        'terms.noContent': 'No terms and conditions content available.',
        'terms.createPage': 'Create Terms & Conditions',
        'terms.loadFailed': 'Failed to load terms content',
        'terms.retry': 'Retry',

        // Modal
        'terms.modal.editTitle': 'Edit Terms & Conditions',
        'terms.modal.createTitle': 'Create Terms & Conditions',
        'terms.modal.editDesc': 'Update the terms and conditions content below.',
        'terms.modal.createDesc': 'Create new terms and conditions content.',
        'terms.modal.content': 'Content',
        'terms.modal.placeholder': 'Enter terms and conditions content...',
        'terms.modal.required': 'Content is required',
        'terms.modal.cancel': 'Cancel',
        'terms.modal.update': 'Update',
        'terms.modal.create': 'Create',
        'terms.modal.updated': 'Terms & Conditions updated successfully',
        'terms.modal.created': 'Terms & Conditions created successfully',
        'terms.modal.failed': 'Operation failed',
    },
    sw: {
        'terms.title': 'Masharti na Vigezo',
        'terms.subtitle': 'Simamia maudhui ya masharti na vigezo',
        'terms.create': 'Unda Masharti',
        'terms.edit': 'Hariri Masharti',
        'terms.refresh': 'Onyesha Upya',
        'terms.searchPlaceholder': 'Tafuta maudhui...',
        'terms.status': 'Hali',
        'terms.published': 'Imechapishwa',
        'terms.notCreated': 'Haijaundwa',
        'terms.wordCount': 'Idadi ya Maneno',
        'terms.lastUpdated': 'Imesasishwa Mwisho',
        'terms.never': 'Kamwe',
        'terms.lastUpdatedLabel': 'Imesasishwa mwisho',
        'terms.created': 'Imeundwa',
        'terms.words': 'maneno',
        'terms.noMatch': 'Hakuna maudhui yanayolingana na utafutaji wako.',
        'terms.noContent': 'Hakuna maudhui ya masharti na vigezo yanayopatikana.',
        'terms.createPage': 'Unda Masharti na Vigezo',
        'terms.loadFailed': 'Imeshindwa kupakia maudhui ya masharti',
        'terms.retry': 'Jaribu Tena',

        // Modal
        'terms.modal.editTitle': 'Hariri Masharti na Vigezo',
        'terms.modal.createTitle': 'Unda Masharti na Vigezo',
        'terms.modal.editDesc': 'Sasisha maudhui ya masharti na vigezo hapa chini.',
        'terms.modal.createDesc': 'Unda maudhui mapya ya masharti na vigezo.',
        'terms.modal.content': 'Maudhui',
        'terms.modal.placeholder': 'Andika maudhui ya masharti na vigezo...',
        'terms.modal.required': 'Maudhui yanahitajika',
        'terms.modal.cancel': 'Ghairi',
        'terms.modal.update': 'Sasisha',
        'terms.modal.create': 'Unda',
        'terms.modal.updated': 'Masharti na Vigezo vimesasishwa kwa mafanikio',
        'terms.modal.created': 'Masharti na Vigezo vimeundwa kwa mafanikio',
        'terms.modal.failed': 'Operesheni imeshindikana',
    },
};

export function tTerms(language, key) {
    return (
        termsTranslations[language]?.[key] ||
        termsTranslations.en?.[key] ||
        key
    );
}