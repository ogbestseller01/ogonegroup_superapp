// src/pages/technicians/technicianslang.js

export const techniciansTranslations = {
    en: {
        // ── Common ────────────────────────────────────────────────
        'tech.common.refresh': 'Refresh',
        'tech.common.cancel':  'Cancel',
        'tech.common.close':   'Close',
        'tech.common.back':    'Back to List',
        'tech.common.na':      'N/A',
        'tech.common.unknown': 'Unknown',
        'tech.common.yes':     'Yes',
        'tech.common.no':      'No',

        // ── Verification statuses ─────────────────────────────────
        'tech.status.verified': 'Verified',
        'tech.status.approved': 'Approved',
        'tech.status.pending':  'Pending',
        'tech.status.rejected': 'Rejected',

        // ── Registration ──────────────────────────────────────────
        'tech.reg.registered': 'Registered',
        'tech.reg.incomplete': 'Incomplete',
        'tech.reg.step':       'Step {step}/4',

        // ── Access / Errors ───────────────────────────────────────
        'tech.accessDenied': 'You do not have permission to view technician details.',
        'tech.notFound':     'Technician not found.',
        'tech.loadFailed':   'Failed to load technician.',
        'tech.invalidDate':  'Invalid date',

        // ── Header actions ────────────────────────────────────────
        'tech.action.approveTechnician': 'Approve Technician',

        // ── Profile header ────────────────────────────────────────
        'tech.profile.jobsCount':  '({n} jobs)',
        'tech.profile.experience': 'Experience:',
        'tech.profile.years':      '{n} years',
        'tech.profile.perHour':    '{rate} TZS/hr',

        // ── Sections ──────────────────────────────────────────────
        'tech.section.bio':                 'Bio',
        'tech.section.identification':      'Identification',
        'tech.section.biometrics':          'Biometric Verification',
        'tech.section.services':            'Services & Pricing',
        'tech.section.location':            'Location',
        'tech.section.portfolio':           'Portfolio ({n})',
        'tech.section.subscriptionHistory': 'Subscription History',

        // ── Bio ───────────────────────────────────────────────────
        'tech.bio.empty': 'No bio provided.',

        // ── Identification ────────────────────────────────────────
        'tech.id.nida':               'NIDA:',
        'tech.id.documentType':       'Document Type:',
        'tech.id.verificationStatus': 'Verification Status:',
        'tech.id.documentLabel':      'ID Document:',
        'tech.id.noDocuments':        'No ID documents uploaded yet.',

        // ── Biometrics ────────────────────────────────────────────
        'tech.bio.view':              'View',
        'tech.bio.hide':              'Hide',
        'tech.bio.fingerprint':       'Fingerprint',
        'tech.bio.face':              'Face',
        'tech.bio.enrolled':          'Enrolled',
        'tech.bio.notEnrolled':       'Not enrolled',
        'tech.bio.faceCapture':       'Face Capture',
        'tech.bio.fingerprintCapture':'Fingerprint Data',
        'tech.bio.capturedAt':        'Captured At',
        'tech.bio.nextOfKin':         'Next of Kin',
        'tech.bio.name':              'Name:',
        'tech.bio.phone':             'Phone:',
        'tech.bio.relationship':      'Relationship:',
        'tech.bio.loadFailed':        'Failed to load biometric data.',

        // ── Services ──────────────────────────────────────────────
        'tech.service.priceRange': 'Price: {min} – {max} TZS',
        'tech.service.none':       'No services assigned.',

        // ── Location ──────────────────────────────────────────────
        'tech.location.area':         'Area:',
        'tech.location.coordinates':  'Coordinates:',
        'tech.location.lastUpdate':   'Last Location Update:',
        'tech.location.lastActivity': 'Last Activity:',

        // ── Subscription ──────────────────────────────────────────
        'tech.sub.plan':          'Plan: {name}',
        'tech.sub.statusLabel':   'Status:',
        'tech.sub.amount':        'Amount: {amount} {currency}',
        'tech.sub.start':         'Start:',
        'tech.sub.expiry':        'Expiry:',
        'tech.sub.payment':       'Payment:',
        'tech.sub.currentStatus': 'Current Status:',
        'tech.sub.currentExpiry': 'Current Expiry:',
        'tech.sub.none':          'No subscription records found.',

        // ── Approve dialog ────────────────────────────────────────
        'tech.approve.title':             'Approve Technician',
        'tech.approve.confirmMsg':        'Are you sure you want to approve',
        'tech.approve.thisTechnician':    'this technician',
        'tech.approve.freeTrialNote':     'This will activate a',
        'tech.approve.freeTrialDays':     '1-day free trial',
        'tech.approve.freeTrialEnd':      'subscription.',
        'tech.approve.processing':        'Approving...',
        'tech.approve.processingBtn':     'Processing...',
        'tech.approve.confirmBtn':        'Yes, Approve',
        'tech.approve.successMsg':        'Technician approved successfully! Free trial activated.',
        'tech.approve.failedMsg':         'Approval failed.',
        'tech.approve.errorMsg':          'An error occurred during approval.',
        'tech.approve.snackbarSuccess':   'Technician approved successfully!',

        // ── List ──────────────────────────────────────────────────
        'tech.list.accessDenied':              'You do not have permission to view technicians.',
        'tech.list.title':                     'Technician Management',
        'tech.list.subtitle':                  'Manage technician profiles and verification',
        'tech.list.searchPlaceholder':         'Search technicians...',
        'tech.list.serviceFilterPlaceholder':  'Filter by service...',
        'tech.list.noFound':                   'No technicians found',
        'tech.list.stat.total':                'Total Technicians',
        'tech.list.stat.verified':             'Verified',
        'tech.list.stat.pending':              'Pending',
        'tech.list.stat.services':             'Services',
        'tech.list.col.technician':            'Technician',
        'tech.list.col.services':              'Services',
        'tech.list.col.location':              'Location',
        'tech.list.col.rating':                'Rating',
        'tech.list.col.status':                'Status',
        'tech.list.serviceCount':              '{n} service{s}',
        'tech.list.yearsExperience':           '{n} yrs experience',
        'tech.list.ratePerHour':               '{rate} TZS/hr',
        'tech.list.noRating':                  'No rating',
        'tech.list.tab.pending':               'New Registrations',
        'tech.list.tab.approved':              'Approved Technicians',
        'tech.list.retry':                     'Retry',
    },

    sw: {
        // ── Common ────────────────────────────────────────────────
        'tech.common.refresh': 'Onyesha Upya',
        'tech.common.cancel':  'Ghairi',
        'tech.common.close':   'Funga',
        'tech.common.back':    'Rudi kwenye Orodha',
        'tech.common.na':      'Hakuna',
        'tech.common.unknown': 'Haijulikani',
        'tech.common.yes':     'Ndiyo',
        'tech.common.no':      'Hapana',

        // ── Verification statuses ─────────────────────────────────
        'tech.status.verified': 'Imethibitishwa',
        'tech.status.approved': 'Imeidhinishwa',
        'tech.status.pending':  'Inasubiri',
        'tech.status.rejected': 'Imekataliwa',

        // ── Registration ──────────────────────────────────────────
        'tech.reg.registered': 'Amejiandikisha',
        'tech.reg.incomplete': 'Haijakamilika',
        'tech.reg.step':       'Hatua {step}/4',

        // ── Access / Errors ───────────────────────────────────────
        'tech.accessDenied': 'Huna ruhusa kuona maelezo ya fundi.',
        'tech.notFound':     'Fundi hakupatikana.',
        'tech.loadFailed':   'Imeshindwa kupakia fundi.',
        'tech.invalidDate':  'Tarehe batili',

        // ── Header actions ────────────────────────────────────────
        'tech.action.approveTechnician': 'Idhinisha Fundi',

        // ── Profile header ────────────────────────────────────────
        'tech.profile.jobsCount':  '(kazi {n})',
        'tech.profile.experience': 'Uzoefu:',
        'tech.profile.years':      'miaka {n}',
        'tech.profile.perHour':    '{rate} TZS/saa',

        // ── Sections ──────────────────────────────────────────────
        'tech.section.bio':                 'Wasifu',
        'tech.section.identification':      'Utambulisho',
        'tech.section.biometrics':          'Uthibitisho wa Bayometriki',
        'tech.section.services':            'Huduma na Bei',
        'tech.section.location':            'Eneo',
        'tech.section.portfolio':           'Portfolio ({n})',
        'tech.section.subscriptionHistory': 'Historia ya Usajili',

        // ── Bio ───────────────────────────────────────────────────
        'tech.bio.empty': 'Hakuna wasifu uliotolewa.',

        // ── Identification ────────────────────────────────────────
        'tech.id.nida':               'NIDA:',
        'tech.id.documentType':       'Aina ya Hati:',
        'tech.id.verificationStatus': 'Hali ya Uthibitisho:',
        'tech.id.documentLabel':      'Hati ya Kitambulisho:',
        'tech.id.noDocuments':        'Hakuna hati za kitambulisho zilizopakiwa bado.',

        // ── Biometrics ────────────────────────────────────────────
        'tech.bio.view':              'Onyesha',
        'tech.bio.hide':              'Ficha',
        'tech.bio.fingerprint':       'Alama ya Kidole',
        'tech.bio.face':              'Uso',
        'tech.bio.enrolled':          'Imesajiliwa',
        'tech.bio.notEnrolled':       'Haijasajiliwa',
        'tech.bio.faceCapture':       'Picha ya Uso',
        'tech.bio.fingerprintCapture':'Data ya Alama ya Kidole',
        'tech.bio.capturedAt':        'Ilipigwa',
        'tech.bio.nextOfKin':         'Ndugu wa Karibu',
        'tech.bio.name':              'Jina:',
        'tech.bio.phone':             'Simu:',
        'tech.bio.relationship':      'Uhusiano:',
        'tech.bio.loadFailed':        'Imeshindwa kupakia data ya bayometriki.',

        // ── Services ──────────────────────────────────────────────
        'tech.service.priceRange': 'Bei: {min} – {max} TZS',
        'tech.service.none':       'Hakuna huduma zilizopangiwa.',

        // ── Location ──────────────────────────────────────────────
        'tech.location.area':         'Eneo:',
        'tech.location.coordinates':  'Kuratibu:',
        'tech.location.lastUpdate':   'Sasisho la Mwisho la Eneo:',
        'tech.location.lastActivity': 'Shughuli ya Mwisho:',

        // ── Subscription ──────────────────────────────────────────
        'tech.sub.plan':          'Mpango: {name}',
        'tech.sub.statusLabel':   'Hali:',
        'tech.sub.amount':        'Kiasi: {amount} {currency}',
        'tech.sub.start':         'Kuanza:',
        'tech.sub.expiry':        'Kuisha:',
        'tech.sub.payment':       'Malipo:',
        'tech.sub.currentStatus': 'Hali ya Sasa:',
        'tech.sub.currentExpiry': 'Kuisha kwa Sasa:',
        'tech.sub.none':          'Hakuna rekodi za usajili zilizopatikana.',

        // ── Approve dialog ────────────────────────────────────────
        'tech.approve.title':             'Idhinisha Fundi',
        'tech.approve.confirmMsg':        'Una uhakika unataka kumuidhinisha',
        'tech.approve.thisTechnician':    'fundi huyu',
        'tech.approve.freeTrialNote':     'Hii itawasha',
        'tech.approve.freeTrialDays':     'jaribio la bure la siku 1',
        'tech.approve.freeTrialEnd':      'usajili.',
        'tech.approve.processing':        'Inaidhinisha...',
        'tech.approve.processingBtn':     'Inachakata...',
        'tech.approve.confirmBtn':        'Ndiyo, Idhinisha',
        'tech.approve.successMsg':        'Fundi ameidhinishwa kwa mafanikio! Jaribio la bure limewashwa.',
        'tech.approve.failedMsg':         'Uidhinishaji umeshindikana.',
        'tech.approve.errorMsg':          'Hitilafu imetokea wakati wa uidhinishaji.',
        'tech.approve.snackbarSuccess':   'Fundi ameidhinishwa kwa mafanikio!',

        // ── List ──────────────────────────────────────────────────
        'tech.list.accessDenied':              'Huna ruhusa kuona mafundi.',
        'tech.list.title':                     'Usimamizi wa Mafundi',
        'tech.list.subtitle':                  'Simamia wasifu na uthibitisho wa mafundi',
        'tech.list.searchPlaceholder':         'Tafuta mafundi...',
        'tech.list.serviceFilterPlaceholder':  'Chuja kwa huduma...',
        'tech.list.noFound':                   'Hakuna mafundi walipatikana',
        'tech.list.stat.total':                'Jumla ya Mafundi',
        'tech.list.stat.verified':             'Imethibitishwa',
        'tech.list.stat.pending':              'Inasubiri',
        'tech.list.stat.services':             'Huduma',
        'tech.list.col.technician':            'Fundi',
        'tech.list.col.services':              'Huduma',
        'tech.list.col.location':              'Eneo',
        'tech.list.col.rating':                'Kiwango',
        'tech.list.col.status':                'Hali',
        'tech.list.serviceCount':              'huduma {n}',
        'tech.list.yearsExperience':           'uzoefu wa miaka {n}',
        'tech.list.ratePerHour':               '{rate} TZS/saa',
        'tech.list.noRating':                  'Hakuna kiwango',
        'tech.list.tab.pending':               'Usajili Mpya',
        'tech.list.tab.approved':              'Mafundi Walioidhinishwa',
        'tech.list.retry':                     'Jaribu Tena',
    },
};

export function tTech(language, key, replacements) {
    let str =
        techniciansTranslations[language]?.[key] ||
        techniciansTranslations.en?.[key] ||
        key;

    if (replacements) {
        Object.entries(replacements).forEach(([k, v]) => {
            str = str.replace(new RegExp(`\\{${k}\\}`, 'g'), v);
        });
    }
    return str;
}