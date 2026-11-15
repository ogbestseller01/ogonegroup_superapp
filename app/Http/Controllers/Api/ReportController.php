<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\BaseApiController;
use App\Models\ServiceRequest;
use App\Models\Subscription;
use App\Models\Technician;
use App\Models\User;
use App\Models\Job;
use App\Models\Ticket;
use App\Traits\FinanceRangeTrait;
use Carbon\Carbon;
use Carbon\CarbonPeriod;
use Illuminate\Http\Request;
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;

class ReportController extends BaseApiController
{
    use FinanceRangeTrait;

    private const DOMAINS = ['customers', 'requests', 'technicians', 'jobs', 'tickets'];

    public function summary(Request $request)
    {
        [$start, $end, $range] = $this->resolveRange($request);
        $type = $request->input('type', 'all');

        if ($type !== 'all') {
            if (!$this->isValidType($type)) {
                return $this->invalidTypeResponse($type);
            }

            return $this->successResponse(array_merge(
                ['range' => $this->rangePayload($start, $end, $range), 'type' => $type],
                $this->buildSummary($type, $request, $start, $end)
            ));
        }

        $customers     = $this->buildSummary('customers', $request, $start, $end);
        $requests      = $this->buildSummary('requests', $request, $start, $end);
        $technicians   = $this->buildSummary('technicians', $request, $start, $end);
        $jobs          = $this->buildSummary('jobs', $request, $start, $end);
        $tickets       = $this->buildSummary('tickets', $request, $start, $end);

        return $this->successResponse([
            'range' => $this->rangePayload($start, $end, $range),
            'combined_totals' => [
                'customers'          => $customers['totals']['count'],
                'requests'           => $requests['totals']['count'],
                'technicians'        => $technicians['totals']['count'],
                'jobs'               => $jobs['totals']['count'],
                'tickets'            => $tickets['totals']['count'],
            ],
            'customers'     => $customers,
            'requests'      => $requests,
            'technicians'   => $technicians,
            'jobs'          => $jobs,
            'tickets'       => $tickets,
        ]);
    }

    public function trends(Request $request)
    {
        [$start, $end, $range] = $this->resolveRange($request);
        $granularity = $this->resolveGranularity($request, $range);
        $unit = $this->bucketUnit($granularity);
        $type = $request->input('type', 'all');
        $status = $request->input('status');

        if ($type !== 'all') {
            if (!$this->isValidType($type)) {
                return $this->invalidTypeResponse($type);
            }

            $buckets = [];
            foreach (CarbonPeriod::create($start, "1 {$unit}", $end) as $date) {
                $bStart = $date->copy()->startOf($unit);
                $bEnd   = $date->copy()->endOf($unit);
                $point  = $this->bucketPoint($type, $bStart, $bEnd, $status);

                $buckets[] = array_merge([
                    'label' => $this->bucketLabel($bStart, $unit),
                    'date'  => $bStart->toDateString(),
                ], $point);
            }

            return $this->successResponse([
                'type'        => $type,
                'granularity' => $granularity,
                'buckets'     => $buckets,
            ]);
        }

        $buckets = [];
        foreach (CarbonPeriod::create($start, "1 {$unit}", $end) as $date) {
            $bStart = $date->copy()->startOf($unit);
            $bEnd   = $date->copy()->endOf($unit);

            $buckets[] = [
                'label'         => $this->bucketLabel($bStart, $unit),
                'date'          => $bStart->toDateString(),
                'customers'     => $this->bucketPoint('customers', $bStart, $bEnd, null)['count'],
                'requests'      => $this->bucketPoint('requests', $bStart, $bEnd, null)['count'],
                'technicians'   => $this->bucketPoint('technicians', $bStart, $bEnd, null)['count'],
                'jobs'          => $this->bucketPoint('jobs', $bStart, $bEnd, null)['count'],
                'tickets'       => $this->bucketPoint('tickets', $bStart, $bEnd, null)['count'],
            ];
        }

        return $this->successResponse([
            'granularity' => $granularity,
            'buckets'     => $buckets,
        ]);
    }

