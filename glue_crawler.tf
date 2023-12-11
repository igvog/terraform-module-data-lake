resource "aws_glue_crawler" "glue_crawler" {
  count = var.glue_crawler_enable ? 1 : 0

  name          = local.full_name
  database_name = var.glue_crawler.database_name
  role          = var.glue_crawler.role

  description            = var.glue_crawler.description
  classifiers            = var.glue_crawler.classifiers
  configuration          = var.glue_crawler.configuration
  schedule               = var.glue_crawler.schedule
  security_configuration = var.glue_crawler.security_configuration
  table_prefix           = var.glue_crawler.table_prefix

  dynamic "dynamodb_target" {
    iterator = dynamodb_target 
    for_each = var.glue_crawler.dynamodb_target != null ? var.glue_crawler.dynamodb_target : []

    content {
      path = lookup(dynamodb_target.value, "path", null)
    }
  }
  
  dynamic "delta_target" {
    iterator = delta_target
    for_each = var.glue_crawler.delta_target
  
    content {
      connection_name = ""
      delta_tables    = var.glue_crawlerdelta_target.delta_tables
      write_manifest  = false
    }
  }

  dynamic "jdbc_target" {
    iterator = jdbc_target
    for_each = var.glue_crawler.jdbc_target != null ? var.glue_crawler.jdbc_target : []

    content {
      connection_name = lookup(jdbc_target.value, "connection_name", null)
      path            = lookup(jdbc_target.value, "path", null)
      exclusions      = lookup(jdbc_target.value, "exclusions", null)
    }
  }

  dynamic "s3_target" {
    iterator = s3_target
    for_each = var.glue_crawler.s3_target != null ? var.glue_crawler.s3_target : []

    content {
      path       = lookup(s3_target.value, "path", null)
      exclusions = lookup(s3_target.value, "exclusions", null)
    }
  }

  dynamic "catalog_target" {
    iterator = catalog_target
    // for_each = length(var.glue_crawler.catalog_target) > 0 ? [var.glue_crawler.catalog_target] : []
    for_each = var.glue_crawler.catalog_target != null ? [var.glue_crawler.catalog_target] : []

    content {
      database_name = lookup(catalog_target.value, "database_name", null)
      tables        = lookup(catalog_target.value, "tables", null)
    }
  }

  dynamic "schema_change_policy" {
    iterator = schema_change_policy
    for_each = var.glue_crawler.schema_change_policy != null ? var.glue_crawler.schema_change_policy : []

    content {
      delete_behavior = lookup(schema_change_policy.value, "delete_behavior", "DEPRECATE_IN_DATABASE")
      update_behavior = lookup(schema_change_policy.value, "update_behavior", "UPDATE_IN_DATABASE")
    }
  }

  dynamic "mongodb_target" {
    iterator = mongodb_target
    for_each = var.glue_crawler.mongodb_target != null ? var.glue_crawler.mongodb_target : []

    content {
      connection_name = lookup(mongodb_target.value, "connection_name", null)

      path     = lookup(mongodb_target.value, "path", null)
      scan_all = lookup(mongodb_target.value, "scan_all", null)
    }
  }

  dynamic "lineage_configuration" {
    iterator = lineage_configuration
    for_each = var.glue_crawler.lineage_configuration != null ? var.glue_crawler.lineage_configuration : []

    content {
      crawler_lineage_settings = lookup(lineage_configuration.value, "crawler_lineage_settings", null)
    }
  }

  dynamic "recrawl_policy" {
    iterator = recrawl_policy
    for_each = var.glue_crawler.recrawl_policy != null ? var.glue_crawler.recrawl_policy : []

    content {
      recrawl_behavior = lookup(recrawl_policy.value, "recrawl_behavior", null)
    }
  }

  tags = merge(
    {
      App = "glue"
    },
    local.base_tags,
    var.tags
  )

  lifecycle {
    create_before_destroy = true
    ignore_changes        = []
  }
  depends_on = [
    aws_glue_job.glue_job,
    aws_s3_object.glue_script_upload
  ]
}
