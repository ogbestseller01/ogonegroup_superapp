<?php

namespace App\Http\Controllers\Api\Finance;

use App\Http\Controllers\Api\BaseApiController;
use App\Models\Subscription;
use App\Traits\FinanceRangeTrait;
use Carbon\CarbonPeriod;
use Illuminate\Http\Request;

class FinanceSubscriptionController extends BaseApiController
{
    use FinanceRangeTrait;

    public function summary(Request $request)
    {
        [$start, $end, $range] = $this->resolveRange($request);
        $status = $request->input('status');

        $baseQuery = Subscription::whereBetween('created_at', [$start, $end]);
        if ($status && $status !== 'all') {
            $baseQuery->where('status', $status);
        }

        // Total count and revenue
        $totalCount = (clone $baseQuery)->count();
        $totalRevenue = (float) (clone $baseQuery)->sum('amount_paid');

        // Active subscriptions: status='active' AND (expiry_date IS NULL OR expiry_date > now)
        $activeCount = (clone $baseQuery)
            ->where('status', 'active')
            ->where(function($q) {
                $q->whereNull('expiry_date')
                  ->orWhere('expiry_date', '>', now());
            })
            ->count();

        // Expired subscriptions: status='expired' OR (status='active' AND expiry_date <= now)
        $expiredCount = (clone $baseQuery)
            ->where(function($q) {
                $q->where('status', 'expired')
                  ->orWhere(function($sub) {
                      $sub->where('status', 'active')
                          ->whereNotNull('expiry_date')
                          ->where('expiry_date', '<=', now());
                  });
            })
            ->count();

        // Status breakdown
        $breakdown = (clone $baseQuery)
            ->selectRaw('status, count(*) as total, sum(amount_paid) as revenue')
            ->groupBy('status')
            ->get()
            ->map(fn ($r) => [
                'status' => $r->status, 
                'total' => (int) $r->total, 
                'revenue' => (float) $r->revenue
            ]);

        return $this->successResponse([
            'range' => ['start' => $start->toDateString(), 'end' => $end->toDateString(), 'label' => $range],
            'totals' => [
                'count'   => $totalCount,
                'revenue' => $totalRevenue,
                'active'  => $activeCount,
                'expired' => $expiredCount,
            ],
            'status_breakdown' => $breakdown,
        ]);
    }

    public function table(Request $request)
    {
        [$start, $end] = $this->resolveRange($request);
        $status = $request->input('status');
        $search = $request->input('search');

        $query = Subscription::with(['user', 'rateCard'])->whereBetween('created_at', [$start, $end]);
        if ($status && $status !== 'all') $query->where('status', $status);
        if ($search) {
            $query->whereHas('user', fn ($q) => $q->where('name', 'LIKE', "%{$search}%")->orWhere('email', 'LIKE', "%{$search}%"));
        }

        return $this->successResponse($query->orderBy('created_at', 'desc')->paginate($request->input('per_page', 10)));
    }

    public function export(Request $request)
    {
        [$start, $end] = $this->resolveRange($request);
        $status = $request->input('status');
        $format = $request->input('format', 'csv');

        $query = Subscription::with(['user', 'rateCard'])->whereBetween('created_at', [$start, $end]);
        if ($status && $status !== 'all') $query->where('status', $status);

        $rows = $query->orderBy('created_at', 'desc')->get();
        $headers = ['ID', 'User', 'Email', 'Plan', 'Amount', 'Currency', 'Status', 'Payment Method', 'Created At', 'Expiry'];
        $filename = 'finance_subscriptions_' . now()->format('Y-m-d_His');

        $mapRow = fn ($row) => [
            $row->id, $row->user->name ?? '-', $row->user->email ?? '-', $row->rateCard->name ?? '-',
            $row->amount_paid, $row->currency, $row->status, $row->payment_method,
            optional($row->created_at)->format('Y-m-d H:i'), optional($row->expiry_date)->format('Y-m-d H:i'),
        ];

        return $format === 'xlsx'
            ? $this->exportExcel($rows, $headers, $filename, $mapRow)
            : $this->exportCsv($rows, $headers, $filename, $mapRow);
    }

