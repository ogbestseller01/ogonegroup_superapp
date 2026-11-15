// src/contexts/TechnicianContext.js
import React, {
    createContext, useCallback, useContext, useMemo, useReducer,
} from 'react';
import { technicianService } from 'services/technician.service';

// ── State shape ──────────────────────────────────────────────
const initialState = {
    // legacy single-list
    items: [],
    item: null,

    // split admin lists
    pendingItems: [],
    approvedItems: [],

    // biometrics cache: { [technicianId]: payload }
    biometrics: {},

    loading: false,
    error: null,
};

// ── Reducer ──────────────────────────────────────────────────
const ACTIONS = {
    REQUEST:  'REQUEST',
    SUCCESS:  'SUCCESS',
    ERROR:    'ERROR',
    CLEAR:    'CLEAR_ERROR',
};

function reducer(state, action) {
    switch (action.type) {
        case ACTIONS.REQUEST:
            return { ...state, loading: true, error: null };

        case ACTIONS.SUCCESS:
            return { ...state, loading: false, ...action.payload };

        case ACTIONS.ERROR:
            return { ...state, loading: false, error: action.payload };

        case ACTIONS.CLEAR:
            return { ...state, error: null };

        default:
            return state;
    }
}

// ── Context ──────────────────────────────────────────────────
const TechnicianContext = createContext(null);

export const TechnicianProvider = ({ children }) => {
    const [state, dispatch] = useReducer(reducer, initialState);

    // ── Legacy: full list ────────────────────────────────────
    const fetchAll = useCallback(async (params) => {
        dispatch({ type: ACTIONS.REQUEST });
        try {
            const response = await technicianService.getAdminTechnicians(params);
            const body = response?.data?.data || {};
            const data = Array.isArray(body.data) ? body.data : [];
            const pagination = {
                total:        body.total        ?? data.length,
                per_page:     body.per_page     ?? params?.per_page ?? 15,
                current_page: body.current_page ?? 1,
                last_page:    body.last_page    ?? 1,
            };

            dispatch({ type: ACTIONS.SUCCESS, payload: { items: data } });
            return { data, pagination };
        } catch (error) {
            const msg = error?.message || 'Failed to load technicians.';
            dispatch({ type: ACTIONS.ERROR, payload: msg });
            throw error;
        }
    }, []);

    // ── Legacy: single technician ────────────────────────────
    const fetchOne = useCallback(async (id) => {
        dispatch({ type: ACTIONS.REQUEST });
        try {
            const response = await technicianService.getTechnician(id);
            const data = response?.data?.data ?? null;
            dispatch({ type: ACTIONS.SUCCESS, payload: { item: data } });
            return { data };
        } catch (error) {
            dispatch({ type: ACTIONS.ERROR, payload: error?.message || 'Failed to load technician.' });
            throw error;
        }
    }, []);

    // ── Split: pending ───────────────────────────────────────
    const fetchPending = useCallback(async (params) => {
        dispatch({ type: ACTIONS.REQUEST });
        try {
            const response = await technicianService.getPendingTechnicians(params);
            const body = response?.data?.data || {};
            const data = Array.isArray(body.data) ? body.data : [];
            const pagination = {
                total:        body.total        ?? data.length,
                per_page:     body.per_page     ?? params?.per_page ?? 15,
                current_page: body.current_page ?? 1,
                last_page:    body.last_page    ?? 1,
            };

            dispatch({ type: ACTIONS.SUCCESS, payload: { pendingItems: data } });
            return { data, pagination };
        } catch (error) {
            dispatch({ type: ACTIONS.ERROR, payload: error?.message || 'Failed to load pending technicians.' });
            throw error;
        }
    }, []);

    // ── Split: approved ──────────────────────────────────────
    const fetchApproved = useCallback(async (params) => {
        dispatch({ type: ACTIONS.REQUEST });
        try {
            const response = await technicianService.getApprovedTechnicians(params);
            const body = response?.data?.data || {};
            const data = Array.isArray(body.data) ? body.data : [];
            const pagination = {
                total:        body.total        ?? data.length,
                per_page:     body.per_page     ?? params?.per_page ?? 15,
                current_page: body.current_page ?? 1,
                last_page:    body.last_page    ?? 1,
            };

            dispatch({ type: ACTIONS.SUCCESS, payload: { approvedItems: data } });
            return { data, pagination };
        } catch (error) {
            dispatch({ type: ACTIONS.ERROR, payload: error?.message || 'Failed to load approved technicians.' });
            throw error;
        }
    }, []);

    // ── Biometrics (cached per technician) ───────────────────
    const fetchBiometrics = useCallback(async (id, { force = false } = {}) => {
        if (!force && state.biometrics[id]) {
            return state.biometrics[id];
        }
        dispatch({ type: ACTIONS.REQUEST });
        try {
            const response = await technicianService.getTechnicianBiometrics(id);
            const data = response?.data?.data ?? null;
            dispatch({
                type: ACTIONS.SUCCESS,
                payload: { biometrics: { ...state.biometrics, [id]: data } },
            });
            return data;
        } catch (error) {
            dispatch({ type: ACTIONS.ERROR, payload: error?.message || 'Failed to load biometrics.' });
            throw error;
        }
    }, [state.biometrics]);

    // ── Misc ─────────────────────────────────────────────────
    const clearError = useCallback(() => dispatch({ type: ACTIONS.CLEAR }), []);

    const value = useMemo(() => ({
        // state
        items:         state.items,
        item:          state.item,
        pendingItems:  state.pendingItems,
        approvedItems: state.approvedItems,
        biometrics:    state.biometrics,
        loading:       state.loading,
        error:         state.error,

        // actions
        fetchAll,
        fetchOne,
        fetchPending,
        fetchApproved,
        fetchBiometrics,
        clearError,
    }), [
        state,
        fetchAll,
        fetchOne,
        fetchPending,
        fetchApproved,
        fetchBiometrics,
        clearError,
    ]);

    return (
        <TechnicianContext.Provider value={value}>
            {children}
        </TechnicianContext.Provider>
    );
};

export const useTechnicians = () => {
    const ctx = useContext(TechnicianContext);
    if (!ctx) {
        throw new Error('useTechnicians must be used within <TechnicianProvider>');
    }
    return ctx;
};