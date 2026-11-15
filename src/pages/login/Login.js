// src/pages/login/Login.js
import { useState, useEffect, useRef } from 'react';
import {
    Box, Paper, TextField, Button, Typography, InputAdornment,
    CircularProgress, Checkbox, FormControlLabel, Link, alpha,
    ToggleButton, ToggleButtonGroup, MenuItem,
    Autocomplete, Tooltip, IconButton, Popover,
} from '@mui/material';
import {
    LockOutlined, SmsOutlined, EmailOutlined,
    PhoneOutlined, AlternateEmail,
    Palette as PaletteIcon,
    Check as CheckIcon,
    Visibility, VisibilityOff, ArrowBackRounded, ErrorOutlineRounded,
    PlumbingOutlined, ElectricalServicesOutlined, FormatPaintOutlined, CarpenterOutlined,
} from '@mui/icons-material';
import { motion, AnimatePresence, MotionConfig } from 'framer-motion';
import { useNavigate } from 'react-router-dom';
import { useAuth } from 'context/AuthContext';
import { useLanguage } from 'context/LanguageContext';
import { showSnackbar } from 'utils/snackbar';
import { tLogin } from './loginlang';
import { COUNTRY_CODES } from './countryCodes';
import LanguageSwitcher from 'components/LanguageSwitcher/LanguageSwitcher';
import { useThemeKey } from 'context/ThemeContext';

/* -----------------------------------------------------------
 *  Brand palette — mobile only (Navy / Gold / Bolt / Green)
 * ----------------------------------------------------------- */
const BRAND = {
    primary:   '#001D45', // Navy 700
    secondary: '#F5C30E', // Gold 500
    accent:    '#074B83', // Bolt 800
    success:   '#0A8A6D', // Green
    info:      '#074B83',
    warning:   '#F5C30E',
};
const BRAND_LIGHT = '#0A3670'; // Navy 600
const BRAND_GRADIENT = `linear-gradient(135deg, ${BRAND_LIGHT} 0%, ${BRAND.primary} 55%, ${BRAND.accent} 100%)`;

const logo = '/assets/logo.png';
const aboutMap = '/assets/about-map.png';   // ← page-wide background image
const EASE = [0.22, 1, 0.36, 1];

/* -----------------------------------------------------------
 *  Theme options — reuse mobile brand colors
 * ----------------------------------------------------------- */
const THEME_OPTIONS = [
    { key: 'default',   color: BRAND.primary,   label: 'Navy'  },
    { key: 'secondary', color: BRAND.secondary, label: 'Gold'  },
    { key: 'success',   color: BRAND.success,   label: 'Green' },
    { key: 'dark',      color: '#000C1F',       label: 'Dark'  },
];

/* -----------------------------------------------------------
 *  Motion variants
 * ----------------------------------------------------------- */
const stepVariants = {
    enter:  (d) => ({ opacity: 0, x: 28 * d }),
    center: { opacity: 1, x: 0, transition: { duration: 0.35, ease: EASE, when: 'beforeChildren', staggerChildren: 0.06 } },
    exit:   (d) => ({ opacity: 0, x: -28 * d, transition: { duration: 0.2 } }),
};
const rise = {
    enter:  { opacity: 0, y: 12 },
    center: { opacity: 1, y: 0, transition: { duration: 0.4, ease: EASE } },
};

/* -----------------------------------------------------------
 *  Shared input / button styling
 * ----------------------------------------------------------- */
const fieldSx = {
    '& .MuiOutlinedInput-root': {
        borderRadius: 2.5,
        bgcolor: 'action.hover',
        transition: 'background-color .2s, box-shadow .2s',
        '&:hover': { bgcolor: 'action.selected' },
        '&.Mui-focused': { boxShadow: `0 0 0 4px ${alpha(BRAND.primary, 0.14)}` },
        '&.Mui-focused fieldset': { borderColor: BRAND.primary, borderWidth: 2 },
    },
    '& .MuiInputLabel-root.Mui-focused': { color: BRAND.primary },
};

const primaryBtnSx = {
    py: 1.7,
    borderRadius: 2.5,
    textTransform: 'none',
    fontWeight: 700,
    fontSize: '1rem',
    color: '#fff',
    background: BRAND_GRADIENT,
    boxShadow: `0 10px 24px -8px ${alpha(BRAND.primary, 0.7)}`,
    transition: 'box-shadow .2s, filter .2s',
    '&:hover': { filter: 'brightness(1.1)', boxShadow: `0 14px 28px -8px ${alpha(BRAND.primary, 0.85)}` },
    '&.Mui-disabled': { color: '#fff', background: BRAND_GRADIENT, opacity: 0.55 },
};

/* -----------------------------------------------------------
 *  Theme Switcher
 * ----------------------------------------------------------- */
