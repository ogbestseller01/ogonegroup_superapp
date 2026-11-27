<!DOCTYPE html>
<html lang="{{ $m['locale'] }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $m['title'] }}</title>
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
                        <div style="font-size:13px;opacity:.8;margin-top:2px;">{{ $m['section'] }}</div>
                    </td>
                </tr>
                <tr>
                    <td style="padding:26px;">
                        <h2 style="margin:0 0 12px;font-size:19px;color:{{ $m['type'] === 'rejected' ? '#b00020' : '#0b3d5c' }};">
                            {{ $m['title'] }}
                        </h2>
                        <p style="margin:0 0 6px;font-size:14px;line-height:1.5;">{{ $m['greeting'] }}</p>
                        <p style="margin:0 0 16px;font-size:14px;line-height:1.5;">{{ $m['intro'] }}</p>

                        <table role="presentation" width="100%" cellpadding="0" cellspacing="0"
                               style="background:#f4f7f6;border-radius:10px;font-size:14px;">
                            @foreach ($m['rows'] as $label => $value)
                                <tr>
                                    <td style="padding:10px 14px;color:#667;">{{ $label }}</td>
                                    <td style="padding:10px 14px;"><b>{{ $value }}</b></td>
                                </tr>
                            @endforeach
                        </table>

                        <p style="margin:18px 0 6px;font-size:14px;font-weight:700;color:#1b7f4b;">{{ $m['addedLabel'] }}</p>
                        @forelse ($m['added'] as $line)
                            <div style="font-size:14px;line-height:1.7;">+ {{ $line }}</div>
                        @empty
                            <div style="font-size:14px;color:#889;">{{ $m['none'] }}</div>
                        @endforelse

                        <p style="margin:16px 0 6px;font-size:14px;font-weight:700;color:#b00020;">{{ $m['removedLabel'] }}</p>
                        @forelse ($m['removed'] as $line)
                            <div style="font-size:14px;line-height:1.7;">&minus; {{ $line }}</div>
                        @empty
                            <div style="font-size:14px;color:#889;">{{ $m['none'] }}</div>
                        @endforelse

                        <p style="margin:18px 0 6px;font-size:14px;font-weight:700;">{{ $m['reasonLabel'] }}</p>
                        <div style="background:#f4f7f6;border-radius:10px;padding:12px 14px;font-size:14px;line-height:1.5;white-space:pre-line;">{{ $m['reason'] }}</div>

                        @if ($m['type'] === 'rejected' && $m['rejectionReason'])
                            <p style="margin:18px 0 6px;font-size:14px;font-weight:700;color:#b00020;">{{ $m['rejectionLabel'] }}</p>
                            <div style="background:#fdecee;border-radius:10px;padding:12px 14px;font-size:14px;line-height:1.5;white-space:pre-line;">{{ $m['rejectionReason'] }}</div>
                        @endif

                        @if ($m['buttonUrl'])
                            <p style="margin:22px 0 0;text-align:center;">
                                <a href="{{ $m['buttonUrl'] }}"
                                   style="display:inline-block;background:#0b3d5c;color:#ffffff;text-decoration:none;font-weight:700;font-size:14px;padding:12px 24px;border-radius:10px;">
                                    {{ $m['buttonText'] }}
                                </a>
                            </p>
                        @endif
                    </td>
                </tr>
                <tr>
                    <td style="padding:14px 26px;background:#f4f7f6;font-size:12px;color:#889;">{{ $m['footer'] }}</td>
                </tr>
            </table>
        </td>
    </tr>
</table>
</body>
</html>
