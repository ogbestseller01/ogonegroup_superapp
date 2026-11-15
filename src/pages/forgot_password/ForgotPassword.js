// src/pages/auth/ForgotPassword.jsx
import { useState } from 'react';
import {
    Container, Paper, TextField, Button, Typography, Box,
    CircularProgress, useTheme, alpha, InputAdornment, Grid,
} from '@mui/material';
import { Email as EmailIcon, ArrowBack as ArrowBackIcon } from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import { useLanguage } from 'context/LanguageContext';
import { showSnackbar } from 'utils/snackbar';
import { authService } from 'services/auth.service';
import { tAuth } from './forgotlang';

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
const BG_DEFAULT     = '#EAF1FB'; // Navy 50
const BG_PAPER       = '#FFFFFF';
const BG_FIELD       = '#F0F7FF'; // Bolt 50
const BORDER_DEFAULT = '#9FC0EB'; // Navy 200
const BORDER_HOVER   = '#0A3670'; // Navy 600

const logo = '/assets/logo.png';

export default function ForgotPassword() {
    const theme = useTheme();
    const navigate = useNavigate();

    const { language } = useLanguage();
    const t = (key, replacements) => tAuth(language, key, replacements);

    const [email, setEmail] = useState('');
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    const handleSubmit = async (e) => {
        e.preventDefault();
        if (!email) {
            setError(t('auth.common.emailRequired'));
            return;
        }
        setLoading(true);
        setError('');
        try {
            const res = await authService.forgotPassword(email);
            if (res.data.success) {
                showSnackbar({ type: 'success', message: t('auth.forgot.otpSent') });
                // ✅ Pass email to reset password page
                navigate('/reset-password', { state: { email: email }, replace: true });
            } else {
                setError(res.data.message || t('auth.forgot.sendFailed'));
            }
        } catch (err) {
            setError(err.response?.data?.message || t('auth.forgot.sendFailed'));
        } finally {
            setLoading(false);
        }
    };

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
                                    {t('auth.forgot.title')}
                                </Typography>
                                <Typography variant="body2" sx={{ color: TEXT_SECONDARY, fontWeight: 500 }}>
                                    {t('auth.forgot.subtitle')}
                                </Typography>
                            </Box>

                            <form onSubmit={handleSubmit}>
                                <TextField
                                    fullWidth
                                    label={t('auth.forgot.emailLabel')}
                                    type="email"
                                    value={email}
                                    onChange={(e) => setEmail(e.target.value)}
                                    required
                                    autoFocus
                                    sx={{
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
                                        '&.Mui-focused .MuiOutlinedInput-notchedOutline': {
                                            borderColor: BRAND.primary,
                                        },
                                    }}
                                    InputProps={{
                                        startAdornment: (
                                            <InputAdornment position="start">
                                                <EmailIcon sx={{ color: TEXT_SECONDARY }} fontSize="small" />
                                            </InputAdornment>
                                        ),
                                    }}
                                />

                                {error && (
                                    <Typography color="error" variant="body2" sx={{ mt: 2, fontWeight: 600 }}>
                                        {error}
                                    </Typography>
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
                                    {loading ? <CircularProgress size={24} color="inherit" /> : t('auth.forgot.submit')}
                                </Button>

                                <Button
                                    fullWidth
                                    variant="text"
                                    startIcon={<ArrowBackIcon />}
                                    onClick={() => navigate('/login')}
                                    sx={{ mt: 2, textTransform: 'none', color: BRAND.primary, fontWeight: 700 }}
                                >
                                    {t('auth.forgot.backToLogin')}
                                </Button>
                            </form>
                        </Paper>
                    </Grid>
                </Grid>
            </Container>
        </Box>
    );
}