# モダナイズAWS検証 (Backend) {ignore=true}

[toc]

---

## GitHub

### YMSL-J/basic-app-backend

https://github.com/YMSL-J/basic-app-backend

`.github/workflow/deploy_aws_ecs.yml`では、以下のステップでECSへのデプロイが実行されている。

1. AWSにログイン (OIDC)
2. Java/Gradleのセットアップ
3. Gradleビルド
4. ビルド成果物(jar)を使用してコンテナイメージを作成し、ECRにPushする
5. ECRにPushしたコンテナイメージを指定したタスク定義の新バージョンを作成する
6. 新バージョンのタスク定義を使用して、指定サービスを更新 (デプロイ)

よって、手順5の実行時には「ECRタスク定義が作成済み」、手順6の実行時には「ECSサービスが稼働中」である必要がある。
そのため、まずコンテナイメージを作りたいだけの場合は、手順5以降をコメントアウトして実行するか、ローカルPCからAWS CLIを使って実行する必要がある。

ワークフローの実行にはAWSの環境情報が定義されたシークレットが必要。
AWS環境構築後、最終的に以下の値を指定した。

**Secrets:**

|key|value|
|---|---|
|AWS_REGION|ap-northeast-1|
|AWS_ROLE_NAME|arn:aws:iam::140651483960:role/basic-app-backend-deploy-role|
|ECR_REPOSITORY|140651483960.dkr.ecr.ap-northeast-1.amazonaws.com/basic-app-backend|
|ECS_SERVICE|basic-app-backend|
|ECS_CLUSTER|basic-app-ecs-cluster|
|CONTAINER_NAME|yna-g3-solid|
|TASK_DEFINITION_NAME|basic-app-ecs-task-def|

## IAM：ID プロバイダ

OIDCプロバイダを追加。

- プロバイダのURL
  - `https://token.actions.githubusercontent.com`

- 対象者
  - `sts.amazonaws.com`

## ECR：Private Repository

プライベートリポジトリを作成。

- リポジトリ名
  - `basic-app-backend`

- URI
  - `140651483960.dkr.ecr.ap-northeast-1.amazonaws.com/basic-app-backend`

## Cloud Watch：ロググループ

### /ecs/basic-app-backend

ECSタスクのログ保管用。

- ロググループ名
  - `/ecs/basic-app-backend`
- 保持期間の設定
  - 3か月 (90日)

### ssm-log

セッションマネージャーのログ保管用。

- ロググループ名
  - `ssm-log`
- 保持期間の設定
  - 3か月 (90日)

## IAM：ポリシー

### basic-app-ecs-task-policy

ECSタスクの動作に必要な権限セット。

``` json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:DescribeLogGroups"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:ap-northeast-1:140651483960:log-group:/ecs/basic-app-backend:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssmmessages:CreateControlChannel",
                "ssmmessages:CreateDataChannel",
                "ssmmessages:OpenControlChannel",
                "ssmmessages:OpenDataChannel"
            ],
            "Resource": "*"
        }
    ]
}
```

### basic-app-ecs-task-exec-policy

ECSタスクの起動に必要な権限セット。

``` json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetSecretValue"
            ],
            "Resource": "arn:aws:secretsmanager:ap-northeast-1:140651483960:secret:basic-app-ecs-task-env-secret-VesIxh"
        }
    ]
}
```

### basic-app-bastion-ec2-policy

踏み台EC2の動作に必要な権限セット。

``` json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:DescribeLogGroups"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams"
            ],
            "Resource": "arn:aws:logs:ap-northeast-1:140651483960:log-group:ssm-log:*"
        }
    ]
}
```

### basic-app-backend-deploy-policy

アプリバックエンドのデプロイに必要な権限セット。

