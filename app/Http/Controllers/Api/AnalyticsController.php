<?php

namespace App\Http\Controllers\Api;

use App\Models\Post;
use App\Models\Comment;
use App\Models\Like;
use App\Models\Service;
use App\Models\ServiceRequest;
use App\Models\Job;
use App\Models\Ticket;
use App\Models\User;
use App\Models\Technician;
use App\Models\Role;
use App\Models\Permission;
use App\Models\Subscription;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class AnalyticsController extends BaseApiController
{
    /**
     * Get comprehensive dashboard analytics.
     * All date aggregations are in East Africa Time (EAT, UTC+3).
     */
    public function getDashboardAnalytics(Request $request)
    {
        $this->checkPermission('dashboard.view');

        // ---------- Core Counts ----------
        $totalUsers = User::count();
        $activeUsers = User::where('is_active', true)->count();
        $inactiveUsers = User::where('is_active', false)->count();

        $usersByRole = DB::table('roles')
            ->leftJoin('model_has_roles', 'roles.id', '=', 'model_has_roles.role_id')
            ->select('roles.id', 'roles.name', 'roles.display_name', DB::raw('COUNT(model_has_roles.model_id) as users_count'))
            ->groupBy('roles.id', 'roles.name', 'roles.display_name')
            ->get();

        $totalRoles = Role::count();
        $totalPermissions = Permission::count();

        // ---------- Technicians ----------
        $totalTechnicians = Technician::count();
        $verifiedTechnicians = Technician::where('verified', true)->count();
        $unverifiedTechnicians = Technician::where('verified', false)->count();
        $onlineTechnicians = Technician::where('is_online', true)->count();
        $technicianRatingStats = Technician::select(
            DB::raw('AVG(rating) as average_rating'),
            DB::raw('MIN(rating) as min_rating'),
            DB::raw('MAX(rating) as max_rating')
        )->first();

        // ---------- Customers ----------
        $customerIds = User::whereDoesntHave('technician')->pluck('id');
        $totalCustomers = $customerIds->count();
        $activeCustomers = User::whereHas('customerRequests')->count();

        // ---------- Likes & Comments ----------
        $totalLikes = Like::count();
        $likesPerPost = Post::withCount('likes')
            ->orderBy('likes_count', 'desc')
            ->limit(10)
            ->get(['id', 'title', 'likes_count']);

        $totalComments = Comment::count();
        $commentsPerPost = Post::withCount('comments')
            ->orderBy('comments_count', 'desc')
            ->limit(10)
            ->get(['id', 'title', 'comments_count']);

        // ---------- Services ----------
        $totalServices = Service::count();
        $servicesWithRequests = Service::has('requests')->count();
        $servicesWithoutRequests = Service::doesntHave('requests')->count();
        $topServices = Service::withCount('requests')
            ->orderBy('requests_count', 'desc')
            ->limit(10)
            ->get(['id', 'name', 'requests_count']);

        // ---------- Service Requests ----------
        $totalRequests = ServiceRequest::count();
        $requestsByStatus = ServiceRequest::select('status', DB::raw('count(*) as total'))
            ->groupBy('status')
            ->get();

        $pendingRequests = ServiceRequest::where('status', 'pending')->count();
        $acceptedRequests = ServiceRequest::where('status', 'accepted')->count();
        $inProgressRequests = ServiceRequest::where('status', 'in_progress')->count();
        $completedRequests = ServiceRequest::where('status', 'completed')->count();
        $cancelledRequests = ServiceRequest::where('status', 'cancelled')->count();
        $rejectedRequests = ServiceRequest::where('status', 'rejected')->count();

        // ---------- Jobs & Tickets (NEW) ----------
        $totalJobs = Job::count();
        $jobsByStatus = Job::select('status', DB::raw('count(*) as total'))
            ->groupBy('status')
            ->get();
            
        $totalTickets = Ticket::count();
        $ticketsByStatus = Ticket::select('status', DB::raw('count(*) as total'))
            ->groupBy('status')
            ->get();

        // Recent requests (last 10) with EAT timestamps
        $recentRequests = ServiceRequest::with(['customer', 'technician.user', 'service'])
            ->orderBy('created_at', 'desc')
            ->limit(10)
            ->get()
            ->map(function ($req) {
                $req->area = $req->technician?->area ?? 'N/A';
                $req->created_at_eat = $req->created_at->setTimezone('Africa/Dar_es_Salaam');
                return $req;
            });

        // Requests trend for the last 30 days (EAT dates)
        $requestsLast30Days = ServiceRequest::select(
                DB::raw("DATE(CONVERT_TZ(created_at, '+00:00', '+03:00')) as date"),
                DB::raw('count(*) as total')
            )
            ->where('created_at', '>=', now()->subDays(30))
            ->groupBy('date')
            ->orderBy('date', 'asc')
            ->get();

        // ---------- EAT-aware Analytics (with default current week) ----------
        $weeklyRequests = $this->getWeeklyRequests($request);
        $userTrend = $this->getUserTrend($request);
        $topTechnicians = $this->getTopTechnicians($request);
        $postsTrend = $this->getPostsTrend($request);
        $requestsByArea = $this->getRequestsByArea($request);

        // ---------- Engagement Metrics ----------
        $engagementMetrics = [
            'total_posts' => Post::count(),
            'total_comments' => $totalComments,
            'total_likes' => $totalLikes,
            'avg_comments_per_post' => Post::withCount('comments')->get()->avg('comments_count') ?? 0,
            'avg_likes_per_post' => Post::withCount('likes')->get()->avg('likes_count') ?? 0,
        ];

        // ---------- Revenue Analytics ----------
        $totalRevenue = Subscription::whereNotNull('payment_reference')
            ->whereNotIn('status', [Subscription::STATUS_PENDING, Subscription::STATUS_CANCELLED])
            ->sum('amount_paid');

        $weeklyRevenue = $this->getWeeklyRevenueForCurrentMonth($request);

        // ---------- Build Response ----------
        $data = [
            'users' => [
                'total' => $totalUsers,
                'active' => $activeUsers,
                'inactive' => $inactiveUsers,
                'by_role' => $usersByRole,
            ],
            'roles' => ['total' => $totalRoles],
            'permissions' => ['total' => $totalPermissions],
            'technicians' => [
                'total' => $totalTechnicians,
                'verified' => $verifiedTechnicians,
                'unverified' => $unverifiedTechnicians,
                'online' => $onlineTechnicians,
                'rating_stats' => $technicianRatingStats,
            ],
            'customers' => [
                'total' => $totalCustomers,
                'active' => $activeCustomers,
            ],
            'likes' => [
                'total' => $totalLikes,
                'top_posts' => $likesPerPost,
            ],
            'comments' => [
                'total' => $totalComments,
                'top_posts' => $commentsPerPost,
            ],
            'services' => [
                'total' => $totalServices,
                'with_requests' => $servicesWithRequests,
                'without_requests' => $servicesWithoutRequests,
                'top_services' => $topServices,
            ],
            'service_requests' => [
                'total' => $totalRequests,
                'by_status' => $requestsByStatus,
                'status_breakdown' => [
                    'pending' => $pendingRequests,
                    'accepted' => $acceptedRequests,
                    'in_progress' => $inProgressRequests,
                    'completed' => $completedRequests,
                    'cancelled' => $cancelledRequests,
                    'rejected' => $rejectedRequests,
                ],
                'recent' => $recentRequests,
                'last_30_days' => $requestsLast30Days,
            ],
            'jobs' => [ // NEW
                'total' => $totalJobs,
                'by_status' => $jobsByStatus,
            ],
            'tickets' => [ // NEW
                'total' => $totalTickets,
                'by_status' => $ticketsByStatus,
            ],
            'engagement_metrics' => $engagementMetrics,
            'weekly_requests' => $weeklyRequests,
            'user_trend' => $userTrend,
            'top_technicians' => $topTechnicians,
            'posts_trend' => $postsTrend,
            'requests_by_area' => $requestsByArea,
            'total_revenue' => round($totalRevenue, 2),
            'weekly_revenue' => $weeklyRevenue,
        ];

        return $this->successResponse($data);
    }

    /**
     * Simplified dashboard summary.
     */
    public function getDashboardSummary(Request $request)
    {
        $this->checkPermission('dashboard.view');

        $data = [
            'total_users' => User::count(),
            'total_roles' => Role::count(),
            'total_permissions' => Permission::count(),
            'total_technicians' => Technician::count(),
            'total_customers' => User::whereDoesntHave('technician')->count(),
            'total_likes' => Like::count(),
            'total_comments' => Comment::count(),
            'total_services' => Service::count(),
            'total_requests' => ServiceRequest::count(),
            'total_jobs' => Job::count(),       // NEW
            'total_tickets' => Ticket::count(), // NEW
            'requests_by_status' => ServiceRequest::select('status', DB::raw('count(*) as total'))
                ->groupBy('status')
                ->get(),
        ];

        return $this->successResponse($data);
    }

    // ---------- PRIVATE HELPERS (EAT-aware) ----------

    private function getWeeklyRequests(Request $request)
    {
        list($startEat, $endEat) = $this->parseDateRangeEat($request);
        
        if (!$startEat || !$endEat) {
            $now = Carbon::now('Africa/Dar_es_Salaam');
            $startEat = $now->copy()->startOfWeek(Carbon::MONDAY)->startOfDay();
            $endEat = $now->copy()->endOfWeek(Carbon::SUNDAY)->endOfDay();
        }

        $startUtc = $startEat->setTimezone('UTC');
        $endUtc = $endEat->setTimezone('UTC');

        return ServiceRequest::select(
                DB::raw("DAYNAME(CONVERT_TZ(created_at, '+00:00', '+03:00')) as day"),
                DB::raw('COUNT(*) as total')
            )
            ->whereBetween('created_at', [$startUtc, $endUtc])
            ->groupBy('day')
            ->orderByRaw("FIELD(day, 'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday')")
            ->get();
    }

    private function getUserTrend(Request $request)
    {
        list($startEat, $endEat) = $this->parseDateRangeEat($request);
        
        if (!$startEat || !$endEat) {
            $now = Carbon::now('Africa/Dar_es_Salaam');
            $startEat = $now->copy()->startOfWeek(Carbon::MONDAY)->startOfDay();
            $endEat = $now->copy()->endOfWeek(Carbon::SUNDAY)->endOfDay();
        }

        $startUtc = $startEat->setTimezone('UTC');
        $endUtc = $endEat->setTimezone('UTC');

        return User::select(
                DB::raw("DATE(CONVERT_TZ(created_at, '+00:00', '+03:00')) as date"),
                DB::raw('COUNT(*) as total'),
                DB::raw('SUM(CASE WHEN EXISTS (SELECT 1 FROM technicians WHERE technicians.user_id = users.id) THEN 1 ELSE 0 END) as technicians'),
                DB::raw('SUM(CASE WHEN NOT EXISTS (SELECT 1 FROM technicians WHERE technicians.user_id = users.id) THEN 1 ELSE 0 END) as customers')
            )
            ->whereBetween('created_at', [$startUtc, $endUtc])
            ->groupBy('date')
            ->orderBy('date', 'asc')
            ->get();
    }

    private function getTopTechnicians(Request $request)
    {
        $limit = $request->get('limit', 10);
        return Technician::select('technicians.id', 'technicians.user_id', 'users.name')
            ->join('users', 'users.id', '=', 'technicians.user_id')
            ->withCount('requests')
            ->orderBy('requests_count', 'desc')
            ->limit($limit)
            ->get();
    }

    private function getPostsTrend(Request $request)
    {
        list($startEat, $endEat) = $this->parseDateRangeEat($request);
        $startUtc = $startEat ? $startEat->setTimezone('UTC') : null;
        $endUtc = $endEat ? $endEat->setTimezone('UTC') : null;

        return Post::select(
                DB::raw("DATE(CONVERT_TZ(created_at, '+00:00', '+03:00')) as date"),
                DB::raw('COUNT(*) as posts')
            )
            ->when($startUtc, fn($q) => $q->where('created_at', '>=', $startUtc))
            ->when($endUtc, fn($q) => $q->where('created_at', '<=', $endUtc))
            ->groupBy('date')
            ->orderBy('date', 'asc')
            ->get();
    }

    private function getRequestsByArea(Request $request)
    {
        list($startEat, $endEat) = $this->parseDateRangeEat($request);
        $startUtc = $startEat ? $startEat->setTimezone('UTC') : null;
        $endUtc = $endEat ? $endEat->setTimezone('UTC') : null;

        return ServiceRequest::select(
                'technicians.area',
                DB::raw('COUNT(*) as total_requests')
            )
            ->join('technicians', 'technicians.id', '=', 'requests.technician_id')
            ->whereNotNull('technicians.area')
            ->when($startUtc, fn($q) => $q->where('requests.created_at', '>=', $startUtc))
            ->when($endUtc, fn($q) => $q->where('requests.created_at', '<=', $endUtc))
            ->groupBy('technicians.area')
            ->orderBy('total_requests', 'desc')
            ->get();
    }

    private function parseDateRangeEat(Request $request)
    {
        $period = $request->get('period');
        $date = $request->get('date');

        if (!$period || !$date) {
            return [null, null];
        }

        $tz = 'Africa/Dar_es_Salaam';
        $start = null;
        $end = null;

        if ($period === 'daily') {
            $start = Carbon::parse($date, $tz)->startOfDay();
            $end = Carbon::parse($date, $tz)->endOfDay();
        } elseif ($period === 'monthly') {
            $start = Carbon::parse($date . '-01', $tz)->startOfDay();
            $end = Carbon::parse($date . '-01', $tz)->endOfMonth()->endOfDay();
        } elseif ($period === 'yearly') {
            $start = Carbon::parse($date . '-01-01', $tz)->startOfDay();
            $end = Carbon::parse($date . '-12-31', $tz)->endOfDay();
        }

        return [$start, $end];
    }

    private function getWeeklyRevenueForCurrentMonth(Request $request)
    {
        $now = Carbon::now('Africa/Dar_es_Salaam');
        $startOfMonth = $now->copy()->startOfMonth();
        $endOfMonth = $now->copy()->endOfMonth();

        $startUtc = $startOfMonth->copy()->setTimezone('UTC');
        $endUtc = $endOfMonth->copy()->setTimezone('UTC');

        $subscriptions = Subscription::whereNotNull('payment_reference')
            ->whereNotIn('status', [Subscription::STATUS_PENDING, Subscription::STATUS_CANCELLED])
            ->whereBetween('created_at', [$startUtc, $endUtc])
            ->get(['amount_paid', 'created_at']);

        $weeklyTotals = [];
        foreach ($subscriptions as $sub) {
            $dateEat = $sub->created_at->setTimezone('Africa/Dar_es_Salaam');
            $weekNumber = $dateEat->weekOfMonth; // 1‑indexed week within the month
            $weeklyTotals[$weekNumber] = ($weeklyTotals[$weekNumber] ?? 0) + $sub->amount_paid;
        }

        $result = [];
        $weeksInMonth = $startOfMonth->copy()->endOfMonth()->weekOfMonth;
        for ($w = 1; $w <= $weeksInMonth; $w++) {
            $weekStart = $startOfMonth->copy()->addWeeks($w - 1)->startOfWeek();
            $weekEnd = $weekStart->copy()->endOfWeek();
            $label = $weekStart->format('M d') . ' - ' . $weekEnd->format('M d');
            $result[] = [
                'week' => $label,
                'total' => round($weeklyTotals[$w] ?? 0, 2),
            ];
        }

        return $result;
    }
}