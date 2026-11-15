import { useState, useEffect, useCallback } from 'react';
import { subscriptionService } from 'services/subscription.service';
import { showSnackbar } from 'utils/snackbar';

const initialForm = {
    name: '',
    price: '',
    duration_days: 1,
    currency: 'TZS',
    description: '',
    is_active: true,
    display_order: 0,
};

export const useRateCardForm = () => {
    const [rateCards, setRateCards] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);
    const [openModal, setOpenModal] = useState(false);
    const [editing, setEditing] = useState(null);
    const [form, setForm] = useState(initialForm);

    // Fetch rate cards directly
    const getRateCards = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            const response = await subscriptionService.getRateCards();
            console.log('Rate Cards API Response:', response);

            // Handle nested response structure
            let data = [];
            if (response?.data?.status === 'success') {
                const responseData = response.data.data;
                // Check if data is paginated (has data.data)
                if (responseData?.data) {
                    data = responseData.data;
                } else if (Array.isArray(responseData)) {
                    data = responseData;
                } else {
                    data = [];
                }
            } else if (Array.isArray(response?.data)) {
                data = response.data;
            }

            setRateCards(data);
        } catch (err) {
            console.error('Error fetching rate cards:', err);
            setError(err.message || 'Failed to load rate cards');
            showSnackbar({ type: 'error', message: 'Failed to load rate cards' });
        } finally {
            setLoading(false);
        }
    }, []);

    // Load on mount
    useEffect(() => {
        getRateCards();
    }, [getRateCards]);

    const resetForm = useCallback(() => {
        setForm(initialForm);
        setEditing(null);
    }, []);

    const openCreate = useCallback(() => {
        resetForm();
        setOpenModal(true);
    }, [resetForm]);

    const openEdit = useCallback((card) => {
        setEditing(card);
        setForm({ ...card });
        setOpenModal(true);
    }, []);

    const closeModal = useCallback(() => {
        setOpenModal(false);
        resetForm();
    }, [resetForm]);

    const handleChange = useCallback((field, value) => {
        setForm(prev => ({ ...prev, [field]: value }));
    }, []);


    const handleSave = useCallback(async () => {
        try {
            if (editing) {
                await subscriptionService.updateRateCard(editing.id, form);
                showSnackbar({ type: 'success', message: 'Rate card updated' });
            } else {
                await subscriptionService.createRateCard(form);
                showSnackbar({ type: 'success', message: 'Rate card created' });
            }
            closeModal();
            await getRateCards();
        } catch (err) {
            console.error('Save error:', err);
            showSnackbar({ type: 'error', message: err.message || 'Operation failed' });
        }
    }, [editing, form, closeModal, getRateCards]);


    const handleDelete = useCallback(async (id) => {
        if (!window.confirm('Delete this rate card?')) return;
        try {
            await subscriptionService.deleteRateCard(id);
            showSnackbar({ type: 'success', message: 'Deleted' });
            await getRateCards();
        } catch (err) {
            console.error('Delete error:', err);
            showSnackbar({ type: 'error', message: err.message || 'Delete failed' });
        }
    }, [getRateCards]);

    return {
        rateCards,
        loading,
        error,
        openModal,
        editing,
        form,
        openCreate,
        openEdit,
        closeModal,
        handleChange,
        handleSave,
        handleDelete,
        refresh: getRateCards,
    };
};