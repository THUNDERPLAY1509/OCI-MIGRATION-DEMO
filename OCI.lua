# TERRAFORM FOR OCI MIGRATION TARGET
# ----------------------------------
# This builds the VCN and Subnets needed for the "After" state.

variable "compartment_ocid" {
  description = "The OCID of the compartment where resources will be created"
  type        = string
}

variable "region" {
  description = "The OCI region (e.g., us-ashburn-1)"
  type        = string
  default     = "us-ashburn-1"
}

provider "oci" {
  region = var.region
}

# --- 1. VCN ---
resource "oci_core_vcn" "migration_vcn" {
  cidr_block     = "10.0.0.0/16"
  compartment_id = var.compartment_ocid
  display_name   = "Migration-Demo-VCN"
  dns_label      = "migdemo"
}

# --- 2. Gateways ---
resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.migration_vcn.id
  display_name   = "Internet-Gateway"
}

resource "oci_core_nat_gateway" "ngw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.migration_vcn.id
  display_name   = "NAT-Gateway"
}

# --- 3. Route Tables ---
resource "oci_core_route_table" "public_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.migration_vcn.id
  display_name   = "Public-Route-Table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw.id
  }
}

resource "oci_core_route_table" "private_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.migration_vcn.id
  display_name   = "Private-Route-Table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.ngw.id
  }
}

# --- 4. Subnets ---
resource "oci_core_subnet" "public_subnet" {
  cidr_block        = "10.0.1.0/24"
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.migration_vcn.id
  display_name      = "Web-Server-Public-Subnet"
  route_table_id    = oci_core_route_table.public_rt.id
  security_list_ids = [oci_core_security_list.public_sl.id]
}

resource "oci_core_subnet" "private_subnet" {
  cidr_block                 = "10.0.2.0/24"
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.migration_vcn.id
  display_name               = "Database-Private-Subnet"
  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_route_table.private_rt.id
  security_list_ids          = [oci_core_security_list.private_sl.id]
}

# --- 5. Security Lists ---
resource "oci_core_security_list" "public_sl" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.migration_vcn.id
  display_name   = "Public-Security-List"

  # Allow inbound HTTP (80) and SSH (22)
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 80
      max = 80
    }
  }
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}

resource "oci_core_security_list" "private_sl" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.migration_vcn.id
  display_name   = "Private-DB-Security-List"

  # Allow inbound MySQL (3306) ONLY from the Public Subnet CIDR
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "10.0.1.0/24"
    tcp_options {
      min = 3306
      max = 3306
    }
  }
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}