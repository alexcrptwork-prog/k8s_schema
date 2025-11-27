#!/bin/bash

# Script to find Kubernetes services in manifests that have Keycloak-related parameters
# This script searches for YAML files in the current directory and subdirectories
# It looks for common Keycloak-related keywords in the manifests and identifies
# the services, deployments, statefulsets, etc. that contain these parameters

# Define keywords related to Keycloak
KEYCLOAK_KEYWORDS=(
    "keycloak"
    "KEYCLOAK"
    "auth-server-url"
    "realms"
    "realm"
    "client-id"
    "client-secret"
    "kc.client"
    "keycloakConfig"
    "authentication"
    "authorization"
    "oidc"
    "oauth"
    "sso"
    "identity"
    "auth"
)

# Find all YAML files in the current directory and subdirectories
YAML_FILES=$(find . -name "*.yaml" -o -name "*.yml" 2>/dev/null)

if [ -z "$YAML_FILES" ]; then
    echo "No YAML files found in the current directory and subdirectories."
    exit 0
fi

echo "Searching for Keycloak-related parameters in the following YAML files:"
echo "$YAML_FILES"
echo ""

# Array to store services that contain Keycloak-related parameters
KEYCLOAK_SERVICES=()

# Process each YAML file
for file in $YAML_FILES; do
    echo "Checking file: $file"
    
    # Extract service names and other resource names from the file
    SERVICES_IN_FILE=$(grep -E "^\s*kind:\s*(Service|Deployment|StatefulSet|DaemonSet|Pod|Application|App)" "$file" | sed 's/.*kind:\s*//' | sed 's/^[[:space:]]*//' | head -1)
    
    # Check if any Keycloak-related keyword exists in the file
    KEYCLOAK_FOUND=false
    for keyword in "${KEYCLOAK_KEYWORDS[@]}"; do
        if grep -qi "$keyword" "$file" > /dev/null; then
            KEYCLOAK_FOUND=true
            break
        fi
    done
    
    if [ "$KEYCLOAK_FOUND" = true ]; then
        echo "  -> Contains Keycloak-related parameters"
        
        # Extract the resource name from the file
        if grep -q "kind:\s*Service" "$file"; then
            SERVICE_NAME=$(grep -A 5 "kind:\s*Service" "$file" | grep -E "^\s*name:" | head -1 | sed 's/.*name:\s*//' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]].*//')
            if [ -n "$SERVICE_NAME" ]; then
                KEYCLOAK_SERVICES+=("Service: $SERVICE_NAME (File: $file)")
            fi
        fi
        
        if grep -q "kind:\s*Deployment" "$file"; then
            DEPLOYMENT_NAME=$(grep -A 5 "kind:\s*Deployment" "$file" | grep -E "^\s*name:" | head -1 | sed 's/.*name:\s*//' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]].*//')
            if [ -n "$DEPLOYMENT_NAME" ]; then
                KEYCLOAK_SERVICES+=("Deployment: $DEPLOYMENT_NAME (File: $file)")
            fi
        fi
        
        if grep -q "kind:\s*StatefulSet" "$file"; then
            STATEFULSET_NAME=$(grep -A 5 "kind:\s*StatefulSet" "$file" | grep -E "^\s*name:" | head -1 | sed 's/.*name:\s*//' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]].*//')
            if [ -n "$STATEFULSET_NAME" ]; then
                KEYCLOAK_SERVICES+=("StatefulSet: $STATEFULSET_NAME (File: $file)")
            fi
        fi
        
        if grep -q "kind:\s*DaemonSet" "$file"; then
            DAEMONSET_NAME=$(grep -A 5 "kind:\s*DaemonSet" "$file" | grep -E "^\s*name:" | head -1 | sed 's/.*name:\s*//' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]].*//')
            if [ -n "$DAEMONSET_NAME" ]; then
                KEYCLOAK_SERVICES+=("DaemonSet: $DAEMONSET_NAME (File: $file)")
            fi
        fi
        
        if grep -q "kind:\s*Pod" "$file"; then
            POD_NAME=$(grep -A 5 "kind:\s*Pod" "$file" | grep -E "^\s*name:" | head -1 | sed 's/.*name:\s*//' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]].*//')
            if [ -n "$POD_NAME" ]; then
                KEYCLOAK_SERVICES+=("Pod: $POD_NAME (File: $file)")
            fi
        fi
        
        # Also check for any resource name under metadata
        RESOURCE_NAME=$(grep -A 10 "metadata:" "$file" | grep -E "^\s*name:" | head -1 | sed 's/.*name:\s*//' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]].*//')
        if [ -n "$RESOURCE_NAME" ]; then
            # Check if this resource name is not already added
            ALREADY_ADDED=false
            for svc in "${KEYCLOAK_SERVICES[@]}"; do
                if [[ "$svc" == *"$RESOURCE_NAME"* ]]; then
                    ALREADY_ADDED=true
                    break
                fi
            done
            if [ "$ALREADY_ADDED" = false ]; then
                KIND=$(grep -E "^\s*kind:\s*" "$file" | head -1 | sed 's/.*kind:\s*//' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]].*//')
                if [ -n "$KIND" ]; then
                    KEYCLOAK_SERVICES+=("$KIND: $RESOURCE_NAME (File: $file)")
                fi
            fi
        fi
    else
        echo "  -> No Keycloak-related parameters found"
    fi
    echo ""
done

# Output the results
if [ ${#KEYCLOAK_SERVICES[@]} -gt 0 ]; then
    echo "=================================================="
    echo "Services/Deployments with Keycloak-related parameters:"
    echo "=================================================="
    for service in "${KEYCLOAK_SERVICES[@]}"; do
        echo "- $service"
    done
else
    echo "=================================================="
    echo "No services/deployments with Keycloak-related parameters found."
    echo "=================================================="
fi