    public function detailed(Request $request)
    {
        $type = $request->input('type');

        if (!$type || !$this->isValidType($type)) {
            return $this->invalidTypeResponse($type, true);
        }

        [$start, $end] = $this->resolveRange($request);
        $status = $request->input('status');
        $search = $request->input('search');
        $perPage = $request->input('per_page', 10);

        $query = match ($type) {
            'customers' => User::role('CUSTOMER')->whereBetween('created_at', [$start, $end]),
            'requests'  => ServiceRequest::with(['customer', 'technician.user', 'service'])
                ->whereBetween('created_at', [$start, $end]),
            'technicians' => Technician::with('user')->whereBetween('created_at', [$start, $end]),
            'jobs'      => Job::with(['customer', 'technician.user', 'request.service'])
                ->whereBetween('created_at', [$start, $end]),
            'tickets'   => Ticket::with(['job.customer', 'job.technician.user'])
                ->whereBetween('created_at', [$start, $end]),
        };

        if ($status && $status !== 'all') {
            $statusColumn = $type === 'technicians' ? 'verification_status' : 'status';
            $query->where($statusColumn, $status);
        }

        if ($search) {
            $this->applySearch($query, $type, $search);
        }

        return $this->successResponse(
            $query->orderBy('created_at', 'desc')->paginate($perPage)
        );
    }

    public function overview(Request $request)
    {
        [$start, $end, $range] = $this->resolveRange($request);
        [$prevStart, $prevEnd] = $this->previousPeriod($start, $end);

        $current = [
            'customers'     => $this->buildSummary('customers', $request, $start, $end),
            'requests'      => $this->buildSummary('requests', $request, $start, $end),
            'technicians'   => $this->buildSummary('technicians', $request, $start, $end),
            'jobs'          => $this->buildSummary('jobs', $request, $start, $end),
            'tickets'       => $this->buildSummary('tickets', $request, $start, $end),
        ];

        $previous = [
            'customers'     => $this->buildSummary('customers', $request, $prevStart, $prevEnd),
            'requests'      => $this->buildSummary('requests', $request, $prevStart, $prevEnd),
            'technicians'   => $this->buildSummary('technicians', $request, $prevStart, $prevEnd),
            'jobs'          => $this->buildSummary('jobs', $request, $prevStart, $prevEnd),
            'tickets'       => $this->buildSummary('tickets', $request, $prevStart, $prevEnd),
        ];

        $headline = [];
        foreach (self::DOMAINS as $domain) {
            $headline[$domain] = [
                'count'  => $current[$domain]['totals']['count'],
                'growth' => $this->growth(
                    $current[$domain]['totals']['count'],
                    $previous[$domain]['totals']['count']
                ),
            ];
        }

        $granularity = $this->resolveGranularity($request, $range);
        $unit = $this->bucketUnit($granularity);
        $buckets = [];
        foreach (CarbonPeriod::create($start, "1 {$unit}", $end) as $date) {
            $bStart = $date->copy()->startOf($unit);
            $bEnd   = $date->copy()->endOf($unit);

            $buckets[] = [
                'label'         => $this->bucketLabel($bStart, $unit),
                'date'          => $bStart->toDateString(),
                'customers'     => $this->bucketPoint('customers', $bStart, $bEnd, null)['count'],
                'requests'      => $this->bucketPoint('requests', $bStart, $bEnd, null)['count'],
                'technicians'   => $this->bucketPoint('technicians', $bStart, $bEnd, null)['count'],
                'jobs'          => $this->bucketPoint('jobs', $bStart, $bEnd, null)['count'],
                'tickets'       => $this->bucketPoint('tickets', $bStart, $bEnd, null)['count'],
            ];
        }

        return $this->successResponse([
            'range' => $this->rangePayload($start, $end, $range),
            'previous_range' => $this->rangePayload($prevStart, $prevEnd, null),
            'headline' => $headline,
            'trend' => [
                'granularity' => $granularity,
                'buckets'     => $buckets,
            ],
        ]);
    }