function ThemeSwitcher() {
    const [anchorEl, setAnchorEl] = useState(null);
    const open = Boolean(anchorEl);
    const { themeKey, setThemeKey } = useThemeKey();

    const handleClose = () => setAnchorEl(null);
    const handleSelect = (key) => { setThemeKey(key); handleClose(); };

    return (
        <>
            <Tooltip title="Change theme">
                <IconButton
                    onClick={(e) => setAnchorEl(e.currentTarget)}
                    size="small"
                    aria-label="Change theme"
                    sx={{ color: '#ffffff', p: 0.75, '&:hover': { bgcolor: 'rgba(255,255,255,0.15)' } }}
                >
                    <PaletteIcon fontSize="small" />
                </IconButton>
            </Tooltip>

            <Popover
                open={open}
                anchorEl={anchorEl}
                onClose={handleClose}
                anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
                transformOrigin={{ vertical: 'top', horizontal: 'right' }}
                PaperProps={{
                    sx: {
                        mt: 1, p: 1.5, borderRadius: 3,
                        bgcolor: 'background.paper',
                        border: '1px solid', borderColor: 'divider',
                        boxShadow: '0 12px 32px rgba(0,0,0,0.18)',
                    },
                }}
            >
                <Typography
                    variant="caption"
                    fontWeight={700}
                    sx={{ display: 'block', mb: 1, color: 'text.secondary', textTransform: 'uppercase', letterSpacing: 0.5 }}
                >
                    Theme
                </Typography>
                <Box sx={{ display: 'flex', gap: 1.25 }}>
                    {THEME_OPTIONS.map((opt) => {
                        const isActive = themeKey === opt.key;
                        return (
                            <Tooltip key={opt.key} title={opt.label}>
                                <Box
                                    component={motion.button}
                                    type="button"
                                    aria-label={opt.label}
                                    aria-pressed={isActive}
                                    whileHover={{ scale: 1.12 }}
                                    whileTap={{ scale: 0.92 }}
                                    onClick={() => handleSelect(opt.key)}
                                    sx={{
                                        width: 34, height: 34, p: 0, borderRadius: '50%',
                                        bgcolor: opt.color, cursor: 'pointer',
                                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                                        border: '2px solid #fff',
                                        outline: isActive ? `2px solid ${BRAND.primary}` : '1px solid rgba(0,0,0,0.12)',
                                        outlineOffset: 1,
                                    }}
                                >
                                    {isActive && <CheckIcon sx={{ fontSize: 18, color: '#fff' }} />}
                                </Box>
                            </Tooltip>
                        );
                    })}
                </Box>
            </Popover>
        </>
    );
}

/* -----------------------------------------------------------
 *  Animated page background:
 *  about-map.png (faded, page-wide) + drifting glow orbs + dot grid
 * ----------------------------------------------------------- */
const ORBS = [
    { size: 520, top: '-12%', left: '-8%',  color: '#001D45', dur: 18, dx: 60,  dy: 40 },
    { size: 440, top: '55%',  left: '70%',  color: '#074B83', dur: 22, dx: -50, dy: -30 },
    { size: 360, top: '10%',  left: '62%',  color: '#F5C30E', dur: 26, dx: -40, dy: 50 },
];

function BackgroundFX() {
    return (
        <Box aria-hidden sx={{ position: 'absolute', inset: 0, overflow: 'hidden', pointerEvents: 'none' }}>
            {/* ---- Map image layer (page-wide, faded) ---- */}
            <Box
                sx={{
                    position: 'absolute',
                    inset: 0,
                    backgroundImage: `url(${aboutMap})`,
                    backgroundSize: 'cover',
                    backgroundPosition: 'center',
                    backgroundRepeat: 'no-repeat',
                    // Different fade per theme
                    opacity: (theme) => theme.palette.mode === 'dark' ? 0.35 : 0.28,
                    filter: 'saturate(0.85)',
                }}
            />

            {/* ---- Navy veil so the map doesn't overpower the card ---- */}
            <Box
                sx={{
                    position: 'absolute',
                    inset: 0,
                    background: (theme) => theme.palette.mode === 'dark'
                        ? `linear-gradient(135deg, ${alpha('#00050F', 0.82)} 0%, ${alpha('#000C1F', 0.78)} 50%, ${alpha('#001533', 0.82)} 100%)`
                        : `linear-gradient(135deg, ${alpha(BRAND.primary, 0.72)} 0%, ${alpha(BRAND.accent, 0.66)} 50%, ${alpha(BRAND_LIGHT, 0.72)} 100%)`,
                }}
            />

            {/* ---- Soft drifting glow orbs ---- */}
            {ORBS.map((o, i) => (
                <motion.div
                    key={i}
                    animate={{ x: [0, o.dx, 0], y: [0, o.dy, 0] }}
                    transition={{ duration: o.dur, repeat: Infinity, ease: 'easeInOut' }}
                    style={{
                        position: 'absolute', top: o.top, left: o.left,
                        width: o.size, height: o.size, borderRadius: '50%',
                        background: o.color, opacity: 0.28, filter: 'blur(90px)',
                    }}
                />
            ))}

            {/* ---- Dot grid on top ---- */}
            <Box sx={{
                position: 'absolute', inset: 0,
                backgroundImage: 'radial-gradient(rgba(255,255,255,0.13) 1px, transparent 1px)',
                backgroundSize: '26px 26px',
                maskImage: 'radial-gradient(ellipse at center, #000 20%, transparent 80%)',
                WebkitMaskImage: 'radial-gradient(ellipse at center, #000 20%, transparent 80%)',
            }} />
        </Box>
    );
}

/* -----------------------------------------------------------
 *  Floating phone mockup (side decorations, large screens only)
 * ----------------------------------------------------------- */
function PhoneMockup({ src, side, rotate, floatDelay = 0 }) {
    const from = side === 'left' ? -90 : 90;
    return (
        <Box sx={{ display: { xs: 'none', lg: 'block' }, width: { lg: 210, xl: 250 }, flexShrink: 0 }}>
            <motion.div
                initial={{ opacity: 0, x: from, rotate: rotate + from * 0.1 }}
                animate={{ opacity: 1, x: 0, rotate }}
                transition={{ type: 'spring', stiffness: 70, damping: 15, delay: 0.4 }}
            >
                <motion.div
                    animate={{ y: [0, -14, 0] }}
                    transition={{ duration: 6, repeat: Infinity, ease: 'easeInOut', delay: floatDelay }}
                >
                    <Box
                        component="img"
                        src={src}
                        alt="NearbyFundi"
                        sx={{ width: '100%', display: 'block', borderRadius: 5, boxShadow: '0 30px 60px rgba(0,0,0,0.45)' }}
                    />
                </motion.div>
            </motion.div>
        </Box>
    );
}

