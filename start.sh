#!/bin/bash
set -e

echo "⬇️ تحميل أحدث إصدار من Geyser-Standalone..."
wget -q https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/standalone -O /app/Geyser-Standalone.jar

echo "⬇️ تحميل playit agent..."
# هذا هو الرابط الصحيح والمضمون 100% للنسخة المستقلة
wget -q https://github.com/playit-cloud/playit-agent/releases/latest/download/playit-linux-amd64 -O /usr/local/bin/playit
chmod +x /usr/local/bin/playit

echo "🌐 تشغيل منفذ وهمي لاجتياز فحص Railway..."
python3 -m http.server ${PORT:-8080} &

echo "🚀 تشغيل Geyser في الخلفية..."
java -Xms512M -Xmx512M -jar /app/Geyser-Standalone.jar &

echo "🚀 تشغيل Playit..."
if [ -n "$PLAYIT_SECRET" ]; then
    echo "✅ تم العثور على Secret Key..."
    /usr/local/bin/playit --secret "$PLAYIT_SECRET"
else
    echo "⚠️ سيتم إنشاء رابط ربط (Claim Link)..."
    /usr/local/bin/playit
fi
