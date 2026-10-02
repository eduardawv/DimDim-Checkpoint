# NOVO - Sprint 4
# Build em multi-stage: a imagem final nao carrega Maven nem codigo-fonte.
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app

COPY pom.xml .
RUN mvn -B -q dependency:go-offline

COPY src ./src
RUN mvn -B -q clean package -DskipTests

# Imagem de execucao
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Requisito da disciplina de DevOps: o container nao pode rodar como root
RUN addgroup -S clyvo && adduser -S clyvo -G clyvo

COPY --from=build /app/target/*.jar app.jar
RUN chown -R clyvo:clyvo /app

USER clyvo
EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
