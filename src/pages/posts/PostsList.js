// src/pages/posts/PostsList.js
import React, { useEffect, useMemo, useState } from 'react';
import {
    Box, Paper, Typography, Button, Table, TableBody, TableCell,
    TableContainer, TableHead, TableRow, TablePagination, TableSortLabel,
    TextField, InputAdornment, IconButton, Chip, Menu, MenuItem, Dialog,
    DialogTitle, DialogContent, DialogActions, CircularProgress,
    useMediaQuery, useTheme, Card, CardContent, Divider, Avatar, Stack,
    Grid, DialogContentText,
} from '@mui/material';
import {
    Search as SearchIcon, Refresh as RefreshIcon, MoreVert as MoreVertIcon,
    Delete as DeleteIcon, Visibility as ViewIcon, Favorite as FavoriteIcon,
    Comment as CommentIcon, Person as PersonIcon, LocationOn as LocationIcon,
    Verified as VerifiedIcon, Star as StarIcon, CalendarToday as CalendarIcon,
    Clear as ClearIcon, PhotoCamera as PhotoCameraIcon,
    Description as DescriptionIcon, Edit as EditIcon, Add as AddIcon,
} from '@mui/icons-material';
import { postService } from 'services/post.service';
import { technicianService } from 'services/technician.service';
import { usePermissions } from 'hooks/usePermissions';
import { useLanguage } from 'context/LanguageContext';
import { showSnackbar } from 'utils/snackbar';
import { tPost } from './postslang';
import { format } from 'date-fns';
import appConfig from '../../config';

import MultiImageCarousel from '../../components/common/MultiImageCarousel';
import PostFormDialog from './PostFormDialog';
import { getImageUrl, getPostImages, normalizePost, normalizePosts } from 'utils/postMedia';

const colors = appConfig.app.colors;

const getHeadCells = (t) => [
    { id: 'post', label: 'Media', disableSort: true },
    { id: 'technician', label: 'Technician', disableSort: true },
    { id: 'likes', label: 'Likes' },
    { id: 'comments', label: 'Comments' },
    { id: 'created_at', label: 'Created' },
    { id: 'actions', label: 'Actions', disableSort: true },
];

