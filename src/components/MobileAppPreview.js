// src/components/MobileAppPreview.jsx
import React from 'react';
import { Box, Typography, useTheme, alpha } from '@mui/material';

const MobileAppPreview = ({ image, title, subtitle }) => {
    const theme = useTheme();

    return (
        <Box
            sx={{
                position: 'relative',
                display: 'flex',
                justifyContent: 'center',
                alignItems: 'center',
                py: 4,
            }}
        >
            <Box
                sx={{
                    position: 'relative',
                    width: 280,
                    height: 'auto',
                    borderRadius: 4,
                    boxShadow: '0 30px 80px rgba(0,0,0,0.15)',
                    transition: 'all 0.3s',
                    '&:hover': {
                        transform: 'translateY(-10px)',
                        boxShadow: '0 40px 100px rgba(0,0,0,0.2)',
                    },
                }}
            >
                <Box
                    component="img"
                    src={image}
                    alt={title}
                    sx={{
                        width: '100%',
                        height: 'auto',
                        borderRadius: 4,
                        display: 'block',
                    }}
                />
                {subtitle && (
                    <Box
                        sx={{
                            position: 'absolute',
                            bottom: 20,
                            left: 20,
                            right: 20,
                            textAlign: 'center',
                        }}
                    >
                        <Typography
                            variant="caption"
                            sx={{
                                color: 'white',
                                background: alpha(theme.palette.common.black, 0.6),
                                px: 2,
                                py: 0.5,
                                borderRadius: 2,
                                backdropFilter: 'blur(8px)',
                            }}
                        >
                            {subtitle}
                        </Typography>
                    </Box>
                )}
            </Box>
        </Box>
    );
};

export default MobileAppPreview;