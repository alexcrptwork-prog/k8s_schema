#!/bin/bash

# Script to search GitLab repositories for Keycloak configurations
# API token and GitLab URL
TOKEN="glpat-iHuevLsAqjBtOKv3Kh7WNW86MQp1OmF4CA.01.0y1ah4wbu"
GITLAB_URL="https://gl.webmonitorx.ru"
OUTPUT_FILE="keycloak_repos.json"

# Function to check API access
check_api_access() {
    echo "Checking API access..."
    response=$(curl -s -o /dev/null -w "%{http_code}" --header "PRIVATE-TOKEN: $TOKEN" "$GITLAB_URL/api/v4/projects?per_page=1")
    
    if [ "$response" = "200" ]; then
        echo "API access OK"
        return 0
    elif [ "$response" = "401" ] || [ "$response" = "403" ]; then
        echo "Authentication failed - check your token"
        return 1
    elif [ "$response" = "404" ]; then
        echo "GitLab API endpoint not found - check the URL"
        return 1
    else
        echo "HTTP response code: $response - there might be an access issue"
        return 1
    fi
}

# Check if we can access the API
if ! check_api_access; then
    echo "Cannot access GitLab API. Please verify your token and URL."
    echo "[]" > "$OUTPUT_FILE"
    exit 1
fi

# Initialize JSON output
echo "[" > "$OUTPUT_FILE"
FIRST_ENTRY=true

# Get all projects from GitLab
echo "Fetching projects from GitLab..."
projects=$(curl -s --header "PRIVATE-TOKEN: $TOKEN" "$GITLAB_URL/api/v4/projects?per_page=1000" | jq -r '.[] | {id, name, web_url} | @base64')

# Count total projects
total_projects=$(echo "$projects" | wc -w)
echo "Found $total_projects projects to search..."

# Process each project
count=0
for project_b64 in $projects; do
    ((count++))
    
    # Decode base64 to get project details
    project_json=$(echo "$project_b64" | base64 --decode)
    project_id=$(echo "$project_json" | jq -r '.id')
    project_name=$(echo "$project_json" | jq -r '.name')
    project_url=$(echo "$project_json" | jq -r '.web_url')
    
    echo "Searching ($count/$total_projects) in project: $project_name (ID: $project_id)"
    
    # Find files that might contain Keycloak configurations
    keycloak_files=()
    
    # Get repository tree to find potential config files
    tree=$(curl -s --header "PRIVATE-TOKEN: $TOKEN" "$GITLAB_URL/api/v4/projects/$project_id/repository/tree?recursive=true")
    
    # Look for common files that might contain Keycloak configurations
    potential_files=$(echo "$tree" | jq -r '.[] | select(.type == "blob") | .path' | grep -E '\.(yml|yaml|json|js|ts|java|properties|xml|env|conf|config)$')
    
    # Also include other common files that might contain Keycloak configs
    potential_files=$(echo -e "$potential_files\n$(echo "$tree" | jq -r '.[] | select(.type == "blob") | .path' | grep -E '(config|application|settings|auth|security|keycloak|oauth|sso)' | head -20)" | grep -v '^$' | sort -u)
    
    for file_path in $potential_files; do
        # Get file content to check for Keycloak references
        encoded_path=$(echo "$file_path" | sed 's|/|%2F|g')
        file_content=$(curl -s --header "PRIVATE-TOKEN: $TOKEN" "$GITLAB_URL/api/v4/projects/$project_id/repository/files/$encoded_path/raw?ref=HEAD" 2>/dev/null)
        
        if [[ $? -eq 0 ]]; then
            # Check if file contains Keycloak-related keywords (case insensitive)
            if echo "$file_content" | grep -i -E -q "keycloak|auth-server-url|realm|client.*id|oidc|sso|oauth|openid|kc\.realm|keycloak\.|spring\.security|spring\.oauth2|authentication|authorization"; then
                echo "  Found Keycloak config in: $file_path"
                keycloak_files+=("$file_path")
            fi
        else
            # If we can't access the file content, try to access it differently
            # This might happen if the file path contains special characters
            continue
        fi
    done
    
    # If Keycloak-related files were found, add project to output
    if [ ${#keycloak_files[@]} -gt 0 ]; then
        # Add comma if not the first entry
        if [ "$FIRST_ENTRY" = false ]; then
            echo "," >> "$OUTPUT_FILE"
        fi
        
        # Create JSON entry for this project
        {
            echo -n "  {" >> "$OUTPUT_FILE"
            echo -n "\"project_name\":\"$project_name\"," >> "$OUTPUT_FILE"
            echo -n "\"repository_url\":\"$project_url\"," >> "$OUTPUT_FILE"
            echo -n "\"keycloak_files\":[" >> "$OUTPUT_FILE"
            
            # Add file entries
            for i in "${!keycloak_files[@]}"; do
                file_path="${keycloak_files[$i]}"
                # Construct the proper URL for the file in GitLab
                file_url="$GITLAB_URL/$project_name/-/blob/main/$file_path"
                
                if [ $i -lt $((${#keycloak_files[@]} - 1)) ]; then
                    echo -n "\"$file_path\"," >> "$OUTPUT_FILE"
                else
                    echo -n "\"$file_path\"" >> "$OUTPUT_FILE"
                fi
            done
            
            echo -n "]," >> "$OUTPUT_FILE"
            echo -n "\"file_urls\":[" >> "$OUTPUT_FILE"
            
            # Add file URLs
            for i in "${!keycloak_files[@]}"; do
                file_path="${keycloak_files[$i]}"
                # Construct the proper URL for the file in GitLab
                file_url="$GITLAB_URL/$project_name/-/blob/main/$file_path"
                
                if [ $i -lt $((${#keycloak_files[@]} - 1)) ]; then
                    echo -n "\"$file_url\"," >> "$OUTPUT_FILE"
                else
                    echo -n "\"$file_url\"" >> "$OUTPUT_FILE"
                fi
            done
            
            echo -n "]" >> "$OUTPUT_FILE"
            echo -n "}" >> "$OUTPUT_FILE"
        }
        
        FIRST_ENTRY=false
    fi
done

echo "]" >> "$OUTPUT_FILE"
echo "Search completed. Results saved to $OUTPUT_FILE"