    public function export(Request $request)
    {
        [$start, $end] = $this->resolveRange($request);
        $status = $request->input('status');
        $format = $request->input('format', 'csv');
        $type = $request->input('type', 'all');

        if ($type === 'all') {
            if ($format !== 'xlsx') {
                return $this->errorResponse(
                    "Combined export only supports format=xlsx (each domain has different columns). Pass a specific ?type= for csv.",
                    422
                );
            }

            return $this->exportCombined($start, $end, $status);
        }

        if (!$this->isValidType($type)) {
            return $this->invalidTypeResponse($type);
        }

        [$headers, $rows, $mapRow, $filename] = $this->exportDataFor($type, $start, $end, $status);

        return $format === 'xlsx'
            ? $this->exportExcel($rows, $headers, $filename, $mapRow)
            : $this->exportCsv($rows, $headers, $filename, $mapRow);
    }

    private function isValidType(?string $type): bool
    {
        return in_array($type, self::DOMAINS, true);
    }

    private function invalidTypeResponse(?string $type, bool $required = false)
    {
        $message = $required
            ? "A ?type= is required. Expected one of: " . implode(', ', self::DOMAINS)
            : "Invalid type '{$type}'. Expected one of: " . implode(', ', self::DOMAINS) . ', or all';

        return $this->errorResponse($message, 422);
    }

    private function rangePayload(Carbon $start, Carbon $end, ?string $range): array
    {
        return array_filter([
            'start' => $start->toDateString(),
            'end'   => $end->toDateString(),
            'label' => $range,
        ], fn ($v) => $v !== null);
    }

    private function previousPeriod(Carbon $start, Carbon $end): array
    {
        $seconds = max($start->diffInSeconds($end), 1);
        $prevEnd = $start->copy()->subSecond();
        $prevStart = $prevEnd->copy()->subSeconds($seconds);

        return [$prevStart, $prevEnd];
    }

    private function growth($current, $previous): float
    {
        if ((float) $previous == 0.0) {
            return $current > 0 ? 100.0 : 0.0;
        }

        return round((($current - $previous) / $previous) * 100, 2);
    }

    private function buildSummary(string $type, Request $request, Carbon $start, Carbon $end): array
    {
        $status = $request->input('status');

        return match ($type) {
            'customers' => $this->summaryCustomers($start, $end, $status),
            'requests' => $this->summaryRequests($start, $end, $status),
            'technicians' => $this->summaryTechnicians($start, $end, $status),
            'jobs' => $this->summaryJobs($start, $end, $status),
            'tickets' => $this->summaryTickets($start, $end, $status),
        };
    }

    private function summaryCustomers(Carbon $start, Carbon $end, ?string $status): array
    {
        $query = User::role('CUSTOMER')->whereBetween('created_at', [$start, $end]);
        if ($status && $status !== 'all') {
            $query->where('status', $status);
        }

        $breakdown = (clone $query)
            ->selectRaw('status, count(*) as total')
            ->groupBy('status')
            ->get()
            ->map(fn ($r) => ['status' => $r->status, 'total' => (int) $r->total]);

        return [
            'totals' => [
                'count'     => (clone $query)->count(),
                'active'    => (clone $query)->where('status', 'active')->count(),
                'pending'   => (clone $query)->where('status', 'pending')->count(),
                'suspended' => (clone $query)->where('status', 'suspended')->count(),
            ],
            'status_breakdown' => $breakdown,
        ];
    }

