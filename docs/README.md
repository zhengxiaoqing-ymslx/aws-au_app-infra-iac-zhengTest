
# Terraform標準定義
    ここでは、実行環境を構築するための標準定義を記載する

## 1.フォルダー構成
    Terraformの標準的なフォルダー構成を以下に示す


### １）/
    概要:　メインモジュールを設置
    内容:　modules以下のソースを読み込み。
            モジュールはそれぞれ main.tf, variables.tf
            erraform init,plan,apply等のコマンドを実行するディレクトリ

### ２）/modules
    概要:　再利用可能なカスタムモジュールを格納するディレクトリ
    内容:　各AWSリソース（例: VPC、EC2、S3など）のモジュールをディレクトリ単位で分割
        モジュールはそれぞれ main.tf, variables.tf, outputs.tf
            main.tf  メインの処理を記載 
            variables.tf  変数を定義するファイル
            outputs.tf    戻り値を取得するための設定ファイル

### ３）/env
    概要: 環境ごとの環境変数を管理
    サブディレクトリ例:
            /dev: 開発環境用
            /qas: 検証用
            /prod: 本番環境用
    内容:　環境に応じた terraform.tfvars（環境固有の値）
        terraform plan,apply等のコマンド時適切な読み込む固有変数を定義。
        モジュールはinternet.tfvars、localnet.tfvars



### ４）README.md
    概要: プロジェクト全体の概要、設定方法、使用手順を記載

### ５）addsource
    概要：プロジェクト固有のサービスを追加する


``` 
【基本構成例】

+-cloudformation                      : AWS AU環境のVPCテンプレート  
|  
+-docs                                : ドキュメント  
|  
+-addsource                           : プロジェクト固有サービス
          +- main.tf                  : プロジェクト固有　main設定  
          +- variables.tf             : プロジェクト固有　変数設定  
          +- terraform.tfvars         : プロジェクト固有　共通設定値  
          +- README.md                : 環境構築手順のドキュメント
          |  
          +-module -+- alb            : alb設定  
                    |  
                    +- aurora         : RDS for aurora (postgresql) 設定  
|  
+-infra  -+- main.tf                  : main設定  
          +- variables.tf             : 変数設定  
          +- terraform.tfvars         : 共通設定値  
          +- README.md                : 環境構築手順のドキュメント
          |  
          +- docker +- niginx         : NGINX用コンテナイメージ定義  
          |  
          +- env ---+- _default       : 環境定義のテンプレート
          |         |  
          |         +- dev            : 開発環境  
          |         |                   internet.tfvars
          |         |                   localnet.tfvars
          |         |                   inital_terraform_config.sh
          |         |  
          |         +- stg            : ステージング環境
          |         |  
          |         +- prd            : 本番環境   
          |  
          +-module -+- alb            : alb設定  
                    |  
                    +- aurora         : RDS for aurora (postgresql) 設定  
                    |  
                    +- cloudfront     : cloudfront設定  
                    |  
                    +- ec2            : 踏み台EC2サーバ設定  
                    |  
                    +- ecr            : ECR設定  
                    |  
                    +- ecs            : ECS設定  
                    |  
                    +- iam            : IAM設定 
                    |  
                    +- nginx          : NGINX設定 (Frontendの社内LAN公開用)  
                    |  
                    +- oidc           : oidc設定  
                    |  
                    +- rds            : RDS for postgresql設定  
                    |  
                    +- s3             : S3設定 (Frontend用)  
                    |  
                    +- security_group : セキュリティグループ設定  
                    |  
                    +- vpc            : vpcエンドポイント設定  
                    |  
                    +- waf            : AWS WAF設定  
```

## ２．命名規則

### ・module名
    AWSサービス名でフォルダーを作成

```
     VPC: modules/vpc
　　 EC2: modules/ec2
　　 S3: modules/s3
```

#### ・ソース内
    ・リソース名、データソース名、変数名、出力など、全て小文字で単語を使用し、 -（ダッシュ）の代わりに _（アンダースコア）を使用してください。
    ・Terraformソース内はスネークケースで記述。　キャメルケースは利用しない。
    ・[サービス]_[リソースタイプ]_[任意]

```
eks-cluster-AmazonEKSClusterPolicy  キャメルケース　＊この記述はしない
eks_cluster_amazon_eks_cluster_policy　　スネークケース　
```

詳細は(https://www.terraform-best-practices.com/ja/naming)　公式参照

```
例:　
   resource "aws_lb_target_group"
   resource "aws_vpc_security_group_ingress_rule"
   data "aws_ec2_managed_prefix_list"
   variable "aws_region_name" {}
   variable "aws_vpc_id" {}
```

## ３．Terraform State (状態管理)
### Stateファイルの管理とは
    TerraformのStateファイルとは、Terraformが管理するインフラストラクチャの状態を保存するファイルです。
    このファイルは、Terraformが次回の適用時に前回の適用結果を参照し、状態の変更があれば新しい状態をStateファイルに反映します。 そのため、Stateファイルの管理が重要であり、誤った操作やStateファイルの紛失が起きると、インフラストラクチャに致命的な影響を与えることがあります。

    ・AWS S3に配置する
    ・初期作業として　inital_terraform_config.sh　を実行しStatを作成
    ・バケット名はAWSアカウント単位で
        bucket_name="tfstate-"${account_id}
    または
        bucket_name="tfstate-"${system_name,,}-"${account_id}"

        で作成


## ４．静的テスト
    作成したソースの整形、静的テストについて

### Terraform 標準コマンド
    ・terraform fmt
        記述されたファイルを正規のフォーマットとスタイルに合わせて整形をしてくれます。
        (https://www.terraform.io/cli/commands/fmt)

    ・terraform validate
        記述されたファイルが構文的に正しいかなどの検査
        (https://developer.hashicorp.com/terraform/cli/commands/validate)


## ５．プロジェクト固有サービス
    ・プロジェクト固有サービスは　ルートディレクトリに「addsource」フォルダーを作成し
    　個別管理する

##　６．作成手順
```
    １：https://github.com/YMC-GROUP/aws-au_app-infra-iac をcloneする
        
    ２：ブランチの作成
    　　・開発環境用branchを作成

    ３：開発環境の構築
    　　・共通テンプレートに基づき開発環境を構築

    ４：必要なリソースの追加
    　　・共通テンプレートに足りないプロジェクト独自リソースを追加する

    ５：変更のコミット
        ・開発環境用branchのコミット

    ６：Pull Requestの作成とマージ
    　　・開発環境用branchを各プロジェクトのmasterにマージ
    
    ７：検証・本番環境へのデプロイ
        ・Github Actionsで検証環境・実行環境のデプロイを行う

    
```
