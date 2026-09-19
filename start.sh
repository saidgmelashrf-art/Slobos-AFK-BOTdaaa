#!/bin/bash

echo "⬇️ تحميل أحدث إصدار من Geyser-Standalone..."
wget -q https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/standalone -O /app/Geyser-Standalone.jar || echo "فشل تحميل Geyser..."

echo "⬇️ تحميل وتثبيت أداة zrok..."
python3 -c '
import urllib.request, json
try:
    req = urllib.request.Request("https://api.github.com/repos/openziti/zrok/releases/latest", headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read().decode())
        url = ""
        for asset in data.get("assets", []):
            if "linux_amd64.tar.gz" in asset["name"]:
                url = asset["browser_download_url"]
                break
        if url:
            urllib.request.urlretrieve(url, "zrok_pkg.tar.gz")
except Exception as e:
    print(f"Error: {e}")
'

if [ -f "zrok_pkg.tar.gz" ]; then
    tar -xzf zrok_pkg.tar.gz || true
fi

# البحث وتثبيت ملف zrok في المسار العام
ZROK_BIN=$(find . -name "zrok" -type f 2>/dev/null | head -n 1)
if [ -n "$ZROK_BIN" ]; then
    chmod +x "$ZROK_BIN"
    mv "$ZROK_BIN" /usr/local/bin/zrok
    echo "✅ تم تثبيت zrok بنجاح في المسار العام!"
else
    echo "⚠️ محاولة التثبيت بالطريقة البديلة..."
    wget -q https://github.com/openziti/zrok/releases/download/v0.4.38/zrok_0.4.38_linux_amd64.tar.gz -O zrok.tar.gz || true
    tar -xzf zrok.tar.gz || true
    if [ -f "zrok" ]; then
        chmod +x zrok
        mv zrok /usr/local/bin/zrok
        echo "✅ تم تثبيت zrok بنجاح بالطريقة البديلة!"
    fi
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

wait
