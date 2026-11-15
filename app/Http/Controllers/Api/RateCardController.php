<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\BaseApiController;
use App\Models\RateCard;
use App\Models\PaymentMethod;
use App\Models\Subscription;
use App\Traits\Auditable;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Storage;

class RateCardController extends BaseApiController
{
    use Auditable;

    /**
     * List all rate cards
     * GET /api/v16/admin/rate-cards
     */
    public function index(Request $request)
    {
        $user = auth()->user();
        if (!$user || (!$user->hasRole('ADMINISTRATOR') && !$user->can('subscriptions.manage'))) {
            return $this->forbidden('You need administrator role or subscriptions.manage permission.');
        }

        $query = RateCard::query();

        if ($request->filled('search')) {
            $query->where('name', 'like', "%{$request->search}%")
                  ->orWhere('description', 'like', "%{$request->search}%");
        }

        $rateCards = $query->orderBy('display_order')
            ->paginate($request->input('per_page', 20));

        return $this->successResponse($rateCards, 'Rate cards retrieved successfully');
    }

    /**
     * Create rate card
     * POST /api/v16/admin/rate-cards
     */
    public function store(Request $request)
    {
        $user = auth()->user();
        if (!$user || (!$user->hasRole('ADMINISTRATOR') && !$user->can('subscriptions.manage'))) {
            return $this->forbidden('You need administrator role or subscriptions.manage permission.');
        }

        $data = $request->validate([
            'name' => 'required|string|max:255',
            'price' => 'required|numeric|min:0',
            'duration_days' => 'required|integer|min:1',
            'currency' => 'required|string|size:3',
            'description' => 'nullable|string',
            'is_active' => 'boolean',
            'display_order' => 'nullable|integer|min:0',
        ]);

        $data['slug'] = Str::slug($data['name']);
        $data['is_active'] = $data['is_active'] ?? true;
        $data['display_order'] = $data['display_order'] ?? 0;

        $rateCard = RateCard::create($data);

        $this->logAudit(
            'create_rate_card',
            'rate_card',
            $rateCard->id,
            "Rate card created: {$rateCard->name}"
        );

        return $this->created($rateCard, 'Rate card created successfully.');
    }

    /**
     * Update rate card
     * PUT /api/v16/admin/rate-cards/{id}
     */
    public function update(Request $request, $id)
    {
        $user = auth()->user();
        if (!$user || (!$user->hasRole('ADMINISTRATOR') && !$user->can('subscriptions.manage'))) {
            return $this->forbidden('You need administrator role or subscriptions.manage permission.');
        }

        $rateCard = RateCard::findOrFail($id);

        $data = $request->validate([
            'name' => 'sometimes|string|max:255',
            'price' => 'sometimes|numeric|min:0',
            'duration_days' => 'sometimes|integer|min:1',
            'currency' => 'sometimes|string|size:3',
            'description' => 'nullable|string',
            'is_active' => 'boolean',
            'display_order' => 'nullable|integer|min:0',
        ]);

        if (isset($data['name'])) {
            $data['slug'] = Str::slug($data['name']);
        }

        $old = $rateCard->toArray();
        $rateCard->update($data);
        $new = $rateCard->fresh()->toArray();

        $this->logAudit(
            'update_rate_card',
            'rate_card',
            $rateCard->id,
            "Rate card updated: {$rateCard->name}",
            $old,
            $new
        );

        return $this->successResponse($rateCard, 'Rate card updated successfully.');
    }

    /**
     * Delete rate card
     * DELETE /api/v16/admin/rate-cards/{id}
     */
    public function destroy($id)
    {
        $user = auth()->user();
        if (!$user || (!$user->hasRole('ADMINISTRATOR') && !$user->can('subscriptions.manage'))) {
            return $this->forbidden('You need administrator role or subscriptions.manage permission.');
        }

        $rateCard = RateCard::findOrFail($id);

        if ($rateCard->subscriptions()->whereIn('status', ['pending', 'active'])->exists()) {
            return $this->errorResponse(
                'Cannot delete rate card with pending or active subscriptions.',
                422
            );
        }

        $rateCard->delete();

        $this->logAudit(
            'delete_rate_card',
            'rate_card',
            $rateCard->id,
            "Rate card deleted: {$rateCard->name}"
        );

        return $this->successResponse(null, 'Rate card deleted successfully.');
    }

