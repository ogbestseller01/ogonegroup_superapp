// src/components/Header/Header.js
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  AppBar,
  Toolbar,
  IconButton,
  Menu,
  MenuItem,
  Avatar,
  Typography,
  Box,
} from '@mui/material';
import {
  Menu as MenuIcon,
  Person as AccountIcon,
  ArrowBack as ArrowBackIcon,
} from '@mui/icons-material';
import classNames from 'classnames';

import useStyles from './styles';
import { toggleSidebar, useLayoutDispatch, useLayoutState } from 'context/LayoutContext';
import { useAuth } from 'context/AuthContext';
import { useLanguage } from 'context/LanguageContext';
import { NotificationBell } from 'pages/monitoring/components/NotificationBell';
import LanguageSwitcher from 'components/LanguageSwitcher/LanguageSwitcher';

const profileImg = '/assets/logo.png';

export default function Header() {
  const classes = useStyles();
  const navigate = useNavigate();
  const { user, logout } = useAuth();
  const { t } = useLanguage();
  const layoutState = useLayoutState();
  const layoutDispatch = useLayoutDispatch();

  const [profileMenu, setProfileMenu] = useState(null);

  const handleLogout = async () => {
    await logout();
    navigate('/login');
  };

  const handleNotificationClick = (notification) => {
    if (notification?.viewAll) {
      navigate('/app/monitoring');
      return;
    }
    navigate('/app/monitoring', {
      state: { selectedRequestId: notification?.request_id },
    });
  };

  return (
      <AppBar position="fixed" className={classes.appBar}>
        <Toolbar className={classes.toolbar}>
          <IconButton
              color="inherit"
              onClick={() => toggleSidebar(layoutDispatch)}
              className={classNames(classes.headerMenuButton, classes.headerMenuButtonCollapse)}
          >
            {layoutState.isSidebarOpened ? (
                <ArrowBackIcon
                    classes={{ root: classNames(classes.headerIcon, classes.headerIconCollapse) }}
                />
            ) : (
                <MenuIcon
                    classes={{ root: classNames(classes.headerIcon, classes.headerIconCollapse) }}
                />
            )}
          </IconButton>

          <Typography variant="h6" className={classes.logotype}>
            NearbyFundi
          </Typography>

          <div className={classes.grow} />

          {/* Language Switcher */}
          <LanguageSwitcher iconColor="rgba(255, 255, 255, 0.7)" />

          {/* Notification Bell */}
          <NotificationBell onNotificationClick={handleNotificationClick} />

          <IconButton
              aria-haspopup="true"
              color="inherit"
              className={classes.headerMenuButton}
              aria-controls="profile-menu"
              onClick={(e) => setProfileMenu(e.currentTarget)}
          >
            <Avatar src={user?.avatar || profileImg} classes={{ root: classes.headerIcon }}>
              {user?.name?.charAt(0) || 'U'}
            </Avatar>
          </IconButton>

          <Box sx={{ display: 'flex', alignItems: 'center', ml: 1 }}>
            <Box component="span" className={classes.profileLabel}>
              {t('header.greeting')}&nbsp;
            </Box>
            <Box component="span" fontWeight="bold" className={classes.profileLabel}>
              {user?.name?.split(' ')[0] || t('header.user')}
            </Box>
          </Box>

          <Menu
              id="profile-menu"
              open={Boolean(profileMenu)}
              anchorEl={profileMenu}
              onClose={() => setProfileMenu(null)}
              className={classes.headerMenu}
              classes={{ paper: classes.profileMenu }}
              disableAutoFocusItem
          >
            <div className={classes.profileMenuUser}>
              <Typography variant="h4" fontWeight="medium">
                {user?.name}
              </Typography>
            </div>
            <MenuItem
                className={classNames(classes.profileMenuItem, classes.headerMenuItem)}
                onClick={() => {
                  setProfileMenu(null);
                  navigate('/app/profile');
                }}
            >
              <AccountIcon className={classes.profileMenuIcon} />
              {t('header.profile')}
            </MenuItem>
            <div className={classes.profileMenuUser}>
              <Typography
                  className={classes.profileMenuLink}
                  color="primary"
                  onClick={handleLogout}
              >
                {t('header.signout')}
              </Typography>
            </div>
          </Menu>
        </Toolbar>
      </AppBar>
  );
}