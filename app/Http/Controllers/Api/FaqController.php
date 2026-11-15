<?php
namespace App\Http\Controllers\Api;

use App\Models\Faq;
use App\Traits\Auditable;
use Illuminate\Http\Request;

class FaqController extends BaseApiController
{
    use Auditable;

    // Public — no auth required (matches routes/api.php v1 & v6 public groups)
    public function index()
    {
        return $this->successResponse(Faq::orderBy('order')->get());
    }

    // Public — no auth required
    public function show($id)
    {
        $faq = Faq::find($id);
        if (!$faq) {
            return $this->notFound('FAQ not found.');
        }

        return $this->successResponse($faq);
    }

    // Admin only — hit via authenticated v6 group
    public function store(Request $request)
    {
        $this->checkPermission('faqs.create');

        $data = $request->validate([
            'question' => 'required|string',
            'answer'   => 'required|string',
            'order'    => 'nullable|integer',
        ]);

        $faq = Faq::create($data);
        $this->logAudit('create_faq', 'faq', $faq->id, "FAQ created: {$faq->question}");
        return $this->created($faq, __('messages.faq_created'));
    }

    // Admin only
    public function update(Request $request, $id)
    {
        $this->checkPermission('faqs.edit');

        $faq = Faq::find($id);
        if (!$faq) {
            return $this->notFound('FAQ not found.');
        }

        $data = $request->validate([
            'question' => 'sometimes|string',
            'answer'   => 'sometimes|string',
            'order'    => 'nullable|integer',
        ]);

        $faq->update($data);
        $this->logAudit('update_faq', 'faq', $id, 'FAQ updated');
        return $this->successResponse($faq, __('messages.faq_updated'));
    }

    // Admin only
    public function destroy($id)
    {
        $this->checkPermission('faqs.delete');

        $faq = Faq::find($id);
        if (!$faq) {
            return $this->notFound('FAQ not found.');
        }

        $faq->delete();
        $this->logAudit('delete_faq', 'faq', $id, 'FAQ deleted');
        return $this->successResponse(null, __('messages.faq_deleted'));
    }
}