``` json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:CompleteLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:InitiateLayerUpload",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage"
            ],
            "Resource": [
                "arn:aws:ecr:ap-northeast-1:140651483960:repository/basic-app-backend"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "ecr:GetAuthorizationToken",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecs:DescribeTaskDefinition",
                "ecs:RegisterTaskDefinition"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecs:DescribeServices",
                "ecs:UpdateService"
            ],
            "Resource": [
                "arn:aws:ecs:ap-northeast-1:140651483960:service/basic-app-ecs-cluster/basic-app-backend"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecs:DescribeTasks",
                "ecs:ListTasks"
            ],
            "Resource": "*",
            "Condition": {
                "ArnEquals": {
                    "ecs:cluster": "arn:aws:ecs:ap-northeast-1:140651483960:cluster/basic-app-ecs-cluster"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": [
                "arn:aws:iam::140651483960:role/basic-app-ecs-task-role",
                "arn:aws:iam::140651483960:role/basic-app-ecs-task-exec-role"
            ],
            "Condition": {
                "StringEquals": {
                    "iam:PassedToService": [
                        "ecs-tasks.amazonaws.com"
                    ]
                }
            }
        }
    ]
}
```

## IAM：ロール

### basic-app-ecs-task-role

ECSタスクロール。
`basic-app-ecs-task-policy`をアタッチ。

**信頼ポリシー：**

``` json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": "ecs-tasks.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
```

### basic-app-ecs-task-exec-role

ECSタスク実行ロール。
`AmazonECSTaskExecutionRolePolicy`と`basic-app-ecs-task-exec-policy`をアタッチ。

**信頼ポリシー：**

``` json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": "ecs-tasks.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
```

### basic-app-bastion-ec2-role

踏み台EC2用のロール。
`AmazonSSMManagedInstanceCore`と`basic-app-bastion-ec2-policy`をアタッチ。

**信頼ポリシー：**

``` json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
```

### basic-app-backend-deploy-role

GitHub Actionsでのデプロイ用のロール。
`basic-app-backend-deploy-policy`をアタッチ。

**信頼ポリシー：**

``` json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::140651483960:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:YMSL-J/basic-app-backend:*"
                }
            }
        }
    ]
}
```

## VPC：セキュリティグループ

### basic-app-ecs-service-alb-sg

ALB用のセキュリティグループ。

- セキュリティグループ名
  - `basic-app-ecs-service-alb-sg`
- 説明
  - for basic-app ALB
- VPC
  - `vpc-TestAWSBuild01`
- インバウンド
  - HTTPS化するまでは設定しない
- アウトバウンド
  - 8080：`basic-app-ecs-service-sg`

### basic-app-ecs-service-sg

ECSサービス用のセキュリティグループ。

- セキュリティグループ名
  - `basic-app-ecs-service-sg`
- 説明
  - for basic-app ECS Service
- VPC
  - `vpc-TestAWSBuild01`
- インバウンド
  - 8080：`basic-app-ecs-service-alb-sg`
- アウトバウンド
  - 5432：`basic-app-rds-sg`
  - 443：`basic-app-ecs-task-vpce-sg`
  - 443：`com.amazonaws.ap-northeast-1.s3`

### basic-app-ecs-task-vpce-sg

ECSタスクの実行や動作に必要となるVPCエンドポイント用のセキュリティグループ。

- セキュリティグループ名
  - `basic-app-ecs-task-vpce-sg`
- 説明
  - for basic-app ECS Task VPC Endpoint
- VPC
  - `vpc-TestAWSBuild01`
- インバウンド
  - 443：`basic-app-ecs-service-sg`
- アウトバウンド
  - すべてのトラフィック

### basic-app-rds-sg

RDS用のセキュリティグループ。

- セキュリティグループ名
  - `basic-app-rds-sg`
- 説明
  - for basic-app RDS
- VPC
  - `vpc-TestAWSBuild01`
- インバウンド
  - 5432：`basic-app-ecs-service-sg`
  - 5432：`basic-app-bastion-ec2-sg`
- アウトバウンド
  - 設定なし

### basic-app-bastion-ec2-sg

踏み台EC2用のセキュリティグループ。

- セキュリティグループ名
  - `basic-app-bastion-ec2-sg`
- 説明
  - for basic-app bastion EC2
- VPC
  - `vpc-TestAWSBuild01`
- インバウンド
  - 設定なし
- アウトバウンド
  - 5432：`basic-app-rds-sg`
  - 443：`basic-app-bastion-ec2-vpce-sg`

### basic-app-bastion-ec2-vpce-sg

踏み台EC2に必要となるVPCエンドポイント用のセキュリティグループ。

