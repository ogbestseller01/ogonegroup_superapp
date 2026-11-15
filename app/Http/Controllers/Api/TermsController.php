<?php
namespace App\Http\Controllers\Api;

use App\Models\Term;
use App\Traits\Auditable;
use Illuminate\Http\Request;

class TermsController extends BaseApiController
{
    use Auditable;

    public function show()
    {
        $term = Term::first();
        if (!$term) {
            return $this->successResponse(null, 'No terms yet.');
        }
        return $this->successResponse($term);
    }

    public function store(Request $request)
    {
        $this->checkPermission('terms.edit');
        $data = $request->validate(['content' => 'required|string']);
        $term = Term::create($data);
        $this->logAudit('create_terms', 'terms', $term->id, 'Created terms page');
        return $this->created($term, __('messages.terms_updated'));
    }

    public function update(Request $request)
    {
        $this->checkPermission('terms.edit');
        $term = Term::first();
        if (!$term) {
            return $this->store($request);
        }
        $data = $request->validate(['content' => 'required|string']);
        $term->update($data);
        $this->logAudit('update_terms', 'terms', $term->id, __('messages.terms_updated_log'));
        return $this->successResponse($term, __('messages.terms_updated'));
    }

    public function destroy()
    {
        $this->checkPermission('terms.edit');
        $term = Term::first();
        if ($term) {
            $term->delete();
            $this->logAudit('delete_terms', 'terms', $term->id, 'Deleted terms page');
        }
        return $this->successResponse(null, 'Terms page deleted');
    }
}