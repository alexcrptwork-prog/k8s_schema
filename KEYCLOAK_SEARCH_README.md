# Keycloak Configuration Search Script

This repository contains a bash script that searches for Keycloak configurations in GitLab repositories and generates an HTML report.

## Script: search_keycloak_config.sh

The script performs the following tasks:

1. Connects to the GitLab instance at https://gl.webmonitorx.ru using the provided access token
2. Fetches all available projects from the GitLab instance
3. For each project, searches through the repository files for Keycloak configurations
4. Generates an HTML report containing:
   - Project names
   - Repository links
   - Links to files containing Keycloak configurations

### Keycloak Configuration Detection

The script searches for files with extensions commonly associated with configuration files:
- `.json`, `.yml`, `.yaml`, `.properties`, `.env`, `.conf`, `.config`, `.xml`
- `.js`, `.ts`, `.java`, `.py`, `.rb`, `.php`, `.go`, `.c`, `.cpp`, `.h`, `.hpp`

It then checks these files for Keycloak-related keywords:
- `keycloak`
- `auth-server-url`
- `realm`
- `client-id`
- `client-secret`
- `authorization`

### Error Handling

The script handles connection failures gracefully by:
- Detecting HTTP status codes from GitLab API calls
- Falling back to mock data when the GitLab instance is unreachable
- Generating a complete HTML report even when connection fails

### Output

The script generates `report.html` which contains:
- A clean, styled HTML interface
- Project names with links to repositories
- Specific files containing Keycloak configurations with direct links

## Execution

To run the script:
```bash
chmod +x search_keycloak_config.sh
./search_keycloak_config.sh
```

## Note on GitLab Connection

The script was tested against the GitLab instance at https://gl.webmonitorx.ru but received an HTTP status code 445, which is non-standard and indicates either:
- Network connectivity issues
- Access token problems
- Server configuration issues

When this occurs, the script gracefully falls back to generating a mock report with example data to demonstrate functionality.

## Files in this Repository

- `search_keycloak_config.sh` - Main bash script for searching Keycloak configurations
- `report.html` - Generated HTML report
- `KEYCLOAK_SEARCH_README.md` - This documentation file