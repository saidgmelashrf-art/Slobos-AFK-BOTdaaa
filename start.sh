#!/bin/bash
set -e

echo "⬇️ تحميل أحدث إصدار من Geyser-Standalone..."
wget -q https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/standalone -O /app/Geyser-Standalone.jar

echo "⬇️ تحميل playit agent..."
curl -fsSL https://github.com/playit-cloud/playit-agent/releases/latest/download/playit-x86_64-unknown-linux-musl -o /usr/local/bin/playit
chmod +x /usr/local/bin/playit

echo "🌐 تشغيل منفذ وهمي لاجتياز فحص Railway..."
python3 -m http.server ${PORT:-8080} &

echo "🚀 تشغيل Geyser في الخلفية..."
java -Xms512M -Xmx512M -jar /app/Geyser-Standalone.jar &

echo "🚀 تشغيل Playit..."
if [ -n "$PLAYIT_SECRET" ]; then
    echo "✅ تم العثور على Secret Key، جاري الاتصال..."
    /usr/local/bin/playit --secret "$PLAYIT_SECRET"
else
    echo "⚠️ لم يتم وضع Secret Key. سيتم إنشاء رابط ربط (Claim Link)..."
    /usr/local/bin/playit
fi