/* -----------------------------------------------------------
 *  Branding panel decorations
 * ----------------------------------------------------------- */
const TRADES = [PlumbingOutlined, ElectricalServicesOutlined, FormatPaintOutlined, CarpenterOutlined];

function PulseRings() {
    return (
        <Box aria-hidden sx={{ position: 'absolute', top: -10, right: -10, width: 200, height: 200, pointerEvents: 'none' }}>
            {[0, 1.2, 2.4].map((delay) => (
                <motion.div
                    key={delay}
                    initial={{ scale: 0.3, opacity: 0 }}
                    animate={{ scale: [0.3, 1.6], opacity: [0.45, 0] }}
                    transition={{ duration: 3.6, repeat: Infinity, ease: 'easeOut', delay }}
                    style={{
                        position: 'absolute', inset: 0, borderRadius: '50%',
                        border: '1.5px solid rgba(255,255,255,0.6)',
                    }}
                />
            ))}
            <Box sx={{ position: 'absolute', left: '50%', top: '50%', width: 10, height: 10, ml: '-5px', mt: '-5px', borderRadius: '50%', bgcolor: '#fff', opacity: 0.8 }} />
        </Box>
    );
}

/* -----------------------------------------------------------
 *  6-box OTP input (typing, backspace, arrows, paste, autofill)
 * ----------------------------------------------------------- */
function OtpInput({ value, onChange, length = 6, hasError }) {
    const refs = useRef([]);
    const focusAt = (i) => refs.current[Math.max(0, Math.min(length - 1, i))]?.focus();

    const handleChange = (i, e) => {
        const d = e.target.value.replace(/\D/g, '');
        if (!d) return;
        onChange((value.slice(0, i) + d + value.slice(i + 1)).slice(0, length));
        focusAt(i + d.length);
    };

    const handleKeyDown = (i, e) => {
        if (e.key === 'Backspace') {
            e.preventDefault();
            if (value[i]) {
                onChange(value.slice(0, i) + value.slice(i + 1));
            } else if (i > 0) {
                onChange(value.slice(0, i - 1) + value.slice(i));
                focusAt(i - 1);
            }
        } else if (e.key === 'ArrowLeft') {
            e.preventDefault(); focusAt(i - 1);
        } else if (e.key === 'ArrowRight') {
            e.preventDefault(); focusAt(i + 1);
        }
    };

    const handlePaste = (e) => {
        e.preventDefault();
        const d = e.clipboardData.getData('text').replace(/\D/g, '').slice(0, length);
        if (!d) return;
        onChange(d);
        focusAt(d.length);
    };

    return (
        <Box sx={{ display: 'flex', gap: { xs: 1, sm: 1.5 }, justifyContent: 'space-between' }}>
            {Array.from({ length }, (_, i) => {
                const filled = Boolean(value[i]);
                return (
                    <Box
                        key={i}
                        component="input"
                        ref={(el) => { refs.current[i] = el; }}
                        value={value[i] || ''}
                        onChange={(e) => handleChange(i, e)}
                        onKeyDown={(e) => handleKeyDown(i, e)}
                        onPaste={handlePaste}
                        onFocus={(e) => e.target.select()}
                        inputMode="numeric"
                        autoComplete={i === 0 ? 'one-time-code' : 'off'}
                        autoFocus={i === 0}
                        aria-label={`Digit ${i + 1}`}
                        maxLength={length}
                        sx={{
                            flex: 1, minWidth: 0, maxWidth: 56, height: { xs: 52, sm: 60 },
                            textAlign: 'center', fontSize: '1.5rem', fontWeight: 700,
                            fontFamily: 'inherit', color: 'text.primary',
                            borderRadius: 2.5, outline: 'none', border: '2px solid',
                            borderColor: hasError ? 'error.main' : filled ? BRAND.primary : 'divider',
                            bgcolor: filled ? alpha(BRAND.primary, 0.08) : 'action.hover',
                            transition: 'border-color .15s, background-color .15s, box-shadow .15s, transform .15s',
                            '&:focus': {
                                borderColor: BRAND.primary,
                                boxShadow: `0 0 0 4px ${alpha(BRAND.primary, 0.16)}`,
                                transform: 'translateY(-2px)',
                            },
                        }}
                    />
                );
            })}
        </Box>
    );
}

/* -----------------------------------------------------------
 *  Inline error
 * ----------------------------------------------------------- */
function ErrorMessage({ error }) {
    return (
        <AnimatePresence initial={false}>
            {error && (
                <motion.div
                    key={error}
                    initial={{ opacity: 0, height: 0 }}
                    animate={{ opacity: 1, height: 'auto', x: [0, -6, 6, -4, 4, 0] }}
                    exit={{ opacity: 0, height: 0 }}
                    transition={{ duration: 0.35 }}
                    style={{ overflow: 'hidden' }}
                >
                    <Box
                        role="alert"
                        sx={{
                            mt: 1.5, px: 1.5, py: 1, borderRadius: 2,
                            display: 'flex', alignItems: 'center', gap: 1,
                            color: 'error.main', fontSize: '0.85rem', fontWeight: 600,
                            bgcolor: (t) => alpha(t.palette.error.main, 0.09),
                        }}
                    >
                        <ErrorOutlineRounded sx={{ fontSize: 18, flexShrink: 0 }} />
                        {error}
                    </Box>
                </motion.div>
            )}
        </AnimatePresence>
    );
}

/* -----------------------------------------------------------
 *  Login Page
 * ----------------------------------------------------------- */