    private function summaryRequests(Carbon $start, Carbon $end, ?string $status): array
    {
        $query = ServiceRequest::whereBetween('created_at', [$start, $end]);
        if ($status && $status !== 'all') {
            $query->where('status', $status);
        }

        $breakdown = (clone $query)
            ->selectRaw('status, count(*) as total')
            ->groupBy('status')
            ->get()
            ->map(fn ($r) => ['status' => $r->status, 'total' => (int) $r->total]);

        return [
            'totals' => [
                'count'      => (clone $query)->count(),
                'pending'    => (clone $query)->where('status', 'pending')->count(),
                'accepted'   => (clone $query)->where('status', 'accepted')->count(),
                'completed'  => (clone $query)->where('status', 'completed')->count(),
                'on_the_way' => (clone $query)->where('status', 'on_the_way')->count(),
                'rejected'   => (clone $query)->where('status', 'rejected')->count(),
                'cancelled'  => (clone $query)->where('status', 'cancelled')->count(),
            ],
            'status_breakdown' => $breakdown,
        ];
    }

    private function summaryTechnicians(Carbon $start, Carbon $end, ?string $status): array
    {
        $query = Technician::whereBetween('created_at', [$start, $end]);
        if ($status && $status !== 'all') {
            $query->where('verification_status', $status);
        }

        $breakdown = (clone $query)
            ->selectRaw('verification_status as status, count(*) as total')
            ->groupBy('verification_status')
            ->get()
            ->map(fn ($r) => ['status' => $r->status, 'total' => (int) $r->total]);

        return [
            'totals' => [
                'count'    => (clone $query)->count(),
                'approved' => (clone $query)->where('verification_status', 'approved')->count(),
                'pending'  => (clone $query)->where('verification_status', 'pending')->count(),
                'online'   => (clone $query)->where('is_online', true)->count(),
            ],
            'status_breakdown' => $breakdown,
        ];
    }

    private function summaryJobs(Carbon $start, Carbon $end, ?string $status): array
    {
        $query = Job::whereBetween('created_at', [$start, $end]);
        if ($status && $status !== 'all') {
            $query->where('status', $status);
        }

        $breakdown = (clone $query)
            ->selectRaw('status, count(*) as total')
            ->groupBy('status')
            ->get()
            ->map(fn ($r) => ['status' => $r->status, 'total' => (int) $r->total]);

        return [
            'totals' => [
                'count'      => (clone $query)->count(),
                'pending'    => (clone $query)->where('status', 'pending')->count(),
                'on_progress'=> (clone $query)->where('status', 'on-progress')->count(),
                'completed'  => (clone $query)->where('status', 'completed')->count(),
            ],
            'status_breakdown' => $breakdown,
        ];
    }

    private function summaryTickets(Carbon $start, Carbon $end, ?string $status): array
    {
        $query = Ticket::whereBetween('created_at', [$start, $end]);
        if ($status && $status !== 'all') {
            $query->where('status', $status);
        }

        $breakdown = (clone $query)
            ->selectRaw('status, count(*) as total')
            ->groupBy('status')
            ->get()
            ->map(fn ($r) => ['status' => $r->status, 'total' => (int) $r->total]);

        return [
            'totals' => [
                'count'      => (clone $query)->count(),
                'on_progress'=> (clone $query)->where('status', 'on-progress')->count(),
                'completed'  => (clone $query)->where('status', 'completed')->count(),
            ],
            'status_breakdown' => $breakdown,
        ];
    }

    private function bucketPoint(string $type, Carbon $bStart, Carbon $bEnd, ?string $status): array
    {
        return match ($type) {
            'customers' => (function () use ($bStart, $bEnd, $status) {
                $q = User::role('CUSTOMER')->whereBetween('created_at', [$bStart, $bEnd]);
                if ($status && $status !== 'all') $q->where('status', $status);
                return ['count' => $q->count()];
            })(),
            'requests' => (function () use ($bStart, $bEnd, $status) {
                $q = ServiceRequest::whereBetween('created_at', [$bStart, $bEnd]);
                if ($status && $status !== 'all') $q->where('status', $status);
                return ['count' => $q->count()];
            })(),
            'technicians' => (function () use ($bStart, $bEnd, $status) {
                $q = Technician::whereBetween('created_at', [$bStart, $bEnd]);
                if ($status && $status !== 'all') $q->where('verification_status', $status);
                return ['count' => $q->count()];
            })(),
            'jobs' => (function () use ($bStart, $bEnd, $status) {
                $q = Job::whereBetween('created_at', [$bStart, $bEnd]);
                if ($status && $status !== 'all') $q->where('status', $status);
                return ['count' => $q->count()];
            })(),
            'tickets' => (function () use ($bStart, $bEnd, $status) {
                $q = Ticket::whereBetween('created_at', [$bStart, $bEnd]);
                if ($status && $status !== 'all') $q->where('status', $status);
                return ['count' => $q->count()];
            })(),
        };
    }