    /**
     * Get payment methods
     * GET /api/v16/admin/payment-methods
     */
    public function getPaymentMethods()
    {
        $user = auth()->user();
        if (!$user || (!$user->hasRole('ADMINISTRATOR') && !$user->can('subscriptions.manage'))) {
            return $this->forbidden('You need administrator role or subscriptions.manage permission.');
        }

        $methods = PaymentMethod::orderBy('display_order')->get();
        return $this->successResponse($methods, 'Payment methods retrieved.');
    }

    /**
     * Create payment method
     * POST /api/v16/admin/payment-methods
     */
    public function storePaymentMethod(Request $request)
    {
        $user = auth()->user();
        if (!$user || (!$user->hasRole('ADMINISTRATOR') && !$user->can('subscriptions.manage'))) {
            return $this->forbidden('You need administrator role or subscriptions.manage permission.');
        }

        $data = $request->validate([
            'name' => 'required|string|max:255',
            'phone_number' => 'required|string|max:50',
            'account_name' => 'nullable|string|max:255',
            'logo' => 'nullable|image|mimes:jpg,jpeg,png,webp|max:2048',
            'is_active' => 'boolean',
            'display_order' => 'nullable|integer|min:0',
        ]);

        $data['slug'] = Str::slug($data['name']);
        $data['is_active'] = $data['is_active'] ?? true;
        $data['display_order'] = $data['display_order'] ?? 0;

        if ($request->hasFile('logo')) {
            $data['logo'] = $request->file('logo')->store('payment_logos', 'public');
        }

        $method = PaymentMethod::create($data);

        $this->logAudit(
            'create_payment_method',
            'payment_method',
            $method->id,
            "Payment method created: {$method->name}"
        );

        return $this->created($method, 'Payment method created successfully.');
    }

    /**
     * Update payment method
     * PUT /api/v16/admin/payment-methods/{id}
     */
    public function updatePaymentMethod(Request $request, $id)
    {
        $user = auth()->user();
        if (!$user || (!$user->hasRole('ADMINISTRATOR') && !$user->can('subscriptions.manage'))) {
            return $this->forbidden('You need administrator role or subscriptions.manage permission.');
        }

        $method = PaymentMethod::findOrFail($id);

        $data = $request->validate([
            'name' => 'sometimes|string|max:255',
            'phone_number' => 'sometimes|string|max:50',
            'account_name' => 'nullable|string|max:255',
            'logo' => 'nullable|image|mimes:jpg,jpeg,png,webp|max:2048',
            'is_active' => 'boolean',
            'display_order' => 'nullable|integer|min:0',
        ]);

        if (isset($data['name'])) {
            $data['slug'] = Str::slug($data['name']);
        }

        if ($request->hasFile('logo')) {
            if ($method->logo && Storage::disk('public')->exists($method->logo)) {
                Storage::disk('public')->delete($method->logo);
            }
            $data['logo'] = $request->file('logo')->store('payment_logos', 'public');
        }

        $old = $method->toArray();
        $method->update($data);
        $new = $method->fresh()->toArray();

        $this->logAudit(
            'update_payment_method',
            'payment_method',
            $method->id,
            "Payment method updated: {$method->name}",
            $old,
            $new
        );

        return $this->successResponse($method, 'Payment method updated successfully.');
    }

    /**
     * Delete payment method
     * DELETE /api/v16/admin/payment-methods/{id}
     */
    public function destroyPaymentMethod($id)
    {
        $user = auth()->user();
        if (!$user || (!$user->hasRole('ADMINISTRATOR') && !$user->can('subscriptions.manage'))) {
            return $this->forbidden('You need administrator role or subscriptions.manage permission.');
        }

        $method = PaymentMethod::findOrFail($id);

        if ($method->logo && Storage::disk('public')->exists($method->logo)) {
            Storage::disk('public')->delete($method->logo);
        }

        $method->delete();

        $this->logAudit(
            'delete_payment_method',
            'payment_method',
            $method->id,
            "Payment method deleted: {$method->name}"
        );

        return $this->successResponse(null, 'Payment method deleted successfully.');
    }
}