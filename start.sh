#!/bin/bash

echo "⬇️ تحميل أحدث إصدار من Geyser-Standalone..."
wget -q https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/standalone -O /app/Geyser-Standalone.jar || echo "فشل تحميل Geyser..."

echo "⬇️ تحميل وتثبيت أداة Playit.gg..."
wget -q https://github.com/playit-cloud/playit-agent/releases/download/v0.15.26/playit-linux-amd64 -O /usr/local/bin/playit
chmod +x /usr/local/bin/playit

echo "🌐 تشغيل منفذ وهمي لاجتياز فحص Railway..."
python3 -m http.server ${PORT:-8080} &

echo "🚀 تشغيل Geyser في الخلفية..."
java -Xms512M -Xmx512M -jar /app/Geyser-Standalone.jar &

echo "🚀 تشغيل Playit.gg لفتح النفق..."
playit &

# سكربت إرسال إشعار إلى ديسكورد
python3 - << 'EOF'
import time
import os
import urllib.request
import json

webhook_url = os.environ.get("DISCORD_WEBHOOK_URL")
if webhook_url:
    time.sleep(6)
    payload = {
        "content": "🚀 **تم تشغيل سيرفر الماينكرافت عبر Playit.gg بنجاح!**\n🎮 تحقق من سجلات Railway (Logs) للحصول على رابط ربط الحساب (Claim Link)."
    }
    try:
        req = urllib.request.Request(
            webhook_url,
            data=json.dumps(payload).encode('utf-8'),
            headers={'Content-Type': 'application/json'}
        )
        urllib.request.urlopen(req)
        print("✅ تم إرسال إشعار التشغيل إلى ديسكورد بنجاح!")
    except Exception as e:
        print(f"⚠️ فشل إرسال الويب هوك: {e}")
EOF

wait
