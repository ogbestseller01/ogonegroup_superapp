// src/components/LanguageSwitcher/LanguageSwitcher.js
import React, { useState } from 'react';
import {
    IconButton,
    Menu,
    MenuItem,
    Tooltip,
    Box,
    Typography,
} from '@mui/material';
import { useLanguage } from 'context/LanguageContext';

// Inline SVG flags — no network required
const UKFlag = ({ size = 24 }) => (
    <svg
        width={size}
        height={size * 0.6}
        viewBox="0 0 60 36"
        xmlns="http://www.w3.org/2000/svg"
        style={{ borderRadius: 2, display: 'block' }}
    >
        <rect width="60" height="36" fill="#012169" />
        <path d="M0,0 L60,36 M60,0 L0,36" stroke="#fff" strokeWidth="7" />
        <path d="M0,0 L60,36 M60,0 L0,36" stroke="#C8102E" strokeWidth="4" />
        <path d="M30,0 V36 M0,18 H60" stroke="#fff" strokeWidth="12" />
        <path d="M30,0 V36 M0,18 H60" stroke="#C8102E" strokeWidth="7" />
    </svg>
);

const TanzaniaFlag = ({ size = 24 }) => (
    <svg
        width={size}
        height={size * 0.6}
        viewBox="0 0 60 36"
        xmlns="http://www.w3.org/2000/svg"
        style={{ borderRadius: 2, display: 'block' }}
    >
        <rect width="60" height="36" fill="#1EB53A" />
        <path d="M0,36 L60,0 L60,36 Z" fill="#00A3DD" />
        <path d="M0,36 L60,0" stroke="#000" strokeWidth="9" />
        <path d="M0,36 L60,0" stroke="#FCD116" strokeWidth="11" />
        <path d="M0,36 L60,0" stroke="#000" strokeWidth="7" />
    </svg>
);

const FLAG_COMPONENTS = {
    en: UKFlag,
    sw: TanzaniaFlag,
};

const LanguageSwitcher = ({
                              iconColor = 'rgba(255, 255, 255, 0.7)',
                              showLabel = false,
                              size = 'medium',
                          }) => {
    const { language, setLanguage, t } = useLanguage();
    const [anchorEl, setAnchorEl] = useState(null);
    const open = Boolean(anchorEl);

    const handleClick = (event) => {
        setAnchorEl(event.currentTarget);
    };

    const handleClose = () => {
        setAnchorEl(null);
    };

    const handleLanguageChange = (lang) => {
        setLanguage(lang);
        handleClose();
    };

    const flagSize = size === 'small' ? 20 : size === 'large' ? 32 : 24;
    const CurrentFlag = FLAG_COMPONENTS[language] || UKFlag;

    return (
        <>
            <Tooltip title={t('language.select')}>
                <IconButton
                    onClick={handleClick}
                    size={size}
                    aria-label="change language"
                    aria-controls={open ? 'language-menu' : undefined}
                    aria-haspopup="true"
                    aria-expanded={open ? 'true' : undefined}
                    sx={{
                        color: iconColor,
                        display: 'flex',
                        alignItems: 'center',
                        gap: 0.5,
                    }}
                >
                    <Box
                        sx={{
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            overflow: 'hidden',
                            borderRadius: 0.5,
                            boxShadow: '0 1px 3px rgba(0,0,0,0.2)',
                        }}
                    >
                        <CurrentFlag size={flagSize} />
                    </Box>
                    {showLabel && (
                        <Typography variant="body2" sx={{ ml: 0.5 }}>
                            {language === 'en' ? 'EN' : 'SW'}
                        </Typography>
                    )}
                </IconButton>
            </Tooltip>

            <Menu
                id="language-menu"
                anchorEl={anchorEl}
                open={open}
                onClose={handleClose}
                MenuListProps={{ 'aria-labelledby': 'language-button' }}
                anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
                transformOrigin={{ vertical: 'top', horizontal: 'right' }}
            >
                <MenuItem
                    onClick={() => handleLanguageChange('en')}
                    selected={language === 'en'}
                    sx={{ gap: 1.5, minWidth: 160 }}
                >
                    <UKFlag size={24} />
                    <Typography variant="body2">{t('language.english')}</Typography>
                </MenuItem>
                <MenuItem
                    onClick={() => handleLanguageChange('sw')}
                    selected={language === 'sw'}
                    sx={{ gap: 1.5, minWidth: 160 }}
                >
                    <TanzaniaFlag size={24} />
                    <Typography variant="body2">{t('language.swahili')}</Typography>
                </MenuItem>
            </Menu>
        </>
    );
};

export default LanguageSwitcher;