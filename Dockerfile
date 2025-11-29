# Multi-stage build for Spring Boot application

# Stage 1: Build the application
#FROM maven:3.9.5-eclipse-temurin-17 AS build
FROM maven:3.9.9-eclipse-temurin-21 AS build

WORKDIR /app

# Copy pom.xml and download dependencies (cached layer)
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code and build the application
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: Create runtime image
#FROM eclipse-temurin:17-jre-alpine
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Install wget for health check
RUN apk add --no-cache wget

# Create a non-root user for security
RUN addgroup -S spring && adduser -S spring -G spring

# Create logs directory with proper permissions
RUN mkdir -p /app/logs && chown -R spring:spring /app

# Copy the JAR file from build stage
COPY --from=build /app/target/springboot-eks.jar app.jar

# Change ownership of JAR file
RUN chown spring:spring app.jar

# Switch to non-root user
USER spring:spring

# Expose the application port
EXPOSE 9091

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:9091/springboot-eks/health || exit 1

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]


#FROM openjdk:17
#ADD target/springboot-eks.jar springboot-eks.jar
#EXPOSE 8080
#ENTRYPOINT ["java","-jar","springboot-eks.jar"]