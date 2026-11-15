<?php
namespace App\Http\Controllers\Api;

use App\Models\About;
use App\Traits\Auditable;
use Illuminate\Http\Request;

class AboutController extends BaseApiController
{
    use Auditable;

    public function show()
    {
        $about = About::first();
        if (!$about) {
            return $this->successResponse(null, 'No about content yet.');
        }
        return $this->successResponse($about);
    }

    public function store(Request $request)
    {
        $this->checkPermission('about.edit');
        $data = $request->validate(['content' => 'required|string']);
        $about = About::create($data);
        $this->logAudit('create_about', 'about', $about->id, 'Created about page');
        return $this->created($about, __('messages.about_updated'));
    }

    public function update(Request $request)
    {
        $this->checkPermission('about.edit');
        $about = About::first();
        if (!$about) {
            return $this->store($request);
        }
        $data = $request->validate(['content' => 'required|string']);
        $about->update($data);
        $this->logAudit('update_about', 'about', $about->id, __('messages.about_updated_log'));
        return $this->successResponse($about, __('messages.about_updated'));
    }

    public function destroy()
    {
        $this->checkPermission('about.edit');
        $about = About::first();
        if ($about) {
            $about->delete();
            $this->logAudit('delete_about', 'about', $about->id, 'Deleted about page');
        }
        return $this->successResponse(null, 'About page deleted');
    }
}