- セキュリティグループ名
  - `basic-app-bastion-ec2-vpce-sg`
- 説明
  - for basic-app bastion EC2 VPC Endpoint
- VPC
  - `vpc-TestAWSBuild01`
- インバウンド
  - 443：`basic-app-bastion-ec2-sg`
- アウトバウンド
  - すべてのトラフィック

## VPC：エンドポイント

### basic-app-ecr-api-vpce

- 名前タグ
  - `basic-app-ecr-api-vpce`
- サービス
  - `com.amazonaws.ap-northeast-1.ecr.api`
- VPC
  - `vpc-TestAWSBuild01`
- サブネット
  - `subnet-TestAWSBuild01-protected-a`
  - `subnet-TestAWSBuild01-protected-c`
- セキュリティグループ
  - `basic-app-ecs-task-vpce-sg`

### basic-app-ecr-dkr-vpce

- 名前タグ
  - `basic-app-ecr-dkr-vpce`
- サービス
  - `com.amazonaws.ap-northeast-1.ecr.dkr`
- VPC
  - `vpc-TestAWSBuild01`
- サブネット
  - `subnet-TestAWSBuild01-protected-a`
  - `subnet-TestAWSBuild01-protected-c`
- セキュリティグループ
  - `basic-app-ecs-task-vpce-sg`

### basic-app-secretsmanager-vpce

- 名前タグ
  - `basic-app-secretsmanager-vpce`
- サービス
  - `com.amazonaws.ap-northeast-1.secretsmanager`
- VPC
  - `vpc-TestAWSBuild01`
- サブネット
  - `subnet-TestAWSBuild01-protected-a`
  - `subnet-TestAWSBuild01-protected-c`
- セキュリティグループ
  - `basic-app-ecs-task-vpce-sg`

### basic-app-logs-vpce

- 名前タグ
  - `basic-app-logs-vpce`
- サービス
  - `com.amazonaws.ap-northeast-1.logs`
- VPC
  - `vpc-TestAWSBuild01`
- サブネット
  - `subnet-TestAWSBuild01-protected-a`
  - `subnet-TestAWSBuild01-protected-c`
- セキュリティグループ
  - `basic-app-ecs-task-vpce-sg`
  - `basic-app-bastion-ec2-vpce-sg`

### basic-app-ssm-vpce

- 名前タグ
  - `basic-app-ssm-vpce`
- サービス
  - `com.amazonaws.ap-northeast-1.ssm`
- VPC
  - `vpc-TestAWSBuild01`
- サブネット
  - `subnet-TestAWSBuild01-protected-a`
  - `subnet-TestAWSBuild01-protected-c`
- セキュリティグループ
  - `basic-app-ecs-task-vpce-sg`
  - `basic-app-bastion-ec2-vpce-sg`

### basic-app-ssmmessages-vpce

- 名前タグ
  - `basic-app-ssmmessages-vpce`
- サービス
  - `com.amazonaws.ap-northeast-1.ssmmessages`
- VPC
  - `vpc-TestAWSBuild01`
- サブネット
  - `subnet-TestAWSBuild01-protected-a`
  - `subnet-TestAWSBuild01-protected-c`
- セキュリティグループ
  - `basic-app-ecs-task-vpce-sg`
  - `basic-app-bastion-ec2-vpce-sg`

### basic-app-ec2messages-vpce

- 名前タグ
  - `basic-app-ec2messages-vpce`
- サービス
  - `com.amazonaws.ap-northeast-1.ec2messages`
- VPC
  - `vpc-TestAWSBuild01`
- サブネット
  - `subnet-TestAWSBuild01-protected-a`
  - `subnet-TestAWSBuild01-protected-c`
- セキュリティグループ
  - `basic-app-bastion-ec2-vpce-sg`

### EP-TestAWSBuild01-S3 (修正)

ECSでのタスク実行時、ECRからのイメージのPullに必要な権限(`"Resource": "*"`)をポリシーに追加。
※今後はモダナイズAWSのデフォルト設定として提供される予定

``` json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:*",
            "Resource": "*"
        }
    ]
}
```

## RDS

### サブネットグループ

