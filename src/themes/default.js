import tinycolor from 'tinycolor2';

const primary = '#001D45';
const secondary = '#F5C30E';
const warning = '#F5C30E';
const success = '#0A8A6D';
const info = '#074B83';

const lightenRate = 7.5;
const darkenRate = 15;

const defaultTheme = {
  palette: {
    mode: 'light',
    primary: {
      main: primary,
      light: '#0A3670',
      dark: '#001533',
      contrastText: '#FFFFFF',
    },
    secondary: {
      main: secondary,
      light: '#FFC61F',
      dark: '#D9A300',
      contrastText: primary,
    },
    warning: {
      main: warning,
      light: '#FFC61F',
      dark: '#D9A300',
      contrastText: primary,
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
      primary: '#001D45',
      secondary: '#074B83',
      disabled: '#9AA5B1',
      hint: '#074B83',
    },
    background: {
      default: '#EAF1FB',
      paper: '#FFFFFF',
      light: '#CFE0F5',
    },
    divider: '#9FC0EB',
    action: {
      active: '#074B83',
      hover: 'rgba(0, 29, 69, 0.06)',
      selected: 'rgba(0, 29, 69, 0.12)',
      disabled: 'rgba(0, 0, 0, 0.3)',
      disabledBackground: 'rgba(0, 0, 0, 0.08)',
      focus: 'rgba(0, 29, 69, 0.16)',
    },
  },
  customShadows: {
    widget: '0px 2px 8px rgba(0, 0, 0, 0.04)',
  },
};

export default defaultTheme;