// src/pages/forgot_password/forgotlang.js

export const authTranslations = {
    en: {
        // ── Common ────────────────────────────────────────────────
        'auth.common.emailRequired': 'Email is required',

        // ── Forgot Password ───────────────────────────────────────
        'auth.forgot.title': 'Forgot Password?',
        'auth.forgot.subtitle': 'Enter your email to receive a password reset OTP',
        'auth.forgot.emailLabel': 'Email Address',
        'auth.forgot.submit': 'Send Reset OTP',
        'auth.forgot.backToLogin': 'Back to Login',
        'auth.forgot.otpSent': 'OTP sent to your email! 📧',
        'auth.forgot.sendFailed': 'Failed to send OTP',
    },

    sw: {
        // ── Common ────────────────────────────────────────────────
        'auth.common.emailRequired': 'Barua pepe inahitajika',

        // ── Forgot Password ───────────────────────────────────────
        'auth.forgot.title': 'Umesahau Nenosiri?',
        'auth.forgot.subtitle': 'Weka barua pepe yako kupokea OTP ya kuweka upya nenosiri',
        'auth.forgot.emailLabel': 'Anwani ya Barua Pepe',
        'auth.forgot.submit': 'Tuma OTP ya Kuweka Upya',
        'auth.forgot.backToLogin': 'Rudi kwenye Kuingia',
        'auth.forgot.otpSent': 'OTP imetumwa kwenye barua pepe yako! 📧',
        'auth.forgot.sendFailed': 'Imeshindwa kutuma OTP',
    },
};

export function tAuth(language, key, replacements) {
    let str =
        authTranslations[language]?.[key] ||
        authTranslations.en?.[key] ||
        key;
    if (replacements) {
        Object.entries(replacements).forEach(([k, v]) => {
            str = str.replace(new RegExp(`\\{${k}\\}`, 'g'), v);
        });
    }
    return str;
}