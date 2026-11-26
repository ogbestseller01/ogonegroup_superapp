<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>New sign-in</title>
</head>
<body style="margin:0;padding:0;background:#f4f7f6;font-family:Arial,Helvetica,sans-serif;color:#1d2b36;">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#f4f7f6;padding:24px 0;">
    <tr>
        <td align="center">
            <table role="presentation" width="480" cellpadding="0" cellspacing="0"
                   style="max-width:480px;width:100%;background:#ffffff;border-radius:16px;overflow:hidden;">
                <tr>
                    <td style="background:#0b3d5c;padding:22px 26px;color:#ffffff;">
                        <div style="font-size:20px;font-weight:700;">Nearby Fundi</div>
                        <div style="font-size:13px;opacity:.8;margin-top:2px;">Security notification</div>
                    </td>
                </tr>
                <tr>
                    <td style="padding:26px;">
                        <h2 style="margin:0 0 12px;font-size:19px;color:#0b3d5c;">New sign-in to your account</h2>
                        <p style="margin:0 0 16px;font-size:14px;line-height:1.5;">
                            Hello {{ $userName }}, your account was just signed in to:
                        </p>

                        <table role="presentation" width="100%" cellpadding="0" cellspacing="0"
                               style="background:#f4f7f6;border-radius:10px;font-size:14px;">
                            <tr>
                                <td style="padding:10px 14px;color:#667;">Time</td>
                                <td style="padding:10px 14px;"><b>{{ $details['when'] }}</b></td>
                            </tr>
                            <tr>
                                <td style="padding:10px 14px;color:#667;">Device</td>
                                <td style="padding:10px 14px;"><b>{{ $details['device'] }}</b></td>
                            </tr>
                            <tr>
                                <td style="padding:10px 14px;color:#667;">IP address</td>
                                <td style="padding:10px 14px;"><b>{{ $details['ip'] }}</b></td>
                            </tr>
                            <tr>
                                <td style="padding:10px 14px;color:#667;">Location</td>
                                <td style="padding:10px 14px;"><b>{{ $details['location'] }}</b></td>
                            </tr>
                            <tr>
                                <td style="padding:10px 14px;color:#667;">Method</td>
                                <td style="padding:10px 14px;"><b>{{ $details['method'] }}</b></td>
                            </tr>
                        </table>

                        <p style="margin:18px 0 8px;font-size:14px;line-height:1.5;">
                            If this was you, no action is needed.
                        </p>
                        <p style="margin:0;font-size:14px;line-height:1.5;color:#b00020;">
                            <b>If this was not you</b>, open the app, tap "Forgot password" to set a new password,
                            then log out of all devices.
                        </p>
                    </td>
                </tr>
                <tr>
                    <td style="padding:14px 26px;background:#f4f7f6;font-size:12px;color:#889;">
                        You receive this email every time someone signs in to your Nearby Fundi account.
                    </td>
                </tr>
            </table>
        </td>
    </tr>
</table>
</body>
</html>