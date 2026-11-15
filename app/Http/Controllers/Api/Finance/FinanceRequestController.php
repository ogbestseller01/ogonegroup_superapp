<?php

namespace App\Http\Controllers\Api\Finance;

use App\Http\Controllers\Api\BaseApiController;
use App\Models\ServiceRequest;
use App\Traits\FinanceRangeTrait;
use Carbon\CarbonPeriod;
use Illuminate\Http\Request;

class FinanceRequestController extends BaseApiController
{
    use FinanceRangeTrait;

    public function summary(Request $request)
    {
        [$start, $end, $range] = $this->resolveRange($request);
        $status = $request->input('status');

        $query = ServiceRequest::whereBetween('created_at', [$start, $end]);

        if ($status && $status !== 'all') {
            $query->where('status', $status);
        }

        $breakdown = (clone $query)
            ->selectRaw('status, count(*) as total')
            ->groupBy('status')
            ->get()
            ->map(fn ($r) => ['status' => $r->status, 'total' => (int) $r->total]);

        return $this->successResponse([
            'range' => [
                'start' => $start->toDateString(),
                'end'   => $end->toDateString(),
                'label' => $range,
            ],
            'totals' => [
                'count'       => (clone $query)->count(),
                'pending'     => (clone $query)->where('status', 'pending')->count(),
                'accepted'    => (clone $query)->where('status', 'accepted')->count(),
                'completed'   => (clone $query)->where('status', 'completed')->count(),
                'on_the_way'  => (clone $query)->where('status', 'on_the_way')->count(),
                'rejected'    => (clone $query)->where('status', 'rejected')->count(),
                'cancelled'   => (clone $query)->where('status', 'cancelled')->count(),
            ],
            'status_breakdown' => $breakdown,
        ]);
    }

    public function trends(Request $request)
    {
        [$start, $end, $range] = $this->resolveRange($request);
        $granularity = $this->resolveGranularity($request, $range);
        $unit = $this->bucketUnit($granularity);
        $status = $request->input('status');

        $buckets = [];
        foreach (CarbonPeriod::create($start, "1 {$unit}", $end) as $date) {
            $bStart = $date->copy()->startOf($unit);
            $bEnd   = $date->copy()->endOf($unit);

            $q = ServiceRequest::whereBetween('created_at', [$bStart, $bEnd]);
            if ($status && $status !== 'all') {
                $q->where('status', $status);
            }

            $buckets[] = [
                'label' => $this->bucketLabel($bStart, $unit),
                'date'  => $bStart->toDateString(),
                'count' => (clone $q)->count(),
            ];
        }

        return $this->successResponse([
            'granularity' => $granularity,
            'buckets'     => $buckets,
        ]);
    }

    public function table(Request $request)
    {
        [$start, $end] = $this->resolveRange($request);
        $status = $request->input('status');
        $search = $request->input('search');

        $query = ServiceRequest::with(['customer', 'technician.user', 'service'])
            ->whereBetween('created_at', [$start, $end]);

        if ($status && $status !== 'all') {
            $query->where('status', $status);
        }

        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('description', 'LIKE', "%{$search}%")
                  ->orWhereHas('customer', function ($u) use ($search) {
                      $u->where('name', 'LIKE', "%{$search}%")
                        ->orWhere('email', 'LIKE', "%{$search}%")
                        ->orWhere('phone', 'LIKE', "%{$search}%");
                  })
                  ->orWhereHas('technician.user', function ($u) use ($search) {
                      $u->where('name', 'LIKE', "%{$search}%");
                  })
                  ->orWhereHas('service', function ($s) use ($search) {
                      $s->where('name', 'LIKE', "%{$search}%");
                  });
            });
        }

        return $this->successResponse(
            $query->orderBy('created_at', 'desc')->paginate($request->input('per_page', 10))
        );
    }

    public function export(Request $request)
    {
        [$start, $end] = $this->resolveRange($request);
        $status = $request->input('status');
        $format = $request->input('format', 'csv');

        $query = ServiceRequest::with(['customer', 'technician.user', 'service'])
            ->whereBetween('created_at', [$start, $end]);

        if ($status && $status !== 'all') {
            $query->where('status', $status);
        }

        $rows = $query->orderBy('created_at', 'desc')->get();

        $headers = [
            'ID', 'Customer', 'Technician', 'Service', 'Status',
            'Description', 'Created At'
        ];

        $filename = 'finance_requests_' . now()->format('Y-m-d_His');

        $mapRow = fn ($row) => [
            $row->id,
            $row->customer->name ?? '-',
            $row->technician->user->name ?? '-',
            $row->service->name ?? '-',
            $row->status,
            $row->description,
            optional($row->created_at)->format('Y-m-d H:i'),
        ];

        return $format === 'xlsx'
            ? $this->exportExcel($rows, $headers, $filename, $mapRow)
            : $this->exportCsv($rows, $headers, $filename, $mapRow);
    }
}