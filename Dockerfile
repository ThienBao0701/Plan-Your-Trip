# syntax=docker/dockerfile:1
# INFRA-02 — production image for the Plan Your Trip Spring Boot backend.
# Multi-stage: build the executable jar with JDK 21 + the project's Maven wrapper, then run it on a
# slim JRE 21 as a non-root user. No source, build tools, or secrets remain in the runtime image.

# ---------- build stage ----------
FROM eclipse-temurin:21-jdk-jammy AS build
WORKDIR /build
# curl + ca-certificates so the Maven wrapper can bootstrap (maven-wrapper.jar is intentionally not committed).
RUN apt-get update \
 && apt-get install -y --no-install-recommends curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*
# Copy the wrapper + POM first so dependency resolution is cached independently of source changes.
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN chmod +x mvnw && ./mvnw -B dependency:go-offline
# Then the source, and build the repackaged Spring Boot jar. Tests run in CI, not during image build.
COPY src/ src/
RUN ./mvnw -B clean package -DskipTests \
 && cp target/planyourtrip-backend-*.jar /build/app.jar

# ---------- runtime stage ----------
FROM eclipse-temurin:21-jre-jammy AS runtime
# curl only, for the container HEALTHCHECK against /api/health/ready. No build tools in the runtime image.
RUN apt-get update \
 && apt-get install -y --no-install-recommends curl \
 && rm -rf /var/lib/apt/lists/* \
 && groupadd --system spring \
 && useradd --system --gid spring --home-dir /app --shell /usr/sbin/nologin spring
WORKDIR /app
COPY --from=build /build/app.jar /app/app.jar
USER spring:spring
EXPOSE 8080
# JAVA_OPTS is overridable (heap/GC). `exec` makes the JVM PID 1 so it receives SIGTERM directly for a clean stop.
ENV JAVA_OPTS=""
ENTRYPOINT ["sh","-c","exec java $JAVA_OPTS -jar /app/app.jar"]
