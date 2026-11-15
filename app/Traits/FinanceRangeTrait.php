<?php

namespace App\Traits;

use Carbon\Carbon;

trait FinanceRangeTrait
{
    protected function resolveRange($request): array
    {
        $range = $request->input('range', 'month');

        if ($range === 'custom' && $request->filled('date_from') && $request->filled('date_to')) {
            return [
                Carbon::parse($request->date_from)->startOfDay(),
                Carbon::parse($request->date_to)->endOfDay(),
                $range,
            ];
        }

        $end = Carbon::now()->endOfDay();
        $start = match ($range) {
            'week'  => Carbon::now()->startOfWeek(),
            'year'  => Carbon::now()->startOfYear(),
            default => Carbon::now()->startOfMonth(),
        };

        return [$start, $end, $range];
    }

    protected function resolveGranularity($request, string $range): string
    {
        if ($request->filled('granularity')) {
            return $request->input('granularity');
        }
        return match ($range) {
            'week'  => 'daily',
            'year'  => 'monthly',
            default => 'daily',
        };
    }

    protected function bucketUnit(string $granularity): string
    {
        return match ($granularity) {
            'weekly'  => 'week',
            'monthly' => 'month',
            default   => 'day',
        };
    }

    protected function bucketLabel(Carbon $date, string $unit): string
    {
        return $unit === 'month' ? $date->format('M Y') : $date->format('d M');
    }

    protected function exportCsv($rows, array $headers, string $filename, callable $mapRow)
    {
        $callback = function () use ($rows, $headers, $mapRow) {
            $handle = fopen('php://output', 'w');
            fputcsv($handle, $headers);
            foreach ($rows as $row) {
                fputcsv($handle, $mapRow($row));
            }
            fclose($handle);
        };

        return response()->stream($callback, 200, [
            'Content-Type'        => 'text/csv',
            'Content-Disposition' => "attachment; filename=\"{$filename}.csv\"",
        ]);
    }

    protected function exportExcel($rows, array $headers, string $filename, callable $mapRow)
    {
        $html = '<table border="1" cellpadding="5"><thead><tr>' .
            collect($headers)->map(fn ($h) => "<th>{$h}</th>")->implode('') .
            '</tr></thead><tbody>';

        foreach ($rows as $row) {
            $cells = $mapRow($row);
            $html .= '<tr>' . collect($cells)->map(fn ($c) => "<td>{$c}</td>")->implode('') . '</tr>';
        }
        $html .= '</tbody></table>';

        return response($html, 200, [
            'Content-Type'        => 'application/vnd.ms-excel',
            'Content-Disposition' => "attachment; filename=\"{$filename}.xls\"",
        ]);
    }
}