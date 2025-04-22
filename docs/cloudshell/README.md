# AWS ClouShell環境の実行方法

## 実行環境

Terraformを実行するために、AWS実行環境に下記のソフトウェアをインストールします。

| ソフトウェア名 | 必須 | 備考 |
|---------------|------|-----|
| Terraform CLI (Terraform Community Edition) | 〇 | 環境構築のみを実施する場合に必要<br>OA-Cubeの管理環境ではないため、ソフトウェア導入申請は不要 |

## 事前準備

### 1.Terraformのインストール

AWSマネージメントコンソールを開き、CloudShellでTerraform CLIのインストールをおこないます。  
展開するリージョンが選択されていることを確認してください。　　
  
``` shell
cd ~
git clone https://github.com/tfutils/tfenv.git ~/.tfenv
mkdir -p ~/.local/bin/
sudo ln -s ~/.tfenv/bin/* ~/.local/bin/
tfenv install 1.10.4
tfenv use 1.10.4
```
  
> [!Caution]  
> CloudShellへのTerraform CLIのインストールはIAM Roleごとに一度実行します。 
  
### 2.リポジトリーをCloudShellに配置（git clone実行）

GitHub認証のトークン設定は公式ドキュメントに従ってください。
``` shell
git clone <リポジトリURL>
```

### 3.リポジトリーの設定（cloudshellの作業フォルダーを/tmpにする）

``` shell
cd ~/<IaCのリポジトリー名>/infra
ln -s /tmp .terraform
```
