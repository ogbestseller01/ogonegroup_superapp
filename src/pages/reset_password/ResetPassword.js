// src/pages/reset_password/ResetPassword.js
import { useState, useEffect, useRef } from 'react';
import {
    Container, Paper, TextField, Button, Typography, Box, IconButton,
    InputAdornment, CircularProgress, useTheme, alpha, Grid, Alert,
} from '@mui/material';
import {
    Visibility, VisibilityOff, Lock as LockIcon,
    ArrowBack as ArrowBackIcon,
} from '@mui/icons-material';
import { useNavigate, useLocation } from 'react-router-dom';
import { useLanguage } from 'context/LanguageContext';
import { showSnackbar } from 'utils/snackbar';
import { authService } from 'services/auth.service';
import { tReset } from './resetlang';

/* -----------------------------------------------------------
 *  Mobile brand palette (Navy / Bolt / Gold / Green)
 * ----------------------------------------------------------- */
const BRAND = {
    primary:   '#001D45', // Navy 700
    secondary: '#F5C30E', // Gold 500
    accent:    '#074B83', // Bolt 800
    success:   '#0A8A6D', // Green
};
const BRAND_LIGHT = '#0A3670'; // Navy 600
const BRAND_GRADIENT = `linear-gradient(135deg, ${BRAND_LIGHT} 0%, ${BRAND.primary} 55%, ${BRAND.accent} 100%)`;

/* -----------------------------------------------------------
 *  Mobile neutrals
 * ----------------------------------------------------------- */
const TEXT_PRIMARY   = '#001D45'; // Navy 700
const TEXT_SECONDARY = '#074B83'; // Bolt 800
const TEXT_MUTED     = '#9FC0EB'; // Navy 200
const BG_DEFAULT     = '#EAF1FB'; // Navy 50
const BG_PAPER       = '#FFFFFF';
const BG_FIELD       = '#F0F7FF'; // Bolt 50
const BORDER_DEFAULT = '#9FC0EB'; // Navy 200
const BORDER_HOVER   = '#0A3670'; // Navy 600

const logo = '/assets/logo.png';

