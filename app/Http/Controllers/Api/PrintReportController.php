<?php

namespace App\Http\Controllers\Api;

use App\Models\Job;
use App\Models\Post;
use App\Models\Review;
use App\Models\ServiceRequest;
use App\Models\Technician;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\Request;
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;

class PrintReportController extends BaseApiController
{
    private const DOMAINS = [
        'users', 'technicians', 'requests', 'jobs', 'reviews', 'posts'
    ];

    // ============================================================
    // 1. DATA FETCHING (For UI Preview)
    // ============================================================
    public function index(Request $request)
    {
        $domain = $request->input('domain', 'users');
        if (!in_array($domain, self::DOMAINS)) {
            return $this->errorResponse('Invalid report domain.', 422);
        }

        [$start, $end] = $this->parseDates($request);

        $data = $this->fetchData(
            $domain, 
            $start, 
            $end, 
            $request->input('search'), 
            $request->input('role'),
            $request->input('status')
        );
        
        // ✅ Add continuous numbers (1, 2, 3...) instead of DB IDs
        $data = $data->map(function ($row, $index) {
            // Remove DB ID if it exists
            unset($row['id']); 
            // Prepend the sequential number
            return array_merge(['no' => $index + 1], $row);
        });

        return $this->successResponse([
            'domain'  => $domain,
            'period'  => [
                'from' => $start->toDateString(),
                'to'   => $end->toDateString(),
            ],
            'columns' => $this->getColumnsForDomain($domain),
            'rows'    => $data,
        ], 'Report data retrieved successfully');
    }

    // ============================================================
    // 2. EXPORTS (CSV, Excel)
    // ============================================================
    public function export(Request $request)
    {
        $domain = $request->input('domain', 'users');
        $format = $request->input('format', 'csv'); 
        
        if (!in_array($domain, self::DOMAINS)) {
            return $this->errorResponse('Invalid report domain.', 422);
        }

        [$start, $end] = $this->parseDates($request);
        
        $rawData = $this->fetchData(
            $domain, 
            $start, 
            $end, 
            $request->input('search'), 
            $request->input('role'),
            $request->input('status')
        );

        // ✅ Add continuous numbers for exports
        $rawData = $rawData->map(function ($row, $index) {
            unset($row['id']);
            return array_merge(['no' => $index + 1], $row);
        })->toArray();

        $headers = array_column($this->getColumnsForDomain($domain), 'label');
        $rows = array_map(fn($item) => array_values($item), $rawData);

        if ($format === 'csv') {
            return $this->exportCsv($headers, $rows, "report_{$domain}");
        } elseif ($format === 'xlsx') {
            return $this->exportXlsx($headers, $rows, "report_{$domain}");
        }

        return $this->errorResponse('Unsupported format.', 422);
    }

