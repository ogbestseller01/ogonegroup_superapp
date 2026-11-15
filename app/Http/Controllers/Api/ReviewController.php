<?php

namespace App\Http\Controllers\Api;

use App\Models\Job;
use App\Models\Review;
use App\Traits\Auditable;
use Illuminate\Database\QueryException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;

/**
 * After a job is completed (OTP verified), the CUSTOMER can submit
 * ONE review per job: star rating (1-5) + remark.
 *
 * completed_jobs_count is already incremented in
 * JobController::verifyCompletion, so it is NOT touched here.
 */
class ReviewController extends BaseApiController
{
    use Auditable;

    public function store(Request $request, $jobId)
    {
        try {
            $data = $request->validate([
                'rating'  => 'required|integer|min:1|max:5',
                'comment' => 'nullable|string|max:1000',
            ]);
        } catch (ValidationException $e) {
            return $this->validationError($e->errors());
        }

        $user = $request->user();
        $job  = Job::find($jobId);

        if (!$job) {
            return $this->notFound('Job not found.');
        }
        if (!$user || (int) $job->customer_id !== (int) $user->id) {
            return $this->forbidden('Only the customer of this job can review it.');
        }
        if (!$job->isCompleted()) {
            return $this->errorResponse('You can only review a job after it is completed.', 422);
        }
        if (Review::where('job_id', $job->id)->exists()) {
            return $this->errorResponse('This job has already been reviewed.', 422);
        }

        try {
            $comment = isset($data['comment']) ? trim($data['comment']) : null;

            $review = Review::create([
                'job_id'        => $job->id,
                'request_id'    => $job->request_id,
                'customer_id'   => $user->id,
                'technician_id' => $job->technician_id,
                'rating'        => $data['rating'],
                'comment'       => $comment === '' ? null : $comment,
            ]);
        } catch (QueryException $e) {
            // unique(job_id) race: double tap
            Log::warning('Duplicate review attempt: ' . $e->getMessage());
            return $this->errorResponse('This job has already been reviewed.', 422);
        } catch (\Throwable $e) {
            Log::error('Review store failed: ' . $e->getMessage());
            return $this->errorResponse('Failed to submit review. Please try again.', 500);
        }

        $this->logAudit('create_review', 'review', $review->id, "Customer reviewed job {$job->job_number}");

        return $this->created($this->formatReview($review), 'Review submitted successfully.');
    }

    public function technicianReviews($technicianId)
    {
        $reviews = Review::with('customer')
            ->where('technician_id', $technicianId)
            ->latest()
            ->get()
            ->map(fn (Review $r) => $this->formatReview($r, withCustomer: true));

        return $this->successResponse($reviews, 'Technician reviews retrieved.');
    }

    private function formatReview(Review $r, bool $withCustomer = false): array
    {
        $out = [
            'id'         => $r->id,
            'job_id'     => $r->job_id,
            'rating'     => (float) $r->rating,
            'comment'    => $r->comment,
            'created_at' => $r->created_at?->toIso8601String(),
        ];

        if ($withCustomer) {
            $out['customer'] = $r->customer
                ? ['id' => $r->customer->id, 'name' => $r->customer->name]
                : null;
        }

        return $out;
    }
}