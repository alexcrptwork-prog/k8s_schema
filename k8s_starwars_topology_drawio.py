#!/usr/bin/env python3
"""
Kubernetes Service Topology Visualizer for draw.io
Generates a draw.io XML file representing the service topology with Star Wars theme
"""

import subprocess
import json
import xml.etree.ElementTree as ET
import xml.dom.minidom
import datetime
import re
import os
from typing import Dict, List, Tuple, Optional


def run_kubectl_command(command: str) -> Optional[dict]:
    """Run kubectl command and return JSON output as dict"""
    try:
        result = subprocess.run(command, shell=True, capture_output=True, text=True, timeout=30)
        if result.returncode != 0:
            print(f"> IMPERIAL ALERT: kubectl command failed: {command}")
            print(f"> ERROR: {result.stderr}")
            return None
        return json.loads(result.stdout) if result.stdout.strip() else {}
    except subprocess.TimeoutExpired:
        print(f"> IMPERIAL ALERT: Command timed out: {command}")
        return None
    except json.JSONDecodeError as e:
        print(f"> IMPERIAL ALERT: Failed to parse JSON from command: {command}")
        print(f"> ERROR: {e}")
        return None


def extract_urls_from_config(data: str) -> List[str]:
    """Extract service URLs from configuration data"""
    # Pattern to match service URLs like http://service.namespace.svc.cluster.local:port
    pattern = r'https?://[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*\.svc\.cluster\.local(?::[0-9]+)?'
    return re.findall(pattern, data, re.IGNORECASE)


def get_all_pods() -> List[Dict]:
    """Get all pods from all namespaces"""
    data = run_kubectl_command("kubectl get pods --all-namespaces -o json")
    return data.get('items', []) if data else []


def get_all_services() -> List[Dict]:
    """Get all services from all namespaces"""
    data = run_kubectl_command("kubectl get services --all-namespaces -o json")
    return data.get('items', []) if data else []


def get_all_configmaps() -> List[Dict]:
    """Get all configmaps from all namespaces"""
    data = run_kubectl_command("kubectl get configmaps --all-namespaces -o json")
    return data.get('items', []) if data else []


def get_all_secrets() -> List[Dict]:
    """Get all secrets from all namespaces"""
    data = run_kubectl_command("kubectl get secrets --all-namespaces -o json")
    return data.get('items', []) if data else []


def get_pod_status(pod: Dict) -> Tuple[str, str]:
    """Extract pod status and reason"""
    phase = pod.get('status', {}).get('phase', 'Unknown')
    conditions = pod.get('status', {}).get('conditions', [])
    
    # Check for specific conditions
    for condition in conditions:
        if condition.get('type') == 'Ready' and condition.get('status') == 'False':
            return 'Not Ready', condition.get('reason', 'Unknown')
        elif condition.get('type') == 'PodScheduled' and condition.get('status') == 'False':
            return 'Unschedulable', condition.get('reason', 'Unknown')
        elif condition.get('type') == 'ContainersReady':
            if condition.get('status') == 'False':
                return 'Containers Not Ready', condition.get('reason', 'Unknown')
    
    # Check container statuses
    container_statuses = pod.get('status', {}).get('containerStatuses', [])
    for container in container_statuses:
        if not container.get('ready', False):
            state = container.get('state', {})
            if 'waiting' in state:
                reason = state['waiting'].get('reason', 'Unknown')
                return 'CrashLoopBackOff' if reason == 'CrashLoopBackOff' else reason, state['waiting'].get('message', '')
            elif 'terminated' in state:
                reason = state['terminated'].get('reason', 'Terminated')
                return reason, state['terminated'].get('message', '')
    
    return phase, 'OK'


