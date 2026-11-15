// src/pages/privacy-policy/privacylang.js

export const privacyTranslations = {
    en: {
        'privacy.title': 'Privacy Policy',
        'privacy.subtitle': 'Manage your privacy policy content',
        'privacy.create': 'Create Policy',
        'privacy.edit': 'Edit',
        'privacy.delete': 'Delete',
        'privacy.refresh': 'Refresh',
        'privacy.searchPlaceholder': 'Search content...',
        'privacy.status': 'Status',
        'privacy.published': 'Published',
        'privacy.notCreated': 'Not Created',
        'privacy.wordCount': 'Word Count',
        'privacy.lastUpdated': 'Last Updated',
        'privacy.never': 'Never',
        'privacy.lastUpdatedLabel': 'Last updated',
        'privacy.created': 'Created',
        'privacy.words': 'words',
        'privacy.noMatch': 'No content matches your search.',
        'privacy.noContent': 'No privacy policy content available.',
        'privacy.createPage': 'Create Privacy Policy',
        'privacy.loadFailed': 'Failed to load privacy policy',
        'privacy.retry': 'Retry',
        'privacy.deleteConfirm': 'Are you sure you want to delete this privacy policy?',
        'privacy.deleted': 'Privacy policy deleted successfully',
        'privacy.deleteFailed': 'Delete failed',

        // Modal
        'privacy.modal.editTitle': 'Edit Privacy Policy',
        'privacy.modal.createTitle': 'Create Privacy Policy',
        'privacy.modal.editDesc': 'Update the privacy policy content below.',
        'privacy.modal.createDesc': 'Create new privacy policy content.',
        'privacy.modal.content': 'Content',
        'privacy.modal.placeholder': 'Enter privacy policy content...',
        'privacy.modal.required': 'Content is required',
        'privacy.modal.cancel': 'Cancel',
        'privacy.modal.update': 'Update',
        'privacy.modal.create': 'Create',
        'privacy.modal.updated': 'Privacy policy updated successfully',
        'privacy.modal.created': 'Privacy policy created successfully',
        'privacy.modal.failed': 'Operation failed',
    },
    sw: {
        'privacy.title': 'Sera ya Faragha',
        'privacy.subtitle': 'Simamia maudhui ya sera ya faragha',
        'privacy.create': 'Unda Sera',
        'privacy.edit': 'Hariri',
        'privacy.delete': 'Futa',
        'privacy.refresh': 'Onyesha Upya',
        'privacy.searchPlaceholder': 'Tafuta maudhui...',
        'privacy.status': 'Hali',
        'privacy.published': 'Imechapishwa',
        'privacy.notCreated': 'Haijaundwa',
        'privacy.wordCount': 'Idadi ya Maneno',
        'privacy.lastUpdated': 'Imesasishwa Mwisho',
        'privacy.never': 'Kamwe',
        'privacy.lastUpdatedLabel': 'Imesasishwa mwisho',
        'privacy.created': 'Imeundwa',
        'privacy.words': 'maneno',
        'privacy.noMatch': 'Hakuna maudhui yanayolingana na utafutaji wako.',
        'privacy.noContent': 'Hakuna maudhui ya sera ya faragha yanayopatikana.',
        'privacy.createPage': 'Unda Sera ya Faragha',
        'privacy.loadFailed': 'Imeshindwa kupakia sera ya faragha',
        'privacy.retry': 'Jaribu Tena',
        'privacy.deleteConfirm': 'Una uhakika unataka kufuta sera hii ya faragha?',
        'privacy.deleted': 'Sera ya faragha imefutwa kwa mafanikio',
        'privacy.deleteFailed': 'Kufuta kumeshindikana',

        // Modal
        'privacy.modal.editTitle': 'Hariri Sera ya Faragha',
        'privacy.modal.createTitle': 'Unda Sera ya Faragha',
        'privacy.modal.editDesc': 'Sasisha maudhui ya sera ya faragha hapa chini.',
        'privacy.modal.createDesc': 'Unda maudhui mapya ya sera ya faragha.',
        'privacy.modal.content': 'Maudhui',
        'privacy.modal.placeholder': 'Andika maudhui ya sera ya faragha...',
        'privacy.modal.required': 'Maudhui yanahitajika',
        'privacy.modal.cancel': 'Ghairi',
        'privacy.modal.update': 'Sasisha',
        'privacy.modal.create': 'Unda',
        'privacy.modal.updated': 'Sera ya faragha imesasishwa kwa mafanikio',
        'privacy.modal.created': 'Sera ya faragha imeundwa kwa mafanikio',
        'privacy.modal.failed': 'Operesheni imeshindikana',
    },
};

export function tPrivacy(language, key) {
    return (
        privacyTranslations[language]?.[key] ||
        privacyTranslations.en?.[key] ||
        key
    );
}