export default function Login() {
    const navigate = useNavigate();
    const { login, requestWebOtp, verifyWebOtp, resendWebOtp, isAuthenticated } = useAuth();

    const { language } = useLanguage();
    const t = (key, replacements) => tLogin(language, key, replacements);

    const [loginMethod, setLoginMethod] = useState('email');
    const [email, setEmail] = useState('');

    const [selectedCountry, setSelectedCountry] = useState(
        COUNTRY_CODES.find(c => c.code === '+255' && c.name === 'Tanzania') || COUNTRY_CODES[0]
    );
    const [phoneNumber, setPhoneNumber] = useState('');

    const [password, setPassword] = useState('');
    const [showPassword, setShowPassword] = useState(false);
    const [rememberMe, setRememberMe] = useState(false);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    const [step, setStep] = useState('credentials');
    const [otp, setOtp] = useState('');
    const [otpMeta, setOtpMeta] = useState(null);
    const [resendCooldown, setResendCooldown] = useState(0);

    const direction = step === 'otp' ? 1 : -1;

    useEffect(() => {
        if (isAuthenticated) navigate('/app/dashboard', { replace: true });
    }, [isAuthenticated, navigate]);

    useEffect(() => {
        if (resendCooldown <= 0) return;
        const interval = setInterval(() => setResendCooldown((c) => c - 1), 1000);
        return () => clearInterval(interval);
    }, [resendCooldown]);

    const getIdentifier = () => {
        if (loginMethod === 'email') return email;
        return `${selectedCountry?.code || ''}${phoneNumber}`;
    };

    const isValidIdentifier = () => {
        if (loginMethod === 'email') return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
        return phoneNumber.replace(/\D/g, '').length >= 7;
    };

    const handleCredentialsSubmit = async (e) => {
        e.preventDefault();
        const identifier = getIdentifier();

        if (!identifier || !password) {
            setError(t('login.msg.fillAll'));
            return;
        }
        if (!isValidIdentifier()) {
            setError(loginMethod === 'email' ? t('login.msg.invalidEmail') : t('login.msg.invalidPhone'));
            return;
        }

        setLoading(true);
        setError('');

        try {
            const data = await requestWebOtp(identifier, password);
            setOtpMeta(data);
            setStep('otp');
            setResendCooldown(60);
            showSnackbar({
                type: 'success',
                message: t('login.msg.otpSent', { target: data.sent_to || t('login.msg.otpSentFallback') }),
            });
        } catch (err) {
            const msg = err?.response?.data?.message || err.message || '';

            if (
                msg.toLowerCase().includes('only available for authorized') ||
                msg.toLowerCase().includes('unauthorized role') ||
                err?.response?.status === 403
            ) {
                try {
                    await login(identifier, password);
                    showSnackbar({ type: 'success', message: t('login.msg.welcome') });
                    navigate('/app/dashboard', { replace: true });
                } catch (classicErr) {
                    setError(classicErr.message || t('login.msg.invalidCredentials'));
                    showSnackbar({ type: 'error', message: classicErr.message || t('login.msg.loginFailed') });
                }
            } else {
                setError(msg || t('login.msg.invalidCredentials'));
                showSnackbar({ type: 'error', message: msg || t('login.msg.loginFailed') });
            }
        } finally {
            setLoading(false);
        }
    };

    const handleOtpSubmit = async (e) => {
        e.preventDefault();
        if (!otp || otp.length !== 6) {
            setError(t('login.msg.enterOtp'));
            return;
        }

        setLoading(true);
        setError('');

        try {
            await verifyWebOtp(otpMeta.email || getIdentifier(), otp);
            showSnackbar({ type: 'success', message: t('login.msg.loginSuccess') });
            navigate('/app/dashboard', { replace: true });
        } catch (err) {
            setError(err.message || t('login.msg.otpInvalid'));
            showSnackbar({ type: 'error', message: err.message || t('login.msg.otpFailed') });
        } finally {
            setLoading(false);
        }
    };

    const handleResendOtp = async () => {
        if (resendCooldown > 0) return;
        setLoading(true);
        try {
            const data = await resendWebOtp(otpMeta.email || getIdentifier());
            setOtpMeta(data);
            setResendCooldown(60);
            showSnackbar({ type: 'success', message: t('login.msg.otpResent') });
        } catch (err) {
            showSnackbar({ type: 'error', message: err.message || t('login.msg.otpResendFailed') });
        } finally {
            setLoading(false);
        }
    };

    const goBackToCredentials = () => {
        setStep('credentials');
        setOtp('');
        setError('');
        setOtpMeta(null);
    };

    const handleLoginMethodChange = (event, newMethod) => {
        if (newMethod !== null) {
            setLoginMethod(newMethod);
            setError('');
        }
    };

    const submitContent = (label) => (
        <AnimatePresence mode="wait" initial={false}>
            <motion.span
                key={loading ? 'loading' : 'label'}
                initial={{ opacity: 0, y: 6 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -6 }}
                transition={{ duration: 0.15 }}
                style={{ display: 'inline-flex', alignItems: 'center' }}
            >
                {loading ? <CircularProgress size={24} color="inherit" /> : label}
            </motion.span>
        </AnimatePresence>
    );

    return (
        <MotionConfig reducedMotion="user">
            <Box
                sx={{
                    minHeight: '100dvh',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    // Solid base gradient behind everything (the map image sits in BackgroundFX on top)
                    background: (theme) => theme.palette.mode === 'dark'
                        ? 'linear-gradient(135deg, #00050F 0%, #000C1F 50%, #001533 100%)'
                        : `linear-gradient(135deg, ${BRAND.primary} 0%, ${BRAND.accent} 40%, ${BRAND_LIGHT} 100%)`,
                    px: { xs: 1.5, sm: 3 },
                    pt: { xs: 9, sm: 10, md: 3 },
                    pb: { xs: 3, md: 3 },
                    position: 'relative',
                    overflow: 'hidden',
                }}
            >
                {/* Full-page background: map + veil + orbs + grid */}
                <BackgroundFX />

                {/* Language + Theme Switcher */}
                <Box
                    component={motion.div}
                    initial={{ opacity: 0, y: -12 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.5, ease: EASE, delay: 0.2 }}
                    sx={{
                        position: 'fixed',
                        top: { xs: 12, sm: 20 },
                        right: { xs: 12, sm: 20 },
                        zIndex: 1000,
                        bgcolor: 'rgba(255,255,255,0.15)',
                        backdropFilter: 'blur(10px)',
                        WebkitBackdropFilter: 'blur(10px)',
                        borderRadius: 3,
                        p: 0.5,
                        display: 'flex',
                        alignItems: 'center',
                        gap: 0.5,
                        border: '1px solid rgba(255,255,255,0.25)',
                        boxShadow: '0 4px 16px rgba(0,0,0,0.15)',
                    }}
                >
                    <LanguageSwitcher iconColor="#ffffff" showLabel size="medium" />
                    <Box sx={{ width: '1px', height: 24, bgcolor: 'rgba(255,255,255,0.25)', mx: 0.5 }} />
                    <ThemeSwitcher />
                </Box>

                <Box
                    sx={{
                        position: 'relative',
                        zIndex: 1,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        gap: { xs: 0, lg: 4, xl: 6 },
                        width: '100%',
                        maxWidth: 1400,
                    }}
                >
                    <PhoneMockup src="/assets/mockups/phone-mockup.png" side="left" rotate={-7} />

                    {/* Card */}
                    <motion.div
                        initial={{ opacity: 0, y: 30, scale: 0.97 }}
                        animate={{ opacity: 1, y: 0, scale: 1 }}
                        transition={{ duration: 0.6, ease: EASE }}
                        style={{ width: '100%', maxWidth: 900 }}
                    >
                        <Paper
                            elevation={0}
                            sx={{
                                width: '100%',
                                borderRadius: { xs: 4, md: 5 },
                                overflow: 'hidden',
                                display: 'flex',
                                flexDirection: { xs: 'column', md: 'row' },
                                boxShadow: '0 30px 60px -12px rgba(0,0,0,0.5)',
                                bgcolor: 'background.paper',
                            }}
                        >
                            {/* ---------- Left branding panel (clean gradient, no image) ---------- */}
                            <Box
                                sx={{
                                    flex: { xs: 'none', md: '0 0 42%' },
                                    position: 'relative',
                                    overflow: 'hidden',
                                    color: '#fff',
                                    p: { xs: 2.5, sm: 3.5, md: 5 },
                                    display: 'flex',
                                    flexDirection: 'column',
                                    justifyContent: 'center',
                                    minHeight: { xs: 260, md: 580 },
                                    background: (theme) => theme.palette.mode === 'dark'
                                        ? `linear-gradient(160deg, ${BRAND.primary} 0%, ${BRAND.accent} 100%)`
                                        : `linear-gradient(160deg, ${BRAND.primary} 0%, ${BRAND.accent} 60%, ${BRAND_LIGHT} 100%)`,
                                }}
                            >
                                {/* Decorative corner circles */}
                                <Box sx={{ position: 'absolute', top: -80, right: -60, width: 280, height: 280, borderRadius: '50%', bgcolor: alpha('#fff', 0.08) }} />
                                <Box sx={{ position: 'absolute', bottom: -110, left: -80, width: 260, height: 260, borderRadius: '50%', bgcolor: alpha('#fff', 0.06) }} />
                                <PulseRings />

                                <Box sx={{
                                    position: 'relative', zIndex: 1,
                                    display: 'flex',
                                    flexDirection: { xs: 'row', md: 'column' },
                                    alignItems: { xs: 'center', md: 'flex-start' },
                                    gap: { xs: 2, md: 0 },
                                }}>
                                    {/* LOGO — bigger + visible */}
                                    <motion.div
                                        initial={{ scale: 0, rotate: -20, opacity: 0 }}
                                        animate={{ scale: 1, rotate: 0, opacity: 1 }}
                                        transition={{ type: 'spring', stiffness: 220, damping: 14, delay: 0.25 }}
                                    >
                                        <Box sx={{
                                            width: { xs: 72, md: 96 },
                                            height: { xs: 72, md: 96 },
                                            mb: { md: 3 },
                                            borderRadius: { xs: 3, md: 4 },
                                            bgcolor: 'rgba(255,255,255,0.95)',
                                            border: '1px solid rgba(255,255,255,0.4)',
                                            boxShadow: '0 8px 24px rgba(0,0,0,0.2)',
                                            display: 'flex', alignItems: 'center', justifyContent: 'center',
                                            flexShrink: 0,
                                            p: 1,
                                        }}>
                                            <Box
                                                component="img"
                                                src={logo}
                                                alt="NearbyFundi"
                                                onError={(e) => {
                                                    e.target.onerror = null;
                                                    e.target.src = `data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="72" height="72" viewBox="0 0 24 24"%3E%3Ctext x="0" y="18" font-size="18" fill="%23001D45" font-weight="bold"%3ENF%3C/text%3E%3C/svg%3E`;
                                                }}
                                                sx={{
                                                    width: { xs: 56, md: 72 },
                                                    height: { xs: 56, md: 72 },
                                                    objectFit: 'contain',
                                                    display: 'block',
                                                }}
                                            />
                                        </Box>
                                    </motion.div>

                                    <motion.div
                                        initial={{ opacity: 0, y: 16 }}
                                        animate={{ opacity: 1, y: 0 }}
                                        transition={{ duration: 0.6, ease: EASE, delay: 0.35 }}
                                    >
                                        <Typography variant="h3" fontWeight={800} sx={{ mb: 0.75, fontSize: { xs: '1.4rem', sm: '1.7rem', md: '2.5rem' }, lineHeight: 1.1, letterSpacing: '-0.02em' }}>
                                            {t('login.brand.welcome')}
                                        </Typography>
                                        <Typography variant="h6" fontWeight={700} sx={{ mb: { md: 1.5 }, fontSize: { xs: '0.95rem', md: '1.25rem' }, color: { xs: 'rgba(255,255,255,0.85)', md: '#fff' } }}>
                                            {t('login.brand.name')}
                                        </Typography>
                                        <Typography variant="body2" sx={{ color: '#f8fafc', maxWidth: 280, lineHeight: 1.7, display: { xs: 'none', md: 'block' } }}>
                                            {t('login.brand.tagline')}
                                        </Typography>
                                    </motion.div>
                                </Box>

                                {/* Trade chips */}
                                <Box sx={{ position: 'relative', zIndex: 1, display: { xs: 'none', md: 'flex' }, gap: 1.25, mt: 4 }}>
                                    {TRADES.map((Icon, i) => (
                                        <motion.div
                                            key={i}
                                            initial={{ opacity: 0, scale: 0.4, y: 12 }}
                                            animate={{ opacity: 1, scale: 1, y: 0 }}
                                            transition={{ type: 'spring', stiffness: 260, damping: 16, delay: 0.7 + i * 0.1 }}
                                            whileHover={{ y: -4, scale: 1.08 }}
                                        >
                                            <Box sx={{
                                                width: 44, height: 44, borderRadius: 3,
                                                display: 'flex', alignItems: 'center', justifyContent: 'center',
                                                bgcolor: 'rgba(255,255,255,0.14)',
                                                border: '1px solid rgba(255,255,255,0.25)',
                                                backdropFilter: 'blur(6px)', WebkitBackdropFilter: 'blur(6px)',
                                            }}>
                                                <Icon sx={{ fontSize: 22, color: '#fff' }} />
                                            </Box>
                                        </motion.div>
                                    ))}
                                </Box>
                            </Box>

                            {/* ---------- Right form panel ---------- */}
                            <Box sx={{
                                flex: 1,
                                minWidth: 0,
                                bgcolor: 'background.paper',
                                p: { xs: 3, sm: 5 },
                                display: 'flex',
                                flexDirection: 'column',
                                justifyContent: 'center',
                            }}>
                                <AnimatePresence mode="wait" custom={direction} initial={false}>
                                    {step === 'credentials' ? (
                                        <motion.div
                                            key="credentials"
                                            custom={direction}
                                            variants={stepVariants}
                                            initial="enter"
                                            animate="center"
                                            exit="exit"
                                        >
                                            <motion.div variants={rise}>
                                                <Typography variant="h4" fontWeight={800} sx={{ color: 'text.primary', mb: 0.5, letterSpacing: '-0.02em', fontSize: { xs: '1.6rem', sm: '2.125rem' } }}>
                                                    {t('login.title')}
                                                </Typography>
                                                <Typography variant="body2" sx={{ color: 'text.secondary', fontWeight: 500, mb: 3 }}>
                                                    {t('login.subtitle')}
                                                </Typography>
                                            </motion.div>

                                            {/* Email / Phone toggle */}
                                            <motion.div variants={rise}>
                                                <ToggleButtonGroup
                                                    value={loginMethod}
                                                    exclusive
                                                    onChange={handleLoginMethodChange}
                                                    aria-label="login method"
                                                    sx={{
                                                        mb: 3,
                                                        width: '100%',
                                                        display: 'flex',
                                                        gap: 1.5,
                                                        '& .MuiToggleButtonGroup-grouped': {
                                                            border: '2px solid !important',
                                                            borderColor: `${alpha(BRAND.primary, 0.25)} !important`,
                                                            borderRadius: '12px !important',
                                                            mx: 0,
                                                            '&:not(:first-of-type)': { ml: 0 },
                                                        },
                                                        '& .MuiToggleButton-root': {
                                                            flex: 1,
                                                            py: 1.2,
                                                            color: 'text.primary',
                                                            bgcolor: 'transparent',
                                                            textTransform: 'none',
                                                            fontWeight: 600,
                                                            transition: 'all 0.2s',
                                                            '&.Mui-selected': {
                                                                background: BRAND_GRADIENT,
                                                                color: '#fff',
                                                                borderColor: `${BRAND.primary} !important`,
                                                                boxShadow: `0 6px 16px -6px ${alpha(BRAND.primary, 0.7)}`,
                                                                '&:hover': { filter: 'brightness(1.1)' },
                                                            },
                                                            '&:hover': {
                                                                backgroundColor: alpha(BRAND.primary, 0.06),
                                                                borderColor: `${BRAND.primary} !important`,
                                                            },
                                                            '&:focus-visible': { outline: `2px solid ${BRAND.primary}`, outlineOffset: 2 },
                                                        },
                                                    }}
                                                >
                                                    <ToggleButton value="email" aria-label="email login">
                                                        <EmailOutlined sx={{ mr: 1, fontSize: 20 }} />
                                                        {t('login.toggle.email')}
                                                    </ToggleButton>
                                                    <ToggleButton value="phone" aria-label="phone login">
                                                        <PhoneOutlined sx={{ mr: 1, fontSize: 20 }} />
                                                        {t('login.toggle.phone')}
                                                    </ToggleButton>
                                                </ToggleButtonGroup>
                                            </motion.div>

                                            <form onSubmit={handleCredentialsSubmit} noValidate>
                                                <motion.div variants={rise}>
                                                    <AnimatePresence mode="wait" initial={false}>
                                                        {loginMethod === 'email' ? (
                                                            <motion.div
                                                                key="email"
                                                                initial={{ opacity: 0, x: -14 }}
                                                                animate={{ opacity: 1, x: 0 }}
                                                                exit={{ opacity: 0, x: 14 }}
                                                                transition={{ duration: 0.18 }}
                                                            >
                                                                <TextField
                                                                    fullWidth
                                                                    placeholder={t('login.field.emailPlaceholder')}
                                                                    label={t('login.field.emailLabel')}
                                                                    type="email"
                                                                    autoComplete="email"
                                                                    value={email}
                                                                    onChange={(e) => setEmail(e.target.value)}
                                                                    required
                                                                    autoFocus
                                                                    sx={fieldSx}
                                                                    InputProps={{
                                                                        startAdornment: (
                                                                            <InputAdornment position="start">
                                                                                <AlternateEmail sx={{ color: 'text.secondary' }} />
                                                                            </InputAdornment>
                                                                        ),
                                                                    }}
                                                                />
                                                            </motion.div>
                                                        ) : (
                                                            <motion.div
                                                                key="phone"
                                                                initial={{ opacity: 0, x: 14 }}
                                                                animate={{ opacity: 1, x: 0 }}
                                                                exit={{ opacity: 0, x: -14 }}
                                                                transition={{ duration: 0.18 }}
                                                            >
                                                                <Box sx={{ display: 'flex', gap: 1.25, alignItems: 'flex-start' }}>
                                                                    <Autocomplete
                                                                        value={selectedCountry}
                                                                        onChange={(e, newValue) => { if (newValue) setSelectedCountry(newValue); }}
                                                                        options={COUNTRY_CODES}
                                                                        getOptionLabel={(option) => `${option.flag} ${option.code}`}
                                                                        isOptionEqualToValue={(option, value) =>
                                                                            option.code === value.code && option.name === value.name
                                                                        }
                                                                        disableClearable
                                                                        autoHighlight
                                                                        sx={{
                                                                            ...fieldSx,
                                                                            width: { xs: 124, sm: 140 },
                                                                            minWidth: { xs: 124, sm: 140 },
                                                                            flexShrink: 0,
                                                                            '& .MuiOutlinedInput-root': {
                                                                                ...fieldSx['& .MuiOutlinedInput-root'],
                                                                                paddingRight: '24px !important',
                                                                            },
                                                                            '& .MuiAutocomplete-input': {
                                                                                fontWeight: 600,
                                                                                fontSize: '0.95rem',
                                                                                minWidth: '0 !important',
                                                                            },
                                                                        }}
                                                                        renderInput={(params) => (
                                                                            <TextField {...params} placeholder="+255" />
                                                                        )}
                                                                        renderOption={(props, option) => (
                                                                            <MenuItem
                                                                                {...props}
                                                                                key={`${option.name}-${option.code}`}
                                                                                sx={{
                                                                                    gap: 1.5, py: 1, fontSize: '0.9rem',
                                                                                    '&.Mui-focused, &:hover': { bgcolor: alpha(BRAND.primary, 0.08) },
                                                                                }}
                                                                            >
                                                                                <span style={{ fontSize: '1.3rem', lineHeight: 1 }}>{option.flag}</span>
                                                                                <Box sx={{ flex: 1, display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 2 }}>
                                                                                    <Typography variant="body2" sx={{ fontWeight: 500, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                                                                                        {option.name}
                                                                                    </Typography>
                                                                                    <Typography variant="body2" sx={{ fontWeight: 700, fontFamily: 'monospace', flexShrink: 0, color: BRAND.primary }}>
                                                                                        {option.code}
                                                                                    </Typography>
                                                                                </Box>
                                                                            </MenuItem>
                                                                        )}
                                                                        noOptionsText={t('login.field.noCountry') || 'No country found'}
                                                                        ListboxProps={{ sx: { maxHeight: 320, '& .MuiMenuItem-root': { minHeight: 44 } } }}
                                                                    />
                                                                    <TextField
                                                                        fullWidth
                                                                        placeholder={t('login.field.phonePlaceholder')}
                                                                        label={t('login.field.phoneLabel')}
                                                                        type="tel"
                                                                        autoComplete="tel-national"
                                                                        value={phoneNumber}
                                                                        onChange={(e) => setPhoneNumber(e.target.value.replace(/\D/g, ''))}
                                                                        required
                                                                        autoFocus
                                                                        sx={fieldSx}
                                                                        InputProps={{
                                                                            startAdornment: (
                                                                                <InputAdornment position="start">
                                                                                    <PhoneOutlined sx={{ color: 'text.secondary' }} />
                                                                                </InputAdornment>
                                                                            ),
                                                                        }}
                                                                    />
                                                                </Box>
                                                            </motion.div>
                                                        )}
                                                    </AnimatePresence>
                                                </motion.div>

                                                <motion.div variants={rise} style={{ marginTop: 20 }}>
                                                    <TextField
                                                        fullWidth
                                                        placeholder={t('login.field.passwordPlaceholder')}
                                                        label={t('login.field.passwordLabel')}
                                                        type={showPassword ? 'text' : 'password'}
                                                        autoComplete="current-password"
                                                        value={password}
                                                        onChange={(e) => setPassword(e.target.value)}
                                                        required
                                                        sx={fieldSx}
                                                        InputProps={{
                                                            startAdornment: (
                                                                <InputAdornment position="start">
                                                                    <LockOutlined sx={{ color: 'text.secondary' }} />
                                                                </InputAdornment>
                                                            ),
                                                            endAdornment: (
                                                                <InputAdornment position="end">
                                                                    <Tooltip title={showPassword ? t('login.password.hide') : t('login.password.show')}>
                                                                        <IconButton
                                                                            edge="end"
                                                                            size="small"
                                                                            onClick={() => setShowPassword(!showPassword)}
                                                                            aria-label={showPassword ? t('login.password.hide') : t('login.password.show')}
                                                                            sx={{ color: 'text.secondary', '&:hover': { color: BRAND.primary } }}
                                                                        >
                                                                            {showPassword ? <VisibilityOff fontSize="small" /> : <Visibility fontSize="small" />}
                                                                        </IconButton>
                                                                    </Tooltip>
                                                                </InputAdornment>
                                                            ),
                                                        }}
                                                    />
                                                    <ErrorMessage error={error} />
                                                </motion.div>

                                                <motion.div variants={rise}>
                                                    <Box display="flex" justifyContent="space-between" alignItems="center" flexWrap="wrap" sx={{ mt: 1, mb: 2.5 }}>
                                                        <FormControlLabel
                                                            control={
                                                                <Checkbox
                                                                    checked={rememberMe}
                                                                    onChange={(e) => setRememberMe(e.target.checked)}
                                                                    size="small"
                                                                    sx={{ '&.Mui-checked': { color: BRAND.primary } }}
                                                                />
                                                            }
                                                            label={
                                                                <Typography variant="body2" sx={{ color: 'text.secondary', fontWeight: 500 }}>
                                                                    {t('login.remember')}
                                                                </Typography>
                                                            }
                                                        />
                                                        <Link
                                                            component="button"
                                                            type="button"
                                                            underline="hover"
                                                            onClick={() => navigate('/forgot-password')}
                                                            sx={{ color: BRAND.primary, fontWeight: 600, fontSize: '0.875rem' }}
                                                        >
                                                            {t('login.forgot')}
                                                        </Link>
                                                    </Box>
                                                </motion.div>

                                                <motion.div variants={rise}>
                                                    <motion.div whileHover={{ y: -1 }} whileTap={{ scale: 0.98 }}>
                                                        <Button type="submit" fullWidth disabled={loading} sx={primaryBtnSx}>
                                                            {submitContent(t('login.submit'))}
                                                        </Button>
                                                    </motion.div>
                                                </motion.div>
                                            </form>
                                        </motion.div>
                                    ) : (
                                        <motion.div
                                            key="otp"
                                            custom={direction}
                                            variants={stepVariants}
                                            initial="enter"
                                            animate="center"
                                            exit="exit"
                                        >
                                            <motion.div variants={rise}>
                                                <Button
                                                    onClick={goBackToCredentials}
                                                    startIcon={<ArrowBackRounded />}
                                                    sx={{ textTransform: 'none', color: 'text.secondary', fontWeight: 600, ml: -1, mb: 2 }}
                                                >
                                                    {t('login.otp.back')}
                                                </Button>
                                            </motion.div>

                                            <motion.div variants={rise}>
                                                <Box sx={{
                                                    width: 52, height: 52, borderRadius: 3.5, mb: 2,
                                                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                                                    color: BRAND.primary, bgcolor: alpha(BRAND.primary, 0.1),
                                                }}>
                                                    <SmsOutlined />
                                                </Box>
                                                <Typography variant="h4" fontWeight={800} sx={{ color: 'text.primary', mb: 0.5, letterSpacing: '-0.02em', fontSize: { xs: '1.6rem', sm: '2.125rem' } }}>
                                                    {t('login.otp.title')}
                                                </Typography>
                                                <Typography variant="body2" sx={{ color: 'text.secondary', fontWeight: 500, mb: 0.5 }}>
                                                    {t('login.otp.subtitlePrefix')}{' '}
                                                    <strong>{otpMeta?.sent_to || t('login.otp.fallbackSentTo')}</strong>
                                                </Typography>
                                                <Typography variant="caption" sx={{ color: 'text.secondary', mb: 3, display: 'block' }}>
                                                    {t('login.otp.expiresIn', { min: otpMeta?.expires_in || 5 })}
                                                </Typography>
                                            </motion.div>

                                            <form onSubmit={handleOtpSubmit}>
                                                <motion.div variants={rise}>
                                                    <OtpInput value={otp} onChange={setOtp} hasError={Boolean(error)} />
                                                    <ErrorMessage error={error} />
                                                </motion.div>

                                                <motion.div variants={rise} style={{ marginTop: 24 }}>
                                                    <motion.div whileHover={{ y: -1 }} whileTap={{ scale: 0.98 }}>
                                                        <Button type="submit" fullWidth disabled={loading || otp.length !== 6} sx={primaryBtnSx}>
                                                            {submitContent(t('login.otp.submit'))}
                                                        </Button>
                                                    </motion.div>
                                                </motion.div>

                                                <motion.div variants={rise}>
                                                    <Box display="flex" justifyContent="center" sx={{ mt: 2 }}>
                                                        <Button
                                                            onClick={handleResendOtp}
                                                            disabled={resendCooldown > 0 || loading}
                                                            sx={{
                                                                textTransform: 'none', color: BRAND.primary, fontWeight: 600,
                                                                '&:hover': { bgcolor: alpha(BRAND.primary, 0.08) },
                                                                '&.Mui-disabled': { color: 'text.disabled' },
                                                            }}
                                                        >
                                                            {resendCooldown > 0
                                                                ? t('login.otp.resendIn', { s: resendCooldown })
                                                                : t('login.otp.resend')}
                                                        </Button>
                                                    </Box>
                                                </motion.div>
                                            </form>
                                        </motion.div>
                                    )}
                                </AnimatePresence>

                                <Typography variant="body2" align="center" sx={{ mt: 4, color: 'text.secondary' }}>
                                    {t('login.footer.noAccount')}{' '}
                                    <Link
                                        component="button"
                                        type="button"
                                        underline="hover"
                                        onClick={() => navigate('')}
                                        sx={{ color: BRAND.primary, fontWeight: 700 }}
                                    >
                                        {t('login.footer.signUp')}
                                    </Link>
                                </Typography>
                            </Box>
                        </Paper>
                    </motion.div>

                    <PhoneMockup src="/assets/mockups/phone-mockup1.png" side="right" rotate={7} floatDelay={1.2} />
                </Box>
            </Box>
        </MotionConfig>
    );
}