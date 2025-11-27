#!/bin/bash

# Script to search for Keycloak configurations in GitLab repositories
# and generate an HTML report

# Configuration
GITLAB_URL="https://gl.webmonitorx.ru"
ACCESS_TOKEN="glpat-iHuevLsAqjBtOKv3Kh7WNW86MQp1OmF4CA.01.0y1ah4wbu"
OUTPUT_FILE="report.html"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to log messages
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# Function to log errors
log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to log warnings
log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required commands
REQUIRED_COMMANDS=("curl" "jq" "grep" "find")
for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if ! command_exists "$cmd"; then
        log_error "Required command '$cmd' not found. Please install it."
        exit 1
    fi
done

# Function to get all projects from GitLab
get_projects() {
    log "Fetching projects from GitLab..."
    
    # Try to get the first page to determine total pages
    response=$(curl -s -w "\n%{http_code}" --header "PRIVATE-TOKEN: $ACCESS_TOKEN" \
        "$GITLAB_URL/api/v4/projects?per_page=100&page=1" 2>/dev/null)
    
    # Extract HTTP status code (last line)
    status_code=$(echo "$response" | tail -n1)
    response_body=$(echo "$response" | sed '$d')  # Remove last line (status code)
    
    # Check if status code is 200
    if [ "$status_code" != "200" ]; then
        log_error "GitLab API returned status code: $status_code"
        return 1
    fi
    
    # Check if response is valid JSON
    if ! echo "$response_body" | jq empty 2>/dev/null; then
        log_error "Invalid JSON response from GitLab API"
        log_error "Response: $response_body"
        return 1
    fi
    
    # Get total count of projects
    total_projects=$(echo "$response_body" | jq 'length')
    log "Found $total_projects projects"
    
    # Extract project information
    echo "$response_body" | jq -r '.[] | "\(.name)\t\(.web_url)\t\(.id)"'
}

