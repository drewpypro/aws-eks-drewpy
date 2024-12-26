import json
import csv
from collections import defaultdict

def parse_dns_logs(input_file, output_file):
    # Dictionary to store unique combinations and their counts
    unique_queries = defaultdict(int)
    
    with open(input_file, 'r') as f:
        for line in f:
            try:
                # Split timestamp and JSON parts
                _, json_str = line.strip().split(' ', 1)
                data = json.loads(json_str)
                
                # Create a tuple of the fields we want to track
                query_key = (
                    data['query_name'],
                    data['query_type'],
                    data['rcode'],
                    data['srcaddr']
                )
                
                # Increment counter for this combination
                unique_queries[query_key] += 1
                
            except Exception as e:
                print(f"Error processing line: {e}")
                continue
    
    # Write results to CSV
    with open(output_file, 'w', newline='') as f:
        writer = csv.writer(f)
        # Write header
        writer.writerow(['Query Name', 'Query Type', 'Response Code', 'Source IP', 'Count'])
        
        # Write data sorted by count (descending) and then by query name
        sorted_queries = sorted(unique_queries.items(), 
                              key=lambda x: (-x[1], x[0][0]))
        
        for (query_name, query_type, rcode, srcaddr), count in sorted_queries:
            writer.writerow([query_name, query_type, rcode, srcaddr, count])

if __name__ == "__main__":
    parse_dns_logs('12-26-24-dnsqueries.csv', 'dns_query_report.csv')
    print("Report generated successfully!")