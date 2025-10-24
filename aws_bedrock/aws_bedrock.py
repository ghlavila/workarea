#!/usr/bin/env python3
"""
Generate SQL and optionally JSON from Bedrock using CSV data and templates.
Sends entire CSV, SQL template, and optional JSON template to AI in one prompt.
Generates one SQL output file and optionally one JSON output file.

Usage:
  # Required arguments: --csv, --sql-templates, --output
  python aws_bedrock.py --csv companies.csv --sql-templates template.sql --output generated.sql

  # With JSON template (generates both SQL and JSON)
  python aws_bedrock.py --csv companies.csv --sql-templates template.sql --json-template template.json --output generated.sql
  # This will create: generated.sql and generated.json

  # With custom prompt file
  python aws_bedrock.py --csv data.csv --sql-templates t.sql --output result.sql --prompt my_prompt.txt

  # With S3 prompt
  python aws_bedrock.py --csv data.csv --sql-templates t.sql --output result.sql --prompt s3://bucket/prompt.txt

  # With S3 output
  python aws_bedrock.py --csv data.csv --sql-templates t.sql --output s3://bucket/output.sql

  # With different model
  python aws_bedrock.py --csv data.csv --sql-templates t.sql --output result.sql --model anthropic.claude-v2

  # Full workflow with SQL and JSON generation
  python aws_bedrock.py --csv companies.csv --sql-templates template.sql --json-template template.json --output result.sql
"""

import argparse
import csv
import json
import os
import re
from pathlib import Path

import boto3
from botocore.config import Config


def load_requirements(csv_path):
    csv_path = Path(csv_path)
    with csv_path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def load_csv_content(csv_path):
    """Load entire CSV file as string."""
    csv_path = Path(csv_path)
    return csv_path.read_text(encoding="utf-8").strip()


def load_sql_examples(sql_template_path):
    sql_template_path = Path(sql_template_path)
    if sql_template_path.exists():
        return sql_template_path.read_text(encoding="utf-8").strip()
    return ""


def load_json_template(json_template_path):
    """Load JSON template file."""
    if not json_template_path:
        return None
    json_template_path = Path(json_template_path)
    if json_template_path.exists():
        return json_template_path.read_text(encoding="utf-8").strip()
    return None


def load_prompt_template(prompt_path):
    """Load prompt template from local file or S3."""
    # Handle S3 paths
    if isinstance(prompt_path, str) and prompt_path.startswith("s3://"):
        # Parse S3 URI: s3://bucket/key/path
        s3_path = prompt_path[5:]  # Remove 's3://'
        bucket, _, key = s3_path.partition("/")
        if not bucket or not key:
            raise SystemExit(f"Invalid S3 path format: {prompt_path}")

        region = os.environ.get("AWS_REGION", "us-east-1")
        s3_client = boto3.client("s3", region_name=region)
        try:
            response = s3_client.get_object(Bucket=bucket, Key=key)
            return response["Body"].read().decode("utf-8").strip()
        except Exception as e:
            raise SystemExit(f"Failed to read S3 prompt template {prompt_path}: {e}")

    # Handle local file paths
    if isinstance(prompt_path, str):
        prompt_path = Path(prompt_path)

    if not prompt_path.exists():
        raise SystemExit(f"Prompt template file not found: {prompt_path}")
    return prompt_path.read_text(encoding="utf-8").strip()


def build_prompt(prompt_template, csv_content, sql_template, json_template=None):
    """Build prompt with CSV content, SQL template, and optional JSON template."""
    prompt = f"{prompt_template}\n\nCSV Content:\n{csv_content}\n\nTemplate SQL:\n{sql_template}"

    if json_template:
        prompt += f"\n\nTemplate JSON:\n{json_template}"

    return prompt


def invoke_bedrock(model_id, prompt):
    region = os.environ.get("AWS_REGION", "us-east-1")
    client = boto3.client(
        "bedrock-runtime",
        region_name=region,
        config=Config(retries={"max_attempts": 3}),
    )

    # Auto-detect model type and use appropriate API format
    if "anthropic" in model_id.lower() or "claude" in model_id.lower():
        # Anthropic Claude models
        body = {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 4096,
            "temperature": 0.2,
            "messages": [{"role": "user", "content": prompt}],
        }
        response = client.invoke_model(
            modelId=model_id,
            contentType="application/json",
            accept="application/json",
            body=json.dumps(body),
        )
        payload = json.loads(response["body"].read())

        result = payload["content"][0]["text"].strip()
        print(f"Generated {len(result)} characters of output")
        return result
    elif "nova" in model_id.lower():
        # Amazon Nova models - use messages format
        body = {
            "messages": [{"role": "user", "content": [{"text": prompt}]}],
            "inferenceConfig": {
                "max_new_tokens": 8192,  # Increased for SQL + JSON generation
                "temperature": 0.2,
                "topP": 0.9
            }
        }
        response = client.invoke_model(
            modelId=model_id,
            contentType="application/json",
            accept="application/json",
            body=json.dumps(body),
        )
        payload = json.loads(response["body"].read())

        result = payload["output"]["message"]["content"][0]["text"].strip()
        print(f"Generated {len(result)} characters of output")
        return result
    else:
        # Amazon Titan models
        body = {
            "inputText": prompt,
            "textGenerationConfig": {
                "maxTokenCount": 4096,
                "temperature": 0.2,
                "topP": 0.9,
                "stopSequences": []
            }
        }
        response = client.invoke_model(
            modelId=model_id,
            contentType="application/json",
            accept="application/json",
            body=json.dumps(body),
        )
        payload = json.loads(response["body"].read())

        result = payload["results"][0]["outputText"].strip()
        print(f"Generated {len(result)} characters of output")
        return result