    /**
     * Get trend data for subscriptions over time.
     * GET /api/finance/subscriptions/trends
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function trends(Request $request)
    {
        [$start, $end, $range] = $this->resolveRange($request);
        $status = $request->input('status');
        $granularity = $request->input('granularity', $this->getDefaultGranularity($start, $end));

        $baseQuery = Subscription::whereBetween('created_at', [$start, $end]);
        if ($status && $status !== 'all') {
            $baseQuery->where('status', $status);
        }

        // Build the date grouping based on granularity
        $dateFormat = $this->getDateFormatForGranularity($granularity);
        $groupBy = $this->getGroupByClause($granularity);

        // Get trend data grouped by date
        $trendData = (clone $baseQuery)
            ->selectRaw("{$groupBy} as date_group, count(*) as count, sum(amount_paid) as revenue")
            ->groupBy('date_group')
            ->orderBy('date_group', 'asc')
            ->get()
            ->map(fn ($item) => [
                'date' => $item->date_group,
                'label' => $this->formatDateLabel($item->date_group, $granularity),
                'count' => (int) $item->count,
                'revenue' => (float) $item->revenue,
            ]);

        // Fill in missing dates for complete time period
        $filledData = $this->fillMissingDates($trendData, $start, $end, $granularity);

        return $this->successResponse([
            'granularity' => $granularity,
            'buckets' => $filledData,
            'range' => [
                'start' => $start->toDateString(),
                'end' => $end->toDateString(),
            ],
            'totals' => [
                'count' => $trendData->sum('count'),
                'revenue' => $trendData->sum('revenue'),
            ],
        ]);
    }

    /**
     * Get the default granularity based on date range.
     */
    private function getDefaultGranularity($start, $end): string
    {
        $days = $start->diffInDays($end);
        
        if ($days <= 7) {
            return 'daily';
        } elseif ($days <= 60) {
            return 'weekly';
        } elseif ($days <= 730) {
            return 'monthly';
        } else {
            return 'yearly';
        }
    }

    /**
     * Get the date format for the given granularity.
     */
    private function getDateFormatForGranularity(string $granularity): string
    {
        return match($granularity) {
            'daily' => '%Y-%m-%d',
            'weekly' => '%Y-%m-%d', // We'll handle week grouping separately
            'monthly' => '%Y-%m-01',
            'yearly' => '%Y-01-01',
            default => '%Y-%m-%d',
        };
    }

    /**
     * Get the SQL GROUP BY clause for the given granularity.
     */
    private function getGroupByClause(string $granularity): string
    {
        return match($granularity) {
            'daily' => "DATE(created_at)",
            'weekly' => "DATE(DATE_SUB(created_at, INTERVAL WEEKDAY(created_at) DAY))",
            'monthly' => "DATE_FORMAT(created_at, '%Y-%m-01')",
            'yearly' => "DATE_FORMAT(created_at, '%Y-01-01')",
            default => "DATE(created_at)",
        };
    }

    /**
     * Format the date label for display.
     */
    private function formatDateLabel(string $date, string $granularity): string
    {
        try {
            $carbon = \Carbon\Carbon::parse($date);
            
            return match($granularity) {
                'daily' => $carbon->format('M j, Y'),
                'weekly' => $carbon->format('M j') . ' - ' . $carbon->addDays(6)->format('M j, Y'),
                'monthly' => $carbon->format('M Y'),
                'yearly' => $carbon->format('Y'),
                default => $carbon->format('M j, Y'),
            };
        } catch (\Exception $e) {
            return $date;
        }
    }

    /**
     * Fill in missing dates in the trend data.
     */
    private function fillMissingDates($trendData, $start, $end, string $granularity): array
    {
        // Get the existing dates as a collection
        $existingDates = $trendData->pluck('date')->toArray();
        $result = [];

        // Generate all dates in the range based on granularity
        $interval = $this->getIntervalForGranularity($granularity);
        $period = CarbonPeriod::create($start, $interval, $end);

        foreach ($period as $date) {
            $dateKey = $date->format('Y-m-d');
            $found = $trendData->firstWhere('date', $dateKey);
            
            if ($found) {
                $result[] = $found;
            } else {
                $result[] = [
                    'date' => $dateKey,
                    'label' => $this->formatDateLabel($dateKey, $granularity),
                    'count' => 0,
                    'revenue' => 0,
                ];
            }
        }

        return $result;
    }

    /**
     * Get the interval string for the given granularity.
     */
    private function getIntervalForGranularity(string $granularity): string
    {
        return match($granularity) {
            'daily' => '1 day',
            'weekly' => '1 week',
            'monthly' => '1 month',
            'yearly' => '1 year',
            default => '1 day',
        };
    }
}