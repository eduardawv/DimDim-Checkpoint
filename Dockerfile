# =================================================================
# Projeto DimDim — Dockerfile
# Build: eclipse-temurin:17-jdk | Runtime: eclipse-temurin:17-jre
# Porta 8080 | Usuário sem root (appuser)
# =================================================================

FROM eclipse-temurin:17-jdk AS build
WORKDIR /app
COPY pom.xml .
COPY .mvn/ .mvn/
COPY mvnw .
RUN chmod +x mvnw && ./mvnw dependency:go-offline -B --no-transfer-progress
COPY src/ src/
RUN ./mvnw package -DskipTests -B --no-transfer-progress

FROM eclipse-temurin:17-jre AS runtime
WORKDIR /app
RUN groupadd --system appgroup && \
    useradd --system --gid appgroup --shell /bin/false appuser
COPY --from=build /app/target/clyvo-predict-0.0.1-SNAPSHOT.jar app.jar
RUN chown -R appuser:appgroup /app
USER appuser
EXPOSE 8080
ENV JAVA_OPTS="-Xms256m -Xmx512m"
ENV SPRING_PROFILES_ACTIVE=prod
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