const PostsList = () => {
    const theme = useTheme();
    const isMobile = useMediaQuery(theme.breakpoints.down('sm'));
    const showTableView = useMediaQuery(theme.breakpoints.up('md'));

    const { language } = useLanguage();
    const t = (key, replacements) => tPost(language, key, replacements);
    const headCells = useMemo(() => getHeadCells(t), [language]);

    const { can } = usePermissions();
    const canView = can('posts.view');
    const canDelete = can('posts.delete');
    const canEdit = can('posts.edit') || can('posts.create');

    const [posts, setPosts] = useState([]);
    const [loading, setLoading] = useState(false);
    const [pagination, setPagination] = useState({ total: 0, per_page: 10 });

    const [technicians, setTechnicians] = useState([]);
    const [page, setPage] = useState(0);
    const [rowsPerPage, setRowsPerPage] = useState(10);

    const [selectedPost, setSelectedPost] = useState(null);
    const [openViewDialog, setOpenViewDialog] = useState(false);
    const [actionMenu, setActionMenu] = useState(null);
    const [selectedPostForMenu, setSelectedPostForMenu] = useState(null);

    const [formOpen, setFormOpen] = useState(false);
    const [formInitial, setFormInitial] = useState(null);
    const [formSubmitting, setFormSubmitting] = useState(false);

    const [confirmDialog, setConfirmDialog] = useState({ open: false, title: '', message: '', action: null });

    useEffect(() => {
        (async () => {
            try {
                const response = await technicianService.getTechnicians({ per_page: 100, status: 'active' });
                if (response?.data?.status === 'success') {
                    const data = response.data.data;
                    if (data && data.data) setTechnicians(data.data);
                    else if (Array.isArray(data)) setTechnicians(data);
                }
            } catch (err) { console.error(err); }
        })();
    }, []);

    const loadPosts = async () => {
        if (!canView) return;
        setLoading(true);
        try {
            const params = { page: page + 1, per_page: rowsPerPage };
            const response = await postService.getAllPosts(params);
            if (response?.data?.status === 'success') {
                const data = response.data.data;
                if (data && data.data) {
                    setPosts(normalizePosts(data.data));
                    setPagination({ total: data.total || 0, per_page: data.per_page || rowsPerPage });
                } else if (Array.isArray(data)) {
                    setPosts(normalizePosts(data));
                    setPagination({ total: data.length, per_page: rowsPerPage });
                }
            }
        } catch (err) {
            showSnackbar({ type: 'error', message: 'Failed to load posts' });
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => { if (canView) loadPosts(); }, [page, rowsPerPage, canView]);

    const handleViewPost = async (post) => {
        try {
            const response = await postService.getPost(post.id);
            setSelectedPost(normalizePost(response.data.data));
        } catch {
            setSelectedPost(post);
        }
        setOpenViewDialog(true);
    };

    const submitForm = async (payload) => {
        setFormSubmitting(true);
        try {
            if (formInitial?.id) await postService.updatePost(formInitial.id, payload);
            else await postService.createPost(payload);
            setFormOpen(false);
            await loadPosts();
            showSnackbar({ type: 'success', message: 'Saved successfully' });
        } catch (err) {
            showSnackbar({ type: 'error', message: 'Failed to save post' });
        } finally {
            setFormSubmitting(false);
        }
    };

    const handleDeletePost = async (id) => {
        try {
            await postService.deletePost(id);
            showSnackbar({ type: 'success', message: 'Post deleted' });
            await loadPosts();
        } catch (err) {
            showSnackbar({ type: 'error', message: 'Failed to delete post' });
        }
    };

    const handleAction = (type) => {
        const target = selectedPostForMenu;
        setActionMenu(null);
        if (type === 'view') return handleViewPost(target);
        if (type === 'edit') { setFormInitial(target); setFormOpen(true); return; }
        if (type === 'delete') {
            setConfirmDialog({
                open: true, title: 'Delete Post', message: 'Are you sure?',
                action: () => handleDeletePost(target.id)
            });
        }
    };

    if (!canView) return <Typography p={3}>Access Denied</Typography>;

    return (
        <Box sx={{ p: { xs: 1.5, sm: 2.5 }, bgcolor: 'background.default' }}>
            <Paper elevation={0} sx={{ borderRadius: 3, overflow: 'hidden', border: '1px solid', borderColor: 'divider' }}>
                <Box sx={{ p: 3, borderBottom: '1px solid', borderColor: 'divider', display: 'flex', justifyContent: 'space-between' }}>
                    <Typography variant="h5" fontWeight={800}>Posts Management</Typography>
                    <Stack direction="row" spacing={2}>
                        {canEdit && <Button variant="outlined" startIcon={<AddIcon />} onClick={() => { setFormInitial(null); setFormOpen(true); }}>Create</Button>}
                        <Button variant="contained" startIcon={<RefreshIcon />} onClick={loadPosts} disabled={loading}>Refresh</Button>
                    </Stack>
                </Box>

                {showTableView ? (
                    <TableContainer>
                        <Table>
                            <TableHead>
                                <TableRow>
                                    {headCells.map((cell) => (
                                        <TableCell key={cell.id}>{cell.label}</TableCell>
                                    ))}
                                </TableRow>
                            </TableHead>
                            <TableBody>
                                {loading ? <TableRow><TableCell colSpan={6} align="center"><CircularProgress /></TableCell></TableRow> :
                                    posts.map((post) => (
                                        <TableRow key={post.id}>
                                            <TableCell>
                                                <Box sx={{ display: 'flex', gap: 1, alignItems: 'center' }}>
                                                    {post.images.length > 0 && <img src={getImageUrl(post.images[0])} alt="" style={{ width: 48, height: 48, borderRadius: 8, objectFit: 'cover' }} />}
                                                    {post.video_url && <Chip label="Video" size="small" color="primary" />}
                                                </Box>
                                            </TableCell>
                                            <TableCell>{post.technician?.name}</TableCell>
                                            <TableCell>{post.likes_count}</TableCell>
                                            <TableCell>{post.comments_count}</TableCell>
                                            <TableCell>{format(new Date(post.created_at), 'MMM d, yyyy')}</TableCell>
                                            <TableCell>
                                                <IconButton onClick={(e) => { setSelectedPostForMenu(post); setActionMenu(e.currentTarget); }}><MoreVertIcon /></IconButton>
                                            </TableCell>
                                        </TableRow>
                                    ))}
                            </TableBody>
                        </Table>
                    </TableContainer>
                ) : (
                    <Box p={2}>
                        {posts.map(post => (
                            <Card key={post.id} sx={{ mb: 2, p: 2 }}>
                                <Box display="flex" gap={2}>
                                    {post.images.length > 0 && <img src={getImageUrl(post.images[0])} alt="" style={{ width: 80, height: 80, borderRadius: 8 }} />}
                                    {post.video_url && <Chip label="Video" color="primary" />}
                                    <Box flex={1}>
                                        <Typography fontWeight="bold">{post.technician?.name}</Typography>
                                        <Typography variant="caption">{format(new Date(post.created_at), 'MMM d')}</Typography>
                                    </Box>
                                    <IconButton onClick={(e) => { setSelectedPostForMenu(post); setActionMenu(e.currentTarget); }}><MoreVertIcon /></IconButton>
                                </Box>
                            </Card>
                        ))}
                    </Box>
                )}

                <TablePagination
                    component="div" count={pagination.total} rowsPerPage={rowsPerPage} page={page}
                    onPageChange={(e, p) => setPage(p)} onRowsPerPageChange={(e) => setRowsPerPage(parseInt(e.target.value, 10))}
                />
            </Paper>

            <Menu anchorEl={actionMenu} open={Boolean(actionMenu)} onClose={() => setActionMenu(null)}>
                <MenuItem onClick={() => handleAction('view')}><ViewIcon sx={{ mr: 1 }} /> View</MenuItem>
                {canEdit && <MenuItem onClick={() => handleAction('edit')}><EditIcon sx={{ mr: 1 }} /> Edit</MenuItem>}
                {canDelete && <MenuItem onClick={() => handleAction('delete')} sx={{ color: 'error.main' }}><DeleteIcon sx={{ mr: 1 }} /> Delete</MenuItem>}
            </Menu>

            <Dialog open={openViewDialog} onClose={() => setOpenViewDialog(false)} maxWidth="md" fullWidth>
                {selectedPost && (
                    <Box>
                        <DialogTitle>Post Details</DialogTitle>
                        <DialogContent dividers>
                            {selectedPost.images.length > 0 && (
                                <MultiImageCarousel images={selectedPost.images} height={400} fit="contain" showThumbnails />
                            )}
                            {selectedPost.video_url && (
                                <Box mt={2}>
                                    <video src={selectedPost.video_url} controls style={{ width: '100%', borderRadius: 8 }} />
                                </Box>
                            )}
                        </DialogContent>
                        <DialogActions>
                            <Button onClick={() => setOpenViewDialog(false)}>Close</Button>
                        </DialogActions>
                    </Box>
                )}
            </Dialog>

            <PostFormDialog
                open={formOpen} onClose={() => setFormOpen(false)}
                onSubmit={submitForm} initialData={formInitial} submitting={formSubmitting}
            />

            <Dialog open={confirmDialog.open} onClose={() => setConfirmDialog({ ...confirmDialog, open: false })}>
                <DialogTitle>{confirmDialog.title}</DialogTitle>
                <DialogContent><DialogContentText>{confirmDialog.message}</DialogContentText></DialogContent>
                <DialogActions>
                    <Button onClick={() => setConfirmDialog({ ...confirmDialog, open: false })}>Cancel</Button>
                    <Button color="error" onClick={() => { confirmDialog.action(); setConfirmDialog({ ...confirmDialog, open: false }); }}>Delete</Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
};

export default PostsList;