provider "aws" {
  region = "us-east-1"
}

resource "aws_athena_database" "reddit_db" {
  name   = "reddit_data_db"
  bucket = var.s3_bucket_name
}

resource "aws_glue_catalog_table" "lambda_sagemaker_table" {
  name          = "lambda_sagemaker_table"
  database_name = aws_athena_database.reddit_db.name

  table_type = "EXTERNAL_TABLE"

  storage_descriptor {
    location      = "s3://${var.s3_bucket_name}/source=lambda-sagemaker/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.IgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }

    columns {
      name = "id"
      type = "string"
    }
    columns {
      name = "title"
      type = "string"
    }
    columns {
      name = "sentiment"
      type = "string"
    }
    columns {
      name = "confidence"
      type = "double"
    }
    columns {
      name = "source"
      type = "string"
    }

  }

  parameters = {
    classification = "json"
    typeOfData     = "file"
  }
}

resource "aws_glue_catalog_table" "eventbridge_pipe_table" {
  name          = "eventbridge_pipe_table"
  database_name = aws_athena_database.reddit_db.name

  table_type = "EXTERNAL_TABLE"

  storage_descriptor {
    location      = "s3://${var.s3_bucket_name}/source=eventbridge-pipe/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.IgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }

    columns {
      name = "source"
      type = "string"
    }
    columns {
      name = "id"
      type = "string"
    }
    columns {
      name = "title"
      type = "string"
    }
    columns {
      name = "author"
      type = "string"
    }
    columns {
      name = "created_utc"
      type = "string"
    }
    columns {
      name = "url"
      type = "string"
    }
    columns {
      name = "score"
      type = "string"
    }
    columns {
      name = "num_comments"
      type = "string"
    }
    columns {
      name = "subreddit"
      type = "string"
    }
  }

  parameters = {
    classification = "json"
    typeOfData     = "file"
  }
}