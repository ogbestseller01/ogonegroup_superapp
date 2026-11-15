// src/contexts/PostContext.js
import { createDataContext } from './createDataContext';
import { postService } from 'services/post.service';

const adapter = {
    getAll: (params) => postService.getAllPosts(params),
    getOne: (id) => postService.getPost(id),
    create: (data) => postService.createPost(data),
    update: (id, data) => postService.updatePost(id, data),
    delete: (id) => postService.deletePost(id),
};

export const { Provider: PostProvider, useResource: usePosts } = createDataContext(adapter, 'Post');