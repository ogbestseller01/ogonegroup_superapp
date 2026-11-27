<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Your NearbyFundi code</title>
</head>
<body style="margin:0;padding:0;background:#f4f7f6;font-family:Arial,Helvetica,sans-serif;color:#1f2937;">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#f4f7f6;padding:24px 12px;">
    <tr>
        <td align="center">
            <table role="presentation" width="100%" cellpadding="0" cellspacing="0"
                   style="max-width:560px;background:#ffffff;border-radius:16px;overflow:hidden;">
                <tr>
                    <td style="background:#0f3d3e;padding:24px 28px;font-size:20px;font-weight:700;color:#ffffff;">
                        NearbyFundi
                    </td>
                </tr>
                <tr>
                    <td style="padding:28px;">
                        <h2 style="margin:0 0 12px;font-size:20px;color:#0f3d3e;">
                            {{ $type === 'password_reset' ? 'Password reset code' : 'Verification code' }}
                        </h2>
                        <p style="font-size:14px;line-height:1.6;">
                            Hello {{ $name }}, use this code to
                            {{ $type === 'password_reset' ? 'reset your password' : 'verify your account' }}:
                        </p>
                        <div style="font-size:32px;font-weight:700;letter-spacing:8px;text-align:center;background:#f4f7f6;border-radius:12px;padding:18px;">
                            {{ $otp }}
                        </div>
                        <p style="font-size:14px;line-height:1.6;">This code expires in 10 minutes.</p>
                        <p style="font-size:13px;line-height:1.6;color:#6b7280;">
                            Never share this code. If you did not request it, please ignore this email.
                        </p>
                    </td>
                </tr>
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