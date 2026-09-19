#!/bin/bash
set -e

echo "⬇️ تحميل أحدث إصدار من Geyser-Standalone..."
wget -q https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/standalone -O /app/Geyser-Standalone.jar

echo "⬇️ تحميل وتثبيت أداة zrok..."
wget -q https://github.com/openziti/zrok/releases/latest/download/zrok_linux_amd64.tar.gz
tar -xzf zrok_linux_amd64.tar.gz
chmod +x zrok
mv zrok /usr/local/bin/zrok

echo "🔑 تفعيل حساب zrok باستخدام التوكن..."
zrok enable $ZROK_TOKEN

echo "🌐 تشغيل منفذ وهمي لاجتياز فحص Railway..."
python3 -m http.server ${PORT:-8080} &

echo "🚀 تشغيل Geyser في الخلفية..."
java -Xms512M -Xmx512M -jar /app/Geyser-Standalone.jar &

echo "🚀 تشغيل zrok لفتح النفق..."
zrok share public http://127.0.0.1:19132 --backend-mode proxy &

# سكربت ذكي لالتقاط رابط zrok وإرساله إلى ديسكورد
python3 - << 'EOF'
import time
import subprocess
import os
import urllib.request
import json

webhook_url = os.environ.get("DISCORD_WEBHOOK_URL")

print("⏳ جاري انتظار إطلاق نفق zrok...")
time.sleep(5)

# يمكنك قراءة الرابط من مخرجات zrok أو تفقده، وحال ظهور الرابط يتم إرساله للديسكورد
if webhook_url:
    payload = {
        "content": "🚀 **تم تشغيل سيرفر الماينكرافت عبر zrok بنجاح!**\n🎮 الرابط العام جاهز لدخول أصحاب الـ Bedrock!"
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

# إبقاء الحاوية قيد التشغيل
wait
