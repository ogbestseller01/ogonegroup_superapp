import { useState } from 'react';
import {
  Grid,
  Typography,
  TextField,
  CircularProgress,
  Avatar,
  Button,
  Chip,
  IconButton,
  InputAdornment,
  Box,
  Stack,
} from '@mui/material';
import {
  Facebook as FacebookIcon,
  Instagram as InstagramIcon,
  LinkedIn as LinkedInIcon,
  Twitter as TwitterIcon,
  Visibility,
  VisibilityOff,
} from '@mui/icons-material';

import useStyles from './styles';
import Widget from '../../components/Widget/Widget';
import { authService } from 'services/auth.service';
import { showSnackbar } from 'utils/snackbar';
import { useAuth } from 'context/AuthContext';
import { useLanguage } from 'context/LanguageContext';
import { tProfile } from './profilelang';

export default function Profile() {
  const classes = useStyles();
  const { user, updateUser, roles } = useAuth();
  const { language } = useLanguage();
  const t = (key) => tProfile(language, key);

  const [editMode, setEditMode] = useState(false);
  const [profileForm, setProfileForm] = useState({
    name: user?.name || '',
    phone: user?.phone || '',
  });
  const [profileLoading, setProfileLoading] = useState(false);

  const [passForm, setPassForm] = useState({
    current_password: '',
    password: '',
    password_confirmation: '',
  });
  const [passLoading, setPassLoading] = useState(false);
  const [showCurrentPassword, setShowCurrentPassword] = useState(false);
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  const roleDisplayName =
      user?.role?.display_name || (roles.length > 0 ? roles[0] : 'User');

  const handleProfileUpdate = async (e) => {
    e.preventDefault();
    setProfileLoading(true);
    try {
      const res = await authService.updateProfile(profileForm);
      if (res.data.success) {
        updateUser(res.data.data.user);
        showSnackbar({ type: 'success', message: t('profile.updateSuccess') });
        setEditMode(false);
      } else {
        showSnackbar({ type: 'error', message: res.data.message || t('profile.updateFailed') });
      }
    } catch (err) {
      showSnackbar({
        type: 'error',
        message: err.response?.data?.message || t('profile.updateFailed'),
      });
    } finally {
      setProfileLoading(false);
    }
  };

  const handlePasswordChange = async (e) => {
    e.preventDefault();
    if (passForm.password !== passForm.password_confirmation) {
      showSnackbar({ type: 'error', message: t('profile.password.mismatch') });
      return;
    }
    setPassLoading(true);
    try {
      const res = await authService.changePassword(
          passForm.current_password,
          passForm.password,
          passForm.password_confirmation
      );
      if (res.data.success) {
        showSnackbar({ type: 'success', message: t('profile.password.success') });
        setPassForm({
          current_password: '',
          password: '',
          password_confirmation: '',
        });
      } else {
        showSnackbar({
          type: 'error',
          message: res.data.message || t('profile.password.failed'),
        });
      }
    } catch (err) {
      showSnackbar({
        type: 'error',
        message: err.response?.data?.message || t('profile.password.failed'),
      });
    } finally {
      setPassLoading(false);
    }
  };

  return (
      <Grid container spacing={3} sx={{ width: '100%', m: 0, p: 2 }}>
        {/* Left – Profile Card */}
        <Grid size={{ xs: 12, md: 6 }}>
          <Widget sx={{ height: '100%' }}>
            <Grid container spacing={2}>
              <Grid
                  size={{ xs: 12, sm: 4 }}
                  sx={{ display: 'flex', justifyContent: 'center' }}
              >
                <Box className={classes.visualProfile}>
                  <Box className={classes.profileImage}>
                    <Avatar sx={{ width: 120, height: 120 }} src={user?.avatar || ''}>
                      {user?.name?.charAt(0) || 'U'}
                    </Avatar>
                  </Box>
                  <Chip
                      className={classes.chipMargin}
                      color="secondary"
                      label={roleDisplayName}
                  />
                </Box>
              </Grid>

              <Grid size={{ xs: 12, sm: 8 }}>
                <Box className={classes.profileDescription}>
                  {editMode ? (
                      <form onSubmit={handleProfileUpdate}>
                        <TextField
                            fullWidth
                            margin="normal"
                            label={t('profile.fullName')}
                            value={profileForm.name}
                            onChange={(e) =>
                                setProfileForm({ ...profileForm, name: e.target.value })
                            }
                            required
                        />
                        <TextField
                            fullWidth
                            margin="normal"
                            label={t('profile.phone')}
                            value={profileForm.phone}
                            onChange={(e) =>
                                setProfileForm({ ...profileForm, phone: e.target.value })
                            }
                        />
                        <Stack direction="row" spacing={1} sx={{ mt: 2 }}>
                          <Button
                              type="submit"
                              variant="contained"
                              color="primary"
                              disabled={profileLoading}
                          >
                            {profileLoading ? (
                                <CircularProgress size={24} />
                            ) : (
                                t('profile.save')
                            )}
                          </Button>
                          <Button variant="outlined" onClick={() => setEditMode(false)}>
                            {t('profile.cancel')}
                          </Button>
                        </Stack>
                      </form>
                  ) : (
                      <>
                        <Typography variant="h4" className={classes.profileTitle}>
                          {user?.name}
                        </Typography>
                        <Typography
                            variant="subtitle1"
                            className={classes.profileSubtitle}
                        >
                          {roleDisplayName}
                        </Typography>
                        <a
                            className={classes.profileExternalRes}
                            href={`mailto:${user?.email}`}
                        >
                          {user?.email}
                        </a>
                        <Box className={classes.socials}>
                          <a href="#"><FacebookIcon fontSize="small" /></a>
                          <a href="#"><TwitterIcon fontSize="small" /></a>
                          <a href="#"><LinkedInIcon fontSize="small" /></a>
                          <a href="#"><InstagramIcon fontSize="small" /></a>
                        </Box>
                        <Button
                            variant="outlined"
                            color="primary"
                            onClick={() => setEditMode(true)}
                        >
                          {t('profile.edit')}
                        </Button>
                      </>
                  )}
                </Box>
              </Grid>
            </Grid>
          </Widget>
        </Grid>

        {/* Right – Change Password */}
        <Grid size={{ xs: 12, md: 6 }}>
          <Widget title={t('profile.password.title')} sx={{ height: '100%' }}>
            <form onSubmit={handlePasswordChange}>
              <TextField
                  fullWidth
                  margin="normal"
                  type={showCurrentPassword ? 'text' : 'password'}
                  label={t('profile.password.current')}
                  value={passForm.current_password}
                  onChange={(e) =>
                      setPassForm({ ...passForm, current_password: e.target.value })
                  }
                  required
                  InputProps={{
                    endAdornment: (
                        <InputAdornment position="end">
                          <IconButton
                              onClick={() => setShowCurrentPassword(!showCurrentPassword)}
                              edge="end"
                          >
                            {showCurrentPassword ? <VisibilityOff /> : <Visibility />}
                          </IconButton>
                        </InputAdornment>
                    ),
                  }}
              />
              <TextField
                  fullWidth
                  margin="normal"
                  type={showNewPassword ? 'text' : 'password'}
                  label={t('profile.password.new')}
                  value={passForm.password}
                  onChange={(e) =>
                      setPassForm({ ...passForm, password: e.target.value })
                  }
                  required
                  InputProps={{
                    endAdornment: (
                        <InputAdornment position="end">
                          <IconButton
                              onClick={() => setShowNewPassword(!showNewPassword)}
                              edge="end"
                          >
                            {showNewPassword ? <VisibilityOff /> : <Visibility />}
                          </IconButton>
                        </InputAdornment>
                    ),
                  }}
              />
              <TextField
                  fullWidth
                  margin="normal"
                  type={showConfirmPassword ? 'text' : 'password'}
                  label={t('profile.password.confirm')}
                  value={passForm.password_confirmation}
                  onChange={(e) =>
                      setPassForm({
                        ...passForm,
                        password_confirmation: e.target.value,
                      })
                  }
                  required
                  InputProps={{
                    endAdornment: (
                        <InputAdornment position="end">
                          <IconButton
                              onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                              edge="end"
                          >
                            {showConfirmPassword ? <VisibilityOff /> : <Visibility />}
                          </IconButton>
                        </InputAdornment>
                    ),
                  }}
              />
              <Button
                  type="submit"
                  variant="contained"
                  color="primary"
                  disabled={passLoading}
                  sx={{ mt: 2 }}
              >
                {passLoading ? (
                    <CircularProgress size={24} />
                ) : (
                    t('profile.password.change')
                )}
              </Button>
            </form>
          </Widget>
        </Grid>
      </Grid>
  );
}