<?php
namespace App\Http\Controllers\Api;

use App\Models\Otp;
use Carbon\Carbon;
use Illuminate\Http\Request; // ✅ Add this import

class OtpController extends BaseApiController
{
    public function index(Request $request)
    {
        $this->checkPermission('otp.view');
        $query = Otp::query();
        
        if ($request->filled('email')) {
            $query->where('email', $request->email);
        }
        if ($request->filled('type')) {
            $query->where('type', $request->type);
        }
        if ($request->has('is_used')) {
            $query->where('is_used', $request->is_used);
        }
        if ($request->filled('start_date')) {
            $query->whereDate('created_at', '>=', $request->start_date);
        }
        if ($request->filled('end_date')) {
            $query->whereDate('created_at', '<=', $request->end_date);
        }
        
        $otps = $query->orderBy('created_at', 'desc')->paginate($request->input('per_page', 30));
        
        // Get stats
        $stats = [
            'total' => Otp::count(),
            'used' => Otp::where('is_used', true)->count(),
            'unused' => Otp::where('is_used', false)->count(),
            'expired' => Otp::where('expires_at', '<', Carbon::now())->count(),
            'by_type' => Otp::select('type', \DB::raw('count(*) as count'))
                ->groupBy('type')
                ->get()
        ];
        
        return $this->successResponse([
            'data' => $otps->items(),
            'total' => $otps->total(),
            'per_page' => $otps->perPage(),
            'current_page' => $otps->currentPage(),
            'last_page' => $otps->lastPage(),
            'stats' => $stats
        ]);
    }

    public function cleanup()
    {
        $this->checkPermission('otp.cleanup');
        $deleted = Otp::where('expires_at', '<', Carbon::now())
            ->where('is_used', false)
            ->delete();
            
        return $this->successResponse(
            ['deleted' => $deleted], 
            "Deleted {$deleted} expired OTP records"
        );
    }
}