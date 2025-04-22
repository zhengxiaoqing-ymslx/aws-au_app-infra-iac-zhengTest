# モダナイズAWS検証 (Domain) {ignore=true}

[toc]

---

## なぜドメイン取得が必要なのか？

HTTPS通信をしたい。
- Webアプリケーションセキュリティ開発要件書にはSSL化が記述されている
  - SSL証明書を取得するためにはドメインが必要

## ドメインを取得する前の準備

WEBサイト開設申請書を作成し提出するルール。
  - [インターネット/ウェブサイトガイドライン](https://globalymc.sharepoint.com/teams/CC/ymccomm/SitePages/guide/secure/japanese/index.aspx)を参考に、WEBサイト開設申請書を作成して提出
  - WEBサイト開設申請書は、上記サイトからダウンロード可能
  - 提出先は、WEBサイト開設申請書に記載されている

## Route53：ホストゾーン

ホストゾーンを作成。

- ドメイン名
  - `modernizedaws.yna-g3.com`
- タイプ
  - `パブリックホストゾーン`

作成されたホストゾーンの**NSレコード**の値をコピー。(次手順で使用)

- コピーする値の例
	``` text
	ns-459.awsdns-57.com
	ns-902.awsdns-48.net
	ns-1484.awsdns-57.org
	ns-1782.awsdns-30.co.uk
	```

## (YNA-G3 Escort Develop Account) Route53：ホストゾーン

既に存在するホストゾーン(ドメイン名: `yna-g3.com`)へレコードを追加。

- レコード名
  - `modernizedaws`
- レコードタイプ
  - `NS`
- 値
  - 前の手順でコピーした値

## Route53：ホストゾーン

ホストゾーン(ドメイン名: `modernizedaws.yna-g3.com`)へレコードを追加。(CloudFrontのデフォルトドメインへのエイリアスを作成)

- レコード名
  - 未入力
- レコードタイプ
  - `A`
- エイリアス
  - `ON`
- トラフィックのルーティング先
  - CloudFrontディストリビューションへのエイリアス
	- 既に作成しているCloudFrontを選択
- ルーティングポリシー
  - シンプルルーティング

## ACM：証明書

CloudFrontのSSL証明書を作成。
リージョンは`バージニア北部`とする。

- 証明書タイプ
  - `パブリック証明書をリクエスト`
- 完全修飾ドメイン名
  - `modernizedaws.yna-g3.com`
  - `www.modernizedaws.yna-g3.com`
- 検証方法
  - `DNS検証`
- キーアルゴリズム
  - `RSA 2048`

## CloudFront：証明書

CloudFrontへACMで作成した証明書を設定。
予め作成済のディストリビューションを選択し、一般 > 設定 > 編集

- Alternative domain name
  - `modernizedaws.yna-g3.com`
  - `www.modernizedaws.yna-g3.com`
- Custom SSL certificate
  - `modernizedaws.yna-g3.com` ※前手順のACMで作成されたSSL証明書
  - Security policy
    - `TLSv1.2_2021`

---

## Route53：ホストゾーン

ホストゾーン(ドメイン名: `modernizedaws.yna-g3.com`)へレコードを追加。(ALBのデフォルトドメインへのエイリアスを作成)

- レコード名
  - `alb`
- レコードタイプ
  - `CNAME`
- 値
  - `basic-app-alb-1922645840.ap-northeast-1.elb.amazonaws.com`
- ルーティングポリシー
  - シンプルルーティング

## ACM：証明書

ALBのSSL証明書を作成。
リージョンは`東京`とする。

- 証明書タイプ
  - `パブリック証明書をリクエスト`
- 完全修飾ドメイン名
  - `alb.modernizedaws.yna-g3.com`
- 検証方法
  - `DNS検証`
- キーアルゴリズム
  - `RSA 2048`

## EC2：ロードバランシング

### リスナー

HTTPSのリスナーを追加。

- リスナーの詳細
	- プロトコル
	  - `HTTPS`
	- ポート
	  - `443`
	- アクションのルーティング
	  - `ターゲットグループへ転送`
	- ターゲットグループ
	  - `basic-app-alb-tg`
- セキュアリスナーの設定
  - デフォルト SSL/TLS サーバー証明書
    - `ACMから`
  - 証明書 (ACM から)
    - `alb.modernizedaws.yna-g3.com`

## VPC：セキュリティグループ

ALBがHTTPS(443)のアクセスを受け付けることができるようにする。
既存の `basic-app-ecs-service-alb-sg` を編集。

- インバウンドルール
  - タイプ
    - `HTTPS`
  - ソース
    - `pl-58a04531` ※CloudFrontのプレフィックスリスト

---

## CloudFront

### ディストリビューション

- オリジン
  - Origin domain
    - `alb.modernizedaws.yna-g3.com`
  - プロトコル
    - `HTTPSのみ`
      - HTTPS port
        - `443`
      - Minimum Origin SSL protocol
        - `TLSv1.2`
  - 名前
    - `backend`
- ビヘイビア
  - パスパターン
    - `/basicapp/*`
  - オリジンとオリジングループ
    - `backend` ※前手順で作成したオリジンの名前
  - ビューワープロトコルポリシー
    - `HTTPS only`
  - 許可された HTTP メソッド
    - `GET, HEAD, OPTIONS, PUT, POST, PATCH, DELETE`
  - キャッシュキーとオリジンリクエスト
    - `Cache policy and origin request policy (recommended)`
	  - キャッシュポリシー
	    - `CachingDisabled`
	  - オリジンリクエストポリシー
	    - `AllViewer`
