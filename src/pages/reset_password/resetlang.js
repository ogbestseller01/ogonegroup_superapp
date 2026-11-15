// src/pages/reset_password/resetlang.js

export const resetTranslations = {
    en: {
        // ── Reset Password ────────────────────────────────────────
        'reset.title': 'Reset Password',
        'reset.subtitle': 'Enter the OTP sent to',
        'reset.otpLabel': 'Enter 6-digit OTP',
        'reset.otpHint': 'Check your email for the OTP code',
        'reset.newPassword': 'New Password',
        'reset.confirmPassword': 'Confirm Password',
        'reset.passwordHelper': 'Minimum 8 characters',
        'reset.submit': 'Reset Password',
        'reset.back': 'Back',

        // ── Messages ──────────────────────────────────────────────
        'reset.requestFirst': 'Please request a password reset first',
        'reset.passwordsMismatch': 'Passwords do not match',
        'reset.otpIncomplete': 'Please enter all 6 digits of OTP',
        'reset.passwordTooShort': 'Password must be at least 8 characters',
        'reset.success': 'Password reset successful! 🎉',
        'reset.failed': 'Password reset failed',
        'reset.resetFailed': 'Reset failed',
    },

    sw: {
        // ── Reset Password ────────────────────────────────────────
        'reset.title': 'Weka Upya Nenosiri',
        'reset.subtitle': 'Weka OTP iliyotumwa kwa',
        'reset.otpLabel': 'Weka OTP ya tarakimu 6',
        'reset.otpHint': 'Angalia barua pepe yako kwa msimbo wa OTP',
        'reset.newPassword': 'Nenosiri Jipya',
        'reset.confirmPassword': 'Thibitisha Nenosiri',
        'reset.passwordHelper': 'Angalau herufi 8',
        'reset.submit': 'Weka Upya Nenosiri',
        'reset.back': 'Rudi',

        // ── Messages ──────────────────────────────────────────────
        'reset.requestFirst': 'Tafadhali omba kuweka upya nenosiri kwanza',
        'reset.passwordsMismatch': 'Nenosiri hazilingani',
        'reset.otpIncomplete': 'Tafadhali weka tarakimu zote 6 za OTP',
        'reset.passwordTooShort': 'Nenosiri lazima liwe na angalau herufi 8',
        'reset.success': 'Nenosiri limewekwa upya kwa mafanikio! 🎉',
        'reset.failed': 'Kuweka upya nenosiri kimeshindikana',
        'reset.resetFailed': 'Kuweka upya kimeshindikana',
    },
};

export function tReset(language, key, replacements) {
    let str =
        resetTranslations[language]?.[key] ||
        resetTranslations.en?.[key] ||
        key;
    if (replacements) {
        Object.entries(replacements).forEach(([k, v]) => {
            str = str.replace(new RegExp(`\\{${k}\\}`, 'g'), v);
        });
    }
    return str;
}