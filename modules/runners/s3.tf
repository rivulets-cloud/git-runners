module "cache" {
  source = "../../modules/s3"

  environment = var.environment
  tags        = local.tags

  create_cache_bucket                  = var.cache_bucket["create"]
  cache_bucket_prefix                  = var.cache_bucket_prefix
  cache_bucket_name_include_account_id = var.cache_bucket_name_include_account_id
  cache_bucket_set_random_suffix       = var.cache_bucket_set_random_suffix
  cache_bucket_versioning              = var.cache_bucket_versioning
  cache_expiration_days                = var.cache_expiration_days
}