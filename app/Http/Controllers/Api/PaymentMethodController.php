<?php

namespace App\Http\Controllers\Api;

use App\Models\PaymentMethod;
use App\Models\Subscription;
use App\Traits\Auditable;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class PaymentMethodController extends BaseApiController
{
    use Auditable;

    public function index(Request $request)
    {
        try {
            $user = auth()->user();
            if (!$user || (!$user->hasRole('ADMINISTRATOR') && !$user->can('subscriptions.manage'))) {
                return $this->forbidden('You need administrator role or subscriptions.manage permission.');
            }

            $query = PaymentMethod::query();

            if ($request->filled('search')) {
                $search = $request->search;
                $query->where(function($q) use ($search) {
                    $q->where('name', 'like', "%{$search}%")
                      ->orWhere('account_name', 'like', "%{$search}%")
                      ->orWhere('phone_number', 'like', "%{$search}%");
                });
            }

            $paymentMethods = $query->orderBy('display_order')
                ->paginate($request->input('per_page', 20));

            $paymentMethods->getCollection()->transform(function($item) {
                if ($item->logo) {
                    $item->logo_url = url('storage/' . $item->logo);
                }
                return $item;
            });

            return $this->successResponse($paymentMethods, 'Payment methods retrieved successfully');
        } catch (\Exception $e) {
            \Log::error('PaymentMethodController index error: ' . $e->getMessage());
            return $this->serverError('Failed to retrieve payment methods.');
        }
    }

    public function store(Request $request)
    {
        try {
            $user = auth()->user();
            if (!$user || (!$user->hasRole('ADMINISTRATOR') && !$user->can('subscriptions.manage'))) {
                return $this->forbidden('You need administrator role or subscriptions.manage permission.');
            }

            $rules = [
                'name' => 'required|string|max:255',
                'phone_number' => 'required|string|max:50',
                'account_name' => 'nullable|string|max:255',
                'is_active' => 'boolean',
                'display_order' => 'nullable|integer|min:0',
            ];

            if ($request->hasFile('logo')) {
                $rules['logo'] = 'nullable|image|mimes:jpg,jpeg,png,webp|max:2048';
            }

            $data = $request->validate($rules);

            $data['name'] = (string) $data['name'];
            $data['phone_number'] = (string) $data['phone_number'];
            $data['account_name'] = isset($data['account_name']) ? (string) $data['account_name'] : null;
            $data['slug'] = Str::slug($data['name']);
            $data['is_active'] = isset($data['is_active']) ? (bool) $data['is_active'] : true;
            $data['display_order'] = isset($data['display_order']) ? (int) $data['display_order'] : 0;

            if ($request->hasFile('logo')) {
                $file = $request->file('logo');
                $filename = time() . '_' . Str::slug($data['name']) . '.' . $file->getClientOriginalExtension();
                $path = $file->storeAs('payment_logos', $filename, 'public');
                $data['logo'] = $path;
            }

            $paymentMethod = PaymentMethod::create($data);

            if ($paymentMethod->logo) {
                $paymentMethod->logo_url = url('storage/' . $paymentMethod->logo);
            }

            $this->logAudit(
                'create_payment_method',
                'payment_method',
                $paymentMethod->id,
                "Payment method created: {$paymentMethod->name}"
            );

            return $this->created($paymentMethod, 'Payment method created successfully.');
        } catch (ValidationException $e) {
            return $this->validationError($e->errors());
        } catch (\Exception $e) {
            \Log::error('PaymentMethodController store error: ' . $e->getMessage());
            return $this->serverError('Failed to create payment method: ' . $e->getMessage());
        }
    }

    public function show($id)
    {
        try {
            $user = auth()->user();
            if (!$user || (!$user->hasRole('ADMINISTRATOR') && !$user->can('subscriptions.manage'))) {
                return $this->forbidden('You need administrator role or subscriptions.manage permission.');
            }

            $paymentMethod = PaymentMethod::findOrFail($id);
            
            if ($paymentMethod->logo) {
                $paymentMethod->logo_url = url('storage/' . $paymentMethod->logo);
            }

            return $this->successResponse($paymentMethod, 'Payment method retrieved successfully.');
        } catch (ModelNotFoundException $e) {
            return $this->notFound('Payment method not found.');
        } catch (\Exception $e) {
            \Log::error('PaymentMethodController show error: ' . $e->getMessage());
            return $this->serverError('Failed to retrieve payment method.');
        }
    }

    public function update(Request $request, $id)
    {
        try {
            $user = auth()->user();
            if (!$user || (!$user->hasRole('ADMINISTRATOR') && !$user->can('subscriptions.manage'))) {
                return $this->forbidden('You need administrator role or subscriptions.manage permission.');
            }

            $paymentMethod = PaymentMethod::findOrFail($id);

            $rules = [
                'name' => 'sometimes|string|max:255',
                'phone_number' => 'sometimes|string|max:50',
                'account_name' => 'nullable|string|max:255',
                'is_active' => 'boolean',
                'display_order' => 'nullable|integer|min:0',
            ];

            if ($request->hasFile('logo')) {
                $rules['logo'] = 'nullable|image|mimes:jpg,jpeg,png,webp|max:2048';
            }

            $data = $request->validate($rules);

            if (isset($data['name'])) {
                $data['name'] = (string) $data['name'];
                $data['slug'] = Str::slug($data['name']);
            }
            if (isset($data['phone_number'])) {
                $data['phone_number'] = (string) $data['phone_number'];
            }
            if (isset($data['account_name'])) {
                $data['account_name'] = (string) $data['account_name'];
            }
            if (isset($data['is_active'])) {
                $data['is_active'] = (bool) $data['is_active'];
            }
            if (isset($data['display_order'])) {
                $data['display_order'] = (int) $data['display_order'];
            }

            if ($request->hasFile('logo')) {
                if ($paymentMethod->logo && Storage::disk('public')->exists($paymentMethod->logo)) {
                    Storage::disk('public')->delete($paymentMethod->logo);
                }
                
                $file = $request->file('logo');
                $filename = time() . '_' . Str::slug($data['name'] ?? $paymentMethod->name) . '.' . $file->getClientOriginalExtension();
                $path = $file->storeAs('payment_logos', $filename, 'public');
                $data['logo'] = $path;
            }

            $old = $paymentMethod->toArray();
            $paymentMethod->update($data);
            $new = $paymentMethod->fresh()->toArray();

            if ($paymentMethod->logo) {
                $paymentMethod->logo_url = url('storage/' . $paymentMethod->logo);
            }

            $this->logAudit(
                'update_payment_method',
                'payment_method',
                $paymentMethod->id,
                "Payment method updated: {$paymentMethod->name}",
                $old,
                $new
            );

            return $this->successResponse($paymentMethod, 'Payment method updated successfully.');
        } catch (ModelNotFoundException $e) {
            return $this->notFound('Payment method not found.');
        } catch (ValidationException $e) {
            return $this->validationError($e->errors());
        } catch (\Exception $e) {
            \Log::error('PaymentMethodController update error: ' . $e->getMessage());
            return $this->serverError('Failed to update payment method: ' . $e->getMessage());
        }
    }

    public function destroy($id)
    {
        try {
            $user = auth()->user();
            if (!$user || (!$user->hasRole('ADMINISTRATOR') && !$user->can('subscriptions.manage'))) {
                return $this->forbidden('You need administrator role or subscriptions.manage permission.');
            }

            $paymentMethod = PaymentMethod::find($id);
            
            if (!$paymentMethod) {
                return $this->notFound('Payment method not found.');
            }

            $hasActiveSubscriptions = Subscription::where('payment_method', $paymentMethod->name)
                ->whereIn('status', ['pending', 'active'])
                ->exists();

            if ($hasActiveSubscriptions) {
                return $this->errorResponse(
                    'Cannot delete payment method that is being used by pending or active subscriptions.',
                    422
                );
            }

            if ($paymentMethod->logo && Storage::disk('public')->exists($paymentMethod->logo)) {
                Storage::disk('public')->delete($paymentMethod->logo);
            }

            $paymentMethod->delete();

            $this->logAudit(
                'delete_payment_method',
                'payment_method',
                $paymentMethod->id,
                "Payment method deleted: {$paymentMethod->name}"
            );

            return $this->successResponse(null, 'Payment method deleted successfully.');
        } catch (\Exception $e) {
            \Log::error('PaymentMethodController destroy error: ' . $e->getMessage());
            return $this->serverError('Failed to delete payment method: ' . $e->getMessage());
        }
    }

    public function dropdown()
    {
        try {
            $user = auth()->user();
            if (!$user || (!$user->hasRole('ADMINISTRATOR') && !$user->can('subscriptions.manage'))) {
                return $this->forbidden('You need administrator role or subscriptions.manage permission.');
            }

            $methods = PaymentMethod::active()
                ->orderBy('display_order')
                ->get(['id', 'name', 'phone_number', 'account_name']);

            return $this->successResponse($methods, 'Payment methods dropdown retrieved.');
        } catch (\Exception $e) {
            \Log::error('PaymentMethodController dropdown error: ' . $e->getMessage());
            return $this->serverError('Failed to retrieve payment methods.');
        }
    }

    public function toggle($id)
    {
        try {
            $user = auth()->user();
            if (!$user || (!$user->hasRole('ADMINISTRATOR') && !$user->can('subscriptions.manage'))) {
                return $this->forbidden('You need administrator role or subscriptions.manage permission.');
            }

            $paymentMethod = PaymentMethod::findOrFail($id);
            $paymentMethod->is_active = !$paymentMethod->is_active;
            $paymentMethod->save();

            $this->logAudit(
                'toggle_payment_method',
                'payment_method',
                $paymentMethod->id,
                "Payment method toggled to " . ($paymentMethod->is_active ? 'active' : 'inactive')
            );

            return $this->successResponse($paymentMethod, 'Payment method status toggled successfully.');
        } catch (ModelNotFoundException $e) {
            return $this->notFound('Payment method not found.');
        } catch (\Exception $e) {
            \Log::error('PaymentMethodController toggle error: ' . $e->getMessage());
            return $this->serverError('Failed to toggle payment method.');
        }
    }
}