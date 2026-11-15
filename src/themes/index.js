import { createTheme } from '@mui/material/styles';

import defaultTheme from './default';
import secondaryTheme from './secondary';
import successTheme from './success';
import darkTheme from './dark';

/* -----------------------------------------------------------
 *  Mobile color palette (single source of truth)
 * ----------------------------------------------------------- */
export const colors = {
  // Brand
  primary:      '#001D45', // Navy 700
  primaryLight: '#0A3670', // Navy 600
  primaryDark:  '#001533', // Navy 800
  secondary:    '#F5C30E', // Gold 500
  accent:       '#074B83', // Bolt 800

  // Navy scale
  navy50:  '#EAF1FB',
  navy100: '#CFE0F5',
  navy200: '#9FC0EB',
  navy600: '#0A3670',
  navy700: '#001D45',
  navy800: '#001533',
  navy900: '#000C1F',
  navy950: '#00050F',

  // Gold scale
  gold400: '#FFC61F',
  gold500: '#F5C30E',
  gold600: '#D9A300',

  // Bolt scale
  bolt50:  '#F0F7FF',
  bolt100: '#E0EFFE',
  bolt200: '#BAE0FD',
  bolt800: '#074B83',
  bolt900: '#0C3F6E',

  // Status
  success: '#0A8A6D',
  error:   '#E53935',
  warning: '#F5C30E',

  // Neutrals
  white:       '#FFFFFF',
  greyText:    '#074B83',
  borderLight: '#9FC0EB',
  divider:     '#9FC0EB',
  scaffold:    '#EAF1FB',

  // Dark mode
  darkBackground:    '#00050F',
  darkSurface:       '#000C1F',
  darkSurfaceLight:  '#001533',
  darkTextPrimary:   '#FFFFFF',
  darkTextSecondary: '#9FC0EB',
  darkBorder:        '#001533',
  darkCard:          '#000C1F',
};

/* -----------------------------------------------------------
 *  Shared typography
 * ----------------------------------------------------------- */
const typography = {
  fontFamily: [
    'Inter',
    '-apple-system',
    'BlinkMacSystemFont',
    '"Segoe UI"',
    'Roboto',
    '"Helvetica Neue"',
    'Arial',
    'sans-serif',
  ].join(','),
  h1: { fontSize: '3rem', fontWeight: 700 },
  h2: { fontSize: '2rem', fontWeight: 700 },
  h3: { fontSize: '1.64rem', fontWeight: 700 },
  h4: { fontSize: '1.5rem', fontWeight: 700 },
  h5: { fontSize: '1.285rem', fontWeight: 700 },
  h6: { fontSize: '1.142rem', fontWeight: 700 },
  button: { textTransform: 'none', fontWeight: 600 },
};

/* -----------------------------------------------------------
 *  Shared component overrides (Light)
 * ----------------------------------------------------------- */
const baseComponents = {
  MuiCssBaseline: {
    styleOverrides: {
      '*::-webkit-scrollbar': { width: '0.4em', height: '0.4em' },
      '*::-webkit-scrollbar-thumb': {
        backgroundColor: 'rgba(0, 29, 69, 0.15)',
        borderRadius: 4,
      },
      '*::-webkit-scrollbar-track': { backgroundColor: 'transparent' },
      body: { margin: 0, padding: 0 },
    },
  },
  MuiCard: {
    styleOverrides: {
      root: {
        borderRadius: 12,
        boxShadow: '0px 2px 8px rgba(0, 0, 0, 0.04)',
        border: '1px solid #9FC0EB',
      },
    },
  },
  MuiPaper: {
    styleOverrides: {
      root: { backgroundImage: 'none' },
    },
  },
  MuiBackdrop: {
    styleOverrides: {
      root: { backgroundColor: 'rgba(0, 29, 69, 0.35)' },
    },
  },
  MuiMenu: {
    styleOverrides: {
      paper: {
        boxShadow: '0px 2px 8px rgba(0, 0, 0, 0.06)',
        border: '1px solid #9FC0EB',
      },
    },
  },
  MuiSelect: {
    styleOverrides: {
      icon: { color: '#0A3670' },
    },
  },
  MuiTableCell: {
    styleOverrides: {
      root: {
        borderBottom: '1px solid #9FC0EB',
        padding: '14px 24px',
      },
      head: { fontSize: '0.95rem', fontWeight: 700 },
      body: { fontSize: '0.95rem' },
    },
  },
  MuiTableRow: {
    styleOverrides: {
      root: { height: 56 },
    },
  },
  MuiButton: {
    styleOverrides: {
      root: { boxShadow: 'none' },
    },
  },
};