    private function applySearch($query, string $type, string $search): void
    {
        match ($type) {
            'customers' => $query->where(function ($q) use ($search) {
                $q->where('name', 'LIKE', "%{$search}%")
                  ->orWhere('email', 'LIKE', "%{$search}%")
                  ->orWhere('phone', 'LIKE', "%{$search}%");
            }),
            'requests' => $query->where(function ($q) use ($search) {
                $q->where('description', 'LIKE', "%{$search}%")
                  ->orWhereHas('customer', fn ($u) => $u->where('name', 'LIKE', "%{$search}%")
                      ->orWhere('email', 'LIKE', "%{$search}%")
                      ->orWhere('phone', 'LIKE', "%{$search}%"))
                  ->orWhereHas('technician.user', fn ($u) => $u->where('name', 'LIKE', "%{$search}%"))
                  ->orWhereHas('service', fn ($s) => $s->where('name', 'LIKE', "%{$search}%"));
            }),
            'technicians' => $query->where(function ($q) use ($search) {
                $q->where('area', 'LIKE', "%{$search}%")
                  ->orWhereHas('user', fn ($u) => $u->where('name', 'LIKE', "%{$search}%")
                      ->orWhere('email', 'LIKE', "%{$search}%"));
            }),
            'jobs' => $query->where(function ($q) use ($search) {
                $q->where('job_number', 'LIKE', "%{$search}%")
                  ->orWhereHas('customer', fn ($u) => $u->where('name', 'LIKE', "%{$search}%"))
                  ->orWhereHas('technician.user', fn ($u) => $u->where('name', 'LIKE', "%{$search}%"));
            }),
            'tickets' => $query->where(function ($q) use ($search) {
                $q->where('ticket_number', 'LIKE', "%{$search}%")
                  ->orWhere('title', 'LIKE', "%{$search}%");
            }),
            default => null,
        };
    }

