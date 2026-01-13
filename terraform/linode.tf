# Object Storage Bucket (per environment)
resource "linode_object_storage_bucket" "backups" {
  label  = "${local.env_prefix}${var.backup_bucket_name}"
  region = var.backup_bucket_region
}

# Object Storage Access Key
resource "linode_object_storage_key" "backups" {
  label = "${local.env_prefix}${var.backup_bucket_name}-key"

  bucket_access {
    bucket_name = linode_object_storage_bucket.backups.label
    region      = linode_object_storage_bucket.backups.region
    permissions = "read_write"
  }
}
