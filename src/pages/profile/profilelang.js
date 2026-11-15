export const profileTranslations = {
    en: {
        'profile.title': 'My Profile',
        'profile.edit': 'Edit Profile',
        'profile.save': 'Save',
        'profile.cancel': 'Cancel',
        'profile.fullName': 'Full Name',
        'profile.phone': 'Phone',
        'profile.email': 'Email',
        'profile.role': 'Role',
        'profile.updateSuccess': 'Profile updated successfully',
        'profile.updateFailed': 'Failed to update profile',

        'profile.password.title': 'Change Password',
        'profile.password.current': 'Current Password',
        'profile.password.new': 'New Password',
        'profile.password.confirm': 'Confirm Password',
        'profile.password.change': 'Change Password',
        'profile.password.mismatch': 'New passwords do not match',
        'profile.password.success': 'Password changed successfully',
        'profile.password.failed': 'Password change failed',
    },
    sw: {
        'profile.title': 'Wasifu Wangu',
        'profile.edit': 'Hariri Wasifu',
        'profile.save': 'Hifadhi',
        'profile.cancel': 'Ghairi',
        'profile.fullName': 'Jina Kamili',
        'profile.phone': 'Simu',
        'profile.email': 'Barua Pepe',
        'profile.role': 'Wadhifa',
        'profile.updateSuccess': 'Wasifu umesasishwa kikamilifu',
        'profile.updateFailed': 'Imeshindwa kusasisha wasifu',

        'profile.password.title': 'Badilisha Nenosiri',
        'profile.password.current': 'Nenosiri la Sasa',
        'profile.password.new': 'Nenosiri Jipya',
        'profile.password.confirm': 'Thibitisha Nenosiri',
        'profile.password.change': 'Badilisha Nenosiri',
        'profile.password.mismatch': 'Nenosiri mpya hayalingani',
        'profile.password.success': 'Nenosiri limebadilishwa kikamilifu',
        'profile.password.failed': 'Imeshindwa kubadilisha nenosiri',
    },
};

export function tProfile(language, key) {
    return (
        profileTranslations[language]?.[key] ||
        profileTranslations.en?.[key] ||
        key
    );
}