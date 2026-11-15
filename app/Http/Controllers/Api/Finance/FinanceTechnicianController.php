<?php

namespace App\Http\Controllers\Api\Finance;

use App\Http\Controllers\Api\BaseApiController;
use App\Models\Technician;
use App\Traits\FinanceRangeTrait;
use Carbon\CarbonPeriod;
use Illuminate\Http\Request;

class FinanceTechnicianController extends BaseApiController
{
    use FinanceRangeTrait;

    public function summary(Request $request)
    {
        [$start, $end, $range] = $this->resolveRange($request);
        $status = $request->input('status'); // verification_status

        $query = Technician::whereBetween('created_at', [$start, $end]);
        if ($status && $status !== 'all') {
            $query->where('verification_status', $status);
        }

        $breakdown = (clone $query)
            ->selectRaw('verification_status as status, count(*) as total')
            ->groupBy('verification_status')
            ->get()
            ->map(fn ($r) => ['status' => $r->status, 'total' => (int) $r->total]);

        return $this->successResponse([
            'range' => [
                'start' => $start->toDateString(),
                'end'   => $end->toDateString(),
                'label' => $range,
            ],
            'totals' => [
                'count'    => (clone $query)->count(),
                'approved' => (clone $query)->where('verification_status', 'approved')->count(),
                'pending'  => (clone $query)->where('verification_status', 'pending')->count(),
                'online'   => (clone $query)->where('is_online', true)->count(),
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

            $q = Technician::whereBetween('created_at', [$bStart, $bEnd]);
            if ($status && $status !== 'all') {
                $q->where('verification_status', $status);
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

        $query = Technician::with('user')->whereBetween('created_at', [$start, $end]);

        if ($status && $status !== 'all') {
            $query->where('verification_status', $status);
        }

        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('area', 'LIKE', "%{$search}%")
                  ->orWhereHas('user', function ($u) use ($search) {
                      $u->where('name', 'LIKE', "%{$search}%")
                        ->orWhere('email', 'LIKE', "%{$search}%");
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

        $query = Technician::with('user')->whereBetween('created_at', [$start, $end]);
        if ($status && $status !== 'all') {
            $query->where('verification_status', $status);
        }

        $rows = $query->orderBy('created_at', 'desc')->get();
        $headers = ['ID', 'Name', 'Email', 'Area', 'Rating', 'Verification Status', 'Online', 'Created At'];
        $filename = 'finance_technicians_' . now()->format('Y-m-d_His');

        $mapRow = fn ($row) => [
            $row->id,
            $row->user->name ?? '-',
            $row->user->email ?? '-',
            $row->area,
            $row->rating,
            $row->verification_status,
            $row->is_online ? 'Yes' : 'No',
            optional($row->created_at)->format('Y-m-d H:i'),
        ];

        return $format === 'xlsx'
            ? $this->exportExcel($rows, $headers, $filename, $mapRow)
            : $this->exportCsv($rows, $headers, $filename, $mapRow);
    }
}