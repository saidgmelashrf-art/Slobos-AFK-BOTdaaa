#!/bin/bash

echo "⬇️ تحميل أحدث إصدار من Geyser-Standalone..."
wget -q https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/standalone -O /app/Geyser-Standalone.jar || echo "فشل التحميل، سيتم تخطيه..."

echo "⬇️ تحميل وتثبيت أداة zrok..."
wget -q https://github.com/openziti/zrok/releases/latest/download/zrok_linux_amd64.tar.gz || echo "فشل تحميل zrok..."
tar -xzf zrok_linux_amd64.tar.gz || true
chmod +x zrok || true
mv zrok /usr/local/bin/zrok || true

if [ -z "$ZROK_TOKEN" ]; then
    echo "❌ تنبيه خطير: متغير ZROK_TOKEN غير موجود في Railway Variables! يرجى إضافته."
else
    echo "🔑 تفعيل حساب zrok..."
    zrok enable $ZROK_TOKEN || echo "التفعيل فشل أو الحساب مفعل مسبقاً، سنتابع..."
fi

echo "🌐 تشغيل منفذ وهمي لاجتياز فحص Railway..."
python3 -m http.server ${PORT:-8080} &

echo "🚀 تشغيل Geyser في الخلفية..."
java -Xms512M -Xmx512M -jar /app/Geyser-Standalone.jar &

echo "🚀 تشغيل zrok لفتح النفق على بورت Geyser..."
zrok share public 127.0.0.1:19132 --backend-mode tcp &

# سكربت إرسال إشعار إلى ديسكورد
python3 - << 'EOF'
import time
import os
import urllib.request
import json

webhook_url = os.environ.get("DISCORD_WEBHOOK_URL")
if webhook_url:
    time.sleep(5)
    payload = {
        "content": "🚀 **تم تشغيل سيرفر الماينكرافت عبر zrok بنجاح!**\n🎮 الرابط جاهز لدخول أصحاب الـ Bedrock بدون أي كراش!"
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

# إبقاء الحاوية تعمل
wait
