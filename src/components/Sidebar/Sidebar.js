// src/components/Sidebar/Sidebar.js
import { useState, useEffect, useMemo } from 'react';
import { ArrowBack as ArrowBackIcon } from '@mui/icons-material';
import { Drawer, IconButton, List } from '@mui/material';
import { useTheme } from '@mui/material';
import classNames from 'classnames';
import { useLocation } from 'react-router-dom';

// styles
import useStyles from './styles';

// components
import SidebarLink from './components/SidebarLink/SidebarLink';

// layout context
import {
  useLayoutState,
  useLayoutDispatch,
  toggleSidebar,
} from 'context/LayoutContext';

function Sidebar({ structure = [] }) {   // ← receive structure from Layout
  const classes = useStyles();
  const theme = useTheme();
  const location = useLocation();

  // global
  const { isSidebarOpened } = useLayoutState();
  const layoutDispatch = useLayoutDispatch();

  // local
  const [isPermanent, setPermanent] = useState(true);

  const isSidebarOpenedWrapper = useMemo(
      () => (!isPermanent ? !isSidebarOpened : isSidebarOpened),
      [isPermanent, isSidebarOpened],
  );

  const toggleDrawer = (value) => (event) => {
    if (
        event.type === 'keydown' &&
        (event.key === 'Tab' || event.key === 'Shift')
    ) {
      return;
    }
    if (value && !isPermanent) toggleSidebar(layoutDispatch);
  };

  useEffect(() => {
    window.addEventListener('resize', handleWindowWidthChange);
    handleWindowWidthChange();
    return () => {
      window.removeEventListener('resize', handleWindowWidthChange);
    };
  }, []);

  function handleWindowWidthChange() {
    const windowWidth = window.innerWidth;
    const breakpointWidth = theme.breakpoints.values.md;
    const isSmallScreen = windowWidth < breakpointWidth;

    if (isSmallScreen && isPermanent) {
      setPermanent(false);
    } else if (!isSmallScreen && !isPermanent) {
      setPermanent(true);
    }
  }

  return (
      <Drawer
          variant={isPermanent ? 'permanent' : 'temporary'}
          className={classNames(classes.drawer, {
            [classes.drawerOpen]: isSidebarOpenedWrapper,
            [classes.drawerClose]: !isSidebarOpenedWrapper,
          })}
          classes={{
            paper: classNames({
              [classes.drawerOpen]: isSidebarOpenedWrapper,
              [classes.drawerClose]: !isSidebarOpenedWrapper,
            }),
          }}
          open={isSidebarOpenedWrapper}
          onClose={toggleDrawer(true)}
      >
        <div className={classes.toolbar} />
        <div className={classes.mobileBackButton}>
          <IconButton onClick={() => toggleSidebar(layoutDispatch)}>
            <ArrowBackIcon
                classes={{
                  root: classNames(classes.headerIcon, classes.headerIconCollapse),
                }}
            />
          </IconButton>
        </div>

        <List
            className={classes.sidebarList}
            classes={{ padding: classes.padding }}
        >
          {structure.map((link) => (
              <SidebarLink
                  key={link.id}
                  location={location}
                  isSidebarOpened={!isPermanent ? !isSidebarOpened : isSidebarOpened}
                  {...link}
                  toggleDrawer={toggleDrawer(true)}
              />
          ))}
        </List>
      </Drawer>
  );
}

export default Sidebar;