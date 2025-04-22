# AWS AU (Application Unit)でのアプリケーション実行環境構築

## 1.AWS AU環境から取得した情報の設定

払い出されたAU環境から下記リソースの値を取得し、「.tfvars」ファイルに設定してください。
| リソース | テンプレート規定の設定値 |
|-----------|--------|
| VPC ID | vpc-0fc56c69d8cca3803 |
| Subnet public-a | subnet-0cb7576f339a2e0c8 |
| Subnet public-c | subnet-08ffef56f7c9aa937 |
| Subnet protected-a | subnet-000cfd6f239ee1909 |
| Subnet protected-c | subnet-0a5aba6ec5b0928c5 |
| Subnet private-a | subnet-0b074b02323e045ea |
| Subnet private-c | subnet-0c2b650e6571ad02a |

## 2.実行環境の準備（CloudShellを使用する場合）

CloudShellに実行環境を準備するための、設定をおこないます。

[CloudShell設定手順](../docs/cloudshell/README.md)

## 3.Session Managerの設定

SSM-SessionManagerRunShellが有る場合は、事前に削除する必要があります。（有ると構築エラーが発生）  
CloudShellでコマンドを実行し、有無を確認してください。

``` shell
# 確認コマンド
aws ssm get-document --name SSM-SessionManagerRunShell

# 削除コマンド
aws ssm delete-document --name SSM-SessionManagerRunShell
```

## 4.Terraformの環境設定


- system_config ファイルの編集

各環境変数の初期値を設定してください。

| 環境変数名 | 説明 | 備考 |
|-----------|------|------|
| system_name | システム名 | ※S3バケット名に追加 |
| environment | 実行環境名 | prd:本番,stg:ステージング,dev:開発 |
| internet | 外部接続用システム名 | ※internet.tfvarsのsystem_name |
| localnet | 内部接続用システム名 | ※localnet.tfvarsのsystem_name |

``` shell
#!/bin/bash
#           1234567890123456789 (limit:19 characters)
system_name=
#           123 (limit:3 characters)
environment=
#        1234567890123456789 (limit:19 characters)
internet=
#        1234567890123456789 (limit:19 characters)
localnet=
#
region_name=ap-northeast-1
```

- terraform初期設定の実行

※-d オープションを使用すると、internet.tfvars,localnet.tfvarsを初期化します。（初回のみ実行）

``` shell
# 開発環境のフォルダーに移動
cd ./infra
bash ./env/dev/inital_terraform_config.sh -d
```

- localnet.tfvarsの修正（社内LAN公開用）
- internet.tfvarsの修正（インターネット公開用）

## 5.AWS環境への適用

記載しているコマンドは、devフォルダ内のファイルを実行する記述です。
構成する環境に合わせて、ファイルパスを変更してください。

### 5-1.初期設定

``` shell
# terraform実行フォルダーに移動
cd ./infra
# 初期コマンド
terraform init -reconfigure -backend-config="env/dev/terraform.tfbackend"
```
インターネット公開（internet.tfvars）の場合は、5-2の手順へ進みます。  
社内LAN公開（localnet.tfvars）の場合は、5-3の手順へ進んでください。

### 5-2.インターネット公開用設定

``` shell
# terraform実行フォルダーに移動
cd ./infra
# 構成確認
terraform plan -var-file="./env/dev/internet.tfvars"
# 構成デプロイ
terraform apply -var-file="./env/dev/internet.tfvars" -auto-approve
# 構成削除
terraform destroy
```

### 5-3.社内LAN公開用設定

``` shell
# terraform実行フォルダーに移動
cd ./infra
# 構成確認
terraform plan -var-file="./env/dev/localnet.tfvars"
# 構成デプロイ
terraform apply -var-file="./env/dev/localnet.tfvars" -auto-approve
# 構成削除
terraform destroy
```


