FROM eclipse-temurin:21-jre-jammy

# تثبيت الأدوات الأساسية وإضافة مستودع Playit الرسمي لمنع أخطاء التحميل
RUN apt-get update && apt-get install -y wget curl bash python3 gnupg && \
    curl -SsL https://playit-cloud.github.io/ppa/key.gpg | gpg --dearmor | tee /etc/apt/trusted.gpg.d/playit.gpg >/dev/null && \
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/playit.gpg] https://playit-cloud.github.io/ppa/data ./" | tee /etc/apt/sources.list.d/playit-cloud.list && \
    apt-get update && apt-get install -y playit && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY config.yml /app/config.yml
COPY start.sh /app/start.sh

RUN chmod +x /app/start.sh

CMD ["/app/start.sh"]
