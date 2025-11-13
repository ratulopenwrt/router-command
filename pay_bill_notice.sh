#!/bin/ash
date=$(date "+%r  %A %d/%m/%Y")

cat <<EOF | sendmail root
Subject: Friendly Reminder — Internet Service Payment Due

Hello,

This is a friendly reminder that your internet service is scheduled for suspension at 00:00 tonight if the outstanding bill is not paid. To avoid any interruption, please settle your bill as soon as possible.

Quick details:
- Deadline: 12:00 AM (midnight) tonight
- Recommended action: Pay via your usual payment method or contact our billing team for help

If you’ve already paid, thank you — please ignore this message. If you need assistance or want to confirm your account status, reply to this email or contact billing at billing@example.com.

Thank you for being a valued user.

Regards,
OpenWRT
Time: $date
EOF

exit 0
