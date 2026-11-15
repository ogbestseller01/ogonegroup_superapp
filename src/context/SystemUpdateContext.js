// src/context/SystemUpdateContext.js
import React, {
    createContext,
    useCallback,
    useContext,
    useMemo,
    useReducer,
} from 'react';
import { systemUpdateService } from 'services/systemUpdate.service';

// ── State ──────────────────────────────────────────────────────
const initialState = {
    items: [],
    item: null,
    pagination: { total: 0, per_page: 15, current_page: 1, last_page: 1 },
    loading: false,
    submitting: false,
    error: null,
};

// ── Reducer ────────────────────────────────────────────────────
const ACTIONS = {
    REQUEST: 'REQUEST',
    SUBMIT: 'SUBMIT',
    SUCCESS: 'SUCCESS',
    ITEM: 'ITEM',
    ERROR: 'ERROR',
    CLEAR: 'CLEAR_ERROR',
};

function reducer(state, action) {
    switch (action.type) {
        case ACTIONS.REQUEST:
            return { ...state, loading: true, error: null };
        case ACTIONS.SUBMIT:
            return { ...state, submitting: true, error: null };
        case ACTIONS.SUCCESS:
            return { ...state, loading: false, submitting: false, ...action.payload };
        case ACTIONS.ITEM:
            return { ...state, loading: false, submitting: false, item: action.payload };
        case ACTIONS.ERROR:
            return { ...state, loading: false, submitting: false, error: action.payload };
        case ACTIONS.CLEAR:
            return { ...state, error: null };
        default:
            return state;
    }
}

// ── Context ────────────────────────────────────────────────────
const SystemUpdateContext = createContext(null);

export const SystemUpdateProvider = ({ children }) => {
    const [state, dispatch] = useReducer(reducer, initialState);

    // ── List ──────────────────────────────────────────────────
    const fetchAll = useCallback(async (params = {}) => {
        dispatch({ type: ACTIONS.REQUEST });
        try {
            const response = await systemUpdateService.getSystemUpdates(params);
            const body = response?.data?.data ?? response?.data ?? {};
            const data = Array.isArray(body.data)
                ? body.data
                : Array.isArray(body)
                    ? body
                    : [];

            const pagination = {
                total: body.total ?? data.length,
                per_page: body.per_page ?? params?.per_page ?? 15,
                current_page: body.current_page ?? params?.page ?? 1,
                last_page: body.last_page ?? 1,
            };

            dispatch({ type: ACTIONS.SUCCESS, payload: { items: data, pagination } });
            return { data, pagination };
        } catch (error) {
            const msg = error?.message || 'Failed to load system updates.';
            dispatch({ type: ACTIONS.ERROR, payload: msg });
            throw error;
        }
    }, []);

    // ── Single ────────────────────────────────────────────────
    const fetchOne = useCallback(async (id) => {
        dispatch({ type: ACTIONS.REQUEST });
        try {
            const response = await systemUpdateService.getSystemUpdate(id);
            const data = response?.data?.data ?? null;
            dispatch({ type: ACTIONS.ITEM, payload: data });
            return data;
        } catch (error) {
            dispatch({ type: ACTIONS.ERROR, payload: error?.message || 'Failed to load update.' });
            throw error;
        }
    }, []);

    // ── Create ────────────────────────────────────────────────
    const create = useCallback(async (payload) => {
        dispatch({ type: ACTIONS.SUBMIT });
        try {
            const response = await systemUpdateService.createSystemUpdate(payload);
            const data = response?.data?.data ?? null;
            dispatch({ type: ACTIONS.SUCCESS, payload: { item: data } });
            return data;
        } catch (error) {
            dispatch({ type: ACTIONS.ERROR, payload: error?.message || 'Failed to create update.' });
            throw error;
        }
    }, []);

    // ── Save draft ────────────────────────────────────────────
    const saveDraft = useCallback(async (payload) => {
        dispatch({ type: ACTIONS.SUBMIT });
        try {
            const response = await systemUpdateService.saveSystemUpdateDraft(payload);
            const data = response?.data?.data ?? null;
            dispatch({ type: ACTIONS.SUCCESS, payload: { item: data } });
            return data;
        } catch (error) {
            dispatch({ type: ACTIONS.ERROR, payload: error?.message || 'Failed to save draft.' });
            throw error;
        }
    }, []);

    // ── Update ────────────────────────────────────────────────
    const update = useCallback(async (id, payload) => {
        dispatch({ type: ACTIONS.SUBMIT });
        try {
            const response = await systemUpdateService.updateSystemUpdate(id, payload);
            const data = response?.data?.data ?? null;
            dispatch({ type: ACTIONS.SUCCESS, payload: { item: data } });
            return data;
        } catch (error) {
            dispatch({ type: ACTIONS.ERROR, payload: error?.message || 'Failed to update.' });
            throw error;
        }
    }, []);

    // ── Publish ───────────────────────────────────────────────
    const publish = useCallback(async (id) => {
        dispatch({ type: ACTIONS.SUBMIT });
        try {
            const response = await systemUpdateService.publishSystemUpdate(id);
            const data = response?.data?.data ?? null;
            dispatch({ type: ACTIONS.SUCCESS, payload: { item: data } });
            return data;
        } catch (error) {
            dispatch({ type: ACTIONS.ERROR, payload: error?.message || 'Failed to publish.' });
            throw error;
        }
    }, []);

    // ── Close ─────────────────────────────────────────────────
    const close = useCallback(async (id) => {
        dispatch({ type: ACTIONS.SUBMIT });
        try {
            const response = await systemUpdateService.closeSystemUpdate(id);
            const data = response?.data?.data ?? null;
            dispatch({ type: ACTIONS.SUCCESS, payload: { item: data } });
            return data;
        } catch (error) {
            dispatch({ type: ACTIONS.ERROR, payload: error?.message || 'Failed to close.' });
            throw error;
        }
    }, []);

    // ── Delete ────────────────────────────────────────────────
    const remove = useCallback(async (id) => {
        dispatch({ type: ACTIONS.SUBMIT });
        try {
            await systemUpdateService.deleteSystemUpdate(id);
            dispatch({ type: ACTIONS.SUCCESS, payload: {} });
        } catch (error) {
            dispatch({ type: ACTIONS.ERROR, payload: error?.message || 'Failed to delete.' });
            throw error;
        }
    }, []);

    const clearError = useCallback(() => dispatch({ type: ACTIONS.CLEAR }), []);

    // ── Value ─────────────────────────────────────────────────
    const value = useMemo(
        () => ({
            items: state.items,
            item: state.item,
            pagination: state.pagination,
            loading: state.loading,
            submitting: state.submitting,
            error: state.error,
            fetchAll,
            fetchOne,
            create,
            saveDraft,
            update,
            publish,
            close,
            remove,
            clearError,
        }),
        [state, fetchAll, fetchOne, create, saveDraft, update, publish, close, remove, clearError]
    );

    return (
        <SystemUpdateContext.Provider value={value}>
            {children}
        </SystemUpdateContext.Provider>
    );
};

export const useSystemUpdates = () => {
    const ctx = useContext(SystemUpdateContext);
    if (!ctx) {
        throw new Error('useSystemUpdates must be used within <SystemUpdateProvider>');
    }
    return ctx;
};