// src/config.js
const baseURLApi = "http://192.168.100.144:8000/api";
const redirectUrl = typeof window !== "undefined"
    ? window.location.origin
    : "https://yourdomain.com";

const appConfig = {
  baseURLApi,
  redirectUrl,
  remote: "https://sing-generator-node.flatlogic.com",
  auth: {
    email: 'admin@example.com',
    password: 'password',
  },
  app: {
    colors: {
      dark: '#001D45',      // Navy 700 - for headers, footers, dark elements
      light: '#FFFFFF',     // White - for backgrounds, cards
      sea: '#074B83',       // Bolt 800 - for primary buttons, links
      sky: '#EAF1FB',       // Navy 50 - for page backgrounds
      wave: '#CFE0F5',      // Navy 100 - for highlights, badges
      rain: '#9FC0EB',      // Navy 200 - for borders, dividers
      middle: '#E0EFFE',    // Bolt 100 - for secondary backgrounds
      black: '#001D45',     // Navy 700 - for text
      salat: '#00050F',     // Green - for success, accepted, verified
    },
  },
};

export default appConfig;