- 名前
  - `basic-app-rds-subnet-group`
- 説明
  - for basic-app RDS
- VPC
  - `vpc-TestAWSBuild01`
- アベイラビリティゾーン
  - `ap-northeast-1a`
  - `ap-northeast-1c`
- サブネット
  - `subnet-TestAWSBuild01-private-a`
  - `subnet-TestAWSBuild01-private-c`

### データベース

|設定項目|設定値|
|---|---|
|**エンジンのタイプ**|PostgreSQL|
|**エンジンバージョン**|15.7-R2|
|**テンプレート**|開発/テスト|
|**可用性と耐久性**|マルチ AZ DB インスタンス|
|**DBインスタンス識別子**|basic-app-rds|
|**マスターユーザー名**|postgres|
|**認証情報管理**|AWS Secrets Manager で管理|
|**DB インスタンスクラス**|db.t3.micro|
|**ストレージタイプ**|汎用 SSD (gp3)|
|**ストレージ割り当て**|20|
|**ストレージの自動スケーリング**|無効 (チェックOFF)|
|**接続**|EC2 コンピューティングリソースに接続しない|
|**ネットワークタイプ**|IPv4|
|**VPC**|vpc-TestAWSBuild01|
|**DBサブネットグループ**|basic-app-rds-subnet-group|
|**パブリックアクセス**|なし|
|**セキュリティグループ**|basic-app-rds-sg|
|**認証機関**|rds-ca-rsa2048-g1|
|**データベース認証**|パスワード認証|

## Systems Manager：セッションマネージャー

CloudWatch logging だけ設定しておいた。

[セッションマネージャー] > [設定]

- CloudWatch logging
  - Enforce encryption
    - チェックOFF
  - ロググループ
    - `ssm-log`

## EC2：インスタンス

### basic-app-bastion-ec2

RDS踏み台用EC2。
準備が必要なユーザーやデータベース、テーブルなどは「補足」を参照。

- 名前
  - `basic-app-bastion-ec2`
- AMI
  - Amazon Linux 2023 AMI
- アーキテクチャ
  - 64 ビット
- インスタンスタイプ
  - t2.micro
- キーペア
  - キーペアなしで続行
- VPC
  - `vpc-TestAWSBuild01`
- サブネット
  - `subnet-TestAWSBuild01-private-a`
- パブリックIPの自動割り当て
  - 無効化
- セキュリティグループ
  - `basic-app-bastion-ec2-sg`
- 高度な詳細
  - IAMインスタンスプロフィール
    - `basic-app-bastion-ec2-role`
  - ユーザーデータ
    ``` bash
    #!/bin/bash
    ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

    userdel -r ec2-user
    rm -f /etc/sudoers.d/90-cloud-init-users
    ```

### ssm start-session

適切な Credecial を設定のうえ実行すること。
AWS CLI と Session Managerプラグイン のインストールが必要。

**EC2にログイン：**

``` powershell
aws ssm start-session `
  --target ${EC2_INSTANCE_ID}
```

**ポートフォワーディング：**

``` powershell
aws ssm start-session `
  --target ${EC2_INSTANCE_ID} `
  --document-name AWS-StartPortForwardingSessionToRemoteHost `
  --parameters '{"host":["${RDS_ENDPOINT}"],"portNumber":["5432"],"localPortNumber":["5432"]}'
```

## WAF & Shield：Web ACLs

- Region
  - Asia Pacific (Tokyo)
- Name
  - `basic-app-waf`
- Rules
  - `AWS-AWSManagedRulesCommonRuleSet` (AWS managed rule groups > Free rule groups > Core rule set)

## Secrets Manager

### basic-app-ecs-task-env-secret

ECSタスク起動時に環境変数として渡すパラメータ群。
ECSタスク定義の作成で使用する。

- APP_PROFILES_ACTIVE
  - `production`
- DB_URL
  - `jdbc:postgresql://basic-app-rds.chpfsf8lkdmx.ap-northeast-1.rds.amazonaws.com:5432/basicapp`
- DB_USERNAME
  - `basicapp`
- DB_PASSWORD
  - `************`

## EC2：ロードバランシング

### ターゲットグループ

- ターゲットタイプ
  - `IP`
