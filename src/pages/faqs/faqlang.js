// src/pages/faqs/faqlang.js

export const faqTranslations = {
    en: {
        'faq.title': 'FAQs',
        'faq.subtitle': 'Manage frequently asked questions and answers',
        'faq.add': 'Add FAQ',
        'faq.refresh': 'Refresh',
        'faq.searchPlaceholder': 'Search FAQs...',
        'faq.total': 'Total FAQs',
        'faq.withAnswers': 'With Answers',
        'faq.lastUpdated': 'Last Updated',
        'faq.never': 'Never',
        'faq.noMatch': 'No FAQs match your search',
        'faq.noFound': 'No FAQs found',
        'faq.created': 'Created',
        'faq.updated': 'Updated',
        'faq.order': 'Order',
        'faq.edit': 'Edit',
        'faq.retry': 'Retry',
        'faq.loadFailed': 'Failed to load FAQs',

        // Table headers
        'faq.col.index': '#',
        'faq.col.question': 'Question',
        'faq.col.answer': 'Answer',
        'faq.col.order': 'Order',
        'faq.col.actions': 'Actions',

        // Modal
        'faq.modal.editTitle': 'Edit FAQ',
        'faq.modal.createTitle': 'Create New FAQ',
        'faq.modal.editDesc': 'Update the frequently asked question and answer below.',
        'faq.modal.createDesc': 'Create a new frequently asked question.',
        'faq.modal.question': 'Question',
        'faq.modal.answer': 'Answer',
        'faq.modal.order': 'Display Order',
        'faq.modal.orderHelp': 'Lower numbers appear first in the list',
        'faq.modal.questionPlaceholder': 'Enter the frequently asked question...',
        'faq.modal.answerPlaceholder': 'Enter the answer to the question...',
        'faq.modal.questionRequired': 'Question is required',
        'faq.modal.answerRequired': 'Answer is required',
        'faq.modal.orderPositive': 'Order must be a positive number',
        'faq.modal.cancel': 'Cancel',
        'faq.modal.update': 'Update',
        'faq.modal.create': 'Create',
        'faq.modal.updated': 'FAQ updated successfully',
        'faq.modal.created': 'FAQ created successfully',
        'faq.modal.failed': 'Operation failed',
    },
    sw: {
        'faq.title': 'Maswali Yanayoulizwa Mara kwa Mara',
        'faq.subtitle': 'Simamia maswali yanayoulizwa mara kwa mara na majibu',
        'faq.add': 'Ongeza FAQ',
        'faq.refresh': 'Onyesha Upya',
        'faq.searchPlaceholder': 'Tafuta FAQs...',
        'faq.total': 'Jumla ya FAQs',
        'faq.withAnswers': 'Zenye Majibu',
        'faq.lastUpdated': 'Imesasishwa Mwisho',
        'faq.never': 'Kamwe',
        'faq.noMatch': 'Hakuna FAQ zinazolingana na utafutaji wako',
        'faq.noFound': 'Hakuna FAQs zilizopatikana',
        'faq.created': 'Imeundwa',
        'faq.updated': 'Imesasishwa',
        'faq.order': 'Mpangilio',
        'faq.edit': 'Hariri',
        'faq.retry': 'Jaribu Tena',
        'faq.loadFailed': 'Imeshindwa kupakia FAQs',

        // Table headers
        'faq.col.index': '#',
        'faq.col.question': 'Swali',
        'faq.col.answer': 'Jibu',
        'faq.col.order': 'Mpangilio',
        'faq.col.actions': 'Vitendo',

        // Modal
        'faq.modal.editTitle': 'Hariri FAQ',
        'faq.modal.createTitle': 'Unda FAQ Mpya',
        'faq.modal.editDesc': 'Sasisha swali na jibu linaloulizwa mara kwa mara hapa chini.',
        'faq.modal.createDesc': 'Unda swali jipya linaloulizwa mara kwa mara.',
        'faq.modal.question': 'Swali',
        'faq.modal.answer': 'Jibu',
        'faq.modal.order': 'Mpangilio wa Onyesho',
        'faq.modal.orderHelp': 'Nambari ndogo zinaonekana kwanza kwenye orodha',
        'faq.modal.questionPlaceholder': 'Andika swali linaloulizwa mara kwa mara...',
        'faq.modal.answerPlaceholder': 'Andika jibu la swali...',
        'faq.modal.questionRequired': 'Swali linahitajika',
        'faq.modal.answerRequired': 'Jibu linahitajika',
        'faq.modal.orderPositive': 'Mpangilio lazima uwe nambari chanya',
        'faq.modal.cancel': 'Ghairi',
        'faq.modal.update': 'Sasisha',
        'faq.modal.create': 'Unda',
        'faq.modal.updated': 'FAQ imesasishwa kwa mafanikio',
        'faq.modal.created': 'FAQ imeundwa kwa mafanikio',
        'faq.modal.failed': 'Operesheni imeshindikana',
    },
};

export function tFaq(language, key) {
    return (
        faqTranslations[language]?.[key] ||
        faqTranslations.en?.[key] ||
        key
    );
}