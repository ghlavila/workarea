 aws s3tables delete-table-bucket \
	 --region us-east-1 \
	 --table-bucket-arn arn:aws:s3tables:us-east-1:716531470317:bucket/gh-test-table

 aws s3tables delete-namespace \
	 --table-bucket-arn arn:aws:s3tables:us-east-1:716531470317:bucket/lavila-test-table-bucket \
	 --namespace lavila_test_namespace
