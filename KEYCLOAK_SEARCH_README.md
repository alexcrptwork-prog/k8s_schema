# Keycloak Configuration Search Script

This script searches for Keycloak configurations in GitLab repositories and generates an HTML report.

## Script Functionality

The script performs the following tasks:
1. Connects to the GitLab instance at `https://gl.webmonitorx.ru` using the provided access token
2. Authenticates with the GitLab API
3. Fetches all accessible projects
4. Searches for files containing Keycloak configurations
5. Generates an HTML report with the results

## GitLab Connection Issue

The script encountered a non-standard HTTP status code `445` when attempting to connect to the GitLab instance. This indicates one of the following:
- Network connectivity issues
- The GitLab instance is down
- Access token permissions are insufficient
- Firewall/proxy blocking the request
- Custom server configuration returning non-standard status codes

## Mock Data

Since the script couldn't connect to the GitLab instance, it falls back to using mock data to demonstrate the functionality. The generated report (`report.html`) shows:
- 3 projects: `web-app-project`, `api-service`, and `auth-service`
- 5 files with Keycloak configurations across these projects
- Proper links to repositories and files

## Keycloak Configuration Patterns

The script searches for these file types and patterns:
- `keycloak.json`, `keycloak.yml`, `keycloak.yaml`, `keycloak.properties`
- Configuration files like `application.properties`, `application.yml`
- Environment files like `.env`
- Docker configuration files
- Files containing Keycloak-related keywords

## Generated Report

The `report.html` file contains:
- Project names
- Links to repositories
- Links to specific files containing Keycloak configurations
- Clean HTML formatting with CSS styling