This module is used to create the backend resources terraform uses to track state. Backend resources are created in each account. The s3 backend bucket and lockign table are created in a primary region. a replication bucket is created in a replication region

Verion the branches with:
```shell script
git tag v0.0.2
git push origin -f --tags
```