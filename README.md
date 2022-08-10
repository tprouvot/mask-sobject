# Mask SObject Framework

This framework allow users to configure some data masking operations.

## How Do You Configure SObjects And Fields to Mask ?

The configuration is based on two objects:

- MaskSObject__c  : which define the object to mask with options such as the order sequence and the where clause
- MaskSObjectField___c : which define the fields to mask and the option of masking (erase, randomize ...)

[![SObjedt config](https://github.com/tprouvot/mask-sobject/blob/framework-beta/screenshots/2022-08-10_09-42-09.png)](https://github.com/tprouvot/mask-sobject/blob/framework-beta/screenshots/2022-08-10_09-42-09.png)
## Deploy to Salesforce

Checkout the repo and deploy it with sfdx:
```sh
sfdx force:source:deploy -p force-app
```

Use GitHub Salesforce Deploy Tool:

![Button](https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/src/main/webapp/resources/img/deploy.png)

