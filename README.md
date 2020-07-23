# jag-wiki-crawler

## Deployment

Use [sam-cli](https://github.com/awslabs/aws-sam-cli).
```sh
sam build -u
sam deploy --parameter-overrides SpreadsheetID=xxxxxxxx....
```

## SSM parameters

- `/jag-maintenance/pukiwiki`:
  ```json
  {
    "location": "https://example.com/pukiwiki",
    "username": "",
    "password": ""
  }
  ```
- `/jag-maintenance/google`: JSON key for GCP service account
