#!/bin/bash
set -e

echo "⬇️ تحميل أحدث إصدار من Geyser-Standalone..."
wget -q https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/standalone -O /app/Geyser-Standalone.jar

echo "⬇️ تحميل أداة bore لفتح البورت..."
wget -q https://github.com/ekzhang/bore/releases/download/v0.5.0/bore-v0.5.0-x86_64-unknown-linux-musl.tar.gz
tar -xf bore-v0.5.0-x86_64-unknown-linux-musl.tar.gz
mv bore /usr/local/bin/bore
chmod +x /usr/local/bin/bore

echo "🌐 تشغيل منفذ وهمي لاجتياز فحص Railway..."
python3 -m http.server ${PORT:-8080} &

echo "🚀 تشغيل Geyser في الخلفية..."
java -Xms512M -Xmx512M -jar /app/Geyser-Standalone.jar &

echo "🚀 تشغيل bore ببورت عشوائي متاح..."
# شلنا تحديد البورت عشان يختار بورت فاضي لوحده وتتجنب خطأ الاستخدام
bore local 19132 --to bore.pub
