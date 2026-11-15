// src/components/posts/PostFormDialog.jsx
import React, { useEffect, useRef, useState } from 'react';
import {
    Dialog, DialogTitle, DialogContent, DialogActions, Button,
    Box, Typography, IconButton, Stack, CircularProgress,
} from '@mui/material';
import {
    AddPhotoAlternate as AddPhotoIcon,
    Close as CloseIcon,
    Delete as DeleteIcon,
    VideoCall as VideoCallIcon,
} from '@mui/icons-material';
import { getImageUrl, getPostImages } from 'utils/postMedia';

const PostFormDialog = ({
                            open, onClose, onSubmit, initialData = null, submitting = false, canEdit = true,
                        }) => {
    const isEdit = Boolean(initialData?.id);
    const [newFiles, setNewFiles] = useState([]);
    const [newPreviews, setNewPreviews] = useState([]);
    const [keepImages, setKeepImages] = useState([]);
    const [videoFile, setVideoFile] = useState(null);
    const [removeVideo, setRemoveVideo] = useState(false);

    const fileInputRef = useRef(null);
    const videoInputRef = useRef(null);

    useEffect(() => {
        if (!open) return;
        setNewFiles([]);
        setNewPreviews([]);
        setKeepImages(isEdit ? getPostImages(initialData) : []);
        setVideoFile(null);
        setRemoveVideo(false);
    }, [open, initialData, isEdit]);

    useEffect(() => {
        return () => {
            newPreviews.forEach((p) => URL.revokeObjectURL(p.url));
        };
    }, [newPreviews]);

    const handleFileChange = (e) => {
        const picked = Array.from(e.target.files || []);
        if (!picked.length) return;
        const previews = picked.map((file) => ({ file, url: URL.createObjectURL(file) }));
        setNewFiles((prev) => [...prev, ...picked]);
        setNewPreviews((prev) => [...prev, ...previews]);
        if (fileInputRef.current) fileInputRef.current.value = '';
    };

    const handleVideoChange = (e) => {
        const file = e.target.files?.[0];
        if (file) {
            setVideoFile(file);
            setRemoveVideo(false);
        }
        if (videoInputRef.current) videoInputRef.current.value = '';
    };

    const removeNewFile = (idx) => {
        setNewPreviews((prev) => {
            const target = prev[idx];
            if (target) URL.revokeObjectURL(target.url);
            return prev.filter((_, i) => i !== idx);
        });
        setNewFiles((prev) => prev.filter((_, i) => i !== idx));
    };

    const removeKept = (url) => {
        setKeepImages((prev) => prev.filter((u) => u !== url));
    };

    const handleSubmit = () => {
        onSubmit?.({
            images: newFiles,
            keep_images: keepImages,
            video: videoFile,
            remove_video: removeVideo,
        });
    };

    const totalImages = keepImages.length + newFiles.length;
    const hasExistingVideo = initialData?.video_url && !removeVideo;

    return (
        <Dialog open={open} onClose={submitting ? undefined : onClose} fullWidth maxWidth="sm" PaperProps={{ sx: { borderRadius: 3 } }}>
            <DialogTitle sx={{ fontWeight: 700, pr: 6 }}>
                {isEdit ? 'Edit Post' : 'Create Post'}
                <IconButton onClick={onClose} size="small" sx={{ position: 'absolute', right: 12, top: 12 }} disabled={submitting}>
                    <CloseIcon />
                </IconButton>
            </DialogTitle>

            <DialogContent dividers>
                <Stack spacing={3}>
                    {/* VIDEO SECTION */}
                    <Box>
                        <Typography variant="subtitle2" fontWeight={600} gutterBottom>
                            Video Clip
                        </Typography>
                        {!videoFile && !hasExistingVideo ? (
                            <Button
                                variant="outlined"
                                startIcon={<VideoCallIcon />}
                                onClick={() => videoInputRef.current?.click()}
                                sx={{ borderRadius: 2, textTransform: 'none' }}
                                disabled={!canEdit}
                            >
                                Attach Video
                            </Button>
                        ) : (
                            <Stack direction="row" spacing={2} alignItems="center" sx={{ p: 2, bgcolor: 'action.hover', borderRadius: 2 }}>
                                <VideoCallIcon color="primary" />
                                <Typography variant="body2" sx={{ flex: 1 }} noWrap>
                                    {videoFile ? videoFile.name : 'Existing Video Attached'}
                                </Typography>
                                <IconButton size="small" color="error" onClick={() => { setVideoFile(null); setRemoveVideo(true); }}>
                                    <DeleteIcon />
                                </IconButton>
                            </Stack>
                        )}
                        <input type="file" hidden accept="video/*" ref={videoInputRef} onChange={handleVideoChange} />
                    </Box>

                    {/* IMAGES SECTION */}
                    <Box>
                        <Typography variant="subtitle2" fontWeight={600} gutterBottom>
                            Images ({totalImages})
                        </Typography>
                        <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(90px, 1fr))', gap: 1 }}>
                            {keepImages.map((url) => (
                                <Box key={`kept-${url}`} sx={{ position: 'relative', aspectRatio: '1 / 1', borderRadius: 1, overflow: 'hidden', bgcolor: 'action.hover' }}>
                                    <Box component="img" src={getImageUrl(url)} alt="" sx={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                                    <IconButton size="small" onClick={() => removeKept(url)} sx={{ position: 'absolute', top: 2, right: 2, bgcolor: 'rgba(0,0,0,0.55)', color: '#fff' }}>
                                        <DeleteIcon fontSize="small" />
                                    </IconButton>
                                </Box>
                            ))}
                            {newPreviews.map((p, idx) => (
                                <Box key={`new-${p.url}`} sx={{ position: 'relative', aspectRatio: '1 / 1', borderRadius: 1, overflow: 'hidden', bgcolor: 'action.hover' }}>
                                    <Box component="img" src={p.url} alt="" sx={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                                    <IconButton size="small" onClick={() => removeNewFile(idx)} sx={{ position: 'absolute', top: 2, right: 2, bgcolor: 'rgba(0,0,0,0.55)', color: '#fff' }}>
                                        <DeleteIcon fontSize="small" />
                                    </IconButton>
                                </Box>
                            ))}
                            {canEdit && (
                                <Box onClick={() => fileInputRef.current?.click()} sx={{
                                    aspectRatio: '1 / 1', borderRadius: 1, border: '2px dashed', borderColor: 'divider',
                                    display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
                                    cursor: 'pointer', color: 'text.secondary', '&:hover': { borderColor: 'primary.main', color: 'primary.main' }
                                }}>
                                    <AddPhotoIcon />
                                    <Typography variant="caption" sx={{ mt: 0.5 }}>Add</Typography>
                                </Box>
                            )}
                        </Box>
                        <input type="file" hidden multiple accept="image/*" ref={fileInputRef} onChange={handleFileChange} />
                    </Box>
                </Stack>
            </DialogContent>

            <DialogActions sx={{ p: 2 }}>
                <Button onClick={onClose} disabled={submitting} sx={{ textTransform: 'none', fontWeight: 600 }}>Cancel</Button>
                <Button
                    variant="contained" onClick={handleSubmit}
                    disabled={submitting || totalImages === 0 && !videoFile && !hasExistingVideo}
                    sx={{ textTransform: 'none', fontWeight: 700, borderRadius: 2 }}
                >
                    {submitting ? <CircularProgress size={18} sx={{ color: '#fff' }} /> : isEdit ? 'Save Changes' : 'Create'}
                </Button>
            </DialogActions>
        </Dialog>
    );
};

export default PostFormDialog;