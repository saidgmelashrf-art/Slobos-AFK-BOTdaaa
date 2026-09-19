#!/bin/bash
set -e

echo "⬇️ تحميل أحدث إصدار من Geyser-Standalone..."
wget -q https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/standalone -O /app/Geyser-Standalone.jar

echo "⬇️ تحميل وتثبيت ngrok..."
wget -q https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
tar -xzf ngrok-v3-stable-linux-amd64.tgz
mv ngrok /usr/local/bin/ngrok
chmod +x /usr/local/bin/ngrok

echo "🔑 ربط حساب ngrok بالـ AuthToken..."
ngrok config add-authtoken $NGROK_AUTHTOKEN

echo "🌐 تشغيل منفذ وهمي لاجتياز فحص Railway..."
python3 -m http.server ${PORT:-8080} &

echo "🚀 تشغيل Geyser في الخلفية..."
java -Xms512M -Xmx512M -jar /app/Geyser-Standalone.jar &

echo "🚀 تشغيل ngrok وتوليد الـ TCP Tunnel..."
ngrok tcp 19132 --log=stdout &

echo "🤖 تشغيل سكربت إرسال البيانات إلى ديسكورد..."
python3 - << 'EOF'
import time
import urllib.request
import json
import os

webhook_url = os.environ.get("DISCORD_WEBHOOK_URL")
if not webhook_url:
    print("⚠️ تنبيه: لم يتم تحديد DISCORD_WEBHOOK_URL")
    exit(0)

# محاولة الاتصال بـ ngrok local API لجلب الـ IP والبورت
for i in range(15):
    try:
        req = urllib.request.Request("http://localhost:4040/api/tunnels")
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode())
            tunnels = data.get("tunnels", [])
            for t in tunnels:
                if t.get("proto") == "tcp":
                    public_url = t.get("public_url") # مثال: tcp://0.tcp.in.ngrok.io:12345
                    clean_url = public_url.replace("tcp://", "")
                    host, port = clean_url.split(":")
                    
                    # تجهيز الرسالة لتروح ديسكورد
                    payload = {
                        "content": f"🚀 **تم تشغيل سيرفر الماينكرافت بنجاح!**\n📌 **Server Address:** `{host}`\n🔌 **Port:** `{port}`\n🎮 الرابط جاهز لدخول أصحاب الـ Bedrock!"
                    }
                    
                    req_discord = urllib.request.Request(
                        webhook_url,
                        data=json.dumps(payload).encode('utf-8'),
                        headers={'Content-Type': 'application/json'}
                    )
                    urllib.request.urlopen(req_discord)
                    print(f"✅ تم إرسال الـ IP والبورت إلى ديسكورد بنجاح: {host}:{port}")
                    exit(0)
    except Exception as e:
        print(f"جاري انتظار ngrok API... ({i+1}/15)")
    time.sleep(2)

print("❌ فشل في جلب معلومات ngrok API وإرسالهاديسكورد")
EOF

# إبقاء الحاوية تعمل
wait
