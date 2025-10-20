• #!/usr/bin/env python3
  """
  Generate SQL from Bedrock using CSV requirements.

  Prereqs:
    pip install boto3 botocore
    export AWS_ACCESS_KEY_ID=..., AWS_SECRET_ACCESS_KEY=..., AWS_REGION=us-east-1
    Ensure IAM policy allows bedrock:InvokeModel on chosen model.
  """

  import csv
  import json
  import os
  import re
  from pathlib import Path

  import boto3
  from botocore.config import Config

  CSV_PATH = Path("requirements.csv")
  SQL_TEMPLATE_PATH = Path("templates.sql")
  OUTPUT_DIR = Path("generated_sql")
  MODEL_ID = "anthropic.claude-3-haiku-20240307-v1:0"
  PROMPT_TEMPLATE = """You are a data engineer.
  Use the CSV-derived requirement to generate ANSI SQL against our Snowflake warehouse.
  Primary table: {table_name}
  Required metrics: {metrics}
  Filters: {filters}
  Group by: {group_by}

  Follow patterns from these examples:
  {sql_examples}

  Return only executable SQL.
  """


  def load_requirements():
      with CSV_PATH.open(newline="", encoding="utf-8") as handle:
          return list(csv.DictReader(handle))


  def load_sql_examples():
      if SQL_TEMPLATE_PATH.exists():
          return SQL_TEMPLATE_PATH.read_text(encoding="utf-8").strip()
      return ""


  def build_prompt(requirement, sql_examples):
      return PROMPT_TEMPLATE.format(sql_examples=sql_examples, **requirement)


  def invoke_bedrock(prompt):
      region = os.environ.get("AWS_REGION", "us-east-1")
      client = boto3.client(
          "bedrock-runtime",
          region_name=region,
          config=Config(retries={"max_attempts": 3}),
      )
      body = {
          "anthropic_version": "bedrock-2023-05-31",
          "max_tokens": 400,
          "temperature": 0.2,
          "messages": [{"role": "user", "content": prompt}],
      }
      response = client.invoke_model(
          modelId=MODEL_ID,
          contentType="application/json",
          accept="application/json",
          body=json.dumps(body),
      )
      payload = json.loads(response["body"].read())
      return payload["content"][0]["text"].strip()


  def slugify(text):
      return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")


  def write_sql(requirement, sql):
      OUTPUT_DIR.mkdir(exist_ok=True)
      filename = f"{requirement['report_id']}_{slugify(requirement['title'])}.sql"
      path = OUTPUT_DIR / filename
      path.write_text(sql + "\n", encoding="utf-8")
      print(f"Wrote SQL for {requirement['title']} to {path}")


  def main():
      requirements = load_requirements()
      if not requirements:
          raise SystemExit("requirements.csv is empty or missing rows.")

      sql_examples = load_sql_examples()

      for requirement in requirements:
          prompt = build_prompt(requirement, sql_examples)
          sql = invoke_bedrock(prompt)
          write_sql(requirement, sql)


  if __name__ == "__main__":
      main()