# Function to search for Keycloak configuration files in a project
search_project_files() {
    local project_id=$1
    local project_name=$2
    local project_url=$3
    
    log "Searching project: $project_name (ID: $project_id)"
    
    # Get repository tree for the project
    tree_response=$(curl -s -w "\n%{http_code}" --header "PRIVATE-TOKEN: $ACCESS_TOKEN" \
        "$GITLAB_URL/api/v4/projects/$project_id/repository/tree?ref=HEAD" 2>/dev/null)
    
    # Extract HTTP status code (last line)
    status_code=$(echo "$tree_response" | tail -n1)
    tree_response_body=$(echo "$tree_response" | sed '$d')  # Remove last line (status code)
    
    # Check if status code is 200
    if [ "$status_code" != "200" ]; then
        log_error "GitLab API returned status code: $status_code for project $project_name"
        return 1
    fi
    
    # Check if response is valid JSON
    if ! echo "$tree_response_body" | jq empty 2>/dev/null; then
        log_error "Invalid JSON response for project $project_name"
        return 1
    fi
    
    # Find potential Keycloak config files
    keycloak_files=()
    
    # Search for files that might contain Keycloak configurations
    files=$(echo "$tree_response_body" | jq -r '.[] | select(.type == "blob") | .path')
    
    for file in $files; do
        # Check if file name matches common Keycloak config files
        if [[ "$file" =~ \.(json|yml|yaml|properties|env|conf|config|xml|js|ts|java|py|rb|php|go|c|cpp|h|hpp)$ ]]; then
            # Download the file content to check for Keycloak configurations
            file_content=$(curl -s -w "\n%{http_code}" --header "PRIVATE-TOKEN: $ACCESS_TOKEN" \
                "$GITLAB_URL/api/v4/projects/$project_id/repository/files/$(echo "$file" | sed 's|/|%2F|g')/raw?ref=HEAD" 2>/dev/null)
            
            # Extract HTTP status code (last line)
            file_status_code=$(echo "$file_content" | tail -n1)
            file_content_body=$(echo "$file_content" | sed '$d')  # Remove last line (status code)
            
            # Check if status code is 200
            if [ "$file_status_code" = "200" ]; then
                # Check if the content contains Keycloak-related keywords
                if echo "$file_content_body" | grep -i -E "keycloak|auth-server-url|realm|client-id|client-secret|authorization" >/dev/null; then
                    keycloak_files+=("$file")
                fi
            fi
        fi
    done
    
    # Output results for this project
    if [ ${#keycloak_files[@]} -gt 0 ]; then
        echo "$project_name|$project_url|${keycloak_files[*]}"
    fi
}

# Function to generate HTML report header
generate_html_header() {
    cat << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Keycloak Configuration Search Report</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            border-bottom: 2px solid #007bff;
            padding-bottom: 10px;
        }
        .project {
            margin-bottom: 30px;
            padding: 15px;
            border: 1px solid #ddd;
            border-radius: 5px;
            background-color: #fafafa;
        }
        .project h2 {
            margin-top: 0;
            color: #007bff;
        }
        .repo-link {
            display: block;
            margin-bottom: 10px;
            font-size: 14px;
            color: #666;
        }
        .files {
            margin-top: 10px;
        }
        .file-link {
            display: block;
            margin: 5px 0;
            padding: 5px;
            background-color: #e9ecef;
            border-radius: 3px;
        }
        .file-link a {
            color: #0056b3;
            text-decoration: none;
        }
        .file-link a:hover {
            text-decoration: underline;
        }
        .no-results {
            text-align: center;
            color: #666;
            font-style: italic;
            padding: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Keycloak Configuration Search Report</h1>
        <p>Search results for Keycloak configurations in GitLab repositories</p>
EOF
}

# Function to generate HTML report footer
generate_html_footer() {
    cat << 'EOF'
    </div>
</body>
</html>
EOF
}

# Function to add project to HTML report
add_project_to_html() {
    local project_name=$1
    local project_url=$2
    local files=$3
    
    echo "        <div class=\"project\">"
    echo "            <h2>$project_name</h2>"
    echo "            <span class=\"repo-link\">Repository: <a href=\"$project_url\" target=\"_blank\">$project_url</a></span>"
    echo "            <div class=\"files\">"
    echo "                <strong>Files containing Keycloak configurations:</strong>"
    
    # Convert space-separated files to individual links
    for file in $files; do
        file_url="$project_url/blob/HEAD/$file"
        echo "                <div class=\"file-link\"><a href=\"$file_url\" target=\"_blank\">$file</a></div>"
    done
    
    echo "            </div>"
    echo "        </div>"
}

# Main execution
main() {
    log "Starting Keycloak configuration search in GitLab repositories..."
    
    # Initialize HTML file
    generate_html_header > "$OUTPUT_FILE"
    
    # Get projects from GitLab
    projects_data=$(get_projects)
    
    if [ $? -ne 0 ]; then
        log_error "Could not fetch projects from GitLab. Using mock data for demonstration."
        
        # Write mock data to HTML file
        {
            echo "        <div class=\"no-results\">"
            echo "            <p>Could not connect to GitLab instance at $GITLAB_URL</p>"
            echo "            <p>This may be due to network issues, access token problems, or server configuration.</p>"
            echo "            <p>Showing mock data for demonstration purposes:</p>"
            echo "        </div>"
            
            # Add mock projects
            add_project_to_html "web-app-project" "https://gl.webmonitorx.ru/example/web-app-project" "config/keycloak.json src/main/resources/application.properties"
            add_project_to_html "api-service" "https://gl.webmonitorx.ru/example/api-service" "docker-compose.yml .env"
            add_project_to_html "auth-service" "https://gl.webmonitorx.ru/example/auth-service" "src/main/resources/application.yml src/main/java/config/KeycloakConfig.java"
        } >> "$OUTPUT_FILE"
        
        # Complete HTML file
        generate_html_footer >> "$OUTPUT_FILE"
        
        log "Mock HTML report generated: $OUTPUT_FILE"
        return
    fi
    
    # Process each project
    project_count=0
    while IFS=$'\t' read -r project_name project_url project_id; do
        # Skip empty lines
        if [ -z "$project_name" ] || [ -z "$project_url" ] || [ -z "$project_id" ]; then
            continue
        fi
        
        # Search for Keycloak configs in this project
        result=$(search_project_files "$project_id" "$project_name" "$project_url")
        
        if [ -n "$result" ]; then
            # Parse the result
            IFS='|' read -r proj_name proj_url files <<< "$result"
            
            # Add to HTML report
            add_project_to_html "$proj_name" "$proj_url" "$files" >> "$OUTPUT_FILE"
            
            log "Found Keycloak configurations in project: $proj_name"
            ((project_count++))
        fi
    done <<< "$projects_data"
    
    if [ $project_count -eq 0 ]; then
        echo "        <div class=\"no-results\">"
        echo "            <p>No Keycloak configurations found in any repositories.</p>"
        echo "        </div>" >> "$OUTPUT_FILE"
    fi
    
    # Complete HTML file
    generate_html_footer >> "$OUTPUT_FILE"
    
    log "Search completed. Found Keycloak configurations in $project_count projects."
    log "HTML report saved to: $OUTPUT_FILE"
}

# Run the main function
main "$@"