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

resource "aws_athena_named_query" "reddit_joined_view" {
  name      = "reddit_sentiment_joined_view"
  database  = aws_athena_database.reddit_db.name
  query     = <<EOF
CREATE OR REPLACE VIEW reddit_joined_view AS
SELECT 
  e.id,
  e.title,
  e.author,
  from_unixtime(CAST(e.created_utc AS double)) AS created_time,
  e.url,
  e.score,
  e.num_comments,
  e.subreddit,
  s.sentiment,
  s.confidence
FROM (
  SELECT
    *, 
    ROW_NUMBER() OVER (PARTITION BY id ORDER BY created_utc DESC) AS rn
  FROM ${aws_glue_catalog_table.eventbridge_pipe_table.name}
) e
INNER JOIN (
  SELECT
    id,
    first_value(sentiment) OVER (PARTITION BY id ORDER BY confidence DESC) AS sentiment,
    first_value(confidence) OVER (PARTITION BY id ORDER BY confidence DESC) AS confidence
  FROM ${aws_glue_catalog_table.lambda_sagemaker_table.name}
  GROUP BY id, sentiment, confidence
) s ON e.id = s.id
WHERE e.rn = 1
EOF
}