    private function exportDataFor(string $type, Carbon $start, Carbon $end, ?string $status): array
    {
        $timestamp = now()->format('Y-m-d_His');

        return match ($type) {
            'customers' => (function () use ($start, $end, $status, $timestamp) {
                $query = User::role('CUSTOMER')->whereBetween('created_at', [$start, $end]);
                if ($status && $status !== 'all') $query->where('status', $status);
                $rows = $query->orderBy('created_at', 'desc')->get();

                return [
                    ['No.', 'Name', 'Email', 'Phone', 'Status', 'Active', 'Created At'],
                    $rows,
                    function ($row, $index) {
                        return [
                            $index + 1, $row->name, $row->email, $row->phone ?? '-',
                            $row->status, $row->is_active ? 'Yes' : 'No',
                            optional($row->created_at)->format('Y-m-d H:i'),
                        ];
                    },
                    "customers_report_{$timestamp}",
                ];
            })(),
            'requests' => (function () use ($start, $end, $status, $timestamp) {
                $query = ServiceRequest::with(['customer', 'technician.user', 'service'])
                    ->whereBetween('created_at', [$start, $end]);
                if ($status && $status !== 'all') $query->where('status', $status);
                $rows = $query->orderBy('created_at', 'desc')->get();

                return [
                    ['No.', 'Customer', 'Technician', 'Service', 'Status', 'Description', 'Created At'],
                    $rows,
                    function ($row, $index) {
                        return [
                            $index + 1, $row->customer->name ?? '-', $row->technician->user->name ?? '-',
                            $row->service->name ?? '-', $row->status, $row->description,
                            optional($row->created_at)->format('Y-m-d H:i'),
                        ];
                    },
                    "requests_report_{$timestamp}",
                ];
            })(),
            'technicians' => (function () use ($start, $end, $status, $timestamp) {
                $query = Technician::with('user')->whereBetween('created_at', [$start, $end]);
                if ($status && $status !== 'all') $query->where('verification_status', $status);
                $rows = $query->orderBy('created_at', 'desc')->get();

                return [
                    ['No.', 'Name', 'Email', 'Area', 'Rating', 'Verification Status', 'Online', 'Created At'],
                    $rows,
                    function ($row, $index) {
                        return [
                            $index + 1, $row->user->name ?? '-', $row->user->email ?? '-', $row->area,
                            $row->rating, $row->verification_status, $row->is_online ? 'Yes' : 'No',
                            optional($row->created_at)->format('Y-m-d H:i'),
                        ];
                    },
                    "technicians_report_{$timestamp}",
                ];
            })(),
            'jobs' => (function () use ($start, $end, $status, $timestamp) {
                $query = Job::with(['customer', 'technician.user', 'request.service'])
                    ->whereBetween('created_at', [$start, $end]);
                if ($status && $status !== 'all') $query->where('status', $status);
                $rows = $query->orderBy('created_at', 'desc')->get();

                return [
                    ['No.', 'Job #', 'Customer', 'Technician', 'Service', 'Status', 'Created At'],
                    $rows,
                    function ($row, $index) {
                        return [
                            $index + 1, 
                            $row->job_number,
                            $row->customer->name ?? '-', 
                            $row->technician->user->name ?? '-',
                            $row->request->service->name ?? '-', 
                            $row->status, 
                            optional($row->created_at)->format('Y-m-d H:i'),
                        ];
                    },
                    "jobs_report_{$timestamp}",
                ];
            })(),
            'tickets' => (function () use ($start, $end, $status, $timestamp) {
                $query = Ticket::with(['job.customer', 'job.technician.user'])
                    ->whereBetween('created_at', [$start, $end]);
                if ($status && $status !== 'all') $query->where('status', $status);
                $rows = $query->orderBy('created_at', 'desc')->get();

                return [
                    ['No.', 'Ticket #', 'Title', 'Job #', 'Customer', 'Status', 'Created At'],
                    $rows,
                    function ($row, $index) {
                        return [
                            $index + 1, 
                            $row->ticket_number,
                            $row->title,
                            $row->job->job_number ?? '-',
                            $row->job->customer->name ?? '-',
                            $row->status, 
                            optional($row->created_at)->format('Y-m-d H:i'),
                        ];
                    },
                    "tickets_report_{$timestamp}",
                ];
            })(),
        };
    }

    private function exportCombined(Carbon $start, Carbon $end, ?string $status)
    {
        $spreadsheet = new Spreadsheet();
        $spreadsheet->removeSheetByIndex(0);

        $sheetTitles = [
            'customers'     => 'Customers',
            'requests'      => 'Requests',
            'technicians'   => 'Technicians',
            'jobs'          => 'Jobs',
            'tickets'       => 'Tickets',
        ];

        foreach (self::DOMAINS as $type) {
            [$headers, $rows, $mapRow] = $this->exportDataFor($type, $start, $end, $status);

            $sheet = $spreadsheet->createSheet();
            $sheet->setTitle($sheetTitles[$type]);
            $sheet->fromArray($headers, null, 'A1');

            $rowIndex = 2;
            foreach ($rows as $index => $row) {
                $sheet->fromArray($mapRow($row, $index), null, "A{$rowIndex}");
                $rowIndex++;
            }

            foreach (range('A', $sheet->getHighestColumn()) as $col) {
                $sheet->getColumnDimension($col)->setAutoSize(true);
            }
        }

        $filename = 'report_all_' . now()->format('Y-m-d_His') . '.xlsx';
        $writer = new Xlsx($spreadsheet);

        return response()->streamDownload(function () use ($writer) {
            $writer->save('php://output');
        }, $filename, [
            'Content-Type' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ]);
    }
}