/* -----------------------------------------------------------
 *  Dark mode specific overrides
 * ----------------------------------------------------------- */
const darkComponents = {
  MuiCssBaseline: {
    styleOverrides: {
      '*::-webkit-scrollbar': { width: '0.4em', height: '0.4em' },
      '*::-webkit-scrollbar-thumb': {
        backgroundColor: '#001533',
        borderRadius: 4,
      },
      '*::-webkit-scrollbar-track': { backgroundColor: 'transparent' },
      body: {
        margin: 0,
        padding: 0,
        backgroundColor: '#00050F',
        color: '#FFFFFF',
      },
    },
  },
  MuiPaper: {
    styleOverrides: {
      root: {
        backgroundImage: 'none',
        backgroundColor: '#000C1F',
        boxShadow: 'none',
        border: '1px solid #001533',
      },
    },
  },
  MuiAppBar: {
    styleOverrides: {
      root: {
        backgroundColor: '#000C1F',
        backgroundImage: 'none',
        boxShadow: 'none',
        borderBottom: '1px solid #001533',
      },
    },
  },
  MuiCard: {
    styleOverrides: {
      root: {
        backgroundColor: '#000C1F',
        backgroundImage: 'none',
        boxShadow: 'none',
        border: '1px solid #001533',
      },
    },
  },
  MuiTableCell: {
    styleOverrides: {
      root: { borderBottom: '1px solid #001533' },
      head: { color: '#9FC0EB', fontWeight: 700 },
      body: { color: '#FFFFFF' },
    },
  },
  MuiTableSortLabel: {
    styleOverrides: {
      root: {
        color: '#9FC0EB',
        '&.Mui-active': { color: '#FFFFFF' },
        '&:hover': { color: '#FFFFFF' },
      },
      icon: { color: '#9FC0EB !important' },
    },
  },
  MuiTablePagination: {
    styleOverrides: {
      toolbar: { color: '#9FC0EB' },
      selectIcon: { color: '#9FC0EB' },
    },
  },
  MuiCheckbox: {
    styleOverrides: {
      root: { color: '#9FC0EB' },
    },
  },
  MuiDivider: {
    styleOverrides: {
      root: { borderColor: '#001533' },
    },
  },
};

/* -----------------------------------------------------------
 *  Theme factory
 * ----------------------------------------------------------- */
const buildTheme = (themeConfig, isDark = false) =>
    createTheme({
      ...themeConfig,
      typography: {
        ...typography,
        ...(themeConfig.typography || {}),
      },
      components: {
        ...baseComponents,
        ...(isDark ? darkComponents : {}),
        MuiCssBaseline: {
          styleOverrides: {
            ...(baseComponents.MuiCssBaseline?.styleOverrides || {}),
            ...(isDark
                ? darkComponents.MuiCssBaseline?.styleOverrides || {}
                : {}),
          },
        },
      },
      shape: { borderRadius: 12 },
    });

/* -----------------------------------------------------------
 *  Export themes
 * ----------------------------------------------------------- */
const themes = {
  default: buildTheme(defaultTheme, false),
  secondary: buildTheme(secondaryTheme, false),
  success: buildTheme(successTheme, false),
  dark: buildTheme(darkTheme, true),
};

export default themes;