- ターゲットグループ名
  - `basic-app-alb-tg`
- プロトコル:ポート
  - `HTTP:8080`
- VPC
  - `vpc-TestAWSBuild01`
- ヘルスチェック
  - ヘルスチェックプロトコル
    - `HTTP`
  - ヘルスチェックパス
    - `/basicapp/HelloWorld`
- IPアドレス
  - "VPC サブネットからの IPv4 アドレスを入力します。" -> "削除"

### ロードバランサー

- タイプ
  - Application Load Balancer
- 名前
  - `basic-app-alb`
- VPC
  - `vpc-TestAWSBuild01`
- マッピング
  - `ap-northeast-1a`
  - `ap-northeast-1c`
- セキュリティグループ
  - `basic-app-ecs-service-alb-sg`
- リスナーとルーティング
  - デフォルトアクション
    - `basic-app-alb-tg`
- AWS Web Application Firewall (WAF)
  - `basic-app-waf`

## ECS：クラスター

- クラスター名
  - `basic-app-ecs-cluster`

## ECS：タスク定義

- タスク定義ファミリー名
  - `basic-app-ecs-task-def`

## ECS：サービス

### basic-app-backend

- クラスター
  - `basic-app-ecs-cluster`
- コンピューティングオプション
  - 起動タイプ
    - FARGATE
  - プラットフォームバージョン
    - LATEST
- アプリケーションタイプ
  - サービス
- タスク定義
  - `basic-app-ecs-task-def`
- サービス名
  - `basic-app-backend`
- ネットワーキング
  - VPC
    - `vpc-TestAWSBuild01`
  - サブネット
    - `subnet-TestAWSBuild01-protected-a`
    - `subnet-TestAWSBuild01-protected-c`
  - セキュリティグループ
    - `basic-app-ecs-service-sg`
  - パブリックIP
    - OFF
- ロードバランシング
  - ロードバランサーの種類
    - Application Load Balancer
  - コンテナ
    - `yna-g3-solid 8080:8080`
  - Application Load Balancer
    - 既存のロードバランサーを使用
      - ロードバランサー
        - `basic-app-alb`
      - リスナー
        - 既存のリスナーを使用
          - 80: HTTP
      - ターゲットグループ
        - 既存のターゲットグループを使用
          - ターゲットグループ名
            - `basic-app-alb-tg`
          - ヘルスチェックパス
            - `/basicapp/HelloWorld`
          - ヘルスチェックプロトコル
            - `HTTP`

**AWS CLI:**

``` powershell
aws ecs create-service `
  --cluster basic-app-ecs-cluster `
  --task-definition basic-app-ecs-task-def `
  --service-name basic-app-backend `
  --desired-count 1 `
  --launch-type FARGATE `
  --network-configuration "awsvpcConfiguration={subnets=[subnet-0e90fa73b9a4fe02b,subnet-0cb868b561c344577],securityGroups=[sg-0b928a4e6d80ab92e],assignPublicIp=DISABLED}" `
  --load-balancers "targetGroupArn=arn:aws:elasticloadbalancing:ap-northeast-1:140651483960:targetgroup/basic-app-alb-tg/299129bcbbab0864,containerName=yna-g3-solid,containerPort=8080" `
  --enable-execute-command
```

### ECS ExecuteCommand

`aws ecs execute-command`実行のためは、ECSサービスの設定：`--enable-execute-command`をONにする必要があるが、
このフラグは AWS Web Console で設定できないため、AWS　CLIコマンドを発行して設定しなければならない。

参考：https://dev.classmethod.jp/articles/ecs-exec/

下記のコマンドを実行して、サービスの更新＆強制デプロイを実行する。
`aws ecs execute-command`実行は、ECSサービスにて`--enable-execute-command`を有効にした後に起動したECSタスクでのみ利用可能となるため、
`--force-new-deployment`を指定して強制デプロイも実施している。

ただし、前述の`aws ecs create-service`コマンドでサービスを起動している場合は、起動時に`--enable-execute-command`を設定済みのため実施は不要。

``` powershell
aws ecs update-service `
  --cluster basic-app-ecs-cluster `
  --service basic-app-backend `
  --enable-execute-command
  --force-new-deployment