export default function ResetPassword() {
    const theme = useTheme();
    const navigate = useNavigate();
    const location = useLocation();

    // ✅ LANGUAGE
    const { language } = useLanguage();
    const t = (key, replacements) => tReset(language, key, replacements);

    // Get email from URL query parameter or state
    const queryParams = new URLSearchParams(location.search);
    const emailFromUrl = queryParams.get('email');
    const emailFromState = location.state?.email || '';
    const email = emailFromUrl || emailFromState;

    const [otp, setOtp] = useState(['', '', '', '', '', '']);
    const [password, setPassword] = useState('');
    const [confirmPassword, setConfirmPassword] = useState('');
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [showPassword, setShowPassword] = useState(false);
    const [showConfirm, setShowConfirm] = useState(false);

    const inputRefs = useRef([]);

    useEffect(() => {
        if (!email) {
            showSnackbar({ type: 'warning', message: t('reset.requestFirst') });
            navigate('/forgot-password', { replace: true });
        }
    }, [email, navigate, language]);

    useEffect(() => {
        if (inputRefs.current[0]) {
            inputRefs.current[0].focus();
        }
    }, []);

    const handleOtpChange = (index, value) => {
        if (value.length > 1) {
            const pasteData = value.slice(0, 6);
            const newOtp = [...otp];
            for (let i = 0; i < pasteData.length && i < 6; i++) {
                newOtp[i] = pasteData[i] || '';
            }
            setOtp(newOtp);
            const nextIndex = Math.min(pasteData.length, 5);
            if (inputRefs.current[nextIndex]) {
                inputRefs.current[nextIndex].focus();
            }
            return;
        }

        const newOtp = [...otp];
        newOtp[index] = value;
        setOtp(newOtp);

        if (value && index < 5) {
            inputRefs.current[index + 1].focus();
        }
    };

    const handleKeyDown = (index, e) => {
        if (e.key === 'Backspace' && !otp[index] && index > 0) {
            inputRefs.current[index - 1].focus();
        }
    };

    const handlePaste = (e) => {
        e.preventDefault();
        const pasteData = e.clipboardData.getData('text').slice(0, 6);
        if (/^\d+$/.test(pasteData)) {
            const newOtp = [...otp];
            for (let i = 0; i < pasteData.length && i < 6; i++) {
                newOtp[i] = pasteData[i];
            }
            setOtp(newOtp);
            const nextIndex = Math.min(pasteData.length, 5);
            if (inputRefs.current[nextIndex]) {
                inputRefs.current[nextIndex].focus();
            }
        }
    };

    const getOtpString = () => otp.join('');

    const handleSubmit = async (e) => {
        e.preventDefault();
        const otpString = getOtpString();

        if (password !== confirmPassword) {
            setError(t('reset.passwordsMismatch'));
            return;
        }
        if (otpString.length !== 6) {
            setError(t('reset.otpIncomplete'));
            return;
        }
        if (password.length < 8) {
            setError(t('reset.passwordTooShort'));
            return;
        }

        setLoading(true);
        setError('');

        try {
            const res = await authService.resetPassword(email, otpString, password, confirmPassword);
            if (res.data.success) {
                showSnackbar({ type: 'success', message: t('reset.success') });
                setTimeout(() => navigate('/login', { replace: true }), 2000);
            } else {
                setError(res.data.message || t('reset.resetFailed'));
            }
        } catch (err) {
            setError(err.response?.data?.message || t('reset.failed'));
        } finally {
            setLoading(false);
        }
    };

    if (!email) return null;

    return (
        <Box
            sx={{
                minHeight: '100vh',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                bgcolor: BG_DEFAULT,
                p: { xs: 2, sm: 3 },
            }}
        >
            <Container maxWidth="sm">
                <Grid container spacing={0}>
                    <Grid item xs={12}>
                        <Paper
                            elevation={0}
                            sx={{
                                p: { xs: 4, sm: 5, md: 6 },
                                borderRadius: 4,
                                boxShadow: '0 20px 60px rgba(0, 29, 69, 0.08)',
                                border: `1px solid ${alpha(BRAND.primary, 0.15)}`,
                                bgcolor: BG_PAPER,
                            }}
                        >
                            <Box textAlign="center" mb={4}>
                                <Box
                                    component="img"
                                    src={logo}
                                    alt="NearbyFundi"
                                    onError={(e) => {
                                        e.target.onerror = null;
                                        e.target.src = `data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="50" height="50" viewBox="0 0 24 24"%3E%3Ctext x="0" y="18" font-size="18" fill="%23001D45"%3ENF%3C/text%3E%3C/svg%3E`;
                                    }}
                                    sx={{ width: 50, height: 50, mx: 'auto', mb: 2 }}
                                />
                                <Typography variant="h4" fontWeight="800" gutterBottom sx={{ color: TEXT_PRIMARY }}>
                                    {t('reset.title')}
                                </Typography>
                                <Typography variant="body2" sx={{ color: TEXT_SECONDARY, fontWeight: 500 }}>
                                    {t('reset.subtitle')}{' '}
                                    <strong style={{ color: BRAND.primary, fontWeight: 700 }}>{email}</strong>
                                </Typography>
                            </Box>

                            <form onSubmit={handleSubmit}>
                                <Box sx={{ mb: 3 }}>
                                    <Typography
                                        variant="caption"
                                        display="block"
                                        sx={{ mb: 2, color: TEXT_SECONDARY, fontWeight: 600, fontSize: '0.85rem' }}
                                    >
                                        {t('reset.otpLabel')}
                                    </Typography>
                                    <Box
                                        display="flex"
                                        justifyContent="center"
                                        gap={1.5}
                                        onPaste={handlePaste}
                                    >
                                        {[0, 1, 2, 3, 4, 5].map((index) => (
                                            <TextField
                                                key={index}
                                                inputRef={(el) => (inputRefs.current[index] = el)}
                                                value={otp[index]}
                                                onChange={(e) => {
                                                    const value = e.target.value.replace(/\D/g, '');
                                                    handleOtpChange(index, value);
                                                }}
                                                onKeyDown={(e) => handleKeyDown(index, e)}
                                                inputProps={{
                                                    maxLength: 6,
                                                    style: {
                                                        textAlign: 'center',
                                                        fontSize: '1.5rem',
                                                        fontWeight: 700,
                                                        color: TEXT_PRIMARY,
                                                        width: '44px',
                                                        height: '56px',
                                                        padding: '0',
                                                    },
                                                }}
                                                sx={{
                                                    '& .MuiInputBase-root': {
                                                        borderRadius: 2,
                                                        bgcolor: BG_FIELD,
                                                        '& .MuiOutlinedInput-notchedOutline': {
                                                            borderColor: BORDER_DEFAULT,
                                                        },
                                                        '&:hover .MuiOutlinedInput-notchedOutline': {
                                                            borderColor: BRAND.primary,
                                                        },
                                                        '&.Mui-focused .MuiOutlinedInput-notchedOutline': {
                                                            borderColor: BRAND.primary,
                                                            borderWidth: 2,
                                                        },
                                                    },
                                                    width: '52px',
                                                }}
                                            />
                                        ))}
                                    </Box>
                                    <Typography
                                        variant="caption"
                                        display="block"
                                        sx={{ mt: 1, textAlign: 'center', color: TEXT_SECONDARY, fontWeight: 500 }}
                                    >
                                        {t('reset.otpHint')}
                                    </Typography>
                                </Box>

                                <TextField
                                    fullWidth
                                    label={t('reset.newPassword')}
                                    type={showPassword ? 'text' : 'password'}
                                    value={password}
                                    onChange={(e) => setPassword(e.target.value)}
                                    required
                                    sx={{
                                        mb: 2,
                                        '& .MuiInputLabel-root': {
                                            color: TEXT_SECONDARY,
                                            fontWeight: 500,
                                            '&.Mui-focused': { color: BRAND.primary },
                                        },
                                        '& .MuiInputBase-root': {
                                            borderRadius: 2,
                                            py: 0.5,
                                            bgcolor: BG_FIELD,
                                            color: TEXT_PRIMARY,
                                            fontWeight: 500,
                                        },
                                        '& .MuiOutlinedInput-notchedOutline': {
                                            borderColor: BORDER_DEFAULT,
                                        },
                                        '&:hover .MuiOutlinedInput-notchedOutline': {
                                            borderColor: BORDER_HOVER,
                                        },
                                        '& .MuiFormHelperText-root': {
                                            color: TEXT_SECONDARY,
                                            fontWeight: 500,
                                        },
                                    }}
                                    InputProps={{
                                        startAdornment: (
                                            <InputAdornment position="start">
                                                <LockIcon sx={{ color: TEXT_SECONDARY }} fontSize="small" />
                                            </InputAdornment>
                                        ),
                                        endAdornment: (
                                            <InputAdornment position="end">
                                                <IconButton
                                                    onClick={() => setShowPassword(!showPassword)}
                                                    edge="end"
                                                    size="small"
                                                    sx={{ color: BRAND.primary }}
                                                >
                                                    {showPassword ? <VisibilityOff /> : <Visibility />}
                                                </IconButton>
                                            </InputAdornment>
                                        ),
                                    }}
                                    helperText={t('reset.passwordHelper')}
                                />

                                <TextField
                                    fullWidth
                                    label={t('reset.confirmPassword')}
                                    type={showConfirm ? 'text' : 'password'}
                                    value={confirmPassword}
                                    onChange={(e) => setConfirmPassword(e.target.value)}
                                    required
                                    sx={{
                                        mb: 1,
                                        '& .MuiInputLabel-root': {
                                            color: TEXT_SECONDARY,
                                            fontWeight: 500,
                                            '&.Mui-focused': { color: BRAND.primary },
                                        },
                                        '& .MuiInputBase-root': {
                                            borderRadius: 2,
                                            py: 0.5,
                                            bgcolor: BG_FIELD,
                                            color: TEXT_PRIMARY,
                                            fontWeight: 500,
                                        },
                                        '& .MuiOutlinedInput-notchedOutline': {
                                            borderColor: BORDER_DEFAULT,
                                        },
                                        '&:hover .MuiOutlinedInput-notchedOutline': {
                                            borderColor: BORDER_HOVER,
                                        },
                                    }}
                                    InputProps={{
                                        startAdornment: (
                                            <InputAdornment position="start">
                                                <LockIcon sx={{ color: TEXT_SECONDARY }} fontSize="small" />
                                            </InputAdornment>
                                        ),
                                        endAdornment: (
                                            <InputAdornment position="end">
                                                <IconButton
                                                    onClick={() => setShowConfirm(!showConfirm)}
                                                    edge="end"
                                                    size="small"
                                                    sx={{ color: BRAND.primary }}
                                                >
                                                    {showConfirm ? <VisibilityOff /> : <Visibility />}
                                                </IconButton>
                                            </InputAdornment>
                                        ),
                                    }}
                                />

                                {error && (
                                    <Alert severity="error" sx={{ mt: 2, fontWeight: 600 }}>
                                        {error}
                                    </Alert>
                                )}

                                <Button
                                    type="submit"
                                    fullWidth
                                    variant="contained"
                                    disabled={loading}
                                    sx={{
                                        mt: 3,
                                        py: 1.8,
                                        fontSize: '1.1rem',
                                        fontWeight: 700,
                                        borderRadius: 2,
                                        textTransform: 'none',
                                        background: BRAND_GRADIENT,
                                        color: '#ffffff',
                                        '&:hover': {
                                            transform: 'translateY(-2px)',
                                            boxShadow: 4,
                                            background: `linear-gradient(135deg, ${BRAND.primary} 0%, ${BRAND.accent} 100%)`,
                                        },
                                    }}
                                >
                                    {loading ? <CircularProgress size={24} color="inherit" /> : t('reset.submit')}
                                </Button>

                                <Button
                                    fullWidth
                                    variant="text"
                                    startIcon={<ArrowBackIcon />}
                                    onClick={() => navigate('/forgot-password')}
                                    sx={{ mt: 2, textTransform: 'none', color: BRAND.primary, fontWeight: 700 }}
                                >
                                    {t('reset.back')}
                                </Button>
                            </form>
                        </Paper>
                    </Grid>
                </Grid>
            </Container>
        </Box>
    );
}