def slugify(text):
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")


def parse_ai_output(output_text):
    """Parse AI output to separate SQL and JSON if both are present.

    Returns tuple: (sql_content, json_content)
    If no JSON found, json_content will be None.
    """
    # Try to find JSON section markers
    json_start_markers = ["```json", "JSON:", "Template JSON:", "Generated JSON:"]
    sql_start_markers = ["```sql", "SQL:", "Template SQL:", "Generated SQL:"]

    # Simple approach: look for ```sql and ```json code blocks
    sql_content = output_text
    json_content = None

    # Check if output contains both SQL and JSON markers
    if "```json" in output_text.lower() or "```sql" in output_text.lower():
        # Extract SQL block
        sql_match = re.search(r"```sql\s*\n(.*?)\n```", output_text, re.DOTALL | re.IGNORECASE)
        if sql_match:
            sql_content = sql_match.group(1).strip()

        # Extract JSON block
        json_match = re.search(r"```json\s*\n(.*?)\n```", output_text, re.DOTALL | re.IGNORECASE)
        if json_match:
            json_content = json_match.group(1).strip()
    else:
        # Try to split by common separators if no code blocks found
        # Look for JSON starting with { or [
        json_start = -1
        for i, line in enumerate(output_text.split('\n')):
            stripped = line.strip()
            if stripped and (stripped[0] == '{' or stripped[0] == '['):
                # Potential JSON start
                json_start_pos = output_text.find(line)
                if json_start_pos > 0:
                    sql_content = output_text[:json_start_pos].strip()
                    json_content = output_text[json_start_pos:].strip()
                    break

    return sql_content, json_content


def write_output(output_path, content, content_type="SQL"):
    """Write content to local file or S3.

    Args:
        output_path: Path to write to (local or S3)
        content: Content to write
        content_type: Type of content for logging (e.g., "SQL", "JSON")
    """
    # Handle S3 paths
    if isinstance(output_path, str) and output_path.startswith("s3://"):
        # Parse S3 URI: s3://bucket/key
        s3_path = output_path[5:]  # Remove 's3://'
        bucket, _, key = s3_path.partition("/")
        if not bucket or not key:
            raise SystemExit(f"Invalid S3 path format (need s3://bucket/key): {output_path}")

        region = os.environ.get("AWS_REGION", "us-east-1")
        s3_client = boto3.client("s3", region_name=region)
        try:
            s3_client.put_object(
                Bucket=bucket,
                Key=key,
                Body=(content + "\n").encode("utf-8"),
                ContentType="text/plain",
            )
            print(f"Wrote {content_type} to s3://{bucket}/{key}")
        except Exception as e:
            raise SystemExit(f"Failed to write to S3 {output_path}: {e}")
    else:
        # Handle local file paths
        output_path = Path(output_path)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(content + "\n", encoding="utf-8")
        print(f"Wrote {content_type} to {output_path}")


def main():
    parser = argparse.ArgumentParser(
        description="Generate SQL from Bedrock using CSV requirements."
    )
    parser.add_argument(
        "--prompt",
        type=str,
        default="prompt.txt",
        help="Local path or S3 URI (s3://bucket/path) to prompt template (default: prompt.txt)",
    )
    parser.add_argument(
        "--csv",
        type=str,
        required=True,
        help="Path to CSV requirements file",
    )
    parser.add_argument(
        "--sql-templates",
        type=str,
        required=True,
        help="Path to SQL template examples file",
    )
    parser.add_argument(
        "--json-template",
        type=str,
        default=None,
        help="Path to JSON template file (optional)",
    )
    parser.add_argument(
        "--output",
        type=str,
        required=True,
        help="Local file path or S3 URI (s3://bucket/key.sql) for output SQL file",
    )
    parser.add_argument(
        "--model",
        type=str,
        default="amazon.nova-pro-v1:0",
        #default="anthropic.claude-3-haiku-20240307-v1:0",  # Requires use case form submission
        #default="amazon.titan-text-express-v1",  # Titan doesn't work well for SQL generation
        help="Bedrock model ID (default: amazon.nova-pro-v1:0)",
    )
    args = parser.parse_args()

    # Load prompt template, CSV content, and SQL template
    prompt_template = load_prompt_template(args.prompt)
    csv_content = load_csv_content(args.csv)
    sql_template = load_sql_examples(args.sql_templates)
    json_template = load_json_template(args.json_template) if args.json_template else None

    # Build single prompt with all content
    prompt = build_prompt(prompt_template, csv_content, sql_template, json_template)

    print(f"Prompt length: {len(prompt)} characters")

    # Invoke AI model once
    if json_template:
        print(f"Invoking {args.model} to generate SQL and JSON...")
    else:
        print(f"Invoking {args.model} to generate SQL...")
    ai_output = invoke_bedrock(args.model, prompt)

    # Debug: Save raw output for inspection
    raw_output_path = Path(args.output).with_suffix('.raw.txt')
    write_output(str(raw_output_path), ai_output, "RAW")

    # Parse output to separate SQL and JSON
    sql_content, json_content = parse_ai_output(ai_output)

    # Write SQL output
    write_output(args.output, sql_content, "SQL")

    # Write JSON output if present
    if json_content:
        # Determine JSON output path based on SQL output path
        output_path = Path(args.output)
        json_output_path = output_path.with_suffix('.json')
        write_output(str(json_output_path), json_content, "JSON")
    else:
        print("Warning: No JSON content found in AI output. Check my.raw.txt for the raw response.")


if __name__ == "__main__":
    main()