def create_drawio_diagram(connections: List[Dict], services: List[Dict], unhealthy_pods: List[Dict]) -> str:
    """Create draw.io XML diagram"""
    # Create the root mxfile element
    root = ET.Element("mxfile", attrib={
        "host": "app.diagrams.net",
        "modified": datetime.datetime.utcnow().isoformat().replace('+00:00', 'Z'),
        "agent": "Mozilla/5.0",
        "etag": "generated",
        "version": "24.7.1",
        "type": "device"
    })
    
    # Add diagram element
    diagram = ET.SubElement(root, "diagram", attrib={
        "name": "K8s Topology",
        "id": "k8s_topology"
    })
    
    # Create graph element
    graph = ET.SubElement(diagram, "mxGraphModel", attrib={
        "dx": "1426",
        "dy": "769",
        "grid": "1",
        " gridSize": "10",
        " guides": "1",
        " tooltips": "1",
        " connect": "1",
        " arrows": "1",
        " fold": "1",
        " page": "1",
        " pageScale": "1",
        " pageWidth": "850",
        " pageHeight": "1100",
        " background": "#121212",
        " math": "0",
        " shadow": "0"
    })
    
    root_cell = ET.SubElement(graph, "root")
    
    # Add default cells
    default_parent = ET.SubElement(root_cell, "mxCell", attrib={"id": "0"})
    root_item = ET.SubElement(root_cell, "mxCell", attrib={"id": "1", "parent": "0"})
    
    # Create a mapping of service names to positions
    service_positions = {}
    x_pos = 100
    y_pos = 100
    
    # Add services to the diagram
    for i, service in enumerate(services):
        name = service['name']
        namespace = service['namespace']
        full_name = f"{name}\n({namespace})"
        
        # Determine if this is a Keycloak-related service
        is_keycloak = 'keycloak' in name.lower() or 'auth' in name.lower()
        
        # Calculate position
        x = x_pos + (i % 5) * 200
        y = y_pos + (i // 5) * 150
        
        service_positions[f"{name}.{namespace}"] = (x, y)
        
        # Create service cell
        service_cell = ET.SubElement(root_cell, "mxCell", attrib={
            "id": f"service_{i}",
            "value": full_name,
            "style": f"rounded=0;whiteSpace=wrap;html=1;fillColor={'#4A1500' if is_keycloak else '#2D2D2D'};strokeColor={'#FF8C00' if is_keycloak else '#FFFFFF'};fontColor=#FFFFFF;",
            "vertex": "1",
            "parent": "1"
        })
        geom = ET.SubElement(service_cell, "mxGeometry", attrib={
            "x": str(x),
            "y": str(y),
            "width": "120",
            "height": "60",
            "as": "geometry"
        })
    
    # Add unhealthy pods to the diagram
    for i, pod in enumerate(unhealthy_pods):
        name = pod['name']
        namespace = pod['namespace']
        status = pod['status']
        reason = pod['reason']
        full_name = f"{name}\n({namespace})\n[{status}: {reason}]"
        
        # Position differently from services
        x = 50
        y = 500 + i * 80
        
        service_positions[f"{name}.{namespace}"] = (x, y)
        
        # Create unhealthy pod cell
        pod_cell = ET.SubElement(root_cell, "mxCell", attrib={
            "id": f"pod_{i}",
            "value": full_name,
            "style": "ellipse;whiteSpace=wrap;html=1;fillColor=#660000;strokeColor=#FF0000;fontColor=#FFFFFF;",
            "vertex": "1",
            "parent": "1"
        })
        geom = ET.SubElement(pod_cell, "mxGeometry", attrib={
            "x": str(x),
            "y": str(y),
            "width": "140",
            "height": "80",
            "as": "geometry"
        })
    
    # Add connections to the diagram
    for i, conn in enumerate(connections):
        source = f"{conn['source_service']}.{conn['source_namespace']}"
        target = f"{conn['target_service']}.{conn['target_namespace']}"
        
        if source in service_positions and target in service_positions:
            source_x, source_y = service_positions[source]
            target_x, target_y = service_positions[target]
            
            # Create connection cell
            edge_cell = ET.SubElement(root_cell, "mxCell", attrib={
                "id": f"edge_{i}",
                "style": "edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;jettySize=auto;orthogonalLoop=1;",
                "edge": "1",
                "parent": "1",
                "source": f"service_{list(service_positions.keys()).index(source)}" if source in [f"{s['name']}.{s['namespace']}" for s in services] else f"pod_{list(service_positions.keys()).index(source) - len(services)}",
                "target": f"service_{list(service_positions.keys()).index(target)}" if target in [f"{s['name']}.{s['namespace']}" for s in services] else f"pod_{list(service_positions.keys()).index(target) - len(services)}",
            })
            
            # Add label to edge
            label = f"{conn['source_port']} → {conn['target_port']}\n({conn['protocol'].upper()})"
            edge_cell.set("value", label)
            
            geom = ET.SubElement(edge_cell, "mxGeometry", attrib={
                "relative": "1",
                "as": "geometry"
            })
    
    # Convert to string and prettify
    rough_string = ET.tostring(root, encoding='unicode')
    reparsed = xml.dom.minidom.parseString(rough_string)
    return reparsed.toprettyxml(indent="  ")


def main():
    print("┌──────────────────────────────────────────────────────┐")
    print("│          GALACTIC EMPIRE CLUSTER TOPOLOGY            │")
    print("│              INTELLIGENCE BRIEFING                    │")
    print("└──────────────────────────────────────────────────────┘")
    print("SECURITY CLEARANCE: COMMAND LEVEL OMEGA")
    print("ANALYZING KUBERNETES BATTLE NETWORK...")
    print("────────────────────────────────────────────────────────────")
    print("SCANNING FOR REBEL SERVICE DEPENDENCIES...")
    
    # Get all cluster resources
    pods = get_all_pods()
    services = get_all_services()
    configmaps = get_all_configmaps()
    secrets = get_all_secrets()
    
    if not pods and not services:
        print("> IMPERIAL ALERT: No pods or services found in the cluster")
        return
    
    # Extract services
    service_list = []
    service_map = {}  # For quick lookup
    
    for service in services:
        name = service['metadata']['name']
        namespace = service['metadata']['namespace']
        service_list.append({
            'name': name,
            'namespace': namespace
        })
        service_map[f"{name}.{namespace}"] = {
            'cluster_ip': service['spec'].get('clusterIP', 'None'),
            'ports': [port.get('port', 'N/A') for port in service['spec'].get('ports', [])]
        }
    
    print(f"> DETECTED {len(service_list)} SERVICES IN THE BATTLE NETWORK")
    
    # Find connections by analyzing pod configurations
    connections = []
    unhealthy_pods = []
    
    for pod in pods:
        pod_name = pod['metadata']['name']
        pod_namespace = pod['metadata']['namespace']
        pod_status, pod_reason = get_pod_status(pod)
        
        # Check if pod is unhealthy
        if pod_status not in ['Running', 'OK']:
            unhealthy_pods.append({
                'name': pod_name,
                'namespace': pod_namespace,
                'status': pod_status,
                'reason': pod_reason
            })
        
        # Extract URLs from pod spec
        pod_spec = pod.get('spec', {})
        containers = pod_spec.get('containers', [])
        
        for container in containers:
            # Check environment variables
            env_vars = container.get('env', [])
            for env in env_vars:
                if 'value' in env:
                    urls = extract_urls_from_config(env['value'])
                    for url in urls:
                        match = re.match(r'https?://([a-zA-Z0-9-]+)\.([a-zA-Z0-9-]+)\.svc\.cluster\.local(?::([0-9]+))?', url, re.IGNORECASE)
                        if match:
                            target_service = match.group(1)
                            target_namespace = match.group(2)
                            target_port = match.group(3) or '80'
                            
                            # Find source port from container ports
                            source_port = 'N/A'
                            container_ports = container.get('ports', [])
                            if container_ports:
                                source_port = str(container_ports[0].get('containerPort', 'N/A'))
                            
                            protocol = 'HTTPS' if 'https' in url.lower() else 'HTTP'
                            
                            connection = {
                                'source_service': pod_name,
                                'source_namespace': pod_namespace,
                                'target_service': target_service,
                                'target_namespace': target_namespace,
                                'source_port': source_port,
                                'target_port': target_port,
                                'protocol': protocol
                            }
                            if connection not in connections:
                                connections.append(connection)
            
            # Check command and args
            for field_name in ['command', 'args']:
                if field_name in container:
                    for item in container[field_name]:
                        urls = extract_urls_from_config(item)
                        for url in urls:
                            match = re.match(r'https?://([a-zA-Z0-9-]+)\.([a-zA-Z0-9-]+)\.svc\.cluster\.local(?::([0-9]+))?', url, re.IGNORECASE)
                            if match:
                                target_service = match.group(1)
                                target_namespace = match.group(2)
                                target_port = match.group(3) or '80'
                                
                                source_port = 'N/A'
                                container_ports = container.get('ports', [])
                                if container_ports:
                                    source_port = str(container_ports[0].get('containerPort', 'N/A'))
                                
                                protocol = 'HTTPS' if 'https' in url.lower() else 'HTTP'
                                
                                connection = {
                                    'source_service': pod_name,
                                    'source_namespace': pod_namespace,
                                    'target_service': target_service,
                                    'target_namespace': target_namespace,
                                    'source_port': source_port,
                                    'target_port': target_port,
                                    'protocol': protocol
                                }
                                if connection not in connections:
                                    connections.append(connection)
    
    # Also check configmaps and secrets for URLs
    for config_item in configmaps + secrets:
        # Get configmap/secret data
        data = config_item.get('data', {})
        for key, value in data.items():
            urls = extract_urls_from_config(value)
            for url in urls:
                match = re.match(r'https?://([a-zA-Z0-9-]+)\.([a-zA-Z0-9-]+)\.svc\.cluster\.local(?::([0-9]+))?', url, re.IGNORECASE)
                if match:
                    target_service = match.group(1)
                    target_namespace = match.group(2)
                    target_port = match.group(3) or '80'
                    
                    # For configmaps/secrets, we'll use a generic source
                    connection = {
                        'source_service': f"{config_item['metadata']['name']}.{config_item['metadata']['namespace']}",
                        'source_namespace': '',
                        'target_service': target_service,
                        'target_namespace': target_namespace,
                        'source_port': 'N/A',
                        'target_port': target_port,
                        'protocol': 'HTTPS' if 'https' in url.lower() else 'HTTP'
                    }
                    if connection not in connections:
                        connections.append(connection)
    
    print(f"> MAPPED {len(connections)} SERVICE CONNECTIONS")
    print(f"> IDENTIFIED {len(unhealthy_pods)} UNHEALTHY PODS")
    
    # Identify Keycloak-related services
    keycloak_services = [s for s in service_list if 'keycloak' in s['name'].lower() or 'auth' in s['name'].lower()]
    if keycloak_services:
        print(f"⚠️  REBEL ACTIVITY DETECTED: {len(keycloak_services)} AUTHENTICATION HUB(S) IDENTIFIED")
    
    # Create draw.io diagram
    print("GENERATING STRATEGIC TOPOLOGY MAP (DRAW.IO FORMAT)...")
    
    # Prepare service data for draw.io
    formatted_services = []
    for service in service_list:
        formatted_services.append({
            'name': service['name'],
            'namespace': service['namespace']
        })
    
    # Generate the draw.io XML
    diagram_xml = create_drawio_diagram(connections, formatted_services, unhealthy_pods)
    
    # Save the draw.io file
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"k8s_starwars_topology_{timestamp}.drawio"
    
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(diagram_xml)
    
    print(f"✅ STRATEGIC MAP COMPLETE: {filename}")
    
    # Create log file
    log_filename = f"GALACTIC_LOG_{timestamp}.txt"
    with open(log_filename, 'w', encoding='utf-8') as f:
        f.write("GALACTIC EMPIRE CLUSTER TOPOLOGY LOG\n")
        f.write(f"Generated: {datetime.datetime.now()}\n")
        f.write(f"Services found: {len(service_list)}\n")
        f.write(f"Connections mapped: {len(connections)}\n")
        f.write(f"Unhealthy pods: {len(unhealthy_pods)}\n")
        f.write(f"Keycloak services: {len(keycloak_services)}\n")
        f.write("\nServices:\n")
        for service in service_list:
            f.write(f"  - {service['name']} ({service['namespace']})\n")
        f.write("\nConnections:\n")
        for conn in connections:
            f.write(f"  - {conn['source_service']}.{conn['source_namespace']} -> {conn['target_service']}.{conn['target_namespace']} ({conn['protocol']})\n")
        f.write("\nUnhealthy Pods:\n")
        for pod in unhealthy_pods:
            f.write(f"  - {pod['name']} ({pod['namespace']}): {pod['status']} - {pod['reason']}\n")
    
    print(f"📋 LOG FILE SAVED: {log_filename}")
    print("────────────────────────────────────────────────────────────")
    print("TOPOLOGY BRIEFING CONCLUDED")
    print("AWAITING FURTHER ORDERS FROM COMMAND...")
    
    # Wait for user input before exiting
    try:
        input("> Press Enter to exit...")
    except KeyboardInterrupt:
        print("\n> EXITING BRIEFING MODE...")


if __name__ == "__main__":
    main()