```

**テスト用コマンド例**

- ECSサービスの設定を確認
  ``` powershell
  aws ecs describe-services `
    --cluster basic-app-ecs-cluster `
    --services basic-app-backend
  ```

- 指定のECSタスクでコマンドを実行
  ``` powershell
  aws ecs execute-command `
    --cluster basic-app-ecs-cluster `
    --task ${ECS_TASK_ID} `
    --container yna-g3-solid `
    --interactive `
    --command "ps aux"
  ```

- 指定のECSタスクでコマンドを実行 (localhostにGETリクエスト)
  ``` powershell
  aws ecs execute-command `
    --cluster basic-app-ecs-cluster `
    --task ${TASK_ID} `
    --container yna-g3-solid `
    --interactive `
    --command "curl -i http://localhost:8080/basicapp/public/getApCheck.json"
  ```

- 指定のECSタスクでコマンドを実行 (localhostにPOSTリクエスト)
  ``` powershell
  aws ecs execute-command `
    --cluster basic-app-ecs-cluster `
    --task 3eb3520a789f4ac3b9b000b3d1232e78 `
    --container yna-g3-solid `
    --interactive `
    --command 'curl -i -X POST -H "Content-Type: application/json" -d ''{"filterName" : ""}\'' http://localhost:8080/basicapp/getUserDataFromDb.json'
  ```

---

## 補足

### push docker image to ECR

ローカルPCからAWS CLIを使って、ECRにコンテナイメージをPush。
クローンした [YMSL-J/basic-app-backend](https://github.com/YMSL-J/basic-app-backend) のルートディレクトリで下記を実施。
AWS CLI と Session Manager Plugin がインストール済み AND Credentials

``` bash
# Build solid application
./gradlew build -x test

# Build Image and add tag
docker build -t 140651483960.dkr.ecr.ap-northeast-1.amazonaws.com/basic-app-backend:local .

# Login ECR
aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin 140651483960.dkr.ecr.ap-northeast-1.amazonaws.com

# Push to ECR
docker push 140651483960.dkr.ecr.ap-northeast-1.amazonaws.com/basic-app-backend:local

# Logout ECR
docker logout public.ecr.aws
```

### データ準備

ユーザー、データベース、スキーマ、テーブル、データを準備する。

1. マスターユーザーで実施
   1. アプリユーザー(basicapp)を作成
      ``` sql
      CREATE USER basicapp WITH PASSWORD '**********';
      ```
   2. アプリユーザーをOwnerとしてデータベースを作成
      ``` sql
      CREATE DATABASE basicapp OWNER basicapp;
      ```

2. アプリユーザー(basicapp)で実施
   1. スキーマを作成
      ``` sql
      CREATE SCHEMA basicapp
      ```
   2. テーブルを作成 (参考：https://github.com/YMC-GROUP/yna-g3-solid-escort-learning/wiki/02.-Predevelopment,-Database#sql-statements)
      ``` sql
      CREATE TABLE basicapp.business_user (
          id float4 NULL,
          code varchar NULL,
          "name" varchar NULL,
          create_author varchar NULL,
          create_datetime timestamp NULL,
          update_author varchar NULL,
          update_pgmid varchar NULL,
          update_datetime timestamp NULL,
          update_counter int4 NULL DEFAULT 0
      );
      ```
   3. データ投入
      ``` sql
      INSERT INTO basicapp.business_user (id, code, "name", create_author, create_datetime, update_author, update_pgmid, update_datetime, update_counter) VALUES
          (1.0, 'SL001', 'Lucy', 'ADMIN',now() ,'ADMIN', 'ADMIN', now(), 0),
          (2.0, 'SL002', 'Lily', 'ADMIN',now() ,'ADMIN', 'ADMIN', now(), 0),
          (3.0, 'SL003', 'Tom', 'ADMIN',now() ,'ADMIN', 'ADMIN', now(), 0),
          (4.0, 'SL004', 'Jack', 'ADMIN',now() ,'ADMIN', 'ADMIN', now(), 0);
      ```

   参考：https://github.com/YMC-GROUP/yna-g3-solid-escort-learning/wiki/02.-Predevelopment,-Database#sql-statements
