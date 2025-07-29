# Config
$region = "us-east-1"
# $streamName = "reddit-input-stream"
$streamName = "reddit-output-stream"
$shardId = "shardId-000000000000"

# Get the Shard Iterator
$shardIterator = aws kinesis get-shard-iterator `
    --stream-name $streamName `
    --shard-id $shardId `
    --shard-iterator-type TRIM_HORIZON `
    --region $region `
    --query "ShardIterator" `
    --output text

# Get Records
$records = aws kinesis get-records `
    --shard-iterator $shardIterator `
    --region $region `
    --output json | ConvertFrom-Json

# Print Records
if ($records.Records.Count -eq 0) {
    Write-Host "No records found."
} else {
    Write-Host "Records:"
    foreach ($record in $records.Records) {
        $decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($record.Data))
        Write-Output $decoded
    }
}