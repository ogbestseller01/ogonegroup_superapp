// src/components/common/MultiImageCarousel.jsx
import React, { useMemo, useState } from 'react';
import { Box, IconButton, Stack } from '@mui/material';
import {
    ChevronLeft as ChevronLeftIcon,
    ChevronRight as ChevronRightIcon,
    PhotoCamera as PhotoCameraIcon,
} from '@mui/icons-material';
import { getImageUrl } from 'utils/postMedia';

/**
 * Reusable multi-image viewer.
 *
 * Props:
 *  - images: string[] (paths or full URLs)
 *  - height / aspectRatio: layout
 *  - fit: 'cover' | 'contain'
 *  - onImageClick?(index): optional click handler (for full-screen)
 *  - emptyFallback: optional node shown when no images
 *  - showThumbnails: optional, renders a thumbnail strip below
 */
const MultiImageCarousel = ({
                                images = [],
                                height,
                                aspectRatio,
                                fit = 'cover',
                                rounded = 0,
                                onImageClick,
                                showThumbnails = false,
                                emptyFallback = null,
                            }) => {
    const safeImages = useMemo(
        () => (Array.isArray(images) ? images.filter(Boolean) : []),
        [images]
    );
    const [index, setIndex] = useState(0);

    if (safeImages.length === 0) {
        if (emptyFallback) return emptyFallback;
        return (
            <Box
                sx={{
                    width: '100%',
                    height: height || 220,
                    bgcolor: 'action.hover',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    borderRadius: rounded,
                }}
            >
                <PhotoCameraIcon sx={{ color: 'text.disabled', fontSize: 40 }} />
            </Box>
        );
    }

    const total = safeImages.length;
    const prev = () => setIndex((i) => (i - 1 + total) % total);
    const next = () => setIndex((i) => (i + 1) % total);

    return (
        <Box>
            <Box
                sx={{
                    position: 'relative',
                    width: '100%',
                    ...(height ? { height } : {}),
                    ...(aspectRatio ? { aspectRatio } : {}),
                    bgcolor: 'action.hover',
                    overflow: 'hidden',
                    borderRadius: rounded,
                }}
            >
                <Box
                    component="img"
                    src={getImageUrl(safeImages[index])}
                    alt={`image ${index + 1}`}
                    onClick={() => onImageClick?.(index)}
                    sx={{
                        width: '100%',
                        height: '100%',
                        objectFit: fit,
                        display: 'block',
                        cursor: onImageClick ? 'zoom-in' : 'default',
                    }}
                />

                {total > 1 && (
                    <>
                        <IconButton
                            size="small"
                            onClick={prev}
                            sx={{
                                position: 'absolute',
                                left: 8,
                                top: '50%',
                                transform: 'translateY(-50%)',
                                bgcolor: 'rgba(0,0,0,0.45)',
                                color: '#fff',
                                '&:hover': { bgcolor: 'rgba(0,0,0,0.7)' },
                            }}
                        >
                            <ChevronLeftIcon fontSize="small" />
                        </IconButton>
                        <IconButton
                            size="small"
                            onClick={next}
                            sx={{
                                position: 'absolute',
                                right: 8,
                                top: '50%',
                                transform: 'translateY(-50%)',
                                bgcolor: 'rgba(0,0,0,0.45)',
                                color: '#fff',
                                '&:hover': { bgcolor: 'rgba(0,0,0,0.7)' },
                            }}
                        >
                            <ChevronRightIcon fontSize="small" />
                        </IconButton>
                        <Box
                            sx={{
                                position: 'absolute',
                                top: 8,
                                right: 8,
                                px: 1,
                                py: 0.25,
                                borderRadius: 1,
                                bgcolor: 'rgba(0,0,0,0.6)',
                                color: '#fff',
                                fontSize: 12,
                                fontWeight: 600,
                            }}
                        >
                            {index + 1}/{total}
                        </Box>
                    </>
                )}
            </Box>

            {showThumbnails && total > 1 && (
                <Stack
                    direction="row"
                    spacing={1}
                    sx={{ mt: 1, overflowX: 'auto', pb: 0.5 }}
                >
                    {safeImages.map((src, i) => (
                        <Box
                            key={`${src}-${i}`}
                            component="img"
                            src={getImageUrl(src)}
                            alt={`thumb-${i + 1}`}
                            onClick={() => setIndex(i)}
                            sx={{
                                width: 64,
                                height: 64,
                                objectFit: 'cover',
                                flexShrink: 0,
                                borderRadius: 1,
                                cursor: 'pointer',
                                border: '2px solid',
                                borderColor:
                                    i === index ? 'primary.main' : 'divider',
                                opacity: i === index ? 1 : 0.7,
                                transition: 'opacity 0.2s, border-color 0.2s',
                            }}
                        />
                    ))}
                </Stack>
            )}
        </Box>
    );
};

export default MultiImageCarousel;