    // ============================================================
    // 3. CORE DATA LOGIC
    // ============================================================
    private function fetchData(string $domain, Carbon $start, Carbon $end, ?string $search, ?string $role = null, ?string $status = null)
    {
        $startStr = $start->startOfDay();
        $endStr = $end->endOfDay();

        switch ($domain) {
            case 'users':
                return User::with('roles')
                    ->whereBetween('created_at', [$startStr, $endStr])
                    ->when($search, fn($q) => $q->where(function($sub) use ($search) {
                        $sub->where('name', 'like', "%{$search}%")
                            ->orWhere('email', 'like', "%{$search}%");
                    }))
                    ->when($role, fn($q) => $q->role($role))
                    ->when($status, fn($q) => $q->where('status', $status))
                    ->get()
                    ->map(fn($u) => [
                        'name' => $u->name,
                        'email' => $u->email ?? '—',
                        'phone' => $u->phone ?? '—',
                        'role' => $u->roles->first()?->display_name ?? $u->roles->first()?->name ?? 'CUSTOMER',
                        'status' => $u->status,
                        'joined' => $u->created_at->format('Y-m-d'),
                    ]);

            case 'technicians':
                return Technician::with(['user', 'services'])
                    ->whereBetween('created_at', [$startStr, $endStr])
                    ->when($search, fn($q) => $q->whereHas('user', fn($uq) => $uq->where('name', 'like', "%{$search}%")))
                    ->when($status, fn($q) => $q->where('verification_status', $status))
                    ->get()
                    ->map(fn($t) => [
                        'name' => $t->user->name ?? '—',
                        'phone' => $t->user->phone ?? '—',
                        'area' => $t->area ?? '—',
                        'rating' => $t->rating,
                        'services' => $t->services->pluck('name')->implode(', '),
                        'status' => $t->verification_status ?? 'pending',
                    ]);

            case 'requests':
                return ServiceRequest::with(['customer', 'technician.user', 'job'])
                    ->whereBetween('created_at', [$startStr, $endStr])
                    ->when($search, fn($q) => $q->where('description', 'like', "%{$search}%"))
                    ->when($status, fn($q) => $q->where('status', $status))
                    ->get()
                    ->map(fn($r) => [
                        'customer' => $r->customer?->name ?? '—',
                        'technician' => $r->technician?->user?->name ?? '—',
                        'description' => substr($r->description ?? '', 0, 40) . '...',
                        'req_status' => $r->status,
                        'job_number' => $r->job?->job_number ?? 'No Job',
                        'job_status' => $r->job?->status ?? '—',
                        'date' => $r->created_at->format('Y-m-d'),
                    ]);

            case 'jobs':
                return Job::with(['customer', 'technician.user', 'tickets'])
                    ->whereBetween('created_at', [$startStr, $endStr])
                    ->when($search, fn($q) => $q->where('job_number', 'like', "%{$search}%"))
                    ->when($status, fn($q) => $q->where('status', $status))
                    ->get()
                    ->map(fn($j) => [
                        'job_number' => $j->job_number,
                        'customer' => $j->customer?->name ?? '—',
                        'technician' => $j->technician?->user?->name ?? '—',
                        'tickets_count' => $j->tickets->count(),
                        'status' => $j->status,
                        'created' => $j->created_at->format('Y-m-d'),
                        'completed' => $j->completed_at?->format('Y-m-d') ?? '—',
                    ]);

            case 'reviews':
                return Review::with(['customer', 'technician.user', 'job'])
                    ->whereBetween('created_at', [$startStr, $endStr])
                    ->when($search, fn($q) => $q->where('comment', 'like', "%{$search}%"))
                    ->get()
                    ->map(fn($r) => [
                        'job_number' => $r->job?->job_number ?? '—',
                        'customer' => $r->customer?->name ?? '—',
                        'technician' => $r->technician?->user?->name ?? '—',
                        'rating' => $r->rating,
                        'comment' => $r->comment ?? 'No comment',
                        'date' => $r->created_at->format('Y-m-d'),
                    ]);

            case 'posts':
                return Post::with('technician.user')
                    ->withCount(['comments', 'likes'])
                    ->whereBetween('created_at', [$startStr, $endStr])
                    ->when($search, fn($q) => $q->whereHas('technician.user', fn($uq) => $uq->where('name', 'like', "%{$search}%")))
                    ->get()
                    ->map(fn($p) => [
                        'technician' => $p->technician?->user?->name ?? '—',
                        'media_type' => $p->video ? 'Video' : 'Images (' . count($p->images ?? []) . ')',
                        'likes' => $p->likes_count,
                        'comments' => $p->comments_count,
                        'date' => $p->created_at->format('Y-m-d'),
                    ]);

            default:
                return collect([]);
        }
    }

    // ============================================================
    // 4. HELPERS
    // ============================================================
    private function parseDates(Request $request): array
    {
        $from = $request->input('from', now()->startOfMonth()->toDateString());
        $to = $request->input('to', now()->endOfMonth()->toDateString());
        return [Carbon::parse($from), Carbon::parse($to)];
    }

