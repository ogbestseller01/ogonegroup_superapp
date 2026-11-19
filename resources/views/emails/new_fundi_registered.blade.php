<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>New fundi registered</title>
</head>
<body style="margin:0;padding:0;background:#f4f7f6;font-family:Arial,Helvetica,sans-serif;color:#1f2937;">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#f4f7f6;padding:24px 12px;">
    <tr>
        <td align="center">
            <table role="presentation" width="100%" cellpadding="0" cellspacing="0"
                   style="max-width:560px;background:#ffffff;border-radius:16px;overflow:hidden;">

                {{-- Header --}}
                <tr>
                    <td style="background:#0f3d3e;padding:24px 28px;">
                        <div style="font-size:20px;font-weight:700;color:#ffffff;">NearbyFundi</div>
                        <div style="font-size:13px;color:#cfe3e1;margin-top:4px;">Admin notification</div>
                    </td>
                </tr>

                {{-- Body --}}
                <tr>
                    <td style="padding:28px;">
                        <h2 style="margin:0 0 8px;font-size:20px;color:#0f3d3e;">New fundi registered</h2>
                        <p style="margin:0 0 20px;font-size:14px;line-height:1.6;color:#4b5563;">
                            A new fundi has submitted a registration and is waiting for your approval.
                        </p>

                        <table role="presentation" width="100%" cellpadding="0" cellspacing="0"
                               style="background:#f4f7f6;border-radius:12px;">
                            <tr>
                                <td style="padding:16px 18px;border-bottom:1px solid #e5e7eb;">
                                    <div style="font-size:12px;color:#6b7280;text-transform:uppercase;letter-spacing:.4px;">Name</div>
                                    <div style="font-size:16px;font-weight:700;margin-top:2px;">{{ $fundiName }}</div>
                                </td>
                            </tr>
                            <tr>
                                <td style="padding:16px 18px;border-bottom:1px solid #e5e7eb;">
                                    <div style="font-size:12px;color:#6b7280;text-transform:uppercase;letter-spacing:.4px;">Place / Area</div>
                                    <div style="font-size:16px;font-weight:700;margin-top:2px;">{{ $area }}</div>
                                </td>
                            </tr>
                            <tr>
                                <td style="padding:16px 18px;border-bottom:1px solid #e5e7eb;">
                                    <div style="font-size:12px;color:#6b7280;text-transform:uppercase;letter-spacing:.4px;">
                                        Service{{ count($services) === 1 ? '' : 's' }}
                                    </div>
                                    <div style="margin-top:8px;">
                                        @forelse ($services as $service)
                                            <span style="display:inline-block;background:#0f3d3e;color:#ffffff;font-size:13px;font-weight:600;padding:5px 12px;border-radius:999px;margin:0 6px 6px 0;">
                                                {{ $service }}
                                            </span>
                                        @empty
                                            <span style="font-size:14px;color:#6b7280;">No services selected</span>
                                        @endforelse
                                    </div>
                                </td>
                            </tr>
                            @if ($fundiPhone)
                                <tr>
                                    <td style="padding:16px 18px;border-bottom:1px solid #e5e7eb;">
                                        <div style="font-size:12px;color:#6b7280;text-transform:uppercase;letter-spacing:.4px;">Phone</div>
                                        <div style="font-size:15px;margin-top:2px;">{{ $fundiPhone }}</div>
                                    </td>
                                </tr>
                            @endif
                            @if ($fundiEmail)
                                <tr>
                                    <td style="padding:16px 18px;border-bottom:1px solid #e5e7eb;">
                                        <div style="font-size:12px;color:#6b7280;text-transform:uppercase;letter-spacing:.4px;">Email</div>
                                        <div style="font-size:15px;margin-top:2px;">{{ $fundiEmail }}</div>
                                    </td>
                                </tr>
                            @endif
                            <tr>
                                <td style="padding:16px 18px;">
                                    <div style="font-size:12px;color:#6b7280;text-transform:uppercase;letter-spacing:.4px;">Registered</div>
                                    <div style="font-size:15px;margin-top:2px;">{{ $registeredAt->format('d M Y, H:i') }}</div>
                                </td>
                            </tr>
                        </table>

                        <p style="margin:22px 0 0;font-size:14px;line-height:1.6;color:#4b5563;">
                            Please review the details and approve or reject this fundi from the admin dashboard.
                        </p>
                    </td>
                </tr>

                {{-- Footer --}}
                <tr>
                    <td style="padding:18px 28px;background:#f4f7f6;font-size:12px;color:#9ca3af;text-align:center;">
                        This is an automated message from NearbyFundi. Please do not reply.
                    </td>
                </tr>
            </table>
        </td>
    </tr>
</table>
</body>
</html>