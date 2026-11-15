<?php

namespace App\Http\Controllers\Api\Finance;

use App\Http\Controllers\Api\BaseApiController;
use App\Models\User;
use App\Traits\FinanceRangeTrait;
use Carbon\CarbonPeriod;
use Illuminate\Http\Request;

class FinanceCustomerController extends BaseApiController
{
    use FinanceRangeTrait;

    private function baseQuery(Request $request, $start, $end)
    {
        $query = User::role('CUSTOMER')->whereBetween('created_at', [$start, $end]);

        $status = $request->input('status');
        if ($status && $status !== 'all') {
            $query->where('status', $status);
        }

        return $query;
    }

    public function summary(Request $request)
    {
        [$start, $end, $range] = $this->resolveRange($request);
        $query = $this->baseQuery($request, $start, $end);

        $breakdown = (clone $query)
            ->selectRaw('status, count(*) as total')
            ->groupBy('status')
            ->get()
            ->map(fn ($r) => [
                'status' => $r->status,
                'total'  => (int) $r->total,
            ]);

        return $this->successResponse([
            'range' => [
                'start' => $start->toDateString(),
                'end'   => $end->toDateString(),
                'label' => $range,
            ],
            'totals' => [
                'count'     => (clone $query)->count(),
                'active'    => (clone $query)->where('status', 'active')->count(),
                'pending'   => (clone $query)->where('status', 'pending')->count(),
                'suspended' => (clone $query)->where('status', 'suspended')->count(),
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

            $q = User::role('CUSTOMER')->whereBetween('created_at', [$bStart, $bEnd]);

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
        $query = $this->baseQuery($request, $start, $end);
        $search = $request->input('search');

        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'LIKE', "%{$search}%")
                  ->orWhere('email', 'LIKE', "%{$search}%")
                  ->orWhere('phone', 'LIKE', "%{$search}%");
            });
        }

        return $this->successResponse(
            $query->orderBy('created_at', 'desc')
                  ->paginate($request->input('per_page', 10))
        );
    }

    public function export(Request $request)
    {
        [$start, $end] = $this->resolveRange($request);
        $format = $request->input('format', 'csv');

        $rows = $this->baseQuery($request, $start, $end)
                     ->orderBy('created_at', 'desc')
                     ->get();

        $headers = ['ID', 'Name', 'Email', 'Phone', 'Status', 'Active', 'Created At'];
        $filename = 'finance_customers_' . now()->format('Y-m-d_His');

        $mapRow = fn ($row) => [
            $row->id,
            $row->name,
            $row->email,
            $row->phone ?? '-',
            $row->status,
            $row->is_active ? 'Yes' : 'No',
            optional($row->created_at)->format('Y-m-d H:i'),
        ];

        return $format === 'xlsx'
            ? $this->exportExcel($rows, $headers, $filename, $mapRow)
            : $this->exportCsv($rows, $headers, $filename, $mapRow);
    }
}