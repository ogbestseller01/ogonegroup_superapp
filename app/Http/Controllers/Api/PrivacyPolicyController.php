<?php

namespace App\Http\Controllers\Api;

use App\Models\PrivacyPolicy;
use App\Traits\Auditable;
use Illuminate\Http\Request;

class PrivacyPolicyController extends BaseApiController
{
    use Auditable; // ensure audit logging works

    /**
     * List all privacy policies (usually one).
     */
    public function index()
    {
        $this->checkPermission('privacy.view');
        $policies = PrivacyPolicy::all();
        return $this->successResponse($policies, 'Privacy policies retrieved.');
    }

    /**
     * Create a new privacy policy (only if none exists).
     */
    public function store(Request $request)
    {
        $this->checkPermission('privacy.edit'); // same as about.edit

        $data = $request->validate([
            'content' => 'required|string'
        ]);

        if (PrivacyPolicy::exists()) {
            return $this->errorResponse('Privacy policy already exists. Use update to modify.', 409);
        }

        $policy = PrivacyPolicy::create($data);
        $this->logAudit('create_privacy_policy', 'privacy_policy', $policy->id, 'Privacy policy created');

        return $this->successResponse($policy, 'Privacy policy created.', 201);
    }

    /**
     * Get a single policy for editing (by ID) – view operation.
     */
    public function edit($id)
    {
        $this->checkPermission('privacy.view');
        $policy = PrivacyPolicy::findOrFail($id);
        return $this->successResponse($policy, 'Privacy policy retrieved for editing.');
    }

    /**
     * Delete a privacy policy.
     */
    public function destroy($id)
    {
        $this->checkPermission('privacy.edit');
        $policy = PrivacyPolicy::findOrFail($id);
        $policy->delete();
        $this->logAudit('delete_privacy_policy', 'privacy_policy', $id, 'Privacy policy deleted');
        return $this->successResponse(null, 'Privacy policy deleted.');
    }

    /**
     * Get a specific policy by ID (view operation).
     */
    public function showById($id)
    {
        $this->checkPermission('privacy.view');
        $policy = PrivacyPolicy::findOrFail($id);
        return $this->successResponse($policy);
    }

    /**
     * Get the first (singleton) policy – public, no permission needed.
     */
    public function show()
    {
        $policy = PrivacyPolicy::first();
        return $this->successResponse($policy, 'Privacy policy retrieved.');
    }

    /**
     * Update or create the singleton policy (upsert).
     */
    public function update(Request $request)
    {
        $this->checkPermission('privacy.edit');
        $data = $request->validate(['content' => 'required|string']);
        $policy = PrivacyPolicy::first();
        if ($policy) {
            $policy->update($data);
        } else {
            $policy = PrivacyPolicy::create($data);
        }
        $this->logAudit('update_privacy_policy', 'privacy_policy', $policy->id, 'Privacy policy updated');
        return $this->successResponse($policy, 'Privacy policy updated.');
    }
}