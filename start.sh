#!/bin/bash

echo "⬇️ تحميل أحدث إصدار من Geyser-Standalone..."
wget -q https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/standalone -O /app/Geyser-Standalone.jar || echo "فشل تحميل Geyser..."

echo "⬇️ جلب وتثبيت أحدث نسخة من أداة zrok تلقائياً..."
ZROK_URL=$(python3 -c '
import urllib.request, json
try:
    req = urllib.request.Request("https://api.github.com/repos/openziti/zrok/releases/latest", headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req) as response:
        data = json.loads(response.read().decode())
        for asset in data.get("assets", []):
            if "linux_amd64.tar.gz" in asset["name"]:
                print(asset["browser_download_url"])
                break
except Exception as e:
    pass
')

if [ -n "$ZROK_URL" ]; then
    wget -q "$ZROK_URL" -O zrok_linux_amd64.tar.gz
    tar -xzf zrok_linux_amd64.tar.gz || true
    
    # البحث الذكي عن ملف zrok أينما تم فك ضغطه ونقله للمسار العام
    ZROK_BIN=$(find . -name "zrok" -type f 2>/dev/null | head -n 1)
    if [ -n "$ZROK_BIN" ]; then
        chmod +x "$ZROK_BIN"
        mv "$ZROK_BIN" /usr/local/bin/zrok
        echo "✅ تم العثور على وتثبيت zrok بنجاح في المسار العام!"
    else
        echo "⚠️ تحذير: لم يتم العثور على ملف zrok بعد فك الضغط."
    fi
else
    echo "⚠️ فشل جلب رابط zrok تلقائياً."
fi

if [ -z "$ZROK_TOKEN" ]; then
    echo "❌ تنبيه: متغير ZROK_TOKEN غير موجود في Railway Variables!"
else
    echo "🔑 تفعيل حساب zrok..."
    zrok enable $ZROK_TOKEN || echo "التفعيل مفعل مسبقاً أو تمت المتابعة..."
fi

echo "🌐 تشغيل منفذ وهمي لاجتياز فحص Railway..."
python3 -m http.server ${PORT:-8080} &

echo "🚀 تشغيل Geyser في الخلفية..."
java -Xms512M -Xmx512M -jar /app/Geyser-Standalone.jar &

echo "🚀 تشغيل zrok لفتح النفق على بورت Geyser..."
zrok share public 127.0.0.1:19132 --backend-mode tcp &

# سكربت إرسال إشعار إلى ديسكورد بعد التأكد من الرابط
python3 - << 'EOF'
import time
import os
import urllib.request
import json

webhook_url = os.environ.get("DISCORD_WEBHOOK_URL")
if webhook_url:
    time.sleep(6)
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
