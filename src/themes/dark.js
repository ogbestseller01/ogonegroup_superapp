import tinycolor from 'tinycolor2';

const primary = '#F5C30E';
const secondary = '#001D45';
const warning = '#F5C30E';
const success = '#0A8A6D';
const info = '#074B83';

const lightenRate = 7.5;
const darkenRate = 15;

const darkTheme = {
  palette: {
    mode: 'dark',
    primary: {
      main: primary,
      light: '#FFC61F',
      dark: '#D9A300',
      contrastText: '#001D45',
    },
    secondary: {
      main: secondary,
      light: '#0A3670',
      dark: '#001533',
      contrastText: '#FFFFFF',
    },
    warning: {
      main: warning,
      light: '#FFC61F',
      dark: '#D9A300',
      contrastText: '#001D45',
    },
    success: {
      main: success,
      light: tinycolor(success).lighten(lightenRate).toHexString(),
      dark: tinycolor(success).darken(darkenRate).toHexString(),
      contrastText: '#FFFFFF',
    },
    info: {
      main: info,
      light: tinycolor(info).lighten(lightenRate).toHexString(),
      dark: tinycolor(info).darken(darkenRate).toHexString(),
      contrastText: '#FFFFFF',
    },
    error: {
      main: '#E53935',
      light: '#F87171',
      dark: '#B91C1C',
      contrastText: '#FFFFFF',
    },
    text: {
      primary: '#FFFFFF',
      secondary: '#9FC0EB',
      disabled: '#6B6B80',
      hint: '#9FC0EB',
    },
    background: {
      default: '#00050F',
      paper: '#000C1F',
      light: '#001533',
    },
    divider: '#001533',
    action: {
      active: '#9FC0EB',
      hover: 'rgba(255, 255, 255, 0.06)',
      selected: 'rgba(245, 195, 14, 0.18)',
      disabled: 'rgba(255, 255, 255, 0.3)',
      disabledBackground: 'rgba(255, 255, 255, 0.12)',
      focus: 'rgba(245, 195, 14, 0.20)',
    },
  },
  customShadows: {
    widget: '0px 1px 4px rgba(0, 0, 0, 0.25)',
  },
};

export default darkTheme;