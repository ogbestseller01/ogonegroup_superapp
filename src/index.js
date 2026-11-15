// src/index.js
import './utils/chartConfig';

import ReactDOM from 'react-dom/client';
import axios from 'axios';
import { ThemeProvider as ThemeProviderV5 } from '@mui/material/styles';
import { StyledEngineProvider } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import 'leaflet/dist/leaflet.css';

import App from './components/App';
import config from './config';

import {
    ThemeProvider as ThemeChangeProvider,
    useThemeState,
} from './context/ThemeContext';
import { LayoutProvider } from 'context/LayoutContext';
import { UserProvider } from 'context/UserContext';
import { ManagementProvider } from 'context/ManagementContext';
import { LanguageProvider } from 'context/LanguageContext';

axios.defaults.baseURL = config.baseURLApi;
axios.defaults.headers.common['Content-Type'] = 'application/json';

const token = localStorage.getItem('token');
if (token) {
    axios.defaults.headers.common['Authorization'] = `Bearer ${token}`;
}

/* Inner wrapper so we can access the theme via hook */
function ThemedApp() {
    const theme = useThemeState();
    return (
        <ThemeProviderV5 theme={theme}>
            <ManagementProvider>
                <CssBaseline />
                <App />
            </ManagementProvider>
        </ThemeProviderV5>
    );
}

const root = ReactDOM.createRoot(document.getElementById('root'));

root.render(
    <LanguageProvider>
        <LayoutProvider>
            <UserProvider>
                <StyledEngineProvider injectFirst>
                    <ThemeChangeProvider>
                        <ThemedApp />
                    </ThemeChangeProvider>
                </StyledEngineProvider>
            </UserProvider>
        </LayoutProvider>
    </LanguageProvider>
);