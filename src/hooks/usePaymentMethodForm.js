import { useState, useCallback, useEffect } from 'react';
import { subscriptionService } from 'services/subscription.service';
import { showSnackbar } from 'utils/snackbar';

const initialForm = {
    name: '',
    phone_number: '',
    account_name: '',
    is_active: true,
    display_order: 0,
    logo: null,
};

export const usePaymentMethodForm = () => {
    const [paymentMethods, setPaymentMethods] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);
    const [openModal, setOpenModal] = useState(false);
    const [editing, setEditing] = useState(null);
    const [form, setForm] = useState(initialForm);
    const [file, setFile] = useState(null);

    // ============================================================
    // FETCH PAYMENT METHODS
    // ============================================================
    const getPaymentMethods = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            const response = await subscriptionService.getPaymentMethods();

            let data = [];
            if (response?.data?.status === 'success') {
                const responseData = response.data.data;
                if (responseData?.data) {
                    data = responseData.data;
                } else if (Array.isArray(responseData)) {
                    data = responseData;
                }
            }

            setPaymentMethods(data);
            return data;
        } catch (err) {
            console.error('Error fetching payment methods:', err);
            setError(err.message || 'Failed to load payment methods');
            showSnackbar({ type: 'error', message: 'Failed to load payment methods' });
        } finally {
            setLoading(false);
        }
    }, []);

    // Load on mount
    useEffect(() => {
        getPaymentMethods();
    }, [getPaymentMethods]);

    // ============================================================
    // FORM HELPERS
    // ============================================================
    const resetForm = useCallback(() => {
        setForm(initialForm);
        setFile(null);
        setEditing(null);
    }, []);

    const openCreate = useCallback(() => {
        resetForm();
        setOpenModal(true);
    }, [resetForm]);

    const openEdit = useCallback((method) => {
        setEditing(method);
        setForm({
            name: method.name || '',
            phone_number: method.phone_number || '',
            account_name: method.account_name || '',
            is_active: method.is_active ?? true,
            display_order: method.display_order || 0,
            logo: null,
        });
        setFile(null);
        setOpenModal(true);
    }, []);

    const closeModal = useCallback(() => {
        setOpenModal(false);
        resetForm();
    }, [resetForm]);

    const handleChange = useCallback((field, value) => {
        setForm(prev => ({ ...prev, [field]: value }));
    }, []);

    const handleFileChange = useCallback((file) => {
        setFile(file);
    }, []);

    // ============================================================
    // CREATE PAYMENT METHOD
    // ============================================================
    const createPaymentMethod = useCallback(async (data) => {
        const response = await subscriptionService.createPaymentMethod(data);
        if (response?.data?.status === 'success') {
            return response.data.data;
        }
        throw new Error(response?.data?.message || 'Failed to create payment method');
    }, []);

    // ============================================================
    // UPDATE PAYMENT METHOD
    // ============================================================
    const updatePaymentMethod = useCallback(async (id, data) => {
        const response = await subscriptionService.updatePaymentMethod(id, data);
        if (response?.data?.status === 'success') {
            return response.data.data;
        }
        throw new Error(response?.data?.message || 'Failed to update payment method');
    }, []);

    // ============================================================
    // DELETE PAYMENT METHOD
    // ============================================================
    const deletePaymentMethod = useCallback(async (id) => {
        const response = await subscriptionService.deletePaymentMethod(id);
        if (response?.data?.status === 'success') {
            return true;
        }
        throw new Error(response?.data?.message || 'Failed to delete payment method');
    }, []);

    // ============================================================
    // SAVE (Create or Update) - FIXED
    // ============================================================
    const handleSave = useCallback(async () => {
        // ✅ Validate required fields
        const name = form.name?.trim();
        const phoneNumber = form.phone_number?.trim();

        if (!name) {
            showSnackbar({ type: 'error', message: 'Name is required' });
            return;
        }
        if (!phoneNumber) {
            showSnackbar({ type: 'error', message: 'Phone number is required' });
            return;
        }

        try {
            // ✅ Create FormData with proper string values
            const data = new FormData();

            // ✅ Explicitly convert all values to strings
            data.append('name', String(name));
            data.append('phone_number', String(phoneNumber));
            data.append('account_name', String(form.account_name?.trim() || ''));
            data.append('is_active', form.is_active ? '1' : '0');
            data.append('display_order', String(form.display_order || 0));

            // ✅ Only append logo if a file is selected
            if (file) {
                data.append('logo', file);
            }

            if (editing) {
                data.append('_method', 'PUT');
                await updatePaymentMethod(editing.id, data);
                showSnackbar({ type: 'success', message: 'Payment method updated successfully' });
            } else {
                await createPaymentMethod(data);
                showSnackbar({ type: 'success', message: 'Payment method created successfully' });
            }

            closeModal();
            await getPaymentMethods();
        } catch (err) {
            console.error('Save error:', err);

            // ✅ Better error message handling
            let errorMessage = 'Operation failed';
            if (err.response?.data?.message) {
                errorMessage = err.response.data.message;
            } else if (err.response?.data?.errors) {
                const errors = err.response.data.errors;
                errorMessage = Object.values(errors).flat().join(', ');
            } else if (err.message) {
                errorMessage = err.message;
            }

            showSnackbar({ type: 'error', message: errorMessage });
        }
    }, [editing, form, file, createPaymentMethod, updatePaymentMethod, closeModal, getPaymentMethods]);

    // ============================================================
    // DELETE
    // ============================================================
    const handleDelete = useCallback(async (id) => {
        try {
            await deletePaymentMethod(id);
            showSnackbar({ type: 'success', message: 'Payment method deleted successfully' });
            await getPaymentMethods();
        } catch (err) {
            console.error('Delete error:', err);
            let errorMessage = 'Delete failed';
            if (err.response?.data?.message) {
                errorMessage = err.response.data.message;
            } else if (err.message) {
                errorMessage = err.message;
            }
            showSnackbar({ type: 'error', message: errorMessage });
        }
    }, [deletePaymentMethod, getPaymentMethods]);

    return {
        paymentMethods,
        loading,
        error,
        openModal,
        editing,
        form,
        file,
        openCreate,
        openEdit,
        closeModal,
        handleChange,
        handleFileChange,
        handleSave,
        handleDelete,
        refresh: getPaymentMethods,
    };
};