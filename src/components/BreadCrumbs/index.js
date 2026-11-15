// src/components/BreadCrumbs/index.js
import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { Box, Grid, Breadcrumbs } from '@mui/material';
import { NavigateNext as NavigateNextIcon } from '@mui/icons-material';

import Widget from '../Widget';
import { Typography } from '../Wrappers';
import useStyles from '../Layout/styles';

const BreadCrumbs = () => {
  const location = useLocation();
  const classes = useStyles();

  const renderBreadCrumbs = () => {
    const url = location.pathname;

    // Remove empty parts and create nice labels
    const parts = url
        .split('/')
        .filter(Boolean)
        .map((part) =>
            part
                .split('-')
                .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
                .join(' ')
        );

    return parts.map((item, index) => {
      const middlewareUrl = '/' + url.split('/').slice(1, index + 2).join('/');
      const isLast = index === parts.length - 1;

      return (
          <Typography
              key={index}
              variant="h6"
              color={isLast ? 'primary' : 'textSecondary'}
          >
            {isLast ? (
                item
            ) : (
                <Link
                    to={middlewareUrl}
                    style={{ color: 'inherit', textDecoration: 'none' }}
                >
                  {item}
                </Link>
            )}
          </Typography>
      );
    });
  };

  // Special case for the main Dashboard page
  const isDashboard = location.pathname === '/app/dashboard';

  return (
      <Widget
          disableWidgetMenu
          inheritHeight
          className={classes.margin}
          bodyClass={classes.navPadding}
      >
        <Grid
            container
            direction="row"
            justifyContent="space-between"
            alignItems="center"
            wrap="nowrap"
            style={{ overflowX: 'auto' }}
        >
          {isDashboard ? (
              <Box display="flex" alignItems="center">
                <Breadcrumbs aria-label="breadcrumb">
                  <Typography variant="h4">Dashboard</Typography>
                </Breadcrumbs>
              </Box>
          ) : (
              <Breadcrumbs
                  separator={<NavigateNextIcon fontSize="small" />}
                  aria-label="breadcrumb"
              >
                {renderBreadCrumbs()}
              </Breadcrumbs>
          )}
        </Grid>
      </Widget>
  );
};

export default BreadCrumbs;