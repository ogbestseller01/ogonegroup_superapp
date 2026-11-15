// src/pages/sms/SendSmsDialog.jsx
import React, { useState, useEffect } from 'react';
import {
    Dialog, DialogTitle, DialogContent, DialogActions, Button, TextField,
    Box, Typography, CircularProgress, FormControl, InputLabel, Select,
    MenuItem, Chip, Alert, IconButton, InputAdornment,
} from '@mui/material';
import { Close as CloseIcon, Send as SendIcon } from '@mui/icons-material';
import { useUserManagement } from 'hooks/useUser';
import { useLanguage } from 'context/LanguageContext';
import { tSms } from './smslang';
import appConfig from '../../config';

const colors = appConfig.app.colors;

const SendSmsDialog = ({ open, onClose, onSend }) => {
    const { language } = useLanguage();
    const t = (key, replacements) => tSms(language, key, replacements);

    const [loading, setLoading] = useState(false);
    const [recipient, setRecipient] = useState('');
    const [message, setMessage] = useState('');
    const [charCount, setCharCount] = useState(0);
    const [error, setError] = useState('');
    const [selectedUser, setSelectedUser] = useState(null);
    const [users, setUsers] = useState([]);
    const [userSearch, setUserSearch] = useState('');

    const { getUsersDropdown } = useUserManagement();

    useEffect(() => {
        if (open) loadUsers();
    }, [open]);

    useEffect(() => { setCharCount(message.length); }, [message]);

    const loadUsers = async () => {
        try {
            const response = await getUsersDropdown({ search: userSearch });
            if (response?.data?.data) setUsers(response.data.data);
        } catch (err) {
            console.error('Failed to load users:', err);
        }
    };

    const handleSend = async () => {
        if (!recipient && !selectedUser) {
            setError(t('sms.send.errorRecipient'));
            return;
        }
        if (!message.trim()) {
            setError(t('sms.send.errorMessage'));
            return;
        }

        setLoading(true);
        setError('');

        try {
            const data = {
                recipient: selectedUser?.phone || recipient,
                message: message.trim(),
                user_id: selectedUser?.id || null,
            };
            await onSend(data);
        } catch (err) {
            setError(err.response?.data?.message || t('sms.send.errorSendFailed'));
        } finally {
            setLoading(false);
        }
    };

    const handleRecipientChange = (value) => {
        setRecipient(value);
        setSelectedUser(null);
        setError('');
    };

    const handleUserSelect = (user) => {
        setSelectedUser(user);
        setRecipient(user?.phone || '');
        setError('');
    };

    const handleClear = () => {
        setRecipient('');
        setMessage('');
        setSelectedUser(null);
        setError('');
        setCharCount(0);
    };

    const getCharCountColor = () => {
        if (charCount <= 160) return colors.salat;
        if (charCount <= 320) return colors.warning;
        return colors.error;
    };

    const getMessageParts = () => {
        if (charCount <= 160) return 1;
        return Math.ceil(charCount / 153);
    };

    const parts = getMessageParts();
    const charCountLabel = t('sms.send.charCount', {
        n: charCount,
        parts,
        s: parts > 1 ? 's' : '',
    });

    return (
        <Dialog
            open={open}
            onClose={onClose}
            maxWidth="sm"
            fullWidth
            PaperProps={{ sx: { borderRadius: 2, bgcolor: 'background.paper' } }} // ✅ Theme aware
        >
            <DialogTitle sx={{
                display: 'flex', justifyContent: 'space-between', alignItems: 'center',
                color: 'text.primary', // ✅ Theme aware
            }}>
                <Box display="flex" alignItems="center" gap={1}>
                    <SendIcon sx={{ color: colors.salat }} />
                    <Typography variant="h6">{t('sms.send.title')}</Typography>
                </Box>
                <IconButton onClick={onClose} size="small" sx={{ color: 'text.secondary' }}>
                    <CloseIcon />
                </IconButton>
            </DialogTitle>

            <DialogContent>
                {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

                {/* User Selection */}
                <Box mb={2}>
                    <FormControl fullWidth size="small">
                        <InputLabel>{t('sms.send.selectUserOptional')}</InputLabel>
                        <Select
                            value={selectedUser?.id || ''}
                            onChange={(e) => {
                                const user = users.find(u => u.id === e.target.value);
                                if (user) handleUserSelect(user);
                            }}
                            label={t('sms.send.selectUserOptional')}
                            sx={{
                                bgcolor: 'action.hover', // ✅ Theme aware
                                borderRadius: 2,
                                '& .MuiOutlinedInput-notchedOutline': { borderColor: 'divider' }, // ✅ Theme aware
                            }}
                        >
                            <MenuItem value="">{t('sms.common.none')}</MenuItem>
                            {users.map((user) => (
                                <MenuItem key={user.id} value={user.id}>
                                    {user.name} - {user.phone || user.email}
                                </MenuItem>
                            ))}
                        </Select>
                    </FormControl>
                    {selectedUser && (
                        <Box mt={1}>
                            <Chip
                                label={`${t('sms.send.selectedPrefix')} ${selectedUser.name} (${selectedUser.phone || selectedUser.email})`}
                                onDelete={() => handleUserSelect(null)}
                                size="small"
                                sx={{ bgcolor: 'primary.50', color: 'primary.main' }} // ✅ Theme aware
                            />
                        </Box>
                    )}
                </Box>

                {/* Recipient */}
                <TextField
                    fullWidth
                    label={t('sms.send.recipientLabel')}
                    placeholder={t('sms.send.recipientPlaceholder')}
                    value={recipient}
                    onChange={(e) => handleRecipientChange(e.target.value)}
                    disabled={!!selectedUser}
                    size="small"
                    sx={{
                        mb: 2,
                        '& .MuiInputBase-root': { bgcolor: 'action.hover', borderRadius: 2 }, // ✅ Theme aware
                        '& .MuiOutlinedInput-notchedOutline': { borderColor: 'divider' }, // ✅ Theme aware
                    }}
                />

                {/* Message */}
                <TextField
                    fullWidth
                    label={t('sms.send.messageLabel')}
                    placeholder={t('sms.send.messagePlaceholder')}
                    multiline
                    rows={4}
                    value={message}
                    onChange={(e) => setMessage(e.target.value)}
                    size="small"
                    sx={{
                        '& .MuiInputBase-root': { bgcolor: 'action.hover', borderRadius: 2 }, // ✅ Theme aware
                        '& .MuiOutlinedInput-notchedOutline': { borderColor: 'divider' }, // ✅ Theme aware
                    }}
                    InputProps={{
                        endAdornment: (
                            <InputAdornment position="end" sx={{ alignItems: 'flex-end' }}>
                                <Typography
                                    variant="caption"
                                    sx={{ color: getCharCountColor(), fontWeight: 500 }}
                                >
                                    {charCountLabel}
                                </Typography>
                            </InputAdornment>
                        ),
                    }}
                />
            </DialogContent>

            <DialogActions sx={{ p: 2, pt: 0, gap: 1 }}>
                <Button
                    onClick={handleClear}
                    variant="outlined"
                    sx={{ borderColor: 'divider', color: 'text.secondary' }} // ✅ Theme aware
                >
                    {t('sms.common.clear')}
                </Button>
                <Button onClick={onClose} sx={{ color: 'text.secondary' }}>{/* ✅ Theme aware */}
                    {t('sms.common.cancel')}
                </Button>
                <Button
                    onClick={handleSend}
                    variant="contained"
                    disabled={loading || !recipient || !message.trim()}
                    startIcon={loading ? <CircularProgress size={20} /> : <SendIcon />}
                    sx={{
                        backgroundColor: colors.salat,
                        '&:hover': { backgroundColor: colors.dark },
                        '&.Mui-disabled': { backgroundColor: 'action.disabledBackground' }, // ✅ Theme aware
                    }}
                >
                    {loading ? t('sms.send.sending') : t('sms.send.sendButton')}
                </Button>
            </DialogActions>
        </Dialog>
    );
};

export default SendSmsDialog;