    private function getColumnsForDomain(string $domain): array
    {
        $map = [
            'users' => [
                ['key' => 'no', 'label' => 'No.'],
                ['key' => 'name', 'label' => 'Name'],
                ['key' => 'email', 'label' => 'Email'],
                ['key' => 'phone', 'label' => 'Phone'],
                ['key' => 'role', 'label' => 'Role'],
                ['key' => 'status', 'label' => 'Status'],
                ['key' => 'joined', 'label' => 'Joined Date'],
            ],
            'technicians' => [
                ['key' => 'no', 'label' => 'No.'],
                ['key' => 'name', 'label' => 'Technician Name'],
                ['key' => 'phone', 'label' => 'Phone'],
                ['key' => 'area', 'label' => 'Area'],
                ['key' => 'rating', 'label' => 'Rating'],
                ['key' => 'services', 'label' => 'Services Offered'],
                ['key' => 'status', 'label' => 'Status'],
            ],
            'requests' => [
                ['key' => 'no', 'label' => 'No.'],
                ['key' => 'customer', 'label' => 'Customer'],
                ['key' => 'technician', 'label' => 'Technician'],
                ['key' => 'description', 'label' => 'Description'],
                ['key' => 'req_status', 'label' => 'Req Status'],
                ['key' => 'job_number', 'label' => 'Linked Job #'],
                ['key' => 'job_status', 'label' => 'Job Status'],
                ['key' => 'date', 'label' => 'Date'],
            ],
            'jobs' => [
                ['key' => 'no', 'label' => 'No.'],
                ['key' => 'job_number', 'label' => 'Job #'],
                ['key' => 'customer', 'label' => 'Customer'],
                ['key' => 'technician', 'label' => 'Technician'],
                ['key' => 'tickets_count', 'label' => 'Tickets'],
                ['key' => 'status', 'label' => 'Job Status'],
                ['key' => 'created', 'label' => 'Created'],
                ['key' => 'completed', 'label' => 'Completed'],
            ],
            'reviews' => [
                ['key' => 'no', 'label' => 'No.'],
                ['key' => 'job_number', 'label' => 'Job #'],
                ['key' => 'customer', 'label' => 'Customer'],
                ['key' => 'technician', 'label' => 'Technician'],
                ['key' => 'rating', 'label' => 'Rating'],
                ['key' => 'comment', 'label' => 'Comment'],
                ['key' => 'date', 'label' => 'Date'],
            ],
            'posts' => [
                ['key' => 'no', 'label' => 'No.'],
                ['key' => 'technician', 'label' => 'Author'],
                ['key' => 'media_type', 'label' => 'Media Type'],
                ['key' => 'likes', 'label' => 'Likes'],
                ['key' => 'comments', 'label' => 'Comments'],
                ['key' => 'date', 'label' => 'Date'],
            ],
        ];

        return $map[$domain] ?? [];
    }

    private function exportCsv(array $headers, array $rows, string $filename)
    {
        $handle = fopen('php://temp', 'r+');
        fputcsv($handle, $headers);
        foreach ($rows as $row) {
            fputcsv($handle, $row);
        }
        rewind($handle);
        $content = stream_get_contents($handle);
        fclose($handle);

        return response($content, 200)
            ->header('Content-Type', 'text/csv')
            ->header('Content-Disposition', "attachment; filename=\"{$filename}.csv\"");
    }

    private function exportXlsx(array $headers, array $rows, string $filename)
    {
        $spreadsheet = new Spreadsheet();
        $sheet = $spreadsheet->getActiveSheet();
        
        $sheet->fromArray($headers, null, 'A1');
        $sheet->fromArray($rows, null, 'A2');
        
        foreach (range('A', $sheet->getHighestColumn()) as $col) {
            $sheet->getColumnDimension($col)->setAutoSize(true);
        }

        $writer = new Xlsx($spreadsheet);

        return response()->streamDownload(function () use ($writer) {
            $writer->save('php://output');
        }, "{$filename}.xlsx", [
            'Content-Type' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ]);
    }
}