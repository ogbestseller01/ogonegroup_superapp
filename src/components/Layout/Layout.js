// src/components/Layout/Layout.js
import React from 'react';
import { Outlet } from 'react-router-dom';
import classnames from 'classnames';

import SettingsIcon from '@mui/icons-material/Settings';
import GithubIcon from '@mui/icons-material/GitHub';
import FacebookIcon from '@mui/icons-material/Facebook';
import TwitterIcon from '@mui/icons-material/Twitter';
import { Fab, IconButton } from '@mui/material';

import useStyles from './styles';
import Header from '../Header';
import Sidebar from '../Sidebar';
import Footer from '../Footer';
import { Link } from '../Wrappers';
import ColorChangeThemePopper from './components/ColorChangeThemePopper';
import BreadCrumbs from '../../components/BreadCrumbs';

import { useLayoutState } from 'context/LayoutContext';
import { getSidebarStructure } from '../Sidebar/SidebarStructure';
import { usePermissions } from 'hooks/usePermissions';
import { useLanguage } from 'context/LanguageContext';

function Layout() {
  const classes = useStyles();
  const [anchorEl, setAnchorEl] = React.useState(null);
  const open = Boolean(anchorEl);
  const id = open ? 'add-section-popover' : undefined;

  const handleClick = (event) => {
    setAnchorEl(open ? null : event.currentTarget);
  };

  const layoutState = useLayoutState();
  const { can, permissions } = usePermissions();
  const { t, language } = useLanguage();

  const permissionsReady = Array.isArray(permissions);

  // Recompute sidebar when permissions or language change
  const dynamicStructure = React.useMemo(() => {
    if (!permissionsReady) return [];
    // ✅ Passes `language` as the 3rd argument so the SidebarStructure
    // can properly fetch translations (including the new Reports menu) from sidebarTranslations.js
    return getSidebarStructure(can, t, language);
  }, [permissionsReady, permissions, language, t, can]);

  return (
      <div className={classes.root}>
        <Header />
        <Sidebar structure={dynamicStructure} />

        <div
            className={classnames(classes.content, {
              [classes.contentShift]: layoutState.isSidebarOpened,
            })}
        >
          <div className={classes.fakeToolbar} />

          <BreadCrumbs structure={dynamicStructure || []} />

          <Outlet />

          <Fab
              color="primary"
              aria-label="settings"
              onClick={handleClick}
              className={classes.changeThemeFab}
              style={{ zIndex: 2000 }}
          >
            <SettingsIcon style={{ color: '#fff' }} />
          </Fab>

          <ColorChangeThemePopper id={id} open={open} anchorEl={anchorEl} />

          <Footer>
            <div>
              <Link
                  color="primary"
                  href="https://ogonegroup.co.tz/"
                  target="_blank"
                  className={classes.link}
              >
                Og One-Group
              </Link>
            </div>
            <div>
              <Link href="https://www.facebook.com/flatlogic" target="_blank">
                <IconButton aria-label="facebook">
                  <FacebookIcon style={{ color: '#6E6E6E99' }} />
                </IconButton>
              </Link>
              <Link href="https://twitter.com/flatlogic" target="_blank">
                <IconButton aria-label="twitter">
                  <TwitterIcon style={{ color: '#6E6E6E99' }} />
                </IconButton>
              </Link>
              <Link href="https://github.com/flatlogic" target="_blank">
                <IconButton
                    aria-label="github"
                    style={{ padding: '12px 0 12px 12px' }}
                >
                  <GithubIcon style={{ color: '#6E6E6E99' }} />
                </IconButton>
              </Link>
            </div>
          </Footer>
        </div>
      </div>
  );
}

export default Layout;