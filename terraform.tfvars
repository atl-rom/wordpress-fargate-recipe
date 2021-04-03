#terraform.tfvars

app_name        = "aeronautics" # Do NOT enter any spaces
app_environment = "test"        # Dev, Test, Prod, etc
# Application access
app_sources_cidr   = ["0.0.0.0/0"] # Specify a list of IPv4 IPs/CIDRs which can access app load balancers
admin_sources_cidr = ["0.0.0.0/0"] # Specify a list of IPv4 IPs/CIDRs which can admin instances
