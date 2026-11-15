// src/context/ThemeContext.js
import React from 'react';
import Themes from '../themes';

const STORAGE_KEY = 'theme';

const ThemeStateContext = React.createContext();
const ThemeDispatchContext = React.createContext();
// ✅ NEW: expose key separately so consumers can highlight active theme
const ThemeKeyContext = React.createContext();

function getInitialThemeKey() {
  try {
    const saved = localStorage.getItem(STORAGE_KEY);
    return saved && Themes[saved] ? saved : 'default';
  } catch {
    return 'default';
  }
}

function ThemeProvider({ children }) {
  const [themeKey, setThemeKey] = React.useState(getInitialThemeKey);

  // Derived: actual MUI theme object
  const theme = Themes[themeKey] || Themes.default;

  // ✅ Dispatcher — accepts either a theme key string OR a full theme object
  const setTheme = React.useCallback((next) => {
    if (typeof next === 'string') {
      const key = Themes[next] ? next : 'default';
      setThemeKey(key);
      try {
        localStorage.setItem(STORAGE_KEY, key);
      } catch {
        /* ignore quota errors */
      }
      return;
    }
    // Fallback: someone passed a full theme object (legacy usage)
    // Find its key by identity match, otherwise default
    const matchedKey = Object.keys(Themes).find((k) => Themes[k] === next);
    if (matchedKey) {
      setThemeKey(matchedKey);
      try {
        localStorage.setItem(STORAGE_KEY, matchedKey);
      } catch {
        /* ignore */
      }
    }
  }, []);

  return (
      <ThemeStateContext.Provider value={theme}>
        <ThemeDispatchContext.Provider value={setTheme}>
          <ThemeKeyContext.Provider value={{ themeKey, setThemeKey: setTheme }}>
            {children}
          </ThemeKeyContext.Provider>
        </ThemeDispatchContext.Provider>
      </ThemeStateContext.Provider>
  );
}

/* -----------------------------------------------------------
 *  Hooks
 * ----------------------------------------------------------- */

function useThemeState() {
  const context = React.useContext(ThemeStateContext);
  if (context === undefined) {
    throw new Error('useThemeState must be used within a ThemeProvider');
  }
  return context;
}

function useThemeDispatch() {
  const context = React.useContext(ThemeDispatchContext);
  if (context === undefined) {
    throw new Error('useThemeDispatch must be used within a ThemeProvider');
  }
  return context;
}

// ✅ NEW hook — use this in ThemeSwitcher to read/change the active key
function useThemeKey() {
  const context = React.useContext(ThemeKeyContext);
  if (context === undefined) {
    throw new Error('useThemeKey must be used within a ThemeProvider');
  }
  return context; // { themeKey, setThemeKey }
}

export {
  ThemeProvider,
  useThemeState,
  useThemeDispatch,
  useThemeKey,
  ThemeStateContext,
  ThemeDispatchContext,
